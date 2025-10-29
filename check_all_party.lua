local check_pokemon = require("libs.check_pokemon")
local MEMORY = {
    PARTY_COUNT = 0x02024029,
    PARTY_START = 0x02024284,
}

-- ============================================================================
-- MAIN CHECK
-- ============================================================================

function main_check()

    local current_party_count = read_byte(MEMORY.PARTY_COUNT)

    -- loop through all party Pokémon
    for i = 1, current_party_count do
        local base_address = MEMORY.PARTY_START + (i - 1) * 100
        
        local success, report = check_pokemon.check_pokemon_at(base_address, "Party", true)
        -- You can add more detailed logging or processing here if needed
        if success and report then
            check_pokemon.print_report(report)
        end

    end
end


-- ============================================================================
-- MAIN LOOP
-- ============================================================================
-- call 1 times when script is loaded
main_check()