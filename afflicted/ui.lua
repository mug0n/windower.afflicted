local ui = {}

local images = require("images")
local texts = require("texts")

local FONT             = "Arial"
local FONT_SIZE        = 12
local HEADER_FONT_SIZE = 10

local WIDTH            = 200
local TOP_HEIGHT       = 4
local BOTTOM_HEIGHT    = 4
local HEADER_HEIGHT    = 18
local SEPARATOR_HEIGHT = 2
local ROW_HEIGHT       = 20
local PADDING_X        = 8
local TEXT_OFFSET_Y    = -2

-- stores all UI elements
ui.elements = {}
ui.middle_rows = T{}
ui.rows = T{}
ui.timers = T{}
ui.row_count = 0

-- references to external data
ui.settings = nil

-- initialize UI (top/bottom borders only)
ui.initialize = function(settings)
    ui.settings = settings

    local x, y  = settings.pos.x, settings.pos.y
    ui.elements.top       = ui.draw_image("bg_top.png",       WIDTH, TOP_HEIGHT,       x, y)
    ui.elements.header    = ui.draw_image("bg_mid.png",       WIDTH, ROW_HEIGHT,       x, y + TOP_HEIGHT)
    ui.elements.separator = ui.draw_image("bg_separator.png", WIDTH, SEPARATOR_HEIGHT, x, y + TOP_HEIGHT + ROW_HEIGHT)
    ui.elements.mid       = ui.draw_image("bg_mid.png",       WIDTH, ROW_HEIGHT,       x, y + TOP_HEIGHT)
    ui.elements.bottom    = ui.draw_image("bg_bottom.png",    WIDTH, BOTTOM_HEIGHT,    x, y + TOP_HEIGHT)
end

ui.show = function()
    for _, element in pairs(ui.elements) do element:show() end
    for _, row     in pairs(ui.rows)     do row:show()     end
    for _, timer   in pairs(ui.timers)   do timer:show()   end
end

ui.hide = function()
    for _, element in pairs(ui.elements) do element:hide() end
    for _, row     in pairs(ui.rows)     do row:hide()     end
    for _, timer   in pairs(ui.timers)   do timer:hide()   end
end

-- update using render model
ui.update = function(target, render_rows)
    local x, y   = ui.settings.pos.x, ui.settings.pos.y
    local text_offset_y   = math.floor((ROW_HEIGHT - FONT_SIZE * 1.2) / 2) + TEXT_OFFSET_Y
    local header_offset_y = math.floor((HEADER_HEIGHT - FONT_SIZE * 1.2) / 2) + TEXT_OFFSET_Y
    local timer_width     = math.floor(5 * FONT_SIZE * 0.6)
    local content_y       = y + TOP_HEIGHT + HEADER_HEIGHT + SEPARATOR_HEIGHT

    -- top border
    ui.elements.top:size(WIDTH, TOP_HEIGHT)
    ui.elements.top:pos(x, y)
    ui.elements.top:show()

    -- header background
    ui.elements.header:size(WIDTH, HEADER_HEIGHT)
    ui.elements.header:pos(x, y + TOP_HEIGHT)
    ui.elements.header:show()

    -- header name (left-aligned)
    if not ui.elements.header_text then
        ui.elements.header_text = ui.draw_text(x + PADDING_X, y + TOP_HEIGHT + header_offset_y, HEADER_FONT_SIZE)
    end

    ui.elements.header_text:pos(x + PADDING_X, y + TOP_HEIGHT + header_offset_y)
    ui.elements.header_text:text(target.name or "Unknown")
    ui.elements.header_text:show()

    -- header id (right-aligned)
    local id_str   = tostring(target.id or 0)
    local id_width = math.floor(#id_str * HEADER_FONT_SIZE * 0.8)

    if not ui.elements.header_id then
        ui.elements.header_id = ui.draw_text(
            x + WIDTH - PADDING_X - id_width,
            y + TOP_HEIGHT + header_offset_y,
            HEADER_FONT_SIZE,
            64, 224, 208
        )
    end

    ui.elements.header_id:pos(x + WIDTH - PADDING_X - id_width, y + TOP_HEIGHT + header_offset_y)
    ui.elements.header_id:text(id_str)
    ui.elements.header_id:show()

    -- separator
    ui.elements.separator:size(WIDTH, SEPARATOR_HEIGHT)
    ui.elements.separator:pos(x, y + TOP_HEIGHT + HEADER_HEIGHT)
    ui.elements.separator:show()

    -- mid background stretched over debuff rows
    ui.elements.mid:size(WIDTH, #render_rows * ROW_HEIGHT)
    ui.elements.mid:pos(x, content_y)
    ui.elements.mid:show()

    -- debuffs rows
    for i, row_data in ipairs(render_rows) do
        local row_y = content_y + (i - 1) * ROW_HEIGHT

        -- name text
        if not ui.rows[i] then
            ui.rows[i] = ui.draw_text(x + PADDING_X, row_y + text_offset_y)
        end

        ui.rows[i]:pos(x + PADDING_X, row_y + text_offset_y)
        ui.rows[i]:text(row_data.name or "")
        ui.rows[i]:show()

        -- timer text
        if not ui.timers[i] then
            ui.timers[i] = ui.draw_text(x + WIDTH - PADDING_X, row_y + text_offset_y)
        end

        ui.timers[i]:pos(x + WIDTH - PADDING_X - timer_width, row_y + text_offset_y)
        ui.timers[i]:text(ui.format_time(row_data.remaining or 0))
        ui.timers[i]:show()
    end

    -- destroy excess rows
    for i = #render_rows + 1, ui.row_count do
        if ui.rows[i]   then ui.rows[i]:destroy();   ui.rows[i]   = nil end
        if ui.timers[i] then ui.timers[i]:destroy();  ui.timers[i] = nil end
    end
    ui.row_count = #render_rows

    -- bottom border
    local bottom_y = content_y + (#render_rows * ROW_HEIGHT)
    ui.elements.bottom:size(WIDTH, BOTTOM_HEIGHT)
    ui.elements.bottom:pos(x, bottom_y)
    ui.elements.bottom:show()
end

-- destroy
ui.destroy = function()
    for _, element in pairs(ui.elements) do element:destroy() end
    for _, row in pairs(ui.rows) do row:destroy() end
    for _, timer in pairs(ui.timers) do timer:destroy() end
    ui.rows = T{}
    ui.timers = T{}
end

-- format seconds as M:SS
ui.format_time = function(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
end

ui.draw_image = function(path, width, height, x, y)
    return images.new({
        texture   = { path = windower.addon_path .. "assets/" .. path, fit = true },
        size      = { width = width, height = height },
        position  = { x = x, y = y },
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
            stroke = { width = 2, alpha = 180, red = 0, green = 0, blue = 0 },
        },
        bg    = { visible = false },
        flags = { draggable = false, right = false },
        visible = false,
    })
end

return ui
