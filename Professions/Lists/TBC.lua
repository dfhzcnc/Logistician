local main = WiderProfessionsAddon
local alchemySpellList = {
    ["Transmutation"] = {
        ["47050"] = true, --"Assassin's Alchemist Stone",
        ["47046"] = true, --"Guardian's Alchemist Stone",
        ["47049"] = true, --"Redeemer's Alchemist Stone",
        ["47048"] = true, --"Sorcerer's Alchemist Stone",
        ["38070"] = true, --"Mercurial Stone",
        ["11459"] = true, --"Philosopher's Stone",
        ["17632"] = true, --"Alchemist's Stone",
        ["28585"] = true, --"Transmute: Primal Earth to Life",
        ["28583"] = true, --"Transmute: Primal Fire to Mana",
        ["28584"] = true, --"Transmute: Primal Life to Earth",
        ["28582"] = true, --"Transmute: Primal Mana to Fire",
        ["28580"] = true, --"Transmute: Primal Shadow to Water",
        ["28581"] = true, --"Transmute: Primal Water to Shadow",
        ["32765"] = true, --"Transmute: Earthstorm Diamond",
        ["28566"] = true, --"Transmute: Primal Air to Fire",
        ["28567"] = true, --"Transmute: Primal Earth to Water",
        ["28568"] = true, --"Transmute: Primal Fire to Earth",
        ["29688"] = true, --"Transmute: Primal Might",
        ["28569"] = true, --"Transmute: Primal Water to Air",
        ["32766"] = true, --"Transmute: Skyfire Diamond",
        ["25146"] = true, --"Transmute: Elemental Fire",
        ["17559"] = true, --"Transmute: Air to Fire",
        ["17187"] = true, --"Transmute: Arcanite",
        ["17566"] = true, --"Transmute: Earth to Life",
        ["17561"] = true, --"Transmute: Earth to Water",
        ["17560"] = true, --"Transmute: Fire to Earth",
        ["17565"] = true, --"Transmute: Life to Earth",
        ["17563"] = true, --"Transmute: Undeath to Water",
        ["17562"] = true, --"Transmute: Water to Air",
        ["17564"] = true, --"Transmute: Water to Undeath",
        ["11479"] = true, --"Transmute: Iron to Gold",
        ["11480"] = true, --"Transmute: Mithril to Truesilver",
    },
    ["Flasks"] = {
        ["28590"] = true, --"Flask of Blinding Light",
        ["28587"] = true, --"Flask of Fortification",
        ["28588"] = true, --"Flask of Mighty Restoration",
        ["28591"] = true, --"Flask of Pure Death",
        ["28589"] = true, --"Flask of Relentless Assault",
        ["42736"] = true, --"Flask of Chromatic Wonder",
        ["17638"] = true, --"Flask of Chromatic Resistance",
        ["17636"] = true, --"Flask of Distilled Wisdom",
        ["17634"] = true, --"Flask of Petrification",
        ["17637"] = true, --"Flask of Supreme Power",
        ["17635"] = true, --"Flask of the Titans",
    },
    ["Potions"] = {
        ["17570"] = true, --"Greater Stoneshield Potion",
        ["4942"] = true, --"Lesser Stoneshield Potion",
        ["45061"] = true, --"Mad Alchemist's Potion",
        ["6619"] = true, --"Cowardly Flight Potion",
        ["28551"] = true, --"Super Healing Potion",
        ["33732"] = true, --"Volatile Healing Potion",
        ["17556"] = true, --"Major Healing Potion",
        ["11457"] = true, --"Superior Healing Potion",
        ["7181"] = true, --"Greater Healing Potion",
        ["3447"] = true, --"Healing Potion",
        ["2337"] = true, --"Lesser Healing Potion",
        ["4508"] = true, --"Discolored Healing Potion",
        ["2330"] = true, --"Minor Healing Potion",
        ["38961"] = true, --"Fel Mana Potion",
        ["28555"] = true, --"Super Mana Potion",
        ["33733"] = true, --"Unstable Mana Potion",
        ["17580"] = true, --"Major Mana Potion",
        ["17553"] = true, --"Superior Mana Potion",
        ["11448"] = true, --"Greater Mana Potion",
        ["3452"] = true, --"Mana Potion",
        ["3173"] = true, --"Lesser Mana Potion",
        ["2331"] = true, --"Minor Mana Potion",
        ["28586"] = true, --"Super Rejuvenation Potion",
        ["22732"] = true, --"Major Rejuvenation Potion",
        ["2332"] = true, --"Minor Rejuvenation Potion",
        ["28579"] = true, --"Ironshield Potion",
        ["28565"] = true, --"Destruction Potion",
        ["28564"] = true, --"Haste Potion",
        ["28563"] = true, --"Heroic Potion",
        ["28562"] = true, --"Major Dreamless Sleep Potion",
        ["38962"] = true, --"Fel Regeneration Potion",
        ["28554"] = true, --"Shrouding Potion",
        ["28550"] = true, --"Insane Strength Potion",
        ["28546"] = true, --"Sneaking Potion",
        ["24367"] = true, --"Living Action Potion",
        ["17572"] = true, --"Purification Potion",
        ["24366"] = true, --"Greater Dreamless Sleep Potion",
        ["17552"] = true, --"Mighty Rage Potion",
        ["3175"] = true, --"Limited Invulnerability Potion",
        ["11464"] = true, --"Invisibility Potion",
        ["15833"] = true, --"Dreamless Sleep Potion",
        ["11458"] = true, --"Wildvine Potion",
        ["11452"] = true, --"Restorative Potion",
        ["11453"] = true, --"Magic Resistance Potion",
        ["6618"] = true, --"Great Rage Potion",
        ["3448"] = true, --"Lesser Invisibility Potion",
        ["6624"] = true, --"Free Action Potion",
        ["3174"] = true, --"Potion of Curing",
        ["3172"] = true, --"Minor Magic Resistance Potion",
        ["7841"] = true, --"Swim Speed Potion",
        ["6617"] = true, --"Rage Potion",
        ["2335"] = true, --"Swiftness Potion",
    },
    ["Elixirs"] = {
        ["11466"] = true, --"Gift of Arthas",
        ["24365"] = true, --"Mageblood Potion",
        ["28578"] = true, --"Elixir of Empowerment",
        ["28570"] = true, --"Elixir of Major Mageblood",
        ["28558"] = true, --"Elixir of Major Shadow Power",
        ["28557"] = true, --"Elixir of Major Defense",
        ["28556"] = true, --"Elixir of Major Firepower",
        ["38960"] = true, --"Fel Strength Elixir",
        ["39639"] = true, --"Elixir of Ironskin",
        ["28553"] = true, --"Elixir of Major Agility",
        ["28552"] = true, --"Elixir of the Searching Eye",
        ["39637"] = true, --"Earthen Elixir",
        ["39638"] = true, --"Elixir of Draenic Wisdom",
        ["28549"] = true, --"Elixir of Major Frost Power",
        ["33741"] = true, --"Elixir of Mastery",
        ["28545"] = true, --"Elixir of Healing Power",
        ["39636"] = true, --"Elixir of Major Fortitude",
        ["28543"] = true, --"Elixir of Camouflage",
        ["28544"] = true, --"Elixir of Major Strength",
        ["33740"] = true, --"Adept's Elixir",
        ["33738"] = true, --"Onslaught Elixir",
        ["17573"] = true, --"Greater Arcane Elixir",
        ["17571"] = true, --"Elixir of the Mongoose",
        ["17557"] = true, --"Elixir of Brute Force",
        ["17555"] = true, --"Elixir of the Sages",
        ["17554"] = true, --"Elixir of Superior Defense",
        ["11477"] = true, --"Elixir of Demonslaying",
        ["11478"] = true, --"Elixir of Detect Demon",
        ["26277"] = true, --"Elixir of Greater Firepower",
        ["11476"] = true, --"Elixir of Shadow Power",
        ["11472"] = true, --"Elixir of Giants",
        ["11468"] = true, --"Elixir of Dream Vision",
        ["11467"] = true, --"Elixir of Greater Agility",
        ["11461"] = true, --"Arcane Elixir",
        ["11465"] = true, --"Elixir of Greater Intellect",
        ["11460"] = true, --"Elixir of Detect Undead",
        ["22808"] = true, --"Elixir of Greater Water Breathing",
        ["12609"] = true, --"Catseye Elixir",
        ["3453"] = true, --"Elixir of Detect Lesser Invisibility",
        ["11450"] = true, --"Elixir of Greater Defense",
        ["21923"] = true, --"Elixir of Frost Power",
        ["11449"] = true, --"Elixir of Agility",
        ["3450"] = true, --"Elixir of Fortitude",
        ["3188"] = true, --"Elixir of Ogre's Strength",
        ["7845"] = true, --"Elixir of Firepower",
        ["2333"] = true, --"Elixir of Lesser Agility",
        ["3177"] = true, --"Elixir of Defense",
        ["8240"] = true, --"Elixir of Giant Growth",
        ["7179"] = true, --"Elixir of Water Breathing",
        ["3171"] = true, --"Elixir of Wisdom",
        ["3230"] = true, --"Elixir of Minor Agility",
        ["2334"] = true, --"Elixir of Minor Fortitude",
        ["2329"] = true, --"Elixir of Lion's Strength",
        ["7183"] = true, --"Elixir of Minor Defense",
        ["2336"] = true, --"Elixir of Tongues",
        ["11447"] = true, --"Elixir of Waterwalking",
        ["24368"] = true, --"Major Troll's Blood Potion",
        ["3451"] = true, --"Mighty Troll's Blood Potion",
        ["3176"] = true, --"Strong Troll's Blood Potion",
        ["3170"] = true, --"Weak Troll's Blood Potion",
    },
    ["ProtectionPotions"] = {
        ["28575"] = true, --"Major Arcane Protection Potion",
        ["28571"] = true, --"Major Fire Protection Potion",
        ["28572"] = true, --"Major Frost Protection Potion",
        ["28577"] = true, --"Major Holy Protection Potion",
        ["28573"] = true, --"Major Nature Protection Potion",
        ["28576"] = true, --"Major Shadow Protection Potion",
        ["41458"] = true, --"Cauldron of Major Arcane Protection",
        ["41500"] = true, --"Cauldron of Major Fire Protection",
        ["41501"] = true, --"Cauldron of Major Frost Protection",
        ["41502"] = true, --"Cauldron of Major Nature Protection",
        ["41503"] = true, --"Cauldron of Major Shadow Protection",
        ["17577"] = true, --"Greater Arcane Protection Potion",
        ["17574"] = true, --"Greater Fire Protection Potion",
        ["17575"] = true, --"Greater Frost Protection Potion",
        ["17576"] = true, --"Greater Nature Protection Potion",
        ["17578"] = true, --"Greater Shadow Protection Potion",
        ["7259"] = true, --"Nature Protection Potion",
        ["7258"] = true, --"Frost Protection Potion",
        ["7257"] = true, --"Fire Protection Potion",
        ["7256"] = true, --"Shadow Protection Potion",
        ["7255"] = true, --"Holy Protection Potion",
        ["17579"] = true, --"Greater Holy Protection Potion",
    },
    ["Misc"] = {
        ["17551"] = true, --"Stonescale Oil",
        ["11451"] = true, --"Oil of Immolation",
        ["3454"] = true, --"Frost Oil",
        ["3449"] = true, --"Shadow Oil",
        ["7837"] = true, --"Fire Oil",
        ["7836"] = true, --"Blackmouth Oil",
        ["24266"] = true, --"Gurubashi Mojo Madness",
        ["11473"] = true, --"Ghost Dye",
        ["11456"] = true, --"Goblin Rocket Fuel",
    }
}

local enchantSpellList = {
    ["Misc"] = {
        ["32667"] = true, --"Runed Eternium Rod",
        ["45765"] = true, --"Void Shatter",
        ["32665"] = true, --"Runed Adamantite Rod",
        ["28028"] = true, --"Void Sphere",
        ["28019"] = true, --"Superior Wizard Oil",
        ["42615"] = true, --"Small Prismatic Shard",
        ["28022"] = true, --"Large Prismatic Shard",
        ["28027"] = true, --"Prismatic Sphere",
        ["28016"] = true, --"Superior Mana Oil",
        ["32664"] = true, --"Runed Fel Iron Rod",
        ["25130"] = true, --"Brilliant Mana Oil",
        ["25129"] = true, --"Brilliant Wizard Oil",
        ["42613"] = true, --"Nexus Transformation",
        ["20051"] = true, --"Runed Arcanite Rod",
        ["25128"] = true, --"Wizard Oil",
        ["15596"] = true, --"Smoking Heart of the Mountain",
        ["25127"] = true, --"Lesser Mana Oil",
        ["17181"] = true, --"Enchanted Leather",
        ["17180"] = true, --"Enchanted Thorium",
        ["13702"] = true, --"Runed Truesilver Rod",
        ["25126"] = true, --"Lesser Wizard Oil",
        ["14810"] = true, --"Greater Mystic Wand",
        ["14809"] = true, --"Lesser Mystic Wand",
        ["13628"] = true, --"Runed Golden Rod",
        ["25125"] = true, --"Minor Mana Oil",
        ["7795"] = true, --"Runed Silver Rod",
        ["14807"] = true, --"Greater Magic Wand",
        ["25124"] = true, --"Minor Wizard Oil",
        ["14293"] = true, --"Lesser Magic Wand",
        ["7421"] = true, --"Runed Copper Rod",
        ["28021"] = true, --"Arcane Dust",
    },
    ["Ring"] = {
        ["27927"] = true, --"Enchant Ring - Stats",
        ["27926"] = true, --"Enchant Ring - Healing Power",
        ["27924"] = true, --"Enchant Ring - Spellpower",
        ["27920"] = true, --"Enchant Ring - Striking",
    },
    ["Boots"] = {
        ["27954"] = true, --"Enchant Boots - Surefooted",
        ["34008"] = true, --"Enchant Boots - Boar's Speed",
        ["34007"] = true, --"Enchant Boots - Cat's Swiftness",
        ["27951"] = true, --"Enchant Boots - Dexterity",
        ["27950"] = true, --"Enchant Boots - Fortitude",
        ["27948"] = true, --"Enchant Boots - Vitality",
        ["20023"] = true, --"Enchant Boots - Greater Agility",
        ["20024"] = true, --"Enchant Boots - Spirit",
        ["20020"] = true, --"Enchant Boots - Greater Stamina",
        ["13935"] = true, --"Enchant Boots - Agility",
        ["13890"] = true, --"Enchant Boots - Minor Speed",
        ["13836"] = true, --"Enchant Boots - Stamina",
        ["13687"] = true, --"Enchant Boots - Lesser Spirit",
        ["13644"] = true, --"Enchant Boots - Lesser Stamina",
        ["13637"] = true, --"Enchant Boots - Lesser Agility",
        ["7867"] = true, --"Enchant Boots - Minor Agility",
        ["7863"] = true, --"Enchant Boots - Minor Stamina",
    },
    ["Weapon"] = {
        ["42974"] = true, --"Enchant Weapon - Executioner",
        ["27984"] = true, --"Enchant Weapon - Mongoose",
        ["27982"] = true, --"Enchant Weapon - Soulfrost",
        ["27981"] = true, --"Enchant Weapon - Sunfire",
        ["28004"] = true, --"Enchant Weapon - Battlemaster",
        ["28003"] = true, --"Enchant Weapon - Spellsurge",
        ["34010"] = true, --"Enchant Weapon - Major Healing",
        ["27975"] = true, --"Enchant Weapon - Major Spellpower",
        ["27972"] = true, --"Enchant Weapon - Potency",
        ["42620"] = true, --"Enchant Weapon - Greater Agility",
        ["46578"] = true, --"Enchant Weapon - Deathfrost",
        ["27968"] = true, --"Enchant Weapon - Major Intellect",
        ["27967"] = true, --"Enchant Weapon - Major Striking",
        ["20034"] = true, --"Enchant Weapon - Crusader",
        ["22750"] = true, --"Enchant Weapon - Healing Power",
        ["20032"] = true, --"Enchant Weapon - Lifestealing",
        ["23804"] = true, --"Enchant Weapon - Mighty Intellect",
        ["23803"] = true, --"Enchant Weapon - Mighty Spirit",
        ["22749"] = true, --"Enchant Weapon - Spell Power",
        ["20031"] = true, --"Enchant Weapon - Superior Striking",
        ["20033"] = true, --"Enchant Weapon - Unholy Weapon",
        ["23800"] = true, --"Enchant Weapon - Agility",
        ["23799"] = true, --"Enchant Weapon - Strength",
        ["20029"] = true, --"Enchant Weapon - Icy Chill",
        ["13898"] = true, --"Enchant Weapon - Fiery Weapon",
        ["13943"] = true, --"Enchant Weapon - Greater Striking",
        ["13915"] = true, --"Enchant Weapon - Demonslaying",
        ["13693"] = true, --"Enchant Weapon - Striking",
        ["21931"] = true, --"Enchant Weapon - Winter's Might",
        ["13653"] = true, --"Enchant Weapon - Lesser Beastslayer",
        ["13655"] = true, --"Enchant Weapon - Lesser Elemental Slayer",
        ["13503"] = true, --"Enchant Weapon - Lesser Striking",
        ["7786"] = true, --"Enchant Weapon - Minor Beastslayer",
        ["7788"] = true, --"Enchant Weapon - Minor Striking",
    },
    ["2HWeapon"] = {
        ["27977"] = true, --"Enchant 2H Weapon - Major Agility",
        ["27971"] = true, --"Enchant 2H Weapon - Savagery",
        ["20036"] = true, --"Enchant 2H Weapon - Major Intellect",
        ["20035"] = true, --"Enchant 2H Weapon - Major Spirit",
        ["20030"] = true, --"Enchant 2H Weapon - Superior Impact",
        ["27837"] = true, --"Enchant 2H Weapon - Agility",
        ["13937"] = true, --"Enchant 2H Weapon - Greater Impact",
        ["13695"] = true, --"Enchant 2H Weapon - Impact",
        ["13529"] = true, --"Enchant 2H Weapon - Lesser Impact",
        ["13380"] = true, --"Enchant 2H Weapon - Lesser Spirit",
        ["7793"] = true, --"Enchant 2H Weapon - Lesser Intellect",
        ["7745"] = true, --"Enchant 2H Weapon - Minor Impact",
    },
    ["Shield"] = {
        ["27947"] = true, --"Enchant Shield - Resistance",
        ["27946"] = true, --"Enchant Shield - Shield Block",
        ["44383"] = true, --"Enchant Shield - Resilience",
        ["27945"] = true, --"Enchant Shield - Intellect",
        ["34009"] = true, --"Enchant Shield - Major Stamina",
        ["27944"] = true, --"Enchant Shield - Tough Shield",
        ["20016"] = true, --"Enchant Shield - Superior Spirit",
        ["20017"] = true, --"Enchant Shield - Greater Stamina",
        ["13933"] = true, --"Enchant Shield - Frost Resistance",
        ["13905"] = true, --"Enchant Shield - Greater Spirit",
        ["13817"] = true, --"Enchant Shield - Stamina",
        ["13689"] = true, --"Enchant Shield - Lesser Block",
        ["13659"] = true, --"Enchant Shield - Spirit",
        ["13631"] = true, --"Enchant Shield - Lesser Stamina",
        ["13485"] = true, --"Enchant Shield - Lesser Spirit",
        ["13464"] = true, --"Enchant Shield - Lesser Protection",
        ["13378"] = true, --"Enchant Shield - Minor Stamina",
    },
    ["Gloves"] = {
        ["33997"] = true, --"Enchant Gloves - Major Spellpower",
        ["33994"] = true, --"Enchant Gloves - Spell Strike",
        ["33999"] = true, --"Enchant Gloves - Major Healing",
        ["33995"] = true, --"Enchant Gloves - Major Strength",
        ["33996"] = true, --"Enchant Gloves - Assault",
        ["33993"] = true, --"Enchant Gloves - Blasting",
        ["25078"] = true, --"Enchant Gloves - Fire Power",
        ["25074"] = true, --"Enchant Gloves - Frost Power",
        ["25079"] = true, --"Enchant Gloves - Healing Power",
        ["25073"] = true, --"Enchant Gloves - Shadow Power",
        ["25080"] = true, --"Enchant Gloves - Superior Agility",
        ["25072"] = true, --"Enchant Gloves - Threat",
        ["20013"] = true, --"Enchant Gloves - Greater Strength",
        ["20012"] = true, --"Enchant Gloves - Greater Agility",
        ["13948"] = true, --"Enchant Gloves - Minor Haste",
        ["13947"] = true, --"Enchant Gloves - Riding Skill",
        ["13868"] = true, --"Enchant Gloves - Advanced Herbalism",
        ["13887"] = true, --"Enchant Gloves - Strength",
        ["13841"] = true, --"Enchant Gloves - Advanced Mining",
        ["13815"] = true, --"Enchant Gloves - Agility",
        ["13698"] = true, --"Enchant Gloves - Skinning",
        ["13620"] = true, --"Enchant Gloves - Fishing",
        ["13617"] = true, --"Enchant Gloves - Herbalism",
        ["13612"] = true, --"Enchant Gloves - Mining",
    },
    ["Cloak"] = {
        ["47051"] = true, --"Enchant Cloak - Steelweave",
        ["34005"] = true, --"Enchant Cloak - Greater Arcane Resistance",
        ["34006"] = true, --"Enchant Cloak - Greater Shadow Resistance",
        ["27962"] = true, --"Enchant Cloak - Major Resistance",
        ["34003"] = true, --"Enchant Cloak - Spell Penetration",
        ["34004"] = true, --"Enchant Cloak - Greater Agility",
        ["27961"] = true, --"Enchant Cloak - Major Armor",
        ["25086"] = true, --"Enchant Cloak - Dodge",
        ["25081"] = true, --"Enchant Cloak - Greater Fire Resistance",
        ["25082"] = true, --"Enchant Cloak - Greater Nature Resistance",
        ["25083"] = true, --"Enchant Cloak - Stealth",
        ["25084"] = true, --"Enchant Cloak - Subtlety",
        ["20015"] = true, --"Enchant Cloak - Superior Defense",
        ["20014"] = true, --"Enchant Cloak - Greater Resistance",
        ["13882"] = true, --"Enchant Cloak - Lesser Agility",
        ["13746"] = true, --"Enchant Cloak - Greater Defense",
        ["13794"] = true, --"Enchant Cloak - Resistance",
        ["13657"] = true, --"Enchant Cloak - Fire Resistance",
        ["13635"] = true, --"Enchant Cloak - Defense",
        ["13522"] = true, --"Enchant Cloak - Lesser Shadow Resistance",
        ["7861"] = true, --"Enchant Cloak - Lesser Fire Resistance",
        ["13421"] = true, --"Enchant Cloak - Lesser Protection",
        ["13419"] = true, --"Enchant Cloak - Minor Agility",
        ["7771"] = true, --"Enchant Cloak - Minor Protection",
        ["7454"] = true, --"Enchant Cloak - Minor Resistance",
    },
    ["Chest"] = {
        ["46594"] = true, --"Enchant Chest - Defense",
        ["27960"] = true, --"Enchant Chest - Exceptional Stats",
        ["33992"] = true, --"Enchant Chest - Major Resilience",
        ["27958"] = true, --"Enchant Chest - Exceptional Mana",
        ["33990"] = true, --"Enchant Chest - Major Spirit",
        ["27957"] = true, --"Enchant Chest - Exceptional Health",
        ["20025"] = true, --"Enchant Chest - Greater Stats",
        ["33991"] = true, --"Enchant Chest - Restore Mana Prime",
        ["20028"] = true, --"Enchant Chest - Major Mana",
        ["20026"] = true, --"Enchant Chest - Major Health",
        ["13941"] = true, --"Enchant Chest - Stats",
        ["13917"] = true, --"Enchant Chest - Superior Mana",
        ["13858"] = true, --"Enchant Chest - Superior Health",
        ["13700"] = true, --"Enchant Chest - Lesser Stats",
        ["13663"] = true, --"Enchant Chest - Greater Mana",
        ["13640"] = true, --"Enchant Chest - Greater Health",
        ["13626"] = true, --"Enchant Chest - Minor Stats",
        ["13607"] = true, --"Enchant Chest - Mana",
        ["13538"] = true, --"Enchant Chest - Lesser Absorption",
        ["7857"] = true, --"Enchant Chest - Health",
        ["7776"] = true, --"Enchant Chest - Lesser Mana",
        ["7748"] = true, --"Enchant Chest - Lesser Health",
        ["7426"] = true, --"Enchant Chest - Minor Absorption",
        ["7443"] = true, --"Enchant Chest - Minor Mana",
        ["7420"] = true, --"Enchant Chest - Minor Health",
    },
    ["Bracer"] = {
        ["27917"] = true, --"Enchant Bracer - Spellpower",
        ["27914"] = true, --"Enchant Bracer - Fortitude",
        ["27913"] = true, --"Enchant Bracer - Restore Mana Prime",
        ["27911"] = true, --"Enchant Bracer - Superior Healing",
        ["27906"] = true, --"Enchant Bracer - Major Defense",
        ["27905"] = true, --"Enchant Bracer - Stats",
        ["27899"] = true, --"Enchant Bracer - Brawn",
        ["34001"] = true, --"Enchant Bracer - Major Intellect",
        ["34002"] = true, --"Enchant Bracer - Assault",
        ["23802"] = true, --"Enchant Bracer - Healing Power",
        ["20011"] = true, --"Enchant Bracer - Superior Stamina",
        ["20010"] = true, --"Enchant Bracer - Superior Strength",
        ["23801"] = true, --"Enchant Bracer - Mana Regeneration",
        ["20009"] = true, --"Enchant Bracer - Superior Spirit",
        ["20008"] = true, --"Enchant Bracer - Greater Intellect",
        ["13945"] = true, --"Enchant Bracer - Greater Stamina",
        ["13939"] = true, --"Enchant Bracer - Greater Strength",
        ["13931"] = true, --"Enchant Bracer - Deflection",
        ["13846"] = true, --"Enchant Bracer - Greater Spirit",
        ["13822"] = true, --"Enchant Bracer - Intellect",
        ["13661"] = true, --"Enchant Bracer - Strength",
        ["13646"] = true, --"Enchant Bracer - Lesser Deflection",
        ["13648"] = true, --"Enchant Bracer - Stamina",
        ["13642"] = true, --"Enchant Bracer - Spirit",
        ["13622"] = true, --"Enchant Bracer - Lesser Intellect",
        ["13536"] = true, --"Enchant Bracer - Lesser Strength",
        ["13501"] = true, --"Enchant Bracer - Lesser Stamina",
        ["7859"] = true, --"Enchant Bracer - Lesser Spirit",
        ["7779"] = true, --"Enchant Bracer - Minor Agility",
        ["7782"] = true, --"Enchant Bracer - Minor Strength",
        ["7428"] = true, --"Enchant Bracer - Minor Deflection",
        ["7418"] = true, --"Enchant Bracer - Minor Health",
        ["7766"] = true, --"Enchant Bracer - Minor Spirit",
        ["7457"] = true, --"Enchant Bracer - Minor Stamina",
    }
}
local cookingItemList = {
    ["Shellfish"] = {
        ["27667"] = true, -- Spicy Crawdad
        ["30155"] = true, -- Clam Bar
        ["16766"] = true, -- Undermine Clam Chowder
        ["2682"] = true, -- Cooked Crab Claw
        ["2683"] = true, -- Crab Cake
        ["5526"] = true, -- Clam Chowder
        ["12216"] = true, -- Spiced Chili Crab
        ["6038"] = true, -- Giant Clam Scorcho
        ["13933"] = true, -- Lobster Stew
        ["5525"] = true, -- Boiled Clams
        ["5527"] = true, -- Goblin Deviled Clams
    },
    ["Fish"] = {
        ["4592"] = true, -- Longjaw Mud Snapper
        ["4593"] = true, -- Bristle Whisker Catfish
        ["6657"] = true, -- Savory Deviate Delight
        ["6290"] = true, -- Brilliant Smallfish
        ["8364"] = true, -- Mithril Headed Trout
        ["6887"] = true, -- Spotted Yellowtail
        ["787"] = true, -- Slitherskin Mackerel
        ["4594"] = true, -- Rockscale Cod
        ["5095"] = true, -- Rainbow Fin Albacore
        ["21072"] = true, -- Smoked Sagefish
        ["21217"] = true, -- Sagefish Delight
        ["13931"] = true, -- Nightfin Soup
        ["13928"] = true, -- Grilled Squid
        ["13930"] = true, -- Filet of Redgill
        ["13932"] = true, -- Poached Sunscale Salmon
        ["13934"] = true, -- Mightfish Steak
        ["13935"] = true, -- Baked Salmon
        ["3663"] = true, -- Murloc Fin Soup
        ["13927"] = true, -- Cooked Glossy Mightfish
        ["6316"] = true, -- Loch Frenzy Delight
        ["13929"] = true, -- Hot Smoked Bass
        ["5476"] = true, -- Fillet of Frenzy
        ["33052"] = true, -- Fisherman's Feast
        ["33053"] = true, -- Hot Buttered Trout
        ["33048"] = true, -- Stewed Trout
        ["27666"] = true, -- Golden Fish Sticks
        ["33825"] = true, -- Skullfish Soup
        ["27664"] = true, -- Grilled Mudfish
        ["27665"] = true, -- Poached Bluefish
        ["27663"] = true, -- Blackened Sporefish
        ["27661"] = true, -- Blackened Trout
        ["33867"] = true, -- Broiled Bloodfin
        ["27662"] = true, -- Feltail Delight
    }
}

function main:isFishRecipe(skillId)
    return fishSkillIdsList[skillId] ~= nil
end

function main:GetCookingList()
    return cookingItemList
end

function main:GetAlchemyList()
    return alchemySpellList
end

function main:GetEnchantingList()
    return enchantSpellList
end

function main:createPetSkillsCategoryMap()
    -- https://www.wowhead.com/classic/hunter-pets
    -- https://warcraft.wiki.gg/wiki/API_C_CreatureInfo.GetCreatureFamilyInfo
    -- local familyIndex = {
    --     ["Bats"] = 24,
    --     ["Bears"] = 4,
    --     ["Boars"] = 5,
    --     ["Carrion Birds"] = 7,
    --     ["Cats"] = 2,
    --     ["Crabs"] = 8,
    --     ["Crocolisks"] = 6,
    --     ["Gorillas"] = 9,
    --     ["Hyenas"] = 25,
    --     ["Owls"] = 26,
    --     ["Raptors"] = 11,
    --     ["Scorpids"] = 20,
    --     ["Spiders"] = 3,
    --     ["Tallstriders"] = 12,
    --     ["Turtles"] = 21,
    --     ["Wind Serpents"] = 27,
    --     ["Wolves"] = 1,
    --     --
    --     ["Ravagers"] = 31,
    --     ["Dragonhawks"] = 30,
    --     ["Warp Stalkers"] = 32,
    --     ["Nether Rays"] = 34,
    --     ["Serpents"] = 35,
    --     ["Sporebats"] = 33,
    -- }
    
    local BITE = GetSpellInfo(17253)
    local CHARGE = GetSpellInfo(7371)
    local CLAW = GetSpellInfo(16827)
    local COWER = GetSpellInfo(1742)
    local DASH = GetSpellInfo(23099)
    local DIVE = GetSpellInfo(23145)
    local FURIOUS_HOWL = GetSpellInfo(24604)
    local GROWL = GetSpellInfo(2649)
    local LIGHTNING_BREATH = GetSpellInfo(24844)
    local PROWL = GetSpellInfo(24450)
    local SCORPID_POISON = GetSpellInfo(24640)
    local SCREECH = GetSpellInfo(24423)
    local SHELL_SHIELD = GetSpellInfo(26064)
    local THUNDERSTOMP = GetSpellInfo(26090)
    local FIRE_BREATH = GetSpellInfo(34889)
    local GORE = GetSpellInfo(35290)
    local POISON_SPIT = GetSpellInfo(35387)
    local WARP = GetSpellInfo(35346)

    local hunterPetList = {
        [BITE] = {
            ["Families"] = {"24", "4", "5", "7", "2", "6", "30", "9", "25", "34", "11", "31", "35", "3", "12", "21", "32", "27", "1"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [CHARGE] = {
            ["Families"] = {"5"},
            ["Category"] = "Utility",
        },
        [CLAW] = {
            ["Families"] = {"4", "7", "2", "8", "26", "11", "20", "32"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [COWER] = {
            -- ["Families"] = {"24", "4", "5", "7", "2", "8", "6", "30", "9", "25", "34", "26", "11", "31", "20", "35", "3", "33", "12", "21", "32", "27", "1"},
            ["Category"] = PET_DEFENSIVE,
        },
        [DASH] = {
            ["Families"] = {"5", "2", "25", "11", "31", "12", "1"},
            ["Category"] = "Utility",
        },
        [DIVE] = {
            ["Families"] = {"24", "7", "30", "34", "26", "27"},
            ["Category"] = "Utility",
        },
        [FIRE_BREATH] = {
            ["Families"] = {"30"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [FURIOUS_HOWL] = {
            ["Families"] = {"1"},
            ["Category"] = "Utility",
        },
        [GORE] = {
            ["Families"] = {"5", "31"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [GROWL] = {
            -- ["Families"] = {"24", "4", "5", "7", "2", "8", "6", "30", "9", "25", "34", "26", "11", "31", "20", "35", "3", "33", "12", "21", "32", "27", "1"},
            ["Category"] = "Utility",
        },
        [LIGHTNING_BREATH] = {
            ["Families"] = {"27"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [POISON_SPIT] = {
            ["Families"] = {"35"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [PROWL] = {
            ["Families"] = {"2"},
            ["Category"] = "Utility",
        },
        [SCORPID_POISON] = {
            ["Families"] = {"20"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [SCREECH] = {
            ["Families"] = {"24", "7", "26"},
            ["Category"] = PET_DEFENSIVE,
        },
        [SHELL_SHIELD] = {
            ["Families"] = {"21"},
            ["Category"] = PET_DEFENSIVE,
        },
        [THUNDERSTOMP] = {
            ["Families"] = {"9"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [WARP] = {
            ["Families"] = {"32"},
            ["Category"] = "Utility",
        },
    }

    main.petSkillsCategoryMap = hunterPetList
end
