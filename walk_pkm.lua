local check_pokemon = require("libs.check_pokemon")

-- ============================================================================
-- FIRE RED MEMORY MAP
-- ============================================================================
local MEMORY = {
    ENEMY_START = 0x0202402C,
    BATTLE_MODE = 0x02022B4C,
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
local has_battled = false

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
            console:log("🎯 Wild battle detected!")
            has_battled = true

            -- check wild pokemon
            local success, report = check_pokemon.check_pokemon_at(MEMORY.ENEMY_START, "Wild")
            if success and report then
                check_pokemon.print_report(report)
            end
        end
    end
    prev_mode = mode
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
console:log("Start detecting wild Pokémon...")
callbacks:add("frame", detect_wild_battle)
