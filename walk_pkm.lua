local check_pokemon = require("libs.check_pokemon")
local json = require("libs.json")
local walk_buffer = console:createBuffer("Competitor Info")
walk_buffer:setSize(65, 200)

local prev_wild_hash = nil
local prev_trainer_hash = nil

-- ============================================================================
-- FIRE RED MEMORY MAP
-- ============================================================================
local MEMORY = {
    WILD_START = 0x0202402C,
    BATTLE_MODE = 0x02022B4C,
    ENEMY_START = 0x202402C,
}

-- ============================================================================
-- BASIC MEMORY READERS
-- ============================================================================
local function read_byte(addr) return emu:read8(addr) end
local function read_word(addr) return emu:read16(addr) end
local function read_dword(addr) return emu:read32(addr) end
local function safe(v) return v or 0 end

-- ============================================================================
-- BATTLE DETECTION
-- ============================================================================

local prev_mode = nil

-- Init state : no battle : 4
-- Encounter state : start battle : 0
-- During battle : battle ongoing : 4

-- Init state : 4
-- Mode : 4
-- Prev mode : nil
-- Mode : 0
-- Prev mode : 4
-- Mode : 4
-- Prev mode : 0

local function detect_wild_battle()
    local mode = emu:read8(MEMORY.BATTLE_MODE)

    if prev_mode == nil then
        prev_mode = mode
        return
    end

    if prev_mode ~= mode then
        if prev_mode ~= 4 and mode == 4 then
            local hash = ""
            local reports = {}
            -- for i = 1, 6 do
                local success, report = check_pokemon.check_pokemon_at(MEMORY.WILD_START, "Wild", { show_moves = true })
                if success and report then
                    hash = hash .. (json.encode(report) or "")
                    table.insert(reports, report)
                end
            -- end
            if prev_wild_hash ~= hash then
                walk_buffer:clear()
                walk_buffer:print("🎯 Wild battle detected!\n")
                for _, report in ipairs(reports) do
                    check_pokemon.print_report(report, walk_buffer)
                end
                prev_wild_hash = hash
            end
        end
    end
    prev_mode = mode
end


local in_trainer_battle = false
local function detect_trainer_battle()
    local mode = emu:read8(MEMORY.BATTLE_MODE)
    if mode == 8 then
        if not in_trainer_battle then
            walk_buffer:clear()
            walk_buffer:print("🎯 Trainer battle detected!\n")
            in_trainer_battle = true
        end

        local hash = ""
        local reports = {}
        for i = 1, 6 do
            local base_address = MEMORY.ENEMY_START + (i - 1) * 100
            local success, report = check_pokemon.check_pokemon_at(base_address, "Trainer")
            if success and report then
                hash = hash .. (json.encode(report) or "")
                table.insert(reports, report)
            end
        end
        if prev_trainer_hash ~= hash then
            walk_buffer:clear()
            walk_buffer:print("Trainer Pokémon info changed!\n")
            for _, report in ipairs(reports) do
                check_pokemon.print_report(report, walk_buffer, { show_moves = true, show_evs_ivs = false })
            end
            prev_trainer_hash = hash
        end
    else
        in_trainer_battle = false
    end
end


-- ============================================================================
-- MAIN LOOP 
-- ============================================================================
walk_buffer:print("Start detecting wild Pokémon and trainer battles...\n")
callbacks:add("frame", detect_wild_battle)
callbacks:add("frame", detect_trainer_battle)