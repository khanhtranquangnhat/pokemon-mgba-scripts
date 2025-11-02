local game_info = console:createBuffer("Game Info")
game_info:setSize(65, 500)

local GAME_VERSION_CODE = emu:read8(0x80000AE)
local GAME_LANGUAGE_CODE = emu:read8(0x80000AF)
local MEMORY = nil
local memory_map = require("memory_map")

-- 0x45: Emerald, 0x50: Sapphire, 0x56: Ruby, 0x52: FireRed, 0x47: LeafGreen
local GAME_NAME = nil
if GAME_VERSION_CODE == 0x52 or GAME_VERSION_CODE == 0x47 then GAME_NAME = "FRLG"
elseif GAME_VERSION_CODE == 0x50 or GAME_VERSION_CODE == 0x56 then GAME_NAME = "SR"
elseif GAME_VERSION_CODE == 0x45 then GAME_NAME = "E"
end

local LANG_KEY = nil
if GAME_LANGUAGE_CODE == 0x4A then LANG_KEY = "JPN"
else LANG_KEY = "EUR_USA" end

if GAME_NAME and LANG_KEY and memory_map[GAME_NAME] and memory_map[GAME_NAME][LANG_KEY] then
    MEMORY = memory_map[GAME_NAME][LANG_KEY]
    game_info:print("Loaded MEMORY for " .. GAME_NAME .. " / " .. LANG_KEY)
else
    game_info:print("Unknown game version or language: " .. tostring(GAME_VERSION_CODE) .. " / " .. tostring(GAME_LANGUAGE_CODE))
end

if not MEMORY then
    game_info:print("Unknown game version code: " .. tostring(GAME_VERSION_CODE))
end


local check_all_party = require("check_all_party")
local walk_pkm = require("walk_pkm")

if MEMORY then
    check_all_party.run(MEMORY)
    callbacks:add("frame", check_all_party.periodic_callback)
    walk_pkm.run(MEMORY)
else
    console:log("MEMORY table not set for this game version.")
end
