local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*/)")
package.path = package.path .. ";" .. script_dir .. "?.lua"
local json = require("json")
local pokemon_check = {}

-- ============================================================================
-- BIT OPERATIONS
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

function bit.bor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        if (a % 2 == 1) or (b % 2 == 1) then
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
-- MEMORY ADDRESSES
-- ============================================================================

local MEMORY = {
    
    PERSONALITY = 0x00,
    OT_ID = 0x04,
    S_ID= 0x06,
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

local HIDDEN_POWER_TYPES = {
 "Fighting", "Flying", "Poison", "Ground",
 "Rock", "Bug", "Ghost", "Steel",
 "Fire", "Water", "Grass", "Electric",
 "Psychic", "Ice", "Dragon", "Dark"}

-- ============================================================================
-- STATIC DATA SETS
-- Small data sets: Local variables for fast lookup (items, natures, moves)
-- Large data sets: JSON files to avoid excessive memory usage (pokemon stats, ev yields)
-- ============================================================================

local ITEMS_DATA = {
    -- Basic Items (000-051)
    ["000"] = "Nothing", ["001"] = "Master Ball", ["002"] = "Ultra Ball", ["003"] = "Great Ball", ["004"] = "Poké Ball",
    ["005"] = "Safari Ball", ["006"] = "Net Ball", ["007"] = "Dive Ball", ["008"] = "Nest Ball", ["009"] = "Repeat Ball",
    ["010"] = "Timer Ball", ["011"] = "Luxury Ball", ["012"] = "Premier Ball", ["013"] = "Potion", ["014"] = "Antidote",
    ["015"] = "Burn Heal", ["016"] = "Ice Heal", ["017"] = "Awakening", ["018"] = "Paralyze Heal", ["019"] = "Full Restore",
    ["020"] = "Max Potion", ["021"] = "Hyper Potion", ["022"] = "Super Potion", ["023"] = "Full Heal", ["024"] = "Revive",
    ["025"] = "Max Revive", ["026"] = "Fresh Water", ["027"] = "Soda Pop", ["028"] = "Lemonade", ["029"] = "Moomoo Milk III",
    ["030"] = "Energy Powder", ["031"] = "Energy Root", ["032"] = "Heal Powder", ["033"] = "Revival Herb", ["034"] = "Ether",
    ["035"] = "Max Ether", ["036"] = "Elixir", ["037"] = "Max Elixir", ["038"] = "Lava Cookie", ["039"] = "Blue Flute",
    ["040"] = "Yellow Flute", ["041"] = "Red Flute", ["042"] = "Black Flute", ["043"] = "White Flute", ["044"] = "Berry Juice",
    ["045"] = "Sacred Ash", ["046"] = "Shoal Salt", ["047"] = "Shoal Shell", ["048"] = "Red Shard", ["049"] = "Blue Shard",
    ["050"] = "Yellow Shard", ["051"] = "Green Shard",
    
    -- Unknown/Unused (052-062)
    ["052"] = "unknown", ["053"] = "unknown", ["054"] = "unknown", ["055"] = "unknown", ["056"] = "unknown",
    ["057"] = "unknown", ["058"] = "unknown", ["059"] = "unknown", ["060"] = "unknown", ["061"] = "unknown", ["062"] = "unknown",
    
    -- Vitamins & Battle Items (063-086)
    ["063"] = "HP Up", ["064"] = "Protein", ["065"] = "Iron", ["066"] = "Carbos", ["067"] = "Calcium",
    ["068"] = "Rare Candy", ["069"] = "PP Up", ["070"] = "Zinc", ["071"] = "PP Max", ["072"] = "unknown",
    ["073"] = "Guard Spec.", ["074"] = "Dire Hit", ["075"] = "X Attack", ["076"] = "X Defense", ["077"] = "X Speed",
    ["078"] = "X Accuracy", ["079"] = "X Sp. Atk", ["080"] = "Poké Doll", ["081"] = "Fluffy Tail", ["082"] = "unknown",
    ["083"] = "Super Repel", ["084"] = "Max Repel", ["085"] = "Escape Rope", ["086"] = "Repel",
    
    -- Unknown & Evolution Stones (087-098)
    ["087"] = "unknown", ["088"] = "unknown", ["089"] = "unknown", ["090"] = "unknown", ["091"] = "unknown", ["092"] = "unknown",
    ["093"] = "Sun Stone", ["094"] = "Moon Stone", ["095"] = "Fire Stone", ["096"] = "Thunder Stone", ["097"] = "Water Stone", ["098"] = "Leaf Stone",
    
    -- Valuable Items (099-120)
    ["099"] = "unknown", ["100"] = "unknown", ["101"] = "unknown", ["102"] = "unknown", ["103"] = "Tiny Mushroom", ["104"] = "Big Mushroom",
    ["105"] = "unknown", ["106"] = "Pearl", ["107"] = "Big Pearl", ["108"] = "Stardust", ["109"] = "Star Piece", ["110"] = "Nugget",
    ["111"] = "Heart Scale", ["112"] = "unknown", ["113"] = "unknown", ["114"] = "unknown", ["115"] = "unknown", ["116"] = "unknown",
    ["117"] = "unknown", ["118"] = "unknown", ["119"] = "unknown", ["120"] = "unknown",
    
    -- Mail Items (121-132)
    ["121"] = "Orange Mail", ["122"] = "Harbor Mail", ["123"] = "Glitter Mail", ["124"] = "Mech Mail", ["125"] = "Wood Mail",
    ["126"] = "Wave Mail", ["127"] = "Bead Mail", ["128"] = "Shadow Mail", ["129"] = "Tropic Mail", ["130"] = "Dream Mail",
    ["131"] = "Fab Mail", ["132"] = "Retro Mail",
    
    -- Berries (133-175)
    ["133"] = "Cheri Berry", ["134"] = "Chesto Berry", ["135"] = "Pecha Berry", ["136"] = "Rawst Berry", ["137"] = "Aspear Berry",
    ["138"] = "Leppa Berry", ["139"] = "Oran Berry", ["140"] = "Persim Berry", ["141"] = "Lum Berry", ["142"] = "Sitrus Berry",
    ["143"] = "Figy Berry", ["144"] = "Wiki Berry", ["145"] = "Mago Berry", ["146"] = "Aguav Berry", ["147"] = "Iapapa Berry",
    ["148"] = "Razz Berry III", ["149"] = "Bluk Berry", ["150"] = "Nanab Berry III", ["151"] = "Wepear Berry", ["152"] = "Pinap Berry",
    ["153"] = "Pomeg Berry", ["154"] = "Kelpsy Berry", ["155"] = "Qualot Berry", ["156"] = "Hondew Berry", ["157"] = "Grepa Berry",
    ["158"] = "Tamato Berry", ["159"] = "Cornn Berry", ["160"] = "Magost Berry", ["161"] = "Rabuta Berry", ["162"] = "Nomel Berry",
    ["163"] = "Spelon Berry", ["164"] = "Pamtre Berry", ["165"] = "Watmel Berry", ["166"] = "Durin Berry", ["167"] = "Belue Berry",
    ["168"] = "Liechi Berry", ["169"] = "Ganlon Berry", ["170"] = "Salac Berry", ["171"] = "Petaya Berry", ["172"] = "Apicot Berry",
    ["173"] = "Lansat Berry", ["174"] = "Starf Berry", ["175"] = "Enigma Berry",
    
    -- Unknown (176-178)
    ["176"] = "unknown", ["177"] = "unknown", ["178"] = "unknown",
    
    -- Hold Items (179-225)
    ["179"] = "Bright Powder", ["180"] = "White Herb", ["181"] = "Macho Brace", ["182"] = "Exp. Share", ["183"] = "Quick Claw",
    ["184"] = "Soothe Bell", ["185"] = "Mental Herb", ["186"] = "Choice Band", ["187"] = "King's Rock", ["188"] = "SilverPowder",
    ["189"] = "Amulet Coin III", ["190"] = "Cleanse Tag", ["191"] = "Soul Dew", ["192"] = "Deep Sea Tooth", ["193"] = "Deep Sea Scale",
    ["194"] = "Smoke Ball", ["195"] = "Everstone", ["196"] = "Focus Band", ["197"] = "Lucky Egg", ["198"] = "Scope Lens",
    ["199"] = "Metal Coat", ["200"] = "Leftovers", ["201"] = "Dragon Scale", ["202"] = "Light Ball", ["203"] = "Soft Sand",
    ["204"] = "Hard Stone", ["205"] = "Miracle Seed", ["206"] = "Black Glasses", ["207"] = "Black Belt", ["208"] = "Magnet",
    ["209"] = "Mystic Water", ["210"] = "Sharp Beak", ["211"] = "Poison Barb", ["212"] = "Never-Melt Ice", ["213"] = "Spell Tag",
    ["214"] = "Twisted Spoon", ["215"] = "Charcoal", ["216"] = "Dragon Fang", ["217"] = "Silk Scarf", ["218"] = "Up-Grade",
    ["219"] = "Shell Bell", ["220"] = "Sea Incense", ["221"] = "Lax Incense", ["222"] = "Lucky Punch", ["223"] = "Metal Powder",
    ["224"] = "Thick Club", ["225"] = "Stick",
    
    -- Unknown (226-253)
    ["226"] = "unknown", ["227"] = "unknown", ["228"] = "unknown", ["229"] = "unknown", ["230"] = "unknown",
    ["231"] = "unknown", ["232"] = "unknown", ["233"] = "unknown", ["234"] = "unknown", ["235"] = "unknown",
    ["236"] = "unknown", ["237"] = "unknown", ["238"] = "unknown", ["239"] = "unknown", ["240"] = "unknown",
    ["241"] = "unknown", ["242"] = "unknown", ["243"] = "unknown", ["244"] = "unknown", ["245"] = "unknown",
    ["246"] = "unknown", ["247"] = "unknown", ["248"] = "unknown", ["249"] = "unknown", ["250"] = "unknown",
    ["251"] = "unknown", ["252"] = "unknown", ["253"] = "unknown",
    
    -- Contest & Key Items (254-376)
    ["254"] = "Red Scarf", ["255"] = "Blue Scarf", ["256"] = "Pink Scarf", ["257"] = "Green Scarf", ["258"] = "Yellow Scarf",
    ["259"] = "Mach Bike III", ["260"] = "Coin Case", ["261"] = "Itemfinder", ["262"] = "Old Rod III", ["263"] = "Good Rod III",
    ["264"] = "Super Rod III", ["265"] = "S.S. Ticket", ["266"] = "Contest Pass", ["267"] = "unknown", ["268"] = "Wailmer Pail",
    ["269"] = "Devon Parts", ["270"] = "Soot Sack", ["271"] = "Basement Key III", ["272"] = "Acro Bike III", ["273"] = "Pokéblock Case",
    ["274"] = "Letter", ["275"] = "Eon Ticket", ["276"] = "Red Orb III", ["277"] = "Blue Orb III", ["278"] = "Scanner",
    ["279"] = "Go-Goggles III", ["280"] = "Meteorite", ["281"] = "Key to Room 1", ["282"] = "Key to Room 2", ["283"] = "Key to Room 4",
    ["284"] = "Key to Room 6", ["285"] = "Storage Key III", ["286"] = "Root Fossil", ["287"] = "Claw Fossil", ["288"] = "Devon Scope III",
    
    -- TMs (289-338)
    ["289"] = "TM Fighting", ["290"] = "TM Dragon", ["291"] = "TM Water", ["292"] = "TM Psychic", ["293"] = "TM Normal",
    ["294"] = "TM Poison", ["295"] = "TM Ice", ["296"] = "TM Fighting", ["297"] = "TM Grass", ["298"] = "TM Normal",
    ["299"] = "TM Fire", ["300"] = "TM Dark", ["301"] = "TM Ice", ["302"] = "TM Ice", ["303"] = "TM Normal",
    ["304"] = "TM Psychic", ["305"] = "TM Normal", ["306"] = "TM Water", ["307"] = "TM Grass", ["308"] = "TM Normal",
    ["309"] = "TM Normal", ["310"] = "TM Grass", ["311"] = "TM Steel", ["312"] = "TM Electric", ["313"] = "TM Electric",
    ["314"] = "TM Ground", ["315"] = "TM Normal", ["316"] = "TM Ground", ["317"] = "TM Psychic", ["318"] = "TM Ghost",
    ["319"] = "TM Fighting", ["320"] = "TM Normal", ["321"] = "TM Psychic", ["322"] = "TM Electric", ["323"] = "TM Fire",
    ["324"] = "TM Poison", ["325"] = "TM Rock", ["326"] = "TM Fire", ["327"] = "TM Rock", ["328"] = "TM Flying",
    ["329"] = "TM Dark", ["330"] = "TM Normal", ["331"] = "TM Normal", ["332"] = "TM Psychic", ["333"] = "TM Normal",
    ["334"] = "TM Dark", ["335"] = "TM Steel", ["336"] = "TM Psychic", ["337"] = "TM Dark", ["338"] = "TM Fire",
    
    -- HMs (339-346)
    ["339"] = "HM Normal", ["340"] = "HM Flying", ["341"] = "HM Water", ["342"] = "HM Normal", ["343"] = "HM Normal",
    ["344"] = "HM Fighting", ["345"] = "HM Water", ["346"] = "HM Water",
    
    -- Final Items (347-376)
    ["347"] = "unknown", ["348"] = "unknown", ["349"] = "Parcel", ["350"] = "Poké Flute III", ["351"] = "Secret Key III",
    ["352"] = "Bike Voucher", ["353"] = "Gold Teeth III", ["354"] = "Old Amber", ["355"] = "Card Key III", ["356"] = "Lift Key III",
    ["357"] = "Helix Fossil", ["358"] = "Dome Fossil", ["359"] = "Silph Scope III", ["360"] = "Bicycle", ["361"] = "Town Map III",
    ["362"] = "Vs. Seeker", ["363"] = "Fame Checker", ["364"] = "TM Case", ["365"] = "Berry Pouch", ["366"] = "Teachy TV",
    ["367"] = "Tri-Pass", ["368"] = "Rainbow Pass", ["369"] = "Tea III", ["370"] = "MysticTicket", ["371"] = "AuroraTicket",
    ["372"] = "Powder Jar", ["373"] = "Ruby", ["374"] = "Sapphire", ["375"] = "Magma Emblem", ["376"] = "Old Sea Map"
}

local NATURE_DATA = {
    hardy = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="No change"},
    lonely = {attack=1.1, defense=0.9, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="+attack, -defense"},
    brave = {attack=1.1, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=0.9, summary="+attack, -speed"},
    adamant = {attack=1.1, defense=1.0, sp_attack=0.9, sp_defense=1.0, speed=1.0, summary="+attack, -sp_attack"},
    naughty = {attack=1.1, defense=1.0, sp_attack=1.0, sp_defense=0.9, speed=1.0, summary="+attack, -sp_defense"},
    bold = {attack=0.9, defense=1.1, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="+defense, -attack"},
    docile = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="No change"},
    relaxed = {attack=1.0, defense=1.1, sp_attack=1.0, sp_defense=1.0, speed=0.9, summary="+defense, -speed"},
    impish = {attack=1.0, defense=1.1, sp_attack=0.9, sp_defense=1.0, speed=1.0, summary="+defense, -sp_attack"},
    lax = {attack=1.0, defense=1.1, sp_attack=1.0, sp_defense=0.9, speed=1.0, summary="+defense, -sp_defense"},
    timid = {attack=0.9, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=1.1, summary="+speed, -attack"},
    hasty = {attack=1.0, defense=0.9, sp_attack=1.0, sp_defense=1.0, speed=1.1, summary="+speed, -defense"},
    serious = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="No change"},
    jolly = {attack=1.0, defense=1.0, sp_attack=0.9, sp_defense=1.0, speed=1.1, summary="+speed, -sp_attack"},
    naive = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=0.9, speed=1.1, summary="+speed, -sp_defense"},
    modest = {attack=0.9, defense=1.0, sp_attack=1.1, sp_defense=1.0, speed=1.0, summary="+sp_attack, -attack"},
    mild = {attack=1.0, defense=0.9, sp_attack=1.1, sp_defense=1.0, speed=1.0, summary="+sp_attack, -defense"},
    quiet = {attack=1.0, defense=1.0, sp_attack=1.1, sp_defense=1.0, speed=0.9, summary="+sp_attack, -speed"},
    bashful = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="No change"},
    rash = {attack=1.0, defense=1.0, sp_attack=1.1, sp_defense=0.9, speed=1.0, summary="+sp_attack, -sp_defense"},
    calm = {attack=0.9, defense=1.0, sp_attack=1.0, sp_defense=1.1, speed=1.0, summary="+sp_defense, -attack"},
    gentle = {attack=1.0, defense=0.9, sp_attack=1.0, sp_defense=1.1, speed=1.0, summary="+sp_defense, -defense"},
    sassy = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=1.1, speed=0.9, summary="+sp_defense, -speed"},
    careful = {attack=1.0, defense=1.0, sp_attack=0.9, sp_defense=1.1, speed=1.0, summary="+sp_defense, -sp_attack"},
    quirky = {attack=1.0, defense=1.0, sp_attack=1.0, sp_defense=1.0, speed=1.0, summary="No change"}
}

local MOVES_DATA = {
    ["001"] = "Pound", ["002"] = "Karate Chop", ["003"] = "Double Slap", ["004"] = "Comet Punch", ["005"] = "Mega Punch",
    ["006"] = "Pay Day", ["007"] = "Fire Punch", ["008"] = "Ice Punch", ["009"] = "Thunder Punch", ["010"] = "Scratch",
    ["011"] = "Vice Grip", ["012"] = "Guillotine", ["013"] = "Razor Wind", ["014"] = "Swords Dance", ["015"] = "Cut",
    ["016"] = "Gust", ["017"] = "Wing Attack", ["018"] = "Whirlwind", ["019"] = "Fly", ["020"] = "Bind",
    ["021"] = "Slam", ["022"] = "Vine Whip", ["023"] = "Stomp", ["024"] = "Double Kick", ["025"] = "Mega Kick",
    ["026"] = "Jump Kick", ["027"] = "Rolling Kick", ["028"] = "Sand Attack", ["029"] = "Headbutt", ["030"] = "Horn Attack",
    ["031"] = "Fury Attack", ["032"] = "Horn Drill", ["033"] = "Tackle", ["034"] = "Body Slam", ["035"] = "Wrap",
    ["036"] = "Take Down", ["037"] = "Thrash", ["038"] = "Double-Edge", ["039"] = "Tail Whip", ["040"] = "Poison Sting",
    ["041"] = "Twineedle", ["042"] = "Pin Missile", ["043"] = "Leer", ["044"] = "Bite", ["045"] = "Growl",
    ["046"] = "Roar", ["047"] = "Sing", ["048"] = "Supersonic", ["049"] = "Sonic Boom", ["050"] = "Disable",
    ["051"] = "Acid", ["052"] = "Ember", ["053"] = "Flamethrower", ["054"] = "Mist", ["055"] = "Water Gun",
    ["056"] = "Hydro Pump", ["057"] = "Surf", ["058"] = "Ice Beam", ["059"] = "Blizzard", ["060"] = "Psybeam",
    ["061"] = "Bubble Beam", ["062"] = "Aurora Beam", ["063"] = "Hyper Beam", ["064"] = "Peck", ["065"] = "Drill Peck",
    ["066"] = "Submission", ["067"] = "Low Kick", ["068"] = "Counter", ["069"] = "Seismic Toss", ["070"] = "Strength",
    ["071"] = "Absorb", ["072"] = "Mega Drain", ["073"] = "Leech Seed", ["074"] = "Growth", ["075"] = "Razor Leaf",
    ["076"] = "Solar Beam", ["077"] = "Poison Powder", ["078"] = "Stun Spore", ["079"] = "Sleep Powder", ["080"] = "Petal Dance",
    ["081"] = "String Shot", ["082"] = "Dragon Rage", ["083"] = "Fire Spin", ["084"] = "Thunder Shock", ["085"] = "Thunderbolt",
    ["086"] = "Thunder Wave", ["087"] = "Thunder", ["088"] = "Rock Throw", ["089"] = "Earthquake", ["090"] = "Fissure",
    ["091"] = "Dig", ["092"] = "Toxic", ["093"] = "Confusion", ["094"] = "Psychic", ["095"] = "Hypnosis",
    ["096"] = "Meditate", ["097"] = "Agility", ["098"] = "Quick Attack", ["099"] = "Rage", ["100"] = "Teleport",
    ["101"] = "Night Shade", ["102"] = "Mimic", ["103"] = "Screech", ["104"] = "Double Team", ["105"] = "Recover",
    ["106"] = "Harden", ["107"] = "Minimize", ["108"] = "Smokescreen", ["109"] = "Confuse Ray", ["110"] = "Withdraw",
    ["111"] = "Defense Curl", ["112"] = "Barrier", ["113"] = "Light Screen", ["114"] = "Haze", ["115"] = "Reflect",
    ["116"] = "Focus Energy", ["117"] = "Bide", ["118"] = "Metronome", ["119"] = "Mirror Move", ["120"] = "Self-Destruct",
    ["121"] = "Egg Bomb", ["122"] = "Lick", ["123"] = "Smog", ["124"] = "Sludge", ["125"] = "Bone Club",
    ["126"] = "Fire Blast", ["127"] = "Waterfall", ["128"] = "Clamp", ["129"] = "Swift", ["130"] = "Skull Bash",
    ["131"] = "Spike Cannon", ["132"] = "Constrict", ["133"] = "Amnesia", ["134"] = "Kinesis", ["135"] = "Soft-Boiled",
    ["136"] = "High Jump Kick", ["137"] = "Glare", ["138"] = "Dream Eater", ["139"] = "Poison Gas", ["140"] = "Barrage",
    ["141"] = "Leech Life", ["142"] = "Lovely Kiss", ["143"] = "Sky Attack", ["144"] = "Transform", ["145"] = "Bubble",
    ["146"] = "Dizzy Punch", ["147"] = "Spore", ["148"] = "Flash", ["149"] = "Psywave", ["150"] = "Splash",
    ["151"] = "Acid Armor", ["152"] = "Crabhammer", ["153"] = "Explosion", ["154"] = "Fury Swipes", ["155"] = "Bonemerang",
    ["156"] = "Rest", ["157"] = "Rock Slide", ["158"] = "Hyper Fang", ["159"] = "Sharpen", ["160"] = "Conversion",
    ["161"] = "Tri Attack", ["162"] = "Super Fang", ["163"] = "Slash", ["164"] = "Substitute", ["165"] = "Struggle",
    ["166"] = "Sketch", ["167"] = "Triple Kick", ["168"] = "Thief", ["169"] = "Spider Web", ["170"] = "Mind Reader",
    ["171"] = "Nightmare", ["172"] = "Flame Wheel", ["173"] = "Snore", ["174"] = "Curse", ["175"] = "Flail",
    ["176"] = "Conversion 2", ["177"] = "Aeroblast", ["178"] = "Cotton Spore", ["179"] = "Reversal", ["180"] = "Spite",
    ["181"] = "Powder Snow", ["182"] = "Protect", ["183"] = "Mach Punch", ["184"] = "Scary Face", ["185"] = "Feint Attack",
    ["186"] = "Sweet Kiss", ["187"] = "Belly Drum", ["188"] = "Sludge Bomb", ["189"] = "Mud-Slap", ["190"] = "Octazooka",
    ["191"] = "Spikes", ["192"] = "Zap Cannon", ["193"] = "Foresight", ["194"] = "Destiny Bond", ["195"] = "Perish Song",
    ["196"] = "Icy Wind", ["197"] = "Detect", ["198"] = "Bone Rush", ["199"] = "Lock-On", ["200"] = "Outrage",
    ["201"] = "Sandstorm", ["202"] = "Giga Drain", ["203"] = "Endure", ["204"] = "Charm", ["205"] = "Rollout",
    ["206"] = "False Swipe", ["207"] = "Swagger", ["208"] = "Milk Drink", ["209"] = "Spark", ["210"] = "Fury Cutter",
    ["211"] = "Steel Wing", ["212"] = "Mean Look", ["213"] = "Attract", ["214"] = "Sleep Talk", ["215"] = "Heal Bell",
    ["216"] = "Return", ["217"] = "Present", ["218"] = "Frustration", ["219"] = "Safeguard", ["220"] = "Pain Split",
    ["221"] = "Sacred Fire", ["222"] = "Magnitude", ["223"] = "Dynamic Punch", ["224"] = "Megahorn", ["225"] = "Dragon Breath",
    ["226"] = "Baton Pass", ["227"] = "Encore", ["228"] = "Pursuit", ["229"] = "Rapid Spin", ["230"] = "Sweet Scent",
    ["231"] = "Iron Tail", ["232"] = "Metal Claw", ["233"] = "Vital Throw", ["234"] = "Morning Sun", ["235"] = "Synthesis",
    ["236"] = "Moonlight", ["237"] = "Hidden Power", ["238"] = "Cross Chop", ["239"] = "Twister", ["240"] = "Rain Dance",
    ["241"] = "Sunny Day", ["242"] = "Crunch", ["243"] = "Mirror Coat", ["244"] = "Psych Up", ["245"] = "Extreme Speed",
    ["246"] = "Ancient Power", ["247"] = "Shadow Ball", ["248"] = "Future Sight", ["249"] = "Rock Smash", ["250"] = "Whirlpool",
    ["251"] = "Beat Up", ["252"] = "Fake Out", ["253"] = "Uproar", ["254"] = "Stockpile", ["255"] = "Spit Up",
    ["256"] = "Swallow", ["257"] = "Heat Wave", ["258"] = "Hail", ["259"] = "Torment", ["260"] = "Flatter",
    ["261"] = "Will-O-Wisp", ["262"] = "Memento", ["263"] = "Facade", ["264"] = "Focus Punch", ["265"] = "Smelling Salts",
    ["266"] = "Follow Me", ["267"] = "Nature Power", ["268"] = "Charge", ["269"] = "Taunt", ["270"] = "Helping Hand",
    ["271"] = "Trick", ["272"] = "Role Play", ["273"] = "Wish", ["274"] = "Assist", ["275"] = "Ingrain",
    ["276"] = "Superpower", ["277"] = "Magic Coat", ["278"] = "Recycle", ["279"] = "Revenge", ["280"] = "Brick Break",
    ["281"] = "Yawn", ["282"] = "Knock Off", ["283"] = "Endeavor", ["284"] = "Eruption", ["285"] = "Skill Swap",
    ["286"] = "Imprison", ["287"] = "Refresh", ["288"] = "Grudge", ["289"] = "Snatch", ["290"] = "Secret Power",
    ["291"] = "Dive", ["292"] = "Arm Thrust", ["293"] = "Camouflage", ["294"] = "Tail Glow", ["295"] = "Luster Purge",
    ["296"] = "Mist Ball", ["297"] = "Feather Dance", ["298"] = "Teeter Dance", ["299"] = "Blaze Kick", ["300"] = "Mud Sport",
    ["301"] = "Ice Ball", ["302"] = "Needle Arm", ["303"] = "Slack Off", ["304"] = "Hyper Voice", ["305"] = "Poison Fang",
    ["306"] = "Crush Claw", ["307"] = "Blast Burn", ["308"] = "Hydro Cannon", ["309"] = "Meteor Mash", ["310"] = "Astonish",
    ["311"] = "Weather Ball", ["312"] = "Aromatherapy", ["313"] = "Fake Tears", ["314"] = "Air Cutter", ["315"] = "Overheat",
    ["316"] = "Odor Sleuth", ["317"] = "Rock Tomb", ["318"] = "Silver Wind", ["319"] = "Metal Sound", ["320"] = "Grass Whistle",
    ["321"] = "Tickle", ["322"] = "Cosmic Power", ["323"] = "Water Spout", ["324"] = "Signal Beam", ["325"] = "Shadow Punch",
    ["326"] = "Extrasensory", ["327"] = "Sky Uppercut", ["328"] = "Sand Tomb", ["329"] = "Sheer Cold", ["330"] = "Muddy Water",
    ["331"] = "Bullet Seed", ["332"] = "Aerial Ace", ["333"] = "Icicle Spear", ["334"] = "Iron Defense", ["335"] = "Block",
    ["336"] = "Howl", ["337"] = "Dragon Claw", ["338"] = "Frenzy Plant", ["339"] = "Bulk Up", ["340"] = "Bounce",
    ["341"] = "Mud Shot", ["342"] = "Poison Tail", ["343"] = "Covet", ["344"] = "Volt Tackle", ["345"] = "Magical Leaf",
    ["346"] = "Water Sport", ["347"] = "Calm Mind", ["348"] = "Leaf Blade", ["349"] = "Dragon Dance", ["350"] = "Rock Blast",
    ["351"] = "Shock Wave", ["352"] = "Water Pulse", ["353"] = "Doom Desire", ["354"] = "Psycho Boost"
}


-- reference national dex list for gen 3 pokemon order
-- source: https://github.com/Real96/PokeLua/blob/main/Gen%203/mGBA/FRLG_RNG_mGBA.lua
local nationalDexList = {
 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,
 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139,
 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199,
 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219,
 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 387, 388, 389, 390, 391, 392, 393, 394,
 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 252, 253, 254,
 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274,
 275, 290, 291, 292, 276, 277, 285, 286, 327, 278, 279, 283, 284, 320, 321, 300, 301, 352, 343, 344,
 299, 324, 302, 339, 340, 370, 341, 342, 349, 350, 318, 319, 328, 329, 330, 296, 297, 309, 310, 322,
 323, 363, 364, 365, 331, 332, 361, 362, 337, 338, 298, 325, 326, 311, 312, 303, 307, 308, 333, 334,
 360, 355, 356, 315, 287, 288, 289, 316, 317, 357, 293, 294, 295, 366, 367, 368, 359, 353, 354, 336,
 335, 369, 304, 305, 306, 351, 313, 314, 345, 346, 347, 348, 280, 281, 282, 371, 372, 373, 374, 375,
 376, 377, 378, 379, 382, 383, 384, 380, 381, 385, 386, 358}

-- ============================================================================
-- MEMORY READ FUNCTIONS
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
-- POKEMON ANALYSIS
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
    
    local species = bit.band(block[1], 0xFFFF)
    local held_item = bit.rshift(block[1], 16)
    
    -- Validate species (Gen 3: 1-386, some special cases up to 411)
    if species > 500 or species == 0 then
        console:log("⚠️ Corrupt species detected: " .. tostring(species) .. " → Using fallback")
        species = 0  -- Use fallback
        held_item = 0  -- Reset held item too
    end
    
    -- Validate held item (items go up to ~376 in Gen 3)
    if held_item > 400 then
        console:log("⚠️ Corrupt held_item detected: " .. tostring(held_item) .. " → Reset to Nothing")
        held_item = 0
    end
    
    return {
        species = species,
        held_item = held_item,
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
    -- block[3]: cutesy_ev, smart_ev, tough_ev, beauty_ev 
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
    -- block[1]: Pokérus status, location caught, level met, Poké Ball/gender.
    -- block[2]: IVs, Egg, Ability
    -- block[3]: Ribbons
    local ivs = block[2]
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

function get_hidden_type_power(iv_hp, iv_atk, iv_def, iv_spatk, iv_spdef, iv_spd)
 local hp_type = (((iv_hp & 1) + (2 * (iv_atk & 1)) + (4 * (iv_def & 1)) + (8 * (iv_spd & 1)) + (16 * (iv_spatk & 1))
                + (32 * (iv_spdef & 1))) * 15) // 63
 local hp_power = (((((iv_hp >> 1) & 1) + (2 * ((iv_atk >> 1) & 1)) + (4 * ((iv_def >> 1) & 1)) + (8 * ((iv_spd >> 1) & 1))
                 + (16 * ((iv_spatk >> 1) & 1)) + (32 * ((iv_spdef >> 1) & 1))) * 40) // 63) + 30

 return hp_type, hp_power
end

-- ============================================================================
-- KIỂM TRA POKEMON
-- ============================================================================

function is_shiny(pid, tid, sid)
    local low_pid = bit.band(pid, 0xFFFF)
    local high_pid = bit.rshift(pid, 16)
    local val = bit.bxor(bit.bxor(sid, tid), bit.bxor(low_pid, high_pid))
    return val < 8
end


local ot_id, t_id, s_id = nil
local max_console_frames = 0

function pokemon_check.check_pokemon_at(base_address, source, cached)
    local personality = get_personality(base_address)

    if cached == nil then cached = false end
    if cached ~= true then
        ot_id = nil
        t_id = nil
        s_id = nil
    end

    if personality == 0 then
        if max_console_frames < 5 then
            console:log("   ❌ Personality = 0 (Pokemon data not in memory or wrong address)")
            max_console_frames = max_console_frames + 1
        end
        return false, nil
    end

    -- Cache OT ID, TID, SID when loop load state to get gift, egg, ...
    if ot_id == nil then
        ot_id = get_ot_id(base_address) -- read32
        t_id = bit.band(ot_id, 0xFFFF)
        s_id = bit.rshift(ot_id, 16)

        console:log("🎯 Fetched OT ID and Trainer ID from memory:")
        console:log("   ✅ Fetched OT ID: " .. ot_id)
        console:log("   ✅ Trainer ID: " .. t_id .. ", Secret ID: " .. s_id)
    else
        -- console:log("   ✅ Using cached OT ID: " .. ot_id .. " (TID: " .. t_id .. ", SID: " .. s_id .. ")")
    end

    local is_shiny = is_shiny(personality, t_id, s_id)

    local decrypted = decrypt_substructures(base_address)
    if not decrypted then
        if max_console_frames < 5 then
            console:log("   ❌ Failed to decrypt enemy Pokémon.")
            max_console_frames = max_console_frames + 1
        end
        return false, nil
    end

    if decrypted["G"] == nil or decrypted["A"] == nil or decrypted["E"] == nil or decrypted["M"] == nil then
        console:log("   ❌ Decrypted substructures are incomplete.")
        return false, nil
    end

    local g = parse_growth(decrypted["G"])
    local a = parse_attack(decrypted["A"])
    local e = parse_evs(decrypted["E"])
    local m = parse_misc(decrypted["M"])

    local s = get_stats(base_address)
    if s.level == 0 or s.hp == 0 then
        console:log("   ❌ Stats not loaded yet (Level or HP = 0)")
        return false, nil
    end

    
    -- Calculate nature from personality (simple, doesn't need bit ops)
    local nature = NATURES[(personality % 25) + 1] or "Unknown"
    
    local report = {
        source = source,
        personality = personality,
        ot_id = ot_id,
        p_id = p_id,
        s_id = s_id,
        is_shiny = is_shiny,
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
-- HELPER FUNCTIONS (OPTIMIZED)
-- ============================================================================
local function get_item_name(id)
    -- Validate item ID range
    if not id or id < 0 or id > 400 then
        return "Nothing"
    end
    
    if id == 0 then
        return "Nothing"
    end
    
    local id_str = string.format("%03d", id) -- chuyển về dạng 3 số, ví dụ 5 -> "005"
    return "🎁 " .. (ITEMS_DATA[id_str] or ("Unknown Item #" .. tostring(id)))
end

-- Load pokemon base stats from JSON (kept for large data)
local parent_dir = script_dir:match("(.-)libs/?$") or script_dir
local base_stats_file = io.open(parent_dir .. "data_set/pokemons_info_gen3.json")
local base_stats = {}
local base_stats_cache = {} -- CACHE: O(1) lookup table

if base_stats_file then
    local content = base_stats_file:read("*all")
    base_stats_file:close()
    base_stats = json.decode(content)
    
    -- Build cache: Convert array to hash table for O(1) lookup
    for _, pkm in ipairs(base_stats) do
        base_stats_cache[pkm.id] = pkm
    end
    console:log("✅ Pokemon base stats loaded and cached: " .. #base_stats .. " entries")
else
    console:log("Error: Could not open pokemons_info_gen3.json")
end

local function get_base_stats_by_id(id)
    if tonumber(id) == nil then
        -- Fallback for invalid ID
        return {
            id = "0000",
            name = "Invalid Pokemon",
            types = {"Normal"},
            abilities = {{name = "Unknown", description = "Unknown ability"}},
            weak = {}, super_weak = {}, resistant = {}, super_resistant = {}, immune = {}
        }
    end

    current_nationalDex = nationalDexList[id + 1]
    local id_str = string.format("%04d", current_nationalDex)

    -- O(1) lookup instead of O(n) loop
    local pokemon_data = base_stats_cache[id_str]
    
    if pokemon_data then
        return pokemon_data
    else
        -- Fallback for Pokemon not found in database
        return {
            id = id_str,
            name = "Unknown Pokemon #" .. id_str,
            types = {"Normal"},
            abilities = {{name = "Unknown", description = "Unknown ability"}},
            weak = {}, super_weak = {}, resistant = {}, super_resistant = {}, immune = {}
        }
    end
end

local function get_nature_stats_by_name(nameInput)
    local name = nameInput:lower()
    return NATURE_DATA[name]
end

-- Load EV yield data from JSON (kept for large data)
local yield_file = io.open(parent_dir .. "data_set/ev_yield.json")
local yields = {}
local yields_cache = {} -- CACHE: O(1) lookup table

if yield_file then
    local content = yield_file:read("*all")
    yield_file:close()
    yields = json.decode(content)
    
    -- Build cache: Convert array to hash table for O(1) lookup
    for _, yield in ipairs(yields) do
        yields_cache[yield.id] = yield
    end
    console:log("✅ EV yields loaded and cached: " .. #yields .. " entries")
else
    console:log("Error: Could not open ev_yield.json")
end

local function get_yield_by_species_id(species_id)
    -- O(1) lookup instead of O(n) loop

    current_nationalDex = nationalDexList[species_id + 1]
    local id_str = string.format("%04d", current_nationalDex)
    return yields_cache[id_str]
end

-- ============================================================================
-- IV CALCULATION REVERSE - IVs are derived from stats; results may not be exact.
-- ============================================================================
local function calc_iv_reverse(stat, base, ev, level, nature_mult, is_hp)
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

    iv = math.max(0, math.min(31, iv))

    return iv
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
    local pokemon_info = get_base_stats_by_id(g.species)

    if not pokemon_info or not pokemon_info.name or pokemon_info.name:find("Unknown") then
        console:log("⚠️ Pokemon data fallback used for species: " .. tostring(g.species))
    end
    
    local name = (pokemon_info and pokemon_info.name) or "Unknown Pokemon"
    local nature_name = report.nature or "Unknown"
    local natureData = get_nature_stats_by_name(nature_name)
    local is_shiny = report.is_shiny or false

    local moves = {}
    local move_count = 0
    if a.moves and a.pp then
        for i = 1, 4 do
            local move_id = a.moves[i]
            local move_pp = a.pp[i]
            if move_id and move_id > 0 then
                move_count = move_count + 1
                local move_name = MOVES_DATA[string.format("%03d", move_id)] or ("Move " .. tostring(move_id))
                table.insert(moves, { name = move_name, pp = move_pp })
            end
        end
    end
    report.moves = moves
    report.move_count = move_count

    -- console:log("report p_id: " .. tostring(report.p_id) .. " ot_id: " .. tostring(report.ot_id) .. " s_id: " .. tostring(report.s_id))
    -- console:log("TID: " .. tostring(tid) .. " SID: " .. tostring(sid))

    -- console:log("TID should be: 36858")

    local ev_yield = get_yield_by_species_id(g.species) or {}
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

    local iv_hp = m.iv_hp or 0
    local iv_atk = m.iv_atk or 0
    local iv_def = m.iv_def or 0
    local iv_spatk = m.iv_spatk or 0
    local iv_spdef = m.iv_spdef or 0
    local iv_spd = m.iv_spd or 0

    local ability_index = m.ability or 0

    local hidden_type, hidden_power_power = get_hidden_type_power(
        iv_hp, iv_atk, iv_def, iv_spatk, iv_spdef, iv_spd
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

    local total_iv_average = total_iv_value / count_cal_iv

    if (total_iv_average >= 29) then
        report.iv_rank = (math.floor(total_iv_average * 100) / 100) .. " 🌟🌟🌟🌟🌟"
    elseif (total_iv_average >= 25) then
        report.iv_rank = (math.floor(total_iv_average * 100) / 100) .. " 🌟🌟🌟🌟"
    elseif (total_iv_average >= 20) then
        report.iv_rank = (math.floor(total_iv_average * 100) / 100) .. " 🌟🌟🌟"
    elseif (total_iv_average >= 15) then
        report.iv_rank = (math.floor(total_iv_average * 100) / 100) .. " 🌟🌟"
    elseif (total_iv_average >= 10) then
        report.iv_rank = (math.floor(total_iv_average * 100) / 100) .. " 🌟"
    else
        report.iv_rank = "No stars : " .. (math.floor(total_iv_average * 100) / 100)
    end

    local pokemon_types = pokemon_info.types or {}
    report.types = pokemon_types

    -- Weaknesses, Resistances, Immunities
    local weaknesses = pokemon_info.weak or {}
    local super_weaknesses = pokemon_info.super_weak or {}
    local resistances = pokemon_info.resistant or {}
    local super_resistances = pokemon_info.super_resistant or {}
    local immunities = pokemon_info.immune or {}

    report.weaknesses = weaknesses
    report.super_weaknesses = super_weaknesses
    report.resistances = resistances
    report.super_resistances = super_resistances
    report.immunities = immunities

    -- Ability effects can be added here in the future
    -- "abilities": [
    --   {
    --     "name": "Overgrow",
    --     "description": "When its health reaches one-third or .."
    --   }
    -- ],
    local ability_effects = pokemon_info.abilities or {}
    report.ability_effects = ability_effects

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
    report.hidden_type = HIDDEN_POWER_TYPES[hidden_type + 1] or "Unknown"
    report.hidden_power_power = hidden_power_power or 0
    report.total_iv_average = total_iv_average or 0
    report.ability_index = ability_index or 0
    return report
end

function pokemon_check.print_report(report, buffer, opts)
    local report = pokemon_check.full_info(report)
    opts = opts or {}
    local show_moves = opts.show_moves == true -- mặc định false
    local is_mewth_farming = opts.is_mewth_farming == true -- mặc định false
    local show_evs_ivs = opts.show_evs_ivs ~= false -- mặc định true
    if buffer and type(buffer.clear) == "function" and type(buffer.print) == "function" then
        buffer:print("🛡️💎🎯 𝙿𝚘𝚔𝚎𝚖𝚘𝚗 Information 🛡️💎🎯\n")
        if (report.is_shiny) then
            buffer:print(string.format("Name : %s", report.name) .. " 💫💖💖 Shiny! 💖💖💫\n")
        else 
            buffer:print(string.format("Name : %s\n", report.name))
        end
        buffer:print("-----------------------------------\n")
        if is_mewth_farming then
            buffer:print(string.format("Held Item: %s\n", report.item))
        else

            local type_list = {}
            for _, v in pairs(report.types or {}) do
                table.insert(type_list, v)
            end
            buffer:print("Types: " .. table.concat(type_list, ", ") .. "\n")
            buffer:print("Weaknesses: " .. table.concat(report.weaknesses or {}, ", ") .. "\n")
            buffer:print("Super Weaknesses: " .. table.concat(report.super_weaknesses or {}, ", ") .. "\n")
            buffer:print("Resistances: " .. table.concat(report.resistances or {}, ", ") .. "\n")
            buffer:print("Super Resistances: " .. table.concat(report.super_resistances or {}, ", ") .. "\n")
            buffer:print("Immunities with: " .. table.concat(report.immunities or {}, ", ") .. "\n")
            buffer:print("-----------------------------------\n")
            buffer:print("Abilities:\n")
            local ability = report.ability_effects[report.ability_index + 1] or {name="Unknown", desc="No description"}
            buffer:print(string.format("  %s: %s\n", ability.name or "Unknown", ability.desc or "No description"))
            buffer:print("-----------------------------------\n")
            buffer:print(string.format("Hidden Power Type: %s (Power: %d)\n", report.hidden_type, report.hidden_power_power))
            buffer:print("-----------------------------------\n")
            buffer:print(string.format("Held Item: %s\n", report.item))
            buffer:print(string.format("Level: %d\n", report.level))
            buffer:print(string.format("Stats: HP:%d ATK:%d DEF:%d SPATK:%d SPDEF:%d SPD:%d\n",
                    report.stats.hp, report.stats.atk, report.stats.def, report.stats.spatk, report.stats.spdef, report.stats.speed))
            if show_evs_ivs then
                
                buffer:print("-----------------------------------\n")  
                buffer:print(string.format("EVs: HP:%d ATK:%d DEF:%d SPATK:%d SPDEF:%d SPD:%d\n",
                    report.evs.hp_ev, report.evs.atk_ev, report.evs.def_ev, report.evs.spatk_ev, report.evs.spdef_ev, report.evs.spd_ev))
                buffer:print(string.format("IVs: HP:%d ATK:%d DEF:%d SPATK:%d SPDEF:%d SPD:%d\n",
                    report.ivs.hp, report.ivs.atk, report.ivs.def, report.ivs.spatk, report.ivs.spdef, report.ivs.speed))      
                buffer:print(string.format("IV Rank: %s\n", report.iv_rank or "No stars"))
            end
            buffer:print(string.format("Nature: %s is: %s\n", report.nature, report.nature_summary))
            buffer:print("-----------------------------------\n")
            buffer:print("EV Yield:\n")
            for stat, value in pairs(report.ev_yield or {}) do
                buffer:print(string.format("  %s: %d\n", stat:upper(), value))
            end
            if show_moves and report.moves then
                buffer:print("-----------------------------------\n")
                buffer:print("Moves:\n")
                for i, move in ipairs(report.moves) do
                    buffer:print(string.format("%d. %s (PP: %d)\n", i, move.name, move.pp or 0))
                end
            end
        end
        buffer:print("===================================\n")
    end
end

return pokemon_check