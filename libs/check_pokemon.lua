local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*/)")
package.path = package.path .. ";" .. script_dir .. "?.lua"
local json = require("json")
local pokemon_check = {}

-- ============================================================================
-- BIT OPERATIONS (mGBA 0.11.x -dev doesn't have 'bit' library)
-- ============================================================================

local bit = {}
local stop = false
local firstTime = true
local highest_match_percent = 0


function bit.band(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function bit.bxor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        if (a % 2) ~= (b % 2) then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function bit.rshift(a, b)
    return math.floor(a / (2 ^ b))
end

function bit.lshift(a, b)
    return a * (2 ^ b)
end

-- ============================================================================
-- ĐỊA CHỈ MEMORY (CHỈ ĐỌC)
-- ============================================================================

local MEMORY = {
    
    PERSONALITY = 0x00,
    OT_ID = 0x04,
    DATA_START = 0x20,
    STATUS = 0x50,
    LEVEL = 0x54,
    CURRENT_HP = 0x56,
    TOTAL_HP = 0x58,
    ATTACK = 0x5A,
    DEFENSE = 0x5C,
    SPEED = 0x5E,
    SP_ATTACK = 0x60,
    SP_DEFENSE = 0x62,
}

local NATURES = {
    "Hardy", "Lonely", "Brave", "Adamant", "Naughty",
    "Bold", "Docile", "Relaxed", "Impish", "Lax",
    "Timid", "Hasty", "Serious", "Jolly", "Naive",
    "Modest", "Mild", "Quiet", "Bashful", "Rash",
    "Calm", "Gentle", "Sassy", "Careful", "Quirky"
}

-- ============================================================================
-- HÀM ĐỌC MEMORY (mGBA 0.10.x API)
-- ============================================================================

function read_byte(address)
    return emu:read8(address)
end

function read_word(address)
    return emu:read16(address)
end

function read_dword(address)
    return emu:read32(address)
end

-- ============================================================================
-- PHÂN TÍCH POKEMON
-- ============================================================================

function get_personality(base_address)
    return read_dword(base_address + MEMORY.PERSONALITY)
end

function get_ot_id(base_address)
    return read_dword(base_address + MEMORY.OT_ID)
end

function get_nature(personality)
    if personality == 0 then return "Unknown" end
    return NATURES[(personality % 25) + 1]
end



local ORDER_TABLE = {
    {"G","A","E","M"},{"G","A","M","E"},{"G","E","A","M"},{"G","E","M","A"},
    {"G","M","A","E"},{"G","M","E","A"},{"A","G","E","M"},{"A","G","M","E"},
    {"A","E","G","M"},{"A","E","M","G"},{"A","M","G","E"},{"A","M","E","G"},
    {"E","G","A","M"},{"E","G","M","A"},{"E","A","G","M"},{"E","A","M","G"},
    {"E","M","G","A"},{"E","M","A","G"},{"M","G","A","E"},{"M","G","E","A"},
    {"M","A","G","E"},{"M","A","E","G"},{"M","E","G","A"},{"M","E","A","G"},
}

-- ============================================================================
-- DECRYPT SUBSTRUCTURES
-- ============================================================================

local SUBSTRUCTURE_ORDER = {
    {"G","A","E","M"}, {"G","A","M","E"}, {"G","E","A","M"}, {"G","E","M","A"},
    {"G","M","A","E"}, {"G","M","E","A"}, {"A","G","E","M"}, {"A","G","M","E"},
    {"A","E","G","M"}, {"A","E","M","G"}, {"A","M","G","E"}, {"A","M","E","G"},
    {"E","G","A","M"}, {"E","G","M","A"}, {"E","A","G","M"}, {"E","A","M","G"},
    {"E","M","G","A"}, {"E","M","A","G"}, {"M","G","A","E"}, {"M","G","E","A"},
    {"M","A","G","E"}, {"M","A","E","G"}, {"M","E","G","A"}, {"M","E","A","G"},
}

local function decrypt_substructures(base)
    local personality = read_dword(base + MEMORY.PERSONALITY)
    local ot_id = read_dword(base + MEMORY.OT_ID)
    if personality == 0 then return nil end

    local key = bit.bxor(personality, ot_id)
    local order = SUBSTRUCTURE_ORDER[(personality % 24) + 1]
    local decrypted = {}

    for i = 1, 4 do
        local offset = MEMORY.DATA_START + (i - 1) * 12
        local block = {}
        for j = 0, 8, 4 do -- 0, 4, 8
            local dword = read_dword(base + offset + j)
            dword = bit.bxor(dword, key)
            table.insert(block, dword)
        end
        decrypted[order[i]] = block
    end
    return decrypted
end


-- ============================================================================
-- PARSE SUBSTRUCTURES
-- ============================================================================
-- Growth block: 3 dword (12 bytes)
local function parse_growth(block)
    -- block[1]: species (lower 16), held_item (upper 16)
    -- block[2]: exp (full 32)
    -- block[3]: pp_bonuses (lower 8), friendship (next 8), unused (upper 16)
    return {
        species = bit.band(block[1], 0xFFFF),
        held_item = bit.rshift(block[1], 16),
        exp = block[2],
        pp_bonuses = bit.band(block[3], 0xFF),
        friendship = bit.band(bit.rshift(block[3], 8), 0xFF),
    }
end

-- Attack block: 3 dword (12 bytes)
local function parse_attack(block)
    -- block[1]: move1 (lower 16), move2 (upper 16)
    -- block[2]: move3 (lower 16), move4 (upper 16)
    -- block[3]: pp1 (lower 8), pp2 (next 8), pp3 (next 8), pp4 (next 8)
    return {
        moves = {
            bit.band(block[1], 0xFFFF),
            bit.rshift(block[1], 16),
            bit.band(block[2], 0xFFFF),
            bit.rshift(block[2], 16),
        },
        pp = {
            bit.band(block[3], 0xFF),
            bit.band(bit.rshift(block[3], 8), 0xFF),
            bit.band(bit.rshift(block[3], 16), 0xFF),
            bit.band(bit.rshift(block[3], 24), 0xFF),
        },
    }
end

-- EVs block: 3 dword (12 bytes)
local function parse_evs(block)
    -- block[1]: hp_ev (lower 8), atk_ev (next 8), def_ev (next 8), spd_ev (next 8)
    -- block[2]: spatk_ev (lower 8), spdef_ev (next 8), rest unused
    return {
        hp_ev = bit.band(block[1], 0xFF),
        atk_ev = bit.band(bit.rshift(block[1], 8), 0xFF),
        def_ev = bit.band(bit.rshift(block[1], 16), 0xFF),
        spd_ev = bit.band(bit.rshift(block[1], 24), 0xFF),
        spatk_ev = bit.band(block[2], 0xFF),
        spdef_ev = bit.band(bit.rshift(block[2], 8), 0xFF),
    }
end

-- Misc block: 3 dword (12 bytes)
local function parse_misc(block)
    -- block[1]: IVs, Egg, Ability (full 32 bits)
    local ivs = block[1]
    return {
        iv_hp = bit.band(ivs, 0x1F),
        iv_atk = bit.band(bit.rshift(ivs, 5), 0x1F),
        iv_def = bit.band(bit.rshift(ivs, 10), 0x1F),
        iv_spd = bit.band(bit.rshift(ivs, 15), 0x1F),
        iv_spatk = bit.band(bit.rshift(ivs, 20), 0x1F),
        iv_spdef = bit.band(bit.rshift(ivs, 25), 0x1F),
        is_egg = bit.band(bit.rshift(ivs, 30), 1) == 1,
        ability = bit.band(bit.rshift(ivs, 31), 1),
    }
end

local function safe(v) return v or 0 end

-- ============================================================================
-- GET STATS FROM LIVE MEMORY
-- ============================================================================

local function get_stats(base)
    local s = {}
    s.level = read_byte(base + MEMORY.LEVEL)
    s.current_hp = read_word(base + MEMORY.CURRENT_HP)
    s.hp = read_word(base + MEMORY.TOTAL_HP)
    s.atk = read_word(base + MEMORY.ATTACK)
    s.def = read_word(base + MEMORY.DEFENSE)
    s.spatk = read_word(base + MEMORY.SP_ATTACK)
    s.spdef = read_word(base + MEMORY.SP_DEFENSE)
    s.speed = read_word(base + MEMORY.SPEED)
    s.nature = NATURES[(read_dword(base + MEMORY.PERSONALITY) % 25) + 1]
    return s
end



-- ============================================================================
-- KIỂM TRA POKEMON
-- ============================================================================

function pokemon_check.check_pokemon_at(base_address, source)
    local personality = get_personality(base_address)
    
    if personality == 0 then
        console:log("   ❌ Personality = 0 (Pokemon data not in memory or wrong address)")
        return false, nil
    end
    
    local ot_id = get_ot_id(base_address)
    local s = get_stats(base_address)
    
    if s.level == 0 or s.hp == 0 then
        console:log("   ❌ Stats not loaded yet (Level or HP = 0)")
        return false, nil
    end

    local decrypted = decrypt_substructures(base_address)
    if not decrypted then
        console:log("❌ Failed to decrypt enemy Pokémon.")
        return
    end

    local g = parse_growth(decrypted["G"])
    local a = parse_attack(decrypted["A"])
    local e = parse_evs(decrypted["E"])
    local m = parse_misc(decrypted["M"])

    
    -- Calculate nature from personality (simple, doesn't need bit ops)
    local nature = NATURES[(personality % 25) + 1] or "Unknown"
    
    local report = {
        source = source,
        personality = personality,
        ot_id = ot_id,
        nature = nature,
        stats = s,
        growth = g,
        attack = a,
        evs = e,
        misc = m
    }
    
    return true, report
end




-- ============================================================================
-- HIỂN THỊ
-- ============================================================================
local parent_dir = script_dir:match("(.-)libs/?$") or script_dir
local item_file = io.open(parent_dir .. "data_set/items.json")
local items = {}

if item_file then
    local content = item_file:read("*all")
    item_file:close()
    items = json.decode(content)
else
    console:log("Error: Could not open items.json")
end

-- Hàm lấy tên item theo id
local function get_item_name(id)
    id = string.format("%03d", id) -- chuyển về dạng 3 số, ví dụ 5 -> "005"
    for _, item in ipairs(items) do
        if item.id == id then
            return item.name
        end
    end
    return "Unknown"
end

----------------------------------------------------------------------------
-- Load pokemon names from JSON
local pokemon_file = io.open(parent_dir .. "data_set/pokemon_name.json")
local pokemons = {}

if pokemon_file then
    local content = pokemon_file:read("*all")
    pokemon_file:close()
    pokemons = json.decode(content)
else
    console:log("Error: Could not open pokemon_name.json")
end

-- Hàm lấy tên pokemon theo id
local function get_pokemon_name(id)
    id = string.format("%03d", id) -- chuyển về dạng 3 số, ví dụ 5 -> "005"
    for _, pokemon in ipairs(pokemons) do
        if pokemon.id == id then
            return pokemon.name
        end
    end
    return "Unknown"
end

----------------------------------------------------------------------------
-- Load pokemon base stats from JSON
local base_stats_file = io.open(parent_dir .. "data_set/base_stats_24.json")
if base_stats_file then
    local content = base_stats_file:read("*all")
    base_stats_file:close()
    base_stats = json.decode(content)
else
    console:log("Error: Could not open base_stats.json")
end

local function get_base_stats_by_id(gSpecies4C)
    for _, pkm in ipairs(base_stats) do
        if pkm.name == name then
            return pkm
        end
    end
    return nil
end

local function get_base_stats_by_id(id)
    id = string.format("%04d", id)
    for _, pkm in ipairs(base_stats) do
        if pkm.id == id then
            return pkm
        end
    end
    return nil
end

----------------------------------------------------------------------------
-- Load nature stats from JSON
local nature_file = io.open(parent_dir .. "data_set/nature_stats.json")

if nature_file then
    local content = nature_file:read("*all")
    nature_file:close()
    natures = json.decode(content)
else
    console:log("Error: Could not open nature_stats.json")
end

local function get_nature_stats_by_name(nameInput)
    local name = nameInput:lower()
    for natureName, natureData in pairs(natures) do
        if natureName == name then
            return natureData
        end
    end
    return nil
end

----------------------------------------------------------------------------
-- Load yield from JSON
local yield_file = io.open(parent_dir .. "data_set/ev_yield.json")

if yield_file then
    local content = yield_file:read("*all")
    yield_file:close()
    yields = json.decode(content)
else
    console:log("Error: Could not open ev_yield.json")
end

local function get_yield_by_species_id(species_id)
    for _, yield in ipairs(yields) do
        if yield.id == species_id then
            return yield
        end
    end
    return nil
end

-- ============================================================================
-- IV CALCULATION
-- ============================================================================
local function calc_iv(stat, base, ev, level, nature_mult, is_hp)
    -- Nếu không truyền nature thì coi là 1.0
    nature_mult = nature_mult or 1.0
    ev = ev or 0
    level = level or 100

    local iv

    if is_hp then
        -- HP formula
        iv = math.floor(((stat - 10) * 100 / level - 2 * base - math.floor(ev / 4) - 100) / 1)
    else
        -- Other stats formula
        iv = math.floor(((stat / nature_mult - 5) * 100 / level - 2 * base - math.floor(ev / 4)) / 1)
    end

    -- Clamp giá trị
    if iv < 0 then iv = 0 end
    if iv > 31 then iv = 31 end

    return iv
end

-- ============================================================================
-- EV YIELD CALCULATION
-- ============================================================================
local function calc_ev_yield(species_id)
    -- Placeholder function: return dummy EV yields
    -- In a real implementation, this would look up a table of species to EV yields
    return {
        hp_ev = 0,
        atk_ev = 0,
        def_ev = 0,
        spatk_ev = 0,
        spdef_ev = 0,
        speed_ev = 0
    }
end

-- {
--   -- Thông tin nguồn gốc
--   source = ...,
--   personality = ...,
--   ot_id = ...,
--   nature = ...,

--   -- Chỉ số thực tế đọc từ memory
--   stats = {
--     level = ...,
--     current_hp = ...,
--     hp = ...,
--     atk = ...,
--     def = ...,
--     spatk = ...,
--     spdef = ...,
--     speed = ...,
--     nature = ...,
--   },

--   -- Thông tin tăng trưởng (growth block)
--   growth = {
--     species = ...,
--     held_item = ...,
--     exp = ...,
--     pp_bonuses = ...,
--     friendship = ...,
--   },

--   -- Thông tin tấn công (attack block)
--   attack = {
--     moves = { ... }, -- 4 moves
--     pp = { ... },    -- 4 pp
--   },

--   -- EVs (ev block)
--   evs = {
--     hp_ev = ...,
--     atk_ev = ...,
--     def_ev = ...,
--     spd_ev = ...,
--     spatk_ev = ...,
--     spdef_ev = ...,
--   },

--   -- Misc (misc block)
--   misc = {
--     iv_hp = ...,
--     iv_atk = ...,
--     iv_def = ...,
--     iv_spd = ...,
--     iv_spatk = ...,
--     iv_spdef = ...,
--     is_egg = ...,
--     ability = ...,
--   },

--   -- Tên Pokémon (tra từ file json)
--   name = ...,

--   -- Level (tra từ stats)
--   level = ...,

--   -- Tên item đang giữ (tra từ file json)
--   item = ...,

--   -- IVs đã tính toán lại theo công thức (dùng cho hiển thị)
--   ivs = {
--     hp = ...,
--     atk = ...,
--     def = ...,
--     spatk = ...,
--     spdef = ...,
--     speed = ...,
--   }
-- }
function pokemon_check.full_info(report)

    local s = report.stats or {}
    local g = report.growth or {}
    local a = report.attack or {}
    local e = report.evs or {}
    local m = report.misc or {}
    local level = s.level or 0
    local name = get_pokemon_name(g.species) or "Unknown"
    gSpecies4C = string.format("%04d", tonumber(g.species))
    local nature_name = report.nature or "Unknown"
    local natureData = get_nature_stats_by_name(nature_name)

    local ev_yield = get_yield_by_species_id(gSpecies4C) or {}
    local ev_value = {}
    local total_ev = ev_yield.value or 0
    -- loop to ev_yield to get item has 1
    for i, v in pairs(ev_yield.ev or {}) do
        if v > 0 then
            ev_value[i] = v
        end
    end

    local hp = s.hp or 0
    local atk = s.atk or 0
    local def = s.def or 0
    local spatk = s.spatk or 0
    local spdef = s.spdef or 0
    local speed = s.speed or 0

    local hp_ev = e.hp_ev or 0
    local atk_ev = e.atk_ev or 0
    local def_ev = e.def_ev or 0
    local spatk_ev = e.spatk_ev or 0
    local spdef_ev = e.spdef_ev or 0
    local spd_ev = e.spd_ev or 0

    local iv_atk = calc_iv(
        atk,
        get_base_stats_by_id(gSpecies4C).attack,
        atk_ev,
        level,
        natureData and natureData.attack or 1.0,
        false
    )
    local iv_def = calc_iv(
        def,
        get_base_stats_by_id(gSpecies4C).defense,
        def_ev,
        level,
        natureData and natureData.defense or 1.0,
        false
    )
    local iv_spatk = calc_iv(
        spatk,
        get_base_stats_by_id(gSpecies4C).sp_attack,
        spatk_ev,
        level,
        natureData and natureData.sp_attack or 1.0,
        false
    )
    local iv_spdef = calc_iv(
        spdef,
        get_base_stats_by_id(gSpecies4C).sp_defense,
        spdef_ev,
        level,
        natureData and natureData.sp_defense or 1.0,
        false
    )
    local iv_spd = calc_iv(
        speed,
        get_base_stats_by_id(gSpecies4C).speed,
        spd_ev,
        level,
        natureData and natureData.speed or 1.0,
        false
    )

    local iv_hp = calc_iv(
        hp,
        get_base_stats_by_id(gSpecies4C).hp,
        hp_ev,
        level,
        natureData and natureData.hp or 1.0,
        true
    )
    local nature_summary = natureData and natureData.summary or ""

    local total_iv_value = 0
    local count_cal_iv = 0

    -- "careful": {"attack":1.0,"defense":1.0,"sp_attack":0.9,"sp_defense":1.1,"speed":1.0,"summary":"+sp_defense, -sp_attack"},

    if (natureData.attack > 0.9) then
        count_cal_iv = count_cal_iv + 1
        total_iv_value = total_iv_value + iv_atk
    end
    if (natureData.defense > 0.9) then
        count_cal_iv = count_cal_iv + 1
        total_iv_value = total_iv_value + iv_def
    end
    if (natureData.sp_attack > 0.9) then
        count_cal_iv = count_cal_iv + 1
        total_iv_value = total_iv_value + iv_spatk
    end
    if (natureData.sp_defense > 0.9) then
        count_cal_iv = count_cal_iv + 1
        total_iv_value = total_iv_value + iv_spdef
    end
    if (natureData.speed > 0.9) then
        count_cal_iv = count_cal_iv + 1
        total_iv_value = total_iv_value + iv_spd
    end
    if (natureData and natureData.hp or 1 > 0.9) then
        count_cal_iv = count_cal_iv + 1
        total_iv_value = total_iv_value + iv_hp
    end

    -- console:log("Total IV Value: " .. total_iv_value .. " Count: " .. count_cal_iv)

    local total_iv_average = total_iv_value / count_cal_iv

    if (total_iv_average >= 29) then
        report.iv_rank = "🌟🌟🌟🌟🌟 " .. (math.floor(total_iv_average * 100) / 100)
    elseif (total_iv_average >= 25) then
        report.iv_rank = "🌟🌟🌟🌟 " .. (math.floor(total_iv_average * 100) / 100)    
    elseif (total_iv_average >= 20) then
        report.iv_rank = "🌟🌟🌟 " .. (math.floor(total_iv_average * 100) / 100)
    elseif (total_iv_average >= 15) then
        report.iv_rank = "🌟🌟 " .. (math.floor(total_iv_average * 100) / 100)
    elseif (total_iv_average >= 10) then
        report.iv_rank = "🌟 " .. (math.floor(total_iv_average * 100) / 100)
    else
        report.iv_rank = "No stars : " .. (math.floor(total_iv_average * 100) / 100)
    end

    report.stats = s
    report.evs = e
    report.name = name
    report.level = level
    report.item = get_item_name(g.held_item)
    report.ivs = {
        hp = iv_hp,
        atk = iv_atk,
        def = iv_def,
        spatk = iv_spatk,
        spdef = iv_spdef,
        speed = iv_spd
    }
    report.total_ev = total_ev
    report.ev_yield = ev_value
    report.nature_summary = nature_summary
    return report
end

function pokemon_check.print_report(report)
    
    local report = pokemon_check.full_info(report)

    console:log("🕹️✨ 𝙿𝚘𝚔𝚎𝚖𝚘𝚗 𝙸𝚗𝚏𝚘 ✨🕹️")

    console:log(string.format("Name : %s", report.name))
    console:log(string.format("Nature: %s is: %s", report.nature, report.nature_summary))
    console:log(string.format("Held Item: %s", report.item))
    console:log(string.format("Level: %d", report.level))
    console:log(string.format("Stats: HP:%d ATK:%d DEF:%d SPATK:%d SPDEF:%d SPD:%d",
        report.stats.hp, report.stats.atk, report.stats.def, report.stats.spatk, report.stats.spdef, report.stats.speed))
    console:log(string.format("EVs: HP:%d ATK:%d DEF:%d SPATK:%d SPDEF:%d SPD:%d",
        report.evs.hp_ev, report.evs.atk_ev, report.evs.def_ev, report.evs.spatk_ev, report.evs.spdef_ev, report.evs.spd_ev))
    console:log(string.format("IVs: HP:%d ATK:%d DEF:%d SPATK:%d SPDEF:%d SPD:%d",
        report.ivs.hp, report.ivs.atk, report.ivs.def, report.ivs.spatk, report.ivs.spdef, report.ivs.speed))
    console:log(string.format("IV Rank: %s", report.iv_rank or "No stars"))
    console:log(string.format("Total EV Yield: %d", report.total_ev or 0))
    console:log("EV Yield Breakdown:")
    for stat, value in pairs(report.ev_yield or {}) do
        console:log(string.format("  %s: %d", stat:upper(), value))
    end
    console:log("🕹️✨ END Pokemon Information")
end

return pokemon_check