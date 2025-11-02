-- Table of memory offsets for each game and language
return {
    ["FRLG"] = {
        JPN = {
            PARTY_COUNT = 0x02023F89,
            PARTY_START = 0x02024190,
            ENEMY_START = 0x02023F8C,
            BATTLE_MODE = 0x02022B4C,
            OPPONENT_PARTY_COUNT = 0x02023C3C,
        },
        EUR_USA = {
            PARTY_COUNT = 0x02024029,
            PARTY_START = 0x02024284,
            ENEMY_START = 0x0202402C,
            BATTLE_MODE = 0x02022B4C,
            OPPONENT_PARTY_COUNT = 0x02023C3C,
        }
    },
    ["SR"] = {
        JPN = {
            PARTY_COUNT = 0x03004280,
            PARTY_START = 0x03004290,
            ENEMY_START = 0x030044F0,
            BATTLE_MODE = 0x02022C80,
            OPPONENT_PARTY_COUNT = 0x02023C3C,
        },
        EUR_USA = {
            PARTY_COUNT = 0x03004350,
            PARTY_START = 0x03004360,
            ENEMY_START = 0x030045C0,
            BATTLE_MODE = 0x02022C80,
            OPPONENT_PARTY_COUNT = 0x02023C3C,
        }
    },
    ["E"] = {
        JPN = {
            PARTY_COUNT = 0x0202418D,
            PARTY_START = 0x02024190,
            ENEMY_START = 0x020243E8,
            BATTLE_MODE = 0x02023D38,
            OPPONENT_PARTY_COUNT = 0x02024E3C,
        },
        EUR_USA = {
            PARTY_COUNT = 0x020244E9,
            PARTY_START = 0x020244EC,
            ENEMY_START = 0x02024744,
            BATTLE_MODE = 0x02023D38,
            OPPONENT_PARTY_COUNT = 0x02024E3C,
        }
    }
}
