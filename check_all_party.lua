local json = require("libs.json")
local check_pokemon = require("libs.check_pokemon")
local MEMORY = {
    PARTY_COUNT = 0x02024029,
    PARTY_START = 0x02024284,
}

local party_buffer = console:createBuffer("Party Info")
party_buffer:setSize(65, 500)

local prev_party_hash = nil
local frame_counter = 0

function main_check()
    local current_party_count = read_byte(MEMORY.PARTY_COUNT)
    local hash = ""
    local reports = {}
    for i = 1, current_party_count do
        local base_address = MEMORY.PARTY_START + (i - 1) * 100
        local success, report = check_pokemon.check_pokemon_at(base_address, "Party", true)
        if success and report then
            hash = hash .. (json.encode(report) or "")
            table.insert(reports, report)
        end
    end
    if prev_party_hash ~= hash then
        party_buffer:clear()
        for _, report in ipairs(reports) do
            check_pokemon.print_report(report, party_buffer, {show_moves = true})
        end
        prev_party_hash = hash
    end
end

function periodic_callback()
    frame_counter = frame_counter + 1
    if frame_counter >= 200 then
        main_check()
        frame_counter = 0
    end
end

callbacks:add("frame", periodic_callback)