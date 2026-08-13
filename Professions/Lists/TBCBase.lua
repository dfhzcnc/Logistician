local main = WiderProfessionsAddon
local alchemySpellList = {
    ["Transmutation"] = {
        ["17632"] = true,--"Alchemist's Stone",
        ["11459"] = true,--"Philosophers' Stone",
        ["25146"] = true,--"Transmute: Elemental Fire",
        ["17559"] = true,--"Transmute: Air to Fire",
        ["17187"] = true,--"Transmute: Arcanite",
        ["17566"] = true,--"Transmute: Earth to Life",
        ["17561"] = true,--"Transmute: Earth to Water",
        ["17560"] = true,--"Transmute: Fire to Earth",
        ["17565"] = true,--"Transmute: Life to Earth",
        ["17563"] = true,--"Transmute: Undeath to Water",
        ["17562"] = true,--"Transmute: Water to Air",
        ["17564"] = true,--"Transmute: Water to Undeath",
        ["11479"] = true,--"Transmute: Iron to Gold",
        ["11480"] = true,--"Transmute: Mithril to Truesilver",
    },
    ["Flasks"] = {
        ["1213546"] = true,--"Flask of Ancient Knowledge",
        ["1213552"] = true,--"Flask of Madness",
        ["1213548"] = true,--"Flask of the Old Gods",
        ["1213544"] = true,--"Flask of Unyielding Sorrow",
        ["17638"] = true,--"Flask of Chromatic Resistance",
        ["17636"] = true,--"Flask of Distilled Wisdom",
        ["17634"] = true,--"Flask of Petrification",
        ["17637"] = true,--"Flask of Supreme Power",
        ["17635"] = true,--"Flask of the Titans",
        ["446226"] = true,--"Flask of Everlasting Nightmares",
        ["446851"] = true,--"Flask of Nightmarish Mojo",
        ["448085"] = true,--"Flask of Restless Dreams",
    },
    ["Potions"] = {
        ["2331"] = true,--"Minor Mana Potion",
        ["3173"] = true,--"Lesser Mana Potion",
        ["3452"] = true,--"Mana Potion",
        ["11448"] = true,--"Greater Mana Potion",
        ["17553"] = true,--"Superior Mana Potion",
        ["17580"] = true,--"Major Mana Potion",
        ["22732"] = true,--"Major Rejuvenation Potion",
        ["24367"] = true,--"Living Action Potion",
        ["17572"] = true,--"Purification Potion",
        ["24366"] = true,--"Greater Dreamless Sleep Potion",
        ["17556"] = true,--"Major Healing Potion",
        ["17552"] = true,--"Mighty Rage Potion",
        ["3175"] = true,--"Limited Invulnerability Potion",
        ["11464"] = true,--"Invisibility Potion",
        ["15833"] = true,--"Dreamless Sleep Potion",
        ["11458"] = true,--"Wildvine Potion",
        ["435971"] = true,--"Mildly Irradiated Rejuvenation Potion",
        ["4942"] = true,--"Lesser Stoneshield Potion",
        ["17570"] = true,--"Greater Stoneshield Potion",
        ["11457"] = true,--"Superior Healing Potion",
        ["11452"] = true,--"Restorative Potion",
        ["6618"] = true,--"Great Rage Potion",
        ["3448"] = true,--"Lesser Invisibility Potion",
        ["7181"] = true,--"Greater Healing Potion",
        ["3447"] = true,--"Healing Potion",
        ["7841"] = true,--"Swim Speed Potion",
        ["6617"] = true,--"Rage Potion",
        ["6624"] = true,--"Free Action Potion",
        ["2335"] = true,--"Swiftness Potion",
        ["2337"] = true,--"Lesser Healing Potion",
        ["4508"] = true,--"Discolored Healing Potion",
        ["2332"] = true,--"Minor Rejuvenation Potion",
        ["2330"] = true,--"Minor Healing Potion",
        ["6619"] = true,--"Cowardly Flight Potion",
    },
    ["Elixirs"] = {
        ["24368"] = true,--"Major Troll's Blood Potion",
        ["17573"] = true,--"Greater Arcane Elixir",
        ["24365"] = true,--"Mageblood Potion",
        ["1213571"] = true,--"Elixir of Alacrity",
        ["1213559"] = true,--"Elixir of the Honey Badger",
        ["1213565"] = true,--"Elixir of the Ironside",
        ["1213563"] = true,--"Elixir of the Mage-Lord",
        ["17571"] = true,--"Elixir of the Mongoose",
        ["17557"] = true,--"Elixir of Brute Force",
        ["17555"] = true,--"Elixir of the Sages",
        ["17554"] = true,--"Elixir of Superior Defense",
        ["11477"] = true,--"Elixir of Demonslaying",
        ["11478"] = true,--"Elixir of Detect Demon",
        ["26277"] = true,--"Elixir of Greater Firepower",
        ["11476"] = true,--"Elixir of Shadow Power",
        ["11472"] = true,--"Elixir of Giants",
        ["11468"] = true,--"Elixir of Dream Vision",
        ["11467"] = true,--"Elixir of Greater Agility",
        ["11465"] = true,--"Elixir of Greater Intellect",
        ["11460"] = true,--"Elixir of Detect Undead",
        ["11466"] = true,--"Gift of Arthas",
        ["11461"] = true,--"Arcane Elixir",
        ["22808"] = true,--"Elixir of Greater Water Breathing",
        ["439960"] = true,--"Lesser Arcane Elixir",
        ["12609"] = true,--"Catseye Elixir",
        ["11450"] = true,--"Elixir of Greater Defense",
        ["21923"] = true,--"Elixir of Frost Power",
        ["11449"] = true,--"Elixir of Agility",
        ["3450"] = true,--"Elixir of Fortitude",
        ["3451"] = true,--"Mighty Troll's Blood Potion",
        ["3453"] = true,--"Elixir of Detect Lesser Invisibility",
        ["3188"] = true,--"Elixir of Ogre's Strength",
        ["7845"] = true,--"Elixir of Firepower",
        ["2333"] = true,--"Elixir of Lesser Agility",
        ["3177"] = true,--"Elixir of Defense",
        ["8240"] = true,--"Elixir of Giant Growth",
        ["7179"] = true,--"Elixir of Water Breathing",
        ["3171"] = true,--"Elixir of Wisdom",
        ["426607"] = true,--"Elixir of Coalesced Regret",
        ["3176"] = true,--"Strong Troll's Blood Potion",
        ["3230"] = true,--"Elixir of Minor Agility",
        ["2334"] = true,--"Elixir of Minor Fortitude",
        ["3170"] = true,--"Weak Troll's Blood Potion",
        ["11447"] = true,--"Elixir of Waterwalking",
        ["2329"] = true,--"Elixir of Lion's Strength",
        ["7183"] = true,--"Elixir of Minor Defense",
        ["2336"] = true,--"Elixir of Tongues",
        ["3174"] = true,--"Elixir of Poison Resistance",
    },
    ["ProtectionPotions"] = {
        ["11453"] = true,--"Magic Resistance Potion",
        ["3172"] = true,--"Minor Magic Resistance Potion",
        ["17577"] = true,--"Greater Arcane Protection Potion",
        ["17574"] = true,--"Greater Fire Protection Potion",
        ["17575"] = true,--"Greater Frost Protection Potion",
        ["17576"] = true,--"Greater Nature Protection Potion",
        ["17578"] = true,--"Greater Shadow Protection Potion",
        ["7259"] = true,--"Nature Protection Potion",
        ["7258"] = true,--"Frost Protection Potion",
        ["7257"] = true,--"Fire Protection Potion",
        ["7256"] = true,--"Shadow Protection Potion",
        ["7255"] = true,--"Holy Protection Potion",
        ["17579"] = true,--"Greater Holy Protection Potion",
    },
    ["Misc"] = {
        ["24266"] = true,--"Gurubashi Mojo Madness",
        ["17551"] = true,--"Stonescale Oil",
        ["11473"] = true,--"Ghost Dye",
        ["11456"] = true,--"Goblin Rocket Fuel",
        ["11451"] = true,--"Oil of Immolation",
        ["3454"] = true,--"Frost Oil",
        ["3449"] = true,--"Shadow Oil",
        ["7837"] = true,--"Fire Oil",
        ["7836"] = true,--"Blackmouth Oil",
        ["22430"] = true,--"Refined Scale of Onyxia",
        ["435969"] = true,--"Insulating Gniodine",
    }
}

local enchantSpellList = {
    ["Misc"] = {
        ["1213635"] = true,--"Enchanted Mushroom",
        ["1213628"] = true,--"Enchanted Prayer Tome",
        ["1213610"] = true,--"Enchanted Repellent",
        ["1213600"] = true,--"Enchanted Stopwatch",
        ["1213633"] = true,--"Enchanted Totem",
        ["17181"] = true,--"Enchanted Leather",
        ["17180"] = true,--"Enchanted Thorium",
        ["1216022"] = true,--"Idol of Feline Ferocity",
        ["1216020"] = true,--"Idol of Sidereal Wrath",
        ["1216024"] = true,--"Idol of Ursin Power",
        ["1216005"] = true,--"Libram of Righteousness",
        ["1216010"] = true,--"Libram of Sanctity",
        ["1216007"] = true,--"Libram of the Exorcist",
        ["1213598"] = true,--"Lodestone of Retaliation",
        ["1213603"] = true,--"Ruby-Encrusted Broach",
        ["1213593"] = true,--"Speedstone",
        ["1213595"] = true,--"Tear of the Dreamer",
        ["1216018"] = true,--"Totem of Flowing Magma",
        ["1216014"] = true,--"Totem of Pyroclastic Thunder",
        ["1216016"] = true,--"Totem of Thunderous Strikes",
        ["471400"] = true,--"Magnificent Trollshine",
        ["463869"] = true,--"Conductive Shield Coating",
        ["15596"] = true,--"Smoking Heart of the Mountain",
        ["22434"] = true,--"Charged Scale of Onyxia",
        ["463866"] = true,--"Sigil of Flowing Waters",
        ["446243"] = true,--"Sigil of Living Dreams",
        ["439156"] = true,--"Sigil of Innovation",
        ["448624"] = true,--"Scroll of Spatial Mending",
        ["1213607"] = true,--"Scroll: Wrath of the Swarm",
        ["20051"] = true,--"Runed Arcanite Rod",
        ["13702"] = true,--"Runed Truesilver Rod",
        ["13628"] = true,--"Runed Golden Rod",
        ["7795"] = true,--"Runed Silver Rod",
        ["7421"] = true,--"Runed Copper Rod",
        ["14810"] = true,--"Greater Mystic Wand",
        ["439134"] = true,--"Greater Mystic Wand",
        ["14809"] = true,--"Lesser Mystic Wand",
        ["14807"] = true,--"Greater Magic Wand",
        ["14293"] = true,--"Lesser Magic Wand",
        ["25130"] = true,--"Brilliant Mana Oil",
        ["25129"] = true,--"Brilliant Wizard Oil",
        ["25128"] = true,--"Wizard Oil",
        ["25127"] = true,--"Lesser Mana Oil",
        ["25126"] = true,--"Lesser Wizard Oil",
        ["25125"] = true,--"Minor Mana Oil",
        ["430409"] = true,--"Blackfathom Mana Oil",
        ["25124"] = true,--"Minor Wizard Oil",
    },
    ["Boots"] = {
        ["20023"] = true,--"Enchant Boots - Greater Agility",
        ["20024"] = true,--"Enchant Boots - Spirit",
        ["20020"] = true,--"Enchant Boots - Greater Stamina",
        ["13935"] = true,--"Enchant Boots - Agility",
        ["13890"] = true,--"Enchant Boots - Minor Speed",
        ["13836"] = true,--"Enchant Boots - Stamina",
        ["13687"] = true,--"Enchant Boots - Lesser Spirit",
        ["13644"] = true,--"Enchant Boots - Lesser Stamina",
        ["13637"] = true,--"Enchant Boots - Lesser Agility",
        ["7867"] = true,--"Enchant Boots - Minor Agility",
        ["7863"] = true,--"Enchant Boots - Minor Stamina",
    },
    ["Weapon"] = {
        ["1231128"] = true,--"Enchant Weapon - Grand Crusader",
        ["1231164"] = true,--"Enchant Weapon - Grand Sorceror",
        ["20034"] = true,--"Enchant Weapon - Crusader",
        ["22750"] = true,--"Enchant Weapon - Healing Power",
        ["20032"] = true,--"Enchant Weapon - Lifestealing",
        ["23804"] = true,--"Enchant Weapon - Mighty Intellect",
        ["23803"] = true,--"Enchant Weapon - Mighty Spirit",
        ["22749"] = true,--"Enchant Weapon - Spell Power",
        ["20031"] = true,--"Enchant Weapon - Superior Striking",
        ["20033"] = true,--"Enchant Weapon - Unholy Weapon",
        ["23800"] = true,--"Enchant Weapon - Agility",
        ["23799"] = true,--"Enchant Weapon - Strength",
        ["20029"] = true,--"Enchant Weapon - Icy Chill",
        ["13898"] = true,--"Enchant Weapon - Fiery Weapon",
        ["13943"] = true,--"Enchant Weapon - Greater Striking",
        ["13915"] = true,--"Enchant Weapon - Demonslaying",
        ["435481"] = true,--"Enchant Weapon - Dismantle",
        ["13693"] = true,--"Enchant Weapon - Striking",
        ["21931"] = true,--"Enchant Weapon - Winter's Might",
        ["13653"] = true,--"Enchant Weapon - Lesser Beastslayer",
        ["13655"] = true,--"Enchant Weapon - Lesser Elemental Slayer",
        ["13503"] = true,--"Enchant Weapon - Lesser Striking",
        ["7786"] = true,--"Enchant Weapon - Minor Beastslayer",
        ["7788"] = true,--"Enchant Weapon - Minor Striking",
    },
    ["2HWeapon"] = {
        ["1219580"] = true,--"Enchant 2H Weapon - Spellblasting",
        ["1231139"] = true,--"Enchant 2H Weapon - Grand Arcanist",
        ["1232172"] = true,--"Enchant 2H Weapon - Grand Inquisitor",
        ["20036"] = true,--"Enchant 2H Weapon - Major Intellect",
        ["20035"] = true,--"Enchant 2H Weapon - Major Spirit",
        ["20030"] = true,--"Enchant 2H Weapon - Superior Impact",
        ["27837"] = true,--"Enchant 2H Weapon - Agility",
        ["13937"] = true,--"Enchant 2H Weapon - Greater Impact",
        ["13695"] = true,--"Enchant 2H Weapon - Impact",
        ["13529"] = true,--"Enchant 2H Weapon - Lesser Impact",
        ["13380"] = true,--"Enchant 2H Weapon - Lesser Spirit",
        ["7793"] = true,--"Enchant 2H Weapon - Lesser Intellect",
        ["7745"] = true,--"Enchant 2H Weapon - Minor Impact",
    },
    ["Shield"] = {
        ["20017"] = true,--"Enchant Shield - Greater Stamina",
        ["1220623"] = true,--"Enchant Shield - Critical Strike",
        ["1219581"] = true,--"Enchant Shield - Excellent Stamina",
        ["463871"] = true,--"Enchant Shield - Law of Nature",
        ["20016"] = true,--"Enchant Shield - Superior Spirit",
        ["13933"] = true,--"Enchant Shield - Frost Resistance",
        ["13905"] = true,--"Enchant Shield - Greater Spirit",
        ["13817"] = true,--"Enchant Shield - Stamina",
        ["13689"] = true,--"Enchant Shield - Lesser Block",
        ["13659"] = true,--"Enchant Shield - Spirit",
        ["13631"] = true,--"Enchant Shield - Lesser Stamina",
        ["13485"] = true,--"Enchant Shield - Lesser Spirit",
        ["13464"] = true,--"Enchant Shield - Lesser Protection",
        ["13378"] = true,--"Enchant Shield - Minor Stamina",
    },
    ["Offhand"] = {
        ["1219578"] = true,--"Enchant Off-Hand - Excellent Spirit",
        ["1219577"] = true,--"Enchant Off-Hand - Superior Intellect",
        ["1219579"] = true,--"Enchant Off-Hand - Wisdom",
    },
    ["Gloves"] = {
        ["1213626"] = true,--"Enchant Gloves - Arcane Power",
        ["1213622"] = true,--"Enchant Gloves - Holy Power",
        ["1219586"] = true,--"Enchant Gloves - Superior Strength",
        ["25078"] = true,--"Enchant Gloves - Fire Power",
        ["25074"] = true,--"Enchant Gloves - Frost Power",
        ["25079"] = true,--"Enchant Gloves - Healing Power",
        ["25073"] = true,--"Enchant Gloves - Shadow Power",
        ["25080"] = true,--"Enchant Gloves - Superior Agility",
        ["25072"] = true,--"Enchant Gloves - Threat",
        ["20013"] = true,--"Enchant Gloves - Greater Strength",
        ["20012"] = true,--"Enchant Gloves - Greater Agility",
        ["13948"] = true,--"Enchant Gloves - Minor Haste",
        ["13947"] = true,--"Enchant Gloves - Riding Skill",
        ["13868"] = true,--"Enchant Gloves - Advanced Herbalism",
        ["13887"] = true,--"Enchant Gloves - Strength",
        ["13841"] = true,--"Enchant Gloves - Advanced Mining",
        ["13815"] = true,--"Enchant Gloves - Agility",
        ["13698"] = true,--"Enchant Gloves - Skinning",
        ["13620"] = true,--"Enchant Gloves - Fishing",
        ["13617"] = true,--"Enchant Gloves - Herbalism",
        ["13612"] = true,--"Enchant Gloves - Mining",
    },
    ["Cloak"] = {
        ["1219587"] = true,--"Enchant Cloak - Agility",
        ["25086"] = true,--"Enchant Cloak - Dodge",
        ["25081"] = true,--"Enchant Cloak - Greater Fire Resistance",
        ["25082"] = true,--"Enchant Cloak - Greater Nature Resistance",
        ["25083"] = true,--"Enchant Cloak - Stealth",
        ["25084"] = true,--"Enchant Cloak - Subtlety",
        ["20015"] = true,--"Enchant Cloak - Superior Defense",
        ["20014"] = true,--"Enchant Cloak - Greater Resistance",
        ["13882"] = true,--"Enchant Cloak - Lesser Agility",
        ["13746"] = true,--"Enchant Cloak - Greater Defense",
        ["13794"] = true,--"Enchant Cloak - Resistance",
        ["13657"] = true,--"Enchant Cloak - Fire Resistance",
        ["13635"] = true,--"Enchant Cloak - Defense",
        ["13522"] = true,--"Enchant Cloak - Lesser Shadow Resistance",
        ["7861"] = true,--"Enchant Cloak - Lesser Fire Resistance",
        ["13421"] = true,--"Enchant Cloak - Lesser Protection",
        ["13419"] = true,--"Enchant Cloak - Minor Agility",
        ["7771"] = true,--"Enchant Cloak - Minor Protection",
        ["7454"] = true,--"Enchant Cloak - Minor Resistance",
    },
    ["Chest"] = {
        ["1213616"] = true,--"Enchant Chest - Living Stats",
        ["20025"] = true,--"Enchant Chest - Greater Stats",
        ["20028"] = true,--"Enchant Chest - Major Mana",
        ["20026"] = true,--"Enchant Chest - Major Health",
        ["13941"] = true,--"Enchant Chest - Stats",
        ["13917"] = true,--"Enchant Chest - Superior Mana",
        ["13858"] = true,--"Enchant Chest - Superior Health",
        ["13700"] = true,--"Enchant Chest - Lesser Stats",
        ["435903"] = true,--"Enchant Chest - Retricutioner",
        ["13663"] = true,--"Enchant Chest - Greater Mana",
        ["13640"] = true,--"Enchant Chest - Greater Health",
        ["13626"] = true,--"Enchant Chest - Minor Stats",
        ["13607"] = true,--"Enchant Chest - Mana",
        ["13538"] = true,--"Enchant Chest - Lesser Absorption",
        ["7857"] = true,--"Enchant Chest - Health",
        ["7776"] = true,--"Enchant Chest - Lesser Mana",
        ["7748"] = true,--"Enchant Chest - Lesser Health",
        ["7426"] = true,--"Enchant Chest - Minor Absorption",
        ["7443"] = true,--"Enchant Chest - Minor Mana",
        ["7420"] = true,--"Enchant Chest - Minor Health",
    },
    ["Bracer"] = {
        ["1217203"] = true,--"Enchant Bracer - Agility",
        ["1220624"] = true,--"Enchant Bracer - Greater Spellpower",
        ["1217189"] = true,--"Enchant Bracer - Spell Power",
        ["23802"] = true,--"Enchant Bracer - Healing Power",
        ["20011"] = true,--"Enchant Bracer - Superior Stamina",
        ["20010"] = true,--"Enchant Bracer - Superior Strength",
        ["23801"] = true,--"Enchant Bracer - Mana Regeneration",
        ["20009"] = true,--"Enchant Bracer - Superior Spirit",
        ["20008"] = true,--"Enchant Bracer - Greater Intellect",
        ["13945"] = true,--"Enchant Bracer - Greater Stamina",
        ["13939"] = true,--"Enchant Bracer - Greater Strength",
        ["13931"] = true,--"Enchant Bracer - Deflection",
        ["13846"] = true,--"Enchant Bracer - Greater Spirit",
        ["13822"] = true,--"Enchant Bracer - Intellect",
        ["13661"] = true,--"Enchant Bracer - Strength",
        ["13646"] = true,--"Enchant Bracer - Lesser Deflection",
        ["13648"] = true,--"Enchant Bracer - Stamina",
        ["13642"] = true,--"Enchant Bracer - Spirit",
        ["13622"] = true,--"Enchant Bracer - Lesser Intellect",
        ["13536"] = true,--"Enchant Bracer - Lesser Strength",
        ["13501"] = true,--"Enchant Bracer - Lesser Stamina",
        ["7859"] = true,--"Enchant Bracer - Lesser Spirit",
        ["7779"] = true,--"Enchant Bracer - Minor Agility",
        ["7782"] = true,--"Enchant Bracer - Minor Strength",
        ["7428"] = true,--"Enchant Bracer - Minor Deflect",
        ["7418"] = true,--"Enchant Bracer - Minor Health",
        ["7766"] = true,--"Enchant Bracer - Minor Spirit",
        ["7457"] = true,--"Enchant Bracer - Minor Stamina",
    }
}

-- A collection of ids for recipes of vaarious categories.
local fishSkillIdsList = {
    ["4592"] = true, -- Longjaw Mud Snapper,
    ["4593"] = true, -- Bristle Whisker Catfish
    ["6657"] = true, -- Savory Deviate Delight
    ["6290"] = true, -- Brilliant Smallfish
    ["8364"] = true, -- Mithril Head Trout
    ["6887"] = true, -- Spotted Yellowtail
    ["787"] = true, -- Slitherskin Mackerel
    ["16766"] = true, -- Undermine Clam Chowder
    ["4594"] = true, -- Rockscale Cod
    ["5095"] = true, -- Rainbow Fin Albacore
    ["21217"] = true, -- Sagefish Delight
    ["21072"] = true, -- Smoked Sagefish
    ["13931"] = true, -- Nightfin Soup
    ["13928"] = true, -- Grilled Squid
    ["13930"] = true, -- Filet of Redgill
    ["232436"] = true, -- Darkclaw Bisque
    ["2682"] = true, -- Cooked Crab Claw
    ["2683"] = true, -- Crab Cake
    ["5526"] = true, -- Clam Chowder
    ["232438"] = true, -- Smoked Redgill
    ["13932"] = true, -- Poached Sunscale Salmon
    ["13934"] = true, -- Mightfish Steak
    ["12216"] = true, -- Spiced Chili Crab
    ["13935"] = true, -- Baked Salmon
    ["3663"] = true, -- Murloc Fin Soup
    ["13927"] = true, -- Cooked Glossy Mightfish
    ["6038"] = true, -- Giant Clam Scorcho
    ["13933"] = true, -- Lobster Stew
    ["6316"] = true, -- Loch Frenzy Delight
    ["13929"] = true, -- Hot Smoked Bass
    ["5476"] = true, -- Fillet of Frenzy
    ["5525"] = true, -- Boiled Clams
    ["5527"] = true, -- Goblin Deviled Clams
}

local cookingItemList = {
    ["Shellfish"] = {
        ["16766"] = true, -- Undermine Clam Chowder
        ["232436"] = true, -- Darkclaw Bisque
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
        ["4592"] = true, -- Longjaw Mud Snapper,
        ["4593"] = true, -- Bristle Whisker Catfish
        ["6657"] = true, -- Savory Deviate Delight
        ["6290"] = true, -- Brilliant Smallfish
        ["8364"] = true, -- Mithril Head Trout
        ["6887"] = true, -- Spotted Yellowtail
        ["787"] = true, -- Slitherskin Mackerel
        ["4594"] = true, -- Rockscale Cod
        ["5095"] = true, -- Rainbow Fin Albacore
        ["21217"] = true, -- Sagefish Delight
        ["21072"] = true, -- Smoked Sagefish
        ["13931"] = true, -- Nightfin Soup
        ["13928"] = true, -- Grilled Squid
        ["13930"] = true, -- Filet of Redgill
        ["232438"] = true, -- Smoked Redgill
        ["13932"] = true, -- Poached Sunscale Salmon
        ["13934"] = true, -- Mightfish Steak
        ["13935"] = true, -- Baked Salmon
        ["3663"] = true, -- Murloc Fin Soup
        ["13927"] = true, -- Cooked Glossy Mightfish
        ["6316"] = true, -- Loch Frenzy Delight
        ["13929"] = true, -- Hot Smoked Bass
        ["5476"] = true, -- Fillet of Frenzy
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

    local hunterPetList = {
        [BITE] = {
            ["Families"] = {"24", "4", "5", "7", "2", "6", "9", "25", "11", "3", "12", "21", "27", "1"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [CHARGE] = {
            ["Families"] = {"5"},
            ["Category"] = "Utility",
        },
        [CLAW] = {
            ["Families"] = {"4", "7", "2", "8", "26", "11", "20"},
            ["Category"] = PET_AGGRESSIVE,
        },
        [COWER] = {
            ["Families"] = {"24", "4", "5", "7", "2", "8", "6", "9", "25", "26", "11", "20", "3", "12", "21", "27", "1"},
            ["Category"] = PET_DEFENSIVE,
        },
        [DASH] = {
            ["Families"] = {"5", "2", "25", "12", "1"},
            ["Category"] = "Utility",
        },
        [DIVE] = {
            ["Families"] = {"24", "7", "26", "27"},
            ["Category"] = "Utility",
        },
        [FURIOUS_HOWL] = {
            ["Families"] = {"1"},
            ["Category"] = "Utility",
        },
        [GROWL] = {
            -- ["Families"] = {"24", "4", "5", "7", "2", "8", "6", "9", "25", "26", "11", "20", "3", "12", "21", "27", "1"},
            ["Category"] = "Utility",
        },
        [LIGHTNING_BREATH] = {
            ["Families"] = {"27"},
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
        }
    }

    main.petSkillsCategoryMap = hunterPetList
end
