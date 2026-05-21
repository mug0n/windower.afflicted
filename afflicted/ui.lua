local images = require("images")
local texts  = require("texts")

local FONT             = "Arial"
local FONT_SIZE        = 12
local HEADER_FONT_SIZE = 10

local MAIN_WIDTH       = 200
local SLEEP_WIDTH      = 320
local TOP_HEIGHT       = 4
local BOTTOM_HEIGHT    = 4
local HEADER_HEIGHT    = 18
local SEPARATOR_HEIGHT = 2
local ROW_HEIGHT       = 20
local PADDING_X        = 8
local HEADER_OFFSET_Y  = -4
local TEXT_OFFSET_Y    = -2

local TIMER_WIDTH = math.floor(5 * FONT_SIZE * 0.6)
local SPELL_WIDTH = math.floor(14 * FONT_SIZE * 0.6)

-- stores all UI elements
local ui = {
    main = {
        pos       = {},
        elements  = {},
        rows      = T{},
        spells    = T{}, -- only used for sleep window, but initialized for both for simplicity
        timers    = T{},
        row_count = 0,
    },
    sleep = {
        pos       = {},
        elements  = {},
        rows      = T{},
        spells    = T{},
        timers    = T{},
        row_count = 0,
    },
}

-- initialize main UI
ui.initialize = function(settings)
    ui.initialize_elements("main",  settings.main_pos,  MAIN_WIDTH)
    ui.initialize_elements("sleep", settings.sleep_pos, SLEEP_WIDTH)
end

-- initialize helper
ui.initialize_elements = function(id, pos, width)
    local x, y = pos.x, pos.y
    ui[id].pos = { x = x, y = y }
    ui[id].width = width

    ui[id].elements.top       = ui.draw_image("bg_top.png",       width, TOP_HEIGHT,       x, y)
    ui[id].elements.header    = ui.draw_image("bg_mid.png",       width, HEADER_HEIGHT,    x, y + TOP_HEIGHT)
    ui[id].elements.separator = ui.draw_image("bg_separator.png", width, SEPARATOR_HEIGHT, x, y + TOP_HEIGHT + HEADER_HEIGHT)
    ui[id].elements.mid       = ui.draw_image("bg_mid.png",       width, ROW_HEIGHT,       x, y + TOP_HEIGHT)
    ui[id].elements.bottom    = ui.draw_image("bg_bottom.png",    width, BOTTOM_HEIGHT,    x, y + TOP_HEIGHT)
end

ui.show = function(id)
    id = id or "main"
    for _, element in pairs(ui[id].elements) do element:show()   end
    for _, row     in pairs(ui[id].rows)     do row:show()       end
    for _, timer   in pairs(ui[id].timers)   do timer.obj:show() end
    for _, spell   in pairs(ui[id].spells)   do spell:show()     end
end

ui.hide = function(id)
    id = id or "main"
    for _, element in pairs(ui[id].elements) do element:hide()   end
    for _, row     in pairs(ui[id].rows)     do row:hide()       end
    for _, timer   in pairs(ui[id].timers)   do timer.obj:hide() end
    for _, spell   in pairs(ui[id].spells)   do spell:hide()     end
end

-- update using render model
ui.update = function(id, render_rows, header)
    local w               = ui[id]
    local x, y            = w.pos.x, w.pos.y
    local width           = w.width
    local header_offset_y = math.floor((HEADER_HEIGHT - HEADER_FONT_SIZE * 1.2) / 2) + HEADER_OFFSET_Y
    local text_offset_y   = math.floor((ROW_HEIGHT - FONT_SIZE * 1.2) / 2) + TEXT_OFFSET_Y
    local content_y       = y + TOP_HEIGHT + HEADER_HEIGHT + SEPARATOR_HEIGHT
    local is_sleep        = (id == "sleep")

    -- if no debuffs, show placeholder row
    if #render_rows == 0 then
        render_rows = T{{ name = "No debuffs found.", remaining = nil }}
    end

    -- top border
    w.elements.top:size(width, TOP_HEIGHT)
    w.elements.top:pos(x, y)
    w.elements.top:show()

    -- header background
    w.elements.header:size(width, HEADER_HEIGHT)
    w.elements.header:pos(x, y + TOP_HEIGHT)
    w.elements.header:show()

    -- header name (left-aligned)
    if not w.elements.header_text then
        w.elements.header_text = ui.draw_text(x + PADDING_X, y + TOP_HEIGHT + header_offset_y, HEADER_FONT_SIZE)
    end
    w.elements.header_text:pos(x + PADDING_X, y + TOP_HEIGHT + header_offset_y)
    w.elements.header_text:text(header and header.name or "")
    w.elements.header_text:show()

    -- header id (right-aligned, only when provided)
    if header and header.id then
        local id_str   = tostring(header.id)
        local id_width = math.floor(#id_str * HEADER_FONT_SIZE * 0.8)
        if not w.elements.header_id then
            w.elements.header_id = ui.draw_text(x + width - PADDING_X - id_width, y + TOP_HEIGHT + header_offset_y, HEADER_FONT_SIZE, 64, 224, 208)
        end
        w.elements.header_id:pos(x + width - PADDING_X - id_width, y + TOP_HEIGHT + header_offset_y)
        w.elements.header_id:text(id_str)
        w.elements.header_id:show()
    elseif w.elements.header_id then
        w.elements.header_id:hide()
    end

    -- separator
    w.elements.separator:size(width, SEPARATOR_HEIGHT)
    w.elements.separator:pos(x, y + TOP_HEIGHT + HEADER_HEIGHT)
    w.elements.separator:show()

    -- mid background stretched to fit rows
    w.elements.mid:size(width, #render_rows * ROW_HEIGHT)
    w.elements.mid:pos(x, content_y)
    w.elements.mid:show()

    -- rows
    for i, row_data in ipairs(render_rows) do
        local row_y = content_y + (i - 1) * ROW_HEIGHT

        -- name (left-aligned)
        if not w.rows[i] then
            w.rows[i] = ui.draw_text(x + PADDING_X, row_y + text_offset_y)
        end
        w.rows[i]:pos(x + PADDING_X, row_y + text_offset_y)
        w.rows[i]:text(row_data.name or "")
        w.rows[i]:show()

        -- spell name column (sleep window only)
        if is_sleep then
            local spell_x = x + width - PADDING_X - TIMER_WIDTH - SPELL_WIDTH
            if not w.spells[i] then
                w.spells[i] = ui.draw_text(spell_x, row_y + text_offset_y, nil, 180, 180, 255)
            end
            w.spells[i]:pos(spell_x, row_y + text_offset_y)
            w.spells[i]:text(row_data.spell_name or "")
            w.spells[i]:show()
        end

        -- timer (right-aligned, color-coded)
        local r, g, b   = ui.timer_color(row_data.remaining or 0, row_data.duration)
        local color_key = r .. "," .. g .. "," .. b
        if not w.timers[i] then
            w.timers[i] = { obj = nil, color = nil }
        end
        if not w.timers[i].obj or w.timers[i].color ~= color_key then
            if w.timers[i].obj then w.timers[i].obj:destroy() end
            w.timers[i].obj   = ui.draw_text(x + width - PADDING_X - TIMER_WIDTH, row_y + text_offset_y, nil, r, g, b)
            w.timers[i].color = color_key
        end
        w.timers[i].obj:pos(x + width - PADDING_X - TIMER_WIDTH, row_y + text_offset_y)
        w.timers[i].obj:text(row_data.remaining and ui.format_time(row_data.remaining) or "")
        w.timers[i].obj:show()
    end

    -- destroy excess rows
    for i = #render_rows + 1, w.row_count do
        if w.rows[i] then w.rows[i]:destroy(); w.rows[i] = nil end
        if w.timers[i] then w.timers[i].obj:destroy(); w.timers[i] = nil end
        if w.spells[i] then w.spells[i]:destroy(); w.spells[i] = nil end
    end
    w.row_count = #render_rows

    -- bottom border
    local bottom_y = content_y + (#render_rows * ROW_HEIGHT)
    w.elements.bottom:size(width, BOTTOM_HEIGHT)
    w.elements.bottom:pos(x, bottom_y)
    w.elements.bottom:show()
end

-- destroy
ui.destroy = function()
    for _, id in ipairs({ "main", "sleep" }) do
        for _, element in pairs(ui[id].elements) do element:destroy()   end
        for _, row     in pairs(ui[id].rows)     do row:destroy()       end
        for _, timer   in pairs(ui[id].timers)   do timer.obj:destroy() end
        for _, spell   in pairs(ui[id].spells)   do spell:destroy()     end
    end
end

ui.draw_image = function(path, width, height, x, y)
    return images.new({
        texture   = { path = windower.addon_path .. "assets/" .. path, fit = true, },
        size      = { width = width, height = height, },
        position  = { x = x, y = y, },
        draggable = false,
        visible   = false,
    })
end

ui.draw_text = function(x, y, size, red, green, blue)
    return texts.new({
        pos   = { x = x, y = y },
        text  = {
            font   = FONT,
            size   = size or FONT_SIZE,
            red    = red   or 255,
            green  = green or 255,
            blue   = blue  or 255,
            alpha  = 255,
            stroke = { width = 2, alpha = 180, red = 0, green = 0, blue = 0, },
        },
        bg    = { visible = false, },
        flags = { draggable = false, },
        visible = false,
    })
end

-- format seconds as M:SS
ui.format_time = function(seconds)
    local total   = math.ceil(seconds)
    local minutes = math.floor(total / 60)
    local secs    = total % 60
    return string.format("%d:%02d", minutes, secs)
end

ui.timer_color = function(remaining, duration)
    if duration and duration > 0 then
        local ratio = remaining / duration
        if ratio <= 0.1 then
            return 255, 80, 80    -- red
        elseif ratio <= 0.6 then
            return 255, 220, 0    -- yellow
        end
    end
    return 255, 255, 255          -- white
end

return ui
