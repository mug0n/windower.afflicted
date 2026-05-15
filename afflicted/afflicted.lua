_addon.name = "Afflicted"
_addon.author = "mug0n"
_addon.version = "1.0.4"
_addon.command = "afflicted"

-- required libraries
local chat = require("chat")
local config = require("config")
local packets = require("packets")

-- script files
local ui = require("ui")

-- default config stuff
local defaults = {
    pos = {
        x = 480,
        y = 120,
    },
    gc_interval = 1.0,
    ui_interval = 0.2,
}

local settings = config.load(defaults)
config.save(settings)

-- afflicted stuff
local Afflicted = {}
local last_ui = 0
local last_gc = 0

Afflicted.debug_mode = false
Afflicted.targets = {}

-- list of status effects we will be tracking
Afflicted.effects = {
    SLEEP           =   2,
    POISON          =   3,
    PARALYSIS       =   4,
    BLINDNESS       =   5,
    SILENCE         =   6,
    PETRIFICATION   =   7,
    DISEASE         =   8,
    CURSE           =   9,
    STUN            =  10,
    BIND            =  11,
    WEIGHT          =  12,
    SLOW            =  13,
    ADDLE           =  21,
    INTIMIDATE      =  22,
    TERROR          =  28,
    PLAGUE          =  31,
    BURN            = 128,
    FROST           = 129,
    CHOKE           = 130,
    RASP            = 131,
    SHOCK           = 132,
    DROWN           = 133,
    DIA             = 134,
    BIO             = 135,
    STR_DOWN        = 136,
    DEX_DOWN        = 137,
    VIT_DOWN        = 138,
    AGI_DOWN        = 139,
    INT_DOWN        = 140,
    MND_DOWN        = 141,
    CHR_DOWN        = 142,
    MAX_HP_DOWN     = 144,
    MAX_MP_DOWN     = 145,
    ACCURACY_DOWN   = 146,
    ATTACK_DOWN     = 147,
    EVASION_DOWN    = 148,
    DEFENSE_DOWN    = 149,
    FLASH           = 156,
    MAGIC_DEF_DOWN  = 167,
    MAGIC_ACC_DOWN  = 174,
    MAGIC_ATK_DOWN  = 175,
    REQUIEM         = 192,
    ELEGY           = 194,
    THRENODY        = 217,
    NOCTURNE        = 223,
    MAGIC_EVA_DOWN  = 404,
    INUNDATION      = 597,
}

-- list of spells that trigger the effects we want to track
Afflicted.spells = {
    [23]  = { duration =  60, effect = { Afflicted.effects.DIA, },              name = "Dia", },
    [24]  = { duration = 120, effect = { Afflicted.effects.DIA, },              name = "Dia II",                removes = T{ 23, 33, 230 }, },
    [25]  = { duration = 180, effect = { Afflicted.effects.DIA, },              name = "Dia III",               removes = T{ 23, 24, 33, 230, 231 }, },
    [33]  = { duration =  60, effect = { Afflicted.effects.DIA, },              name = "Diaga",                 removes = T{ 23 }, },
    [56]  = { duration = 180, effect = { Afflicted.effects.SLOW, },             name = "Slow", },
    [58]  = { duration = 120, effect = { Afflicted.effects.PARALYSIS, },        name = "Paralyze", },
    [59]  = { duration = 120, effect = { Afflicted.effects.SILENCE, },          name = "Silence", },
    [79]  = { duration = 180, effect = { Afflicted.effects.SLOW, },             name = "Slow II", },
    [80]  = { duration = 120, effect = { Afflicted.effects.PARALYSIS, },        name = "Paralyze II", },
    [98]  = { duration =  90, effect = { Afflicted.effects.SLEEP, },            name = "Repose",                removes = T{ 253, 273, 376, 463 }, },
    [112] = { duration =  12, effect = { Afflicted.effects.FLASH, },            name = "Flash", },
    [216] = { duration = 120, effect = { Afflicted.effects.WEIGHT, },           name = "Gravity", },
    [217] = { duration = 120, effect = { Afflicted.effects.WEIGHT, },           name = "Gravity II", },
    [220] = { duration =  30, effect = { Afflicted.effects.POISON, },           name = "Poison", },
    [221] = { duration = 120, effect = { Afflicted.effects.POISON, },           name = "Poison II", },
    [225] = { duration =  60, effect = { Afflicted.effects.POISON, },           name = "Poisonga", },
    [226] = { duration = 120, effect = { Afflicted.effects.POISON, },           name = "Poisonga II", },
    [230] = { duration =  60, effect = { Afflicted.effects.BIO, },              name = "Bio",                   removes = T{ 23, 33 }, },
    [231] = { duration = 120, effect = { Afflicted.effects.BIO, },              name = "Bio II",                removes = T{ 23, 24, 33, 230 }, },
    [232] = { duration = 180, effect = { Afflicted.effects.BIO, },              name = "Bio III",               removes = T{ 23, 24, 25, 33, 230, 231 }, },
    [235] = { duration = 120, effect = { Afflicted.effects.BURN, },             name = "Burn",                  removes = T{ 236 }, },
    [236] = { duration = 120, effect = { Afflicted.effects.FROST, },            name = "Frost",                 removes = T{ 237 }, },
    [237] = { duration = 120, effect = { Afflicted.effects.CHOKE, },            name = "Choke",                 removes = T{ 238 }, },
    [238] = { duration = 120, effect = { Afflicted.effects.RASP, },             name = "Rasp",                  removes = T{ 239 }, },
    [239] = { duration = 120, effect = { Afflicted.effects.SHOCK, },            name = "Shock",                 removes = T{ 240 }, },
    [240] = { duration = 120, effect = { Afflicted.effects.DROWN, },            name = "Drown",                 removes = T{ 235 }, },
    [252] = { duration =   5, effect = { Afflicted.effects.STUN, },             name = "Stun", },
    [253] = { duration =  60, effect = { Afflicted.effects.SLEEP, },            name = "Sleep", },
    [254] = { duration = 180, effect = { Afflicted.effects.BLINDNESS, },        name = "Blind", },
    [255] = { duration =  30, effect = { Afflicted.effects.PETRIFICATION, },    name = "Break", },
    [258] = { duration =  60, effect = { Afflicted.effects.BIND, },             name = "Bind", },
    [259] = { duration =  90, effect = { Afflicted.effects.SLEEP, },            name = "Sleep II",              removes = T{ 253, 273, 376, 463 }, },
    [273] = { duration =  60, effect = { Afflicted.effects.SLEEP, },            name = "Sleepga", },
    [274] = { duration =  90, effect = { Afflicted.effects.SLEEP, },            name = "Sleepga II",            removes = T{ 253, 273, 376, 463 }, },
    [276] = { duration = 180, effect = { Afflicted.effects.BLINDNESS, },        name = "Blind II", },
    [286] = { duration = 180, effect = { Afflicted.effects.ADDLE, },            name = "Addle", },
    [319] = { duration = 120, effect = { Afflicted.effects.ATTACK_DOWN, },      name = "Aisha: Ichi", },
    [341] = { duration = 180, effect = { Afflicted.effects.PARALYSIS, },        name = "Jubaku: Ichi", },
    [344] = { duration = 180, effect = { Afflicted.effects.SLOW, },             name = "Hojo: Ichi", },
    [345] = { duration = 300, effect = { Afflicted.effects.SLOW, },             name = "Hojo: Ni",              removes = T{ 344 }, },
    [347] = { duration = 180, effect = { Afflicted.effects.BLINDNESS, },        name = "Kurayami: Ichi", },
    [348] = { duration = 300, effect = { Afflicted.effects.BLINDNESS, },        name = "Kurayami: Ni",          removes = T{ 347 }, },
    [350] = { duration =  60, effect = { Afflicted.effects.POISON, },           name = "Dokumori: Ichi", },
    [365] = { duration =  30, effect = { Afflicted.effects.PETRIFICATION, },    name = "Breakga", },
    [368] = { duration =  64, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem", },
    [369] = { duration =  80, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem II",        removes = T{ 368 }, },
    [370] = { duration =  96, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem III",       removes = T{ 368, 369 }, },
    [371] = { duration = 112, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem IV",        removes = T{ 368, 369, 370 }, },
    [372] = { duration = 128, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem V",         removes = T{ 368, 369, 370, 371 }, },
    [373] = { duration = 144, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem VI",        removes = T{ 368, 369, 370, 371, 372 }, },
    [374] = { duration = 160, effect = { Afflicted.effects.REQUIEM, },          name = "Foe Requiem VII",       removes = T{ 368, 369, 370, 371, 372, 373 }, },
    [376] = { duration =  30, effect = { Afflicted.effects.SLEEP, },            name = "Horde Lullaby", },
    [421] = { duration = 120, effect = { Afflicted.effects.ELEGY, },            name = "Battlefield Elegy", },
    [422] = { duration = 180, effect = { Afflicted.effects.ELEGY, },            name = "Carnage Elegy",         removes = T{ 421 }, },
    [423] = { duration = 240, effect = { Afflicted.effects.ELEGY, },            name = "Massacre Elegy",        removes = T{ 421, 422 }, },
    [454] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Fire Threnody",         removes = T{ 455, 456, 457, 458, 459, 460, 461 }, },
    [455] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Ice Threnody",          removes = T{ 454, 456, 457, 458, 459, 460, 461 }, },
    [456] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Wind Threnody",         removes = T{ 454, 455, 457, 458, 459, 460, 461 }, },
    [457] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Earth Threnody",        removes = T{ 454, 455, 456, 458, 459, 460, 461 }, },
    [458] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Lightning Threnody",    removes = T{ 454, 455, 456, 457, 459, 460, 461 }, },
    [459] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Water Threnody",        removes = T{ 454, 455, 456, 457, 458, 460, 461 }, },
    [460] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Light Threnody",        removes = T{ 454, 455, 456, 457, 458, 459, 461 }, },
    [461] = { duration =  60, effect = { Afflicted.effects.THRENODY, },         name = "Dark Threnody",         removes = T{ 454, 455, 456, 457, 458, 459, 460 }, },
    [463] = { duration =  30, effect = { Afflicted.effects.SLEEP, },            name = "Foe Lullaby", },
    [513] = { duration = 180, effect = { Afflicted.effects.POISON, },           name = "Venom Shell", },
    [524] = { duration =  60, effect = { Afflicted.effects.ACCURACY_DOWN, },    name = "Sandspin", },
    [531] = { duration =   5, effect = { Afflicted.effects.BIND, },             name = "Ice Break", },
    [535] = { duration =  30, effect = { Afflicted.effects.FROST, },            name = "Cold Wave", },
    [536] = { duration =  30, effect = { Afflicted.effects.POISON, },           name = "Poison Breath", },
    [572] = { duration =  30, effect = { Afflicted.effects.BURN, },             name = "Sound Blast", },
    [575] = { duration =  10, effect = { Afflicted.effects.TERROR, },           name = "Jettatura", },
    [584] = { duration =  45, effect = { Afflicted.effects.SLEEP, },            name = "Sheep Song", },
    [588] = { duration = 120, effect = { Afflicted.effects.PLAGUE, },           name = "Lowing", },
    [598] = { duration =  90, effect = { Afflicted.effects.SLEEP, },            name = "Soporific" },
    [599] = { duration =  30, effect = { Afflicted.effects.POISON, },           name = "Queasyshroom", },
    [608] = { duration =  60, effect = { Afflicted.effects.PARALYSIS, },        name = "Frost Breath", },
    [610] = { duration =  60, effect = { Afflicted.effects.EVASION_DOWN, },     name = "Infrasonics", },
    [611] = { duration = 180, effect = { Afflicted.effects.POISON, },           name = "Disseverment", },
    [638] = { duration =  30, effect = { Afflicted.effects.POISON, },           name = "Feather Storm", },
    [644] = { duration =  60, effect = { Afflicted.effects.PARALYSIS, },        name = "Mind Blast", },
    [651] = { duration =  60, effect = { Afflicted.effects.ATTACK_DOWN, Afflicted.effects.DEFENSE_DOWN, }, name = "Corrosive Ooze", },
    [654] = { duration =  60, effect = { Afflicted.effects.PARALYSIS, },        name = "Sub-Zero Smash", },
    [656] = { duration =  12, effect = { Afflicted.effects.MAGIC_DEF_DOWN, },   name = "Acrid Stream", },
    [659] = { duration =  30, effect = { Afflicted.effects.ATTACK_DOWN, },      name = "Demoralizing Roar", },
    [678] = { duration =  60, effect = { Afflicted.effects.SLEEP, },            name = "Dream Flower", },
    [682] = { duration =  60, effect = { Afflicted.effects.PLAGUE, },           name = "Delta Thrust", },
    [699] = { duration =  60, effect = { Afflicted.effects.ACCURACY_DOWN, },    name = "Barbed Crescent", },
    [841] = { duration = 120, effect = { Afflicted.effects.EVASION_DOWN, },     name = "Distract", },
    [842] = { duration = 120, effect = { Afflicted.effects.EVASION_DOWN, },     name = "Distract II",           removes = T{ 841 }, },
    [843] = { duration = 120, effect = { Afflicted.effects.MAGIC_EVA_DOWN, },   name = "Frazzle", },
    [844] = { duration = 120, effect = { Afflicted.effects.MAGIC_EVA_DOWN, },   name = "Frazzle II",            removes = T{ 843 }, },
    [871] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Fire Threnody II",      removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 872, 873, 874, 875, 876, 877, 878 }, },
    [872] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Ice Threnody II",       removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 873, 874, 875, 876, 877, 878 }, },
    [873] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Wind Threnody II",      removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 874, 875, 876, 877, 878 }, },
    [874] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Earth Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 875, 876, 877, 878 }, },
    [875] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Ltng Threnody II",      removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 876, 877, 878 }, },
    [876] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Water Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 875, 877, 878 }, },
    [877] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Light Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 875, 876, 878 }, },
    [878] = { duration =  90, effect = { Afflicted.effects.THRENODY, },         name = "Dark Threnody II",      removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 875, 876, 877 }, },
    [879] = { duration = 300, effect = { Afflicted.effects.INUNDATION, },       name = "Inundation", },
}

Afflicted.addon_message = function(text)
    windower.add_to_chat(7, "[" .. _addon.name:color(338) .. "] " .. text)
end

Afflicted.get_target = function(target_id)
    return Afflicted.targets[target_id]
end

Afflicted.ensure_target = function(target_id)
    if not Afflicted.targets[target_id] then
        Afflicted.targets[target_id] = T{}
    end

    return Afflicted.targets[target_id]
end

Afflicted.remove_target = function(target_id)
    Afflicted.targets[target_id] = nil
end

Afflicted.apply_spell_effects = function(target_id, spell_id)
    if Afflicted.debug_mode then
        Afflicted.addon_message(string.format("Applying effects from spell %s to target %s.",  spell_id, target_id))
    end

    -- get target table and spell data
    local target = Afflicted.ensure_target(target_id)
    local spell = Afflicted.spells[spell_id]
    if not spell then return end

    -- check if the spell is blocked by any of the one currently applied
    -- (spell.blocked_by is generated at load time)
    local blocked_by = spell.blocked_by
    for _, v in ipairs(target) do
        -- cannot overwrite itself or is blocked by another
        if spell_id == v.spell_id or (blocked_by and blocked_by:contains(v.spell_id)) then
            if Afflicted.debug_mode then
                Afflicted.addon_message(string.format("Spell %s on %s was blocked by %s.", spell_id, target_id, v.spell_id))
            end
            return
        end
    end

    -- remove any effects this spell overwrites (spell.removes)
    local removes = spell.removes
    if removes then
        for i = #target, 1, -1 do
            local effect = target[i]

            if removes:contains(effect.spell_id) then
                if Afflicted.debug_mode then
                    Afflicted.addon_message(string.format("Spell %s on %s overwrites %s.", spell_id, target_id, effect.spell_id))
                end

                -- remove effect directly from target table since we know the index
                table.remove(target, i)
            end
        end
    end

    -- apply spell effect(s)
    for _, effect_id in ipairs(spell.effect) do
        Afflicted.add_effect(target_id, spell_id, effect_id, os.clock() + spell.duration)
    end
end

Afflicted.add_effect = function(target_id, spell_id, effect_id, expiration)
    if Afflicted.debug_mode then
        Afflicted.addon_message(string.format("Adding effect %s from spell %s to target %s.",  effect_id, spell_id, target_id))
    end

    -- init/get target table
    local target = Afflicted.ensure_target(target_id)

    -- add effect and duration to it
    -- guard against duplicates effects for these rare case where an effect could overwrite itself
    for _, effect in ipairs(target) do
        if effect.effect_id == effect_id then
            if Afflicted.debug_mode then
                Afflicted.addon_message(string.format("Refreshing effect %s from spell %s on target %s.",  effect_id, spell_id, target_id))
            end

            effect.spell_id = spell_id
            effect.expiration = expiration
            return
        end
    end

    table.insert(target, {
        spell_id = spell_id,
        effect_id = effect_id,
        expiration = expiration
    })
end

Afflicted.remove_effect = function(target_id, effect_id)
    if Afflicted.debug_mode then
        Afflicted.addon_message(string.format("Removing effect %s from target %s.",  effect_id, target_id))
    end

    -- find and remove effect from target table
    local target = Afflicted.get_target(target_id)
    if not target then return end

    for i = #target, 1, -1 do
        if target[i].effect_id == effect_id then
            table.remove(target, i)
        end
    end

    -- if table is empty after removing effect, remove target from afflicted targets
    if #target == 0 then Afflicted.remove_target(target_id) end
end

Afflicted.garbage_collect = function()
    local current_time = os.clock()
    for target_id, effects in pairs(Afflicted.targets) do
        local mob = windower.ffxi.get_mob_by_id(target_id)
        if not mob then
            -- mob is dead or out of range, remove it from afflicted targets
            Afflicted.targets[target_id] = nil
        else
            -- remove expired effects from target table
            for i = #effects, 1, -1 do
                if effects[i].expiration <= current_time then
                    table.remove(effects, i)
                end
            end

            -- if table is empty after removing expired effects, remove target from afflicted targets
            if #effects == 0 then
                Afflicted.targets[target_id] = nil
            end
        end
    end
end

Afflicted.build_render_model = function(target_id)
    local effects = Afflicted.targets[target_id]
    if not effects then return T{} end

    local now = os.clock()
    local render_data = T{}

    for _, effect in ipairs(effects) do
        local spell = Afflicted.spells[effect.spell_id]
        if spell then
            render_data:append({
                name = spell.name,
                effect_id = effect.effect_id,
                remaining = math.max(0, effect.expiration - now),
                spell_id = effect.spell_id
            })
        end
    end

    -- sort by remaining duration, ascending (soonest to expire first)
    table.sort(render_data, function(a, b)
        return a.remaining < b.remaining
    end)

    return render_data
end

windower.register_event("load", function()
    -- build a spell.removes reverse lookup cache (spell.blocked_by)
    for k, v in pairs(Afflicted.spells) do
        local removes = v.removes or {}
        for _, rv in ipairs(removes) do
            if Afflicted.spells[rv].blocked_by == nil then
                Afflicted.spells[rv].blocked_by = T{}
            end

            if not Afflicted.spells[rv].blocked_by:contains(k) then
                Afflicted.spells[rv].blocked_by:append(k)
            end
        end
    end

    -- ui
    ui.initialize(settings, Afflicted.spells)
end)

windower.register_event("unload", function()
    ui.destroy()
end)

windower.register_event("logout", "zone change", function()
    Afflicted.targets = {}
end)

windower.register_event("incoming chunk", function(id, data)
    if id == 0x28 then
        -- action packet
        local packet = windower.packets.parse_action(data)
        if packet.category == 4 then
            for _, target in ipairs(packet.targets) do
                for _, action in ipairs(target.actions) do
                    -- debug mode message
                    if Afflicted.debug_mode then
                        Afflicted.addon_message(string.format("target=%s action=%s param=%s", target.id, action.message, packet.param))
                    end

                    -- 2 and 252 are damaging spells
                    -- 236, 237, 268, 271 are non damaging spells
                    -- 264 is damaging spells such as Diaga for targets caught in the aoe (2 on target and 264 on other mobs caught in aoe)
                    -- 277 is non damaging spells such as Sleepga for targets caught in aoe spells (237 and 271 on target, 277 and 278 on mobs caught in aoe)
                    if action and S{ 2, 236, 237, 252, 264, 268, 271, 277, 278 }:contains(action.message) then
                        -- try to apply the spell
                        Afflicted.apply_spell_effects(target.id, packet.param)
                    end
                end
            end
        end
    elseif id == 0x29 then
        -- action message packet
        local target_id = data:unpack("I", 0x09)
        local param_1 = data:unpack("I", 0x0D)
        local message_id = data:unpack("H", 0x19) % 32768

        -- debug mode message
        if Afflicted.debug_mode then
            Afflicted.addon_message(string.format("target=%s action=%s param=%s", target_id, message_id, param_1))
        end

        if S{ 6, 20, 113, 406, 605, 646 }:contains(message_id) then
            -- target has died
            Afflicted.remove_target(target_id)
        elseif S{ 64, 204, 206, 350, 531 }:contains(message_id) then
            -- effect has worn off
            Afflicted.remove_effect(target_id, param_1)
        end
    end
end)

windower.register_event("prerender", function()
    local now = os.clock()

    -- throttle garbage collection
    if now - last_gc >= settings.gc_interval then
        last_gc = now
        Afflicted.garbage_collect()
    end

    -- throttle ui updates
    if now - last_ui >= settings.ui_interval then
        last_ui = now

        -- update ui for current target
        local target = windower.ffxi.get_mob_by_target("t")
        if target and Afflicted.targets[target.id] then
            local render_model = Afflicted.build_render_model(target.id)
            ui.update(target, render_model)
            ui.show()
        else
            ui.hide()
        end
    end
end)

windower.register_event("addon command", function(arg1)
    arg1 = arg1 and arg1:lower() or nil

    if arg1 == "list" then
        Afflicted.addon_message("Listing tracked debuffs.")
        for k, v in pairs(Afflicted.targets) do
            Afflicted.addon_message(string.format("Target %s:", k))
            for vk, vv in ipairs(v) do
                local spell = Afflicted.spells[vv.spell_id]
                Afflicted.addon_message(string.format("  - spell=%s, spell_id=%s, effect_id=%s, expiration=%s", spell.name, vv.spell_id, vv.effect_id, vv.expiration))
            end
        end
    elseif arg1 == "debug" then
        Afflicted.debug_mode = not Afflicted.debug_mode
        Afflicted.addon_message(string.format("Debug mode: %s.", (Afflicted.debug_mode and "ON" or "OFF")))
    else
        Afflicted.addon_message("Usage: " .. _addon.command .. " <command>")
        Afflicted.addon_message("Available commands:")
        Afflicted.addon_message("  - help   .. displays this help screen")
        Afflicted.addon_message("  - list   .. lists all tracked debuffs")
        Afflicted.addon_message("  - debug  .. toggles debug mode")
    end
end)
