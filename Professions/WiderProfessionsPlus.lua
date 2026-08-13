local ADDON_NAME = ...
local main = _G.WiderProfessionsAddon

local WPP = CreateFrame("Frame", "WiderProfessionsPlusController")
local DEFAULT_CRAFT_SECONDS = 3
local MAX_ROWS = 10

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Logistician|r: " .. tostring(msg))
end

local function ItemIDFromLink(link)
    if not link then return nil end
    local id = string.match(link, "item:(%d+)")
    return id and tonumber(id) or nil
end

local function InitDB()
    WiderProfessionsPlusDB = WiderProfessionsPlusDB or {}
    local db = WiderProfessionsPlusDB

    -- 0.1.11: a single cross-profession queue.
    db.queue = db.queue or {}
    db.queues = db.queues or {} -- legacy 0.1.10 storage, retained for migration only
    db.craftTimes = db.craftTimes or {}
    db.settings = db.settings or {}
    db.recipeProfession = db.recipeProfession or {}
    db.recipeCache = db.recipeCache or {}
    db.seenProfessions = db.seenProfessions or {}
    db.productionGoals = db.productionGoals or {}
    -- Persisted independently from the transient cast state so a stopped
    -- production run can resume after closing the panel, /reload, or logout.
    if db.productionSession and type(db.productionSession) ~= "table" then
        db.productionSession = nil
    end

    if not db.sharedQueueMigrated then
        -- Old builds kept one independent queue per profession. There was no
        -- meaningful cross-profession ordering to preserve, so migrate each
        -- profession as a block in stable alphabetical order. The user can
        -- then drag rows into the exact desired order.
        local professions = {}
        for profession, queue in pairs(db.queues) do
            if type(queue) == "table" and #queue > 0 then
                table.insert(professions, profession)
            end
        end
        table.sort(professions)

        for _, profession in ipairs(professions) do
            for _, entry in ipairs(db.queues[profession]) do
                entry.profession = entry.profession or profession
                table.insert(db.queue, entry)
            end
        end

        db.sharedQueueMigrated = true
    end

    if db.settings.expandCraftables == nil then db.settings.expandCraftables = true end
    return db
end

local function NormalizeProfessionName(name)
    if not name then return nil end
    local smelting = GetSpellInfo(2656)
    local mining = GetSpellInfo(2575)
    if smelting and name == smelting then
        return mining or name
    end
    return name
end

local function CurrentProfession()
    main = main or _G.WiderProfessionsAddon
    if not main or main.windowType ~= "TradeSkill" then return nil end
    local name = GetTradeSkillLine()
    if name and name ~= UNKNOWN then return NormalizeProfessionName(name) end
    return nil
end

local function GetQueue(create)
    -- `create` remains in the signature for compatibility with older callers;
    -- the shared queue always exists after InitDB().
    local db = InitDB()
    return db.queue
end

local function MoneyText(value)
    if not value or value <= 0 then return "--" end
    return GetCoinTextureString(math.floor(value + 0.5))
end

local function LogisticianPrice(itemID)
    if type(itemID) ~= "number" then return nil end

    local bridge = _G.WiderProfessionsLogisticianBridge
    if bridge and type(bridge.GetAuctionPriceByItemID) == "function" then
        return bridge:GetAuctionPriceByItemID(itemID)
    end

    return nil
end

local function MarketPrice(link, itemID)
    itemID = itemID or ItemIDFromLink(link)
    return LogisticianPrice(itemID)
end

-- TBC profession supplies that are purchased from NPC vendors. Logistician's
-- vendor-price API reports the sell-to-vendor value for arbitrary items, so it
-- cannot by itself tell us whether an NPC sells an item. Keep this whitelist
-- deliberately conservative to avoid removing legitimate AH materials.
local VENDOR_SOLD_REAGENTS = {
    [2320] = true,  -- Coarse Thread
    [2321] = true,  -- Fine Thread
    [2324] = true,  -- Bleach
    [2604] = true,  -- Red Dye
    [2605] = true,  -- Green Dye
    [2678] = true,  -- Mild Spices
    [2692] = true,  -- Hot Spices
    [2880] = true,  -- Weak Flux
    [3371] = true,  -- Empty Vial
    [3372] = true,  -- Leaded Vial
    [3466] = true,  -- Strong Flux
    [3713] = true,  -- Soothing Spices
    [3857] = true,  -- Coal
    [4289] = true,  -- Salt
    [4291] = true,  -- Silken Thread
    [4340] = true,  -- Gray Dye
    [4341] = true,  -- Yellow Dye
    [4342] = true,  -- Purple Dye
    [4399] = true,  -- Wooden Stock
    [4400] = true,  -- Heavy Stock
    [6260] = true,  -- Blue Dye
    [6261] = true,  -- Orange Dye
    [8150] = true,  -- Deeprock Salt
    [8343] = true,  -- Heavy Silken Thread
    [8925] = true,  -- Crystal Vial
    [10290] = true, -- Pink Dye
    [10647] = true, -- Engineer's Ink
    [14341] = true, -- Rune Thread
    [18256] = true, -- Imbued Vial
    [30817] = true, -- Simple Flour
}

local function IsVendorSoldReagent(link, itemID)
    itemID = itemID or ItemIDFromLink(link)
    return itemID and VENDOR_SOLD_REAGENTS[itemID] or false
end

local function GetRecipeSnapshot(index)
    if not index then return nil end
    local name, skillType, numAvailable = GetTradeSkillInfo(index)
    if not name or skillType == "header" then return nil end

    local link = GetTradeSkillItemLink(index)
    local itemID = ItemIDFromLink(link)
    local minMade, maxMade = GetTradeSkillNumMade(index)
    minMade = minMade or 1
    maxMade = maxMade or minMade

    local reagents = {}
    for reagentIndex = 1, GetTradeSkillNumReagents(index) do
        local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(index, reagentIndex)
        local reagentLink = GetTradeSkillReagentItemLink(index, reagentIndex)
        table.insert(reagents, {
            name = reagentName or UNKNOWN,
            link = reagentLink,
            itemID = ItemIDFromLink(reagentLink),
            icon = reagentTexture,
            count = reagentCount or 0,
            playerCount = playerReagentCount or 0,
        })
    end

    return {
        name = name,
        link = link,
        itemID = itemID,
        skillId = itemID and tostring(itemID) or name,
        index = index,
        numAvailable = numAvailable or 0,
        minProduced = minMade,
        maxProduced = maxMade,
        reagents = reagents,
    }
end

local function CopyReagentsForStorage(reagents)
    local result = {}
    for _, reagent in ipairs(reagents or {}) do
        table.insert(result, {
            name = reagent.name,
            link = reagent.link,
            itemID = reagent.itemID or ItemIDFromLink(reagent.link),
            icon = reagent.icon or reagent.texture,
            count = tonumber(reagent.count) or 0,
        })
    end
    return result
end

local function RecipeForStorage(recipe, profession)
    if not recipe then return nil end
    local itemID = recipe.itemID or ItemIDFromLink(recipe.link)
    local icon = recipe.icon or recipe.texture
    if not icon and itemID and GetItemIcon then
        icon = GetItemIcon(itemID)
    end

    return {
        profession = NormalizeProfessionName and NormalizeProfessionName(profession) or profession,
        name = recipe.name,
        link = recipe.link,
        itemID = itemID,
        skillId = tostring(recipe.skillId or itemID or recipe.name),
        icon = icon,
        minProduced = recipe.minProduced or 1,
        maxProduced = recipe.maxProduced or recipe.minProduced or 1,
        reagents = CopyReagentsForStorage(recipe.reagents),
    }
end

local function FindTradeSkillIndex(entry)
    if not entry then return nil end
    for index = 1, GetNumTradeSkills() do
        local name, skillType = GetTradeSkillInfo(index)
        if skillType ~= "header" then
            if entry.itemID then
                local link = GetTradeSkillItemLink(index)
                if ItemIDFromLink(link) == entry.itemID then
                    return index
                end
            elseif name == entry.name then
                return index
            end
        end
    end
    return nil
end

local function BuildRecipeMap()
    local result = {}
    for index = 1, GetNumTradeSkills() do
        local snapshot = GetRecipeSnapshot(index)
        if snapshot and snapshot.itemID then
            result[snapshot.itemID] = snapshot
        end
    end
    return result
end

local function QueueTotalCrafts(queue)
    local total = 0
    for _, entry in ipairs(queue or {}) do total = total + (entry.quantity or 0) end
    return total
end

local function ComputeProfit(skill)
    if not skill or not skill.link then return nil end
    local outputID = ItemIDFromLink(skill.link)
    if not outputID then return nil end

    local outputUnitPrice = MarketPrice(skill.link, outputID)
    if not outputUnitPrice then return nil end

    local minMade = skill.minProduced or 1
    local maxMade = skill.maxProduced or minMade
    local averageMade = (minMade + maxMade) / 2
    local outputValue = outputUnitPrice * averageMade

    local materialCost = 0
    local missingPrice = false
    for _, reagent in ipairs(skill.reagents or {}) do
        local reagentID = reagent.itemID or ItemIDFromLink(reagent.link)
        local price = MarketPrice(reagent.link, reagentID)
        if price then
            materialCost = materialCost + price * (reagent.count or 0)
        else
            missingPrice = true
        end
    end

    return {
        output = outputValue,
        materials = materialCost,
        profit = missingPrice and nil or (outputValue - materialCost),
        partial = missingPrice,
    }
end

-- Profession-opening spell IDs used by the Classic/TBC client.
-- Mining is special: the skill line is Mining, while the recipe-window spell
-- is Smelting.
local PROFESSION_OPENERS = {
    { lineSpellID = 2259,  openerSpellID = 2259  }, -- Alchemy
    { lineSpellID = 2018,  openerSpellID = 2018  }, -- Blacksmithing
    { lineSpellID = 2550,  openerSpellID = 2550  }, -- Cooking
    { lineSpellID = 7411,  openerSpellID = 7411  }, -- Enchanting
    { lineSpellID = 4036,  openerSpellID = 4036  }, -- Engineering
    { lineSpellID = 3273,  openerSpellID = 3273  }, -- First Aid
    { lineSpellID = 25229, openerSpellID = 25229 }, -- Jewelcrafting
    { lineSpellID = 2108,  openerSpellID = 2108  }, -- Leatherworking
    { lineSpellID = 2575,  openerSpellID = 2656  }, -- Mining -> Smelting
    { lineSpellID = 3908,  openerSpellID = 3908  }, -- Tailoring
}

-- Common Mining/Smelting outputs. This makes Engineering -> Mining reagent
-- navigation useful immediately, even before WPP has had a chance to cache
-- the Mining recipe list on this character.
local MINING_OUTPUT_ITEMS = {
    [2840]  = true, -- Copper Bar
    [2841]  = true, -- Bronze Bar
    [2842]  = true, -- Silver Bar
    [3575]  = true, -- Iron Bar
    [3576]  = true, -- Tin Bar
    [3577]  = true, -- Gold Bar
    [3859]  = true, -- Steel Bar
    [3860]  = true, -- Mithril Bar
    [6037]  = true, -- Truesilver Bar
    [11371] = true, -- Dark Iron Bar
    [12359] = true, -- Thorium Bar
    [17771] = true, -- Elementium Bar
    [23445] = true, -- Fel Iron Bar
    [23446] = true, -- Adamantite Bar
    [23447] = true, -- Eternium Bar
    [23448] = true, -- Felsteel Bar
    [23449] = true, -- Khorium Bar
    [23573] = true, -- Hardened Adamantite Bar
}

local function ProfessionOpener(professionName)
    if not professionName then return nil end

    for _, entry in ipairs(PROFESSION_OPENERS) do
        local lineName = GetSpellInfo(entry.lineSpellID)
        local openerName = GetSpellInfo(entry.openerSpellID)

        -- Some client/localization combinations may expose the opener name as
        -- the trade-skill line name, so accept either.
        if professionName == lineName or professionName == openerName then
            return openerName, entry.openerSpellID
        end
    end

    -- Safe fallback for ordinary professions whose skill-line spell and
    -- opener have the same localized name.
    return professionName, nil
end

local function CacheCurrentProfessionRecipes()
    if not main or main.windowType ~= "TradeSkill" then return end

    local profession = CurrentProfession()
    if not profession then return end

    local db = InitDB()
    db.seenProfessions[profession] = true

    for index = 1, GetNumTradeSkills() do
        local skillName, skillType = GetTradeSkillInfo(index)
        if skillName and skillType ~= "header" then
            local snapshot = GetRecipeSnapshot(index)
            if snapshot and snapshot.itemID then
                local key = tostring(snapshot.itemID)
                db.recipeProfession[key] = profession
                db.recipeCache[key] = RecipeForStorage(snapshot, profession)
            end
        end
    end
end

local function ResolveOtherProfession(itemID)
    if not itemID then return nil end
    local db = InitDB()

    local cached = db.recipeProfession[tostring(itemID)]
    if cached then
        return cached
    end

    -- Mining is the important special case for Engineering characters:
    -- bars are produced through the Smelting trade-skill window.
    if MINING_OUTPUT_ITEMS[itemID] then
        local miningName = GetSpellInfo(2575)
        local smeltingName = GetSpellInfo(2656)
        if (IsSpellKnown and IsSpellKnown(2656))
            or (db.seenProfessions[miningName])
            or (db.seenProfessions[smeltingName]) then
            return miningName or smeltingName or "Mining"
        end
    end

    return nil
end

local function FindSpellBookSlotByName(spellName)
    if not spellName then return nil end

    -- TBC Anniversary uses the legacy player spellbook API. Search every
    -- visible player spell tab because profession opener spell IDs change as
    -- the profession rank increases (Apprentice/Journeyman/Expert/etc.).
    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
    for tab = 1, numTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        if offset and numSpells then
            for slot = offset + 1, offset + numSpells do
                local name = GetSpellBookItemName(slot, BOOKTYPE_SPELL)
                if name == spellName then
                    return slot
                end
            end
        end
    end

    return nil
end

local function CastProfessionOpener(openerName)
    if not openerName then return false end

    -- Prefer the actual spellbook slot. This avoids the incorrect assumption
    -- that the character still "knows" the original rank-1 profession spell ID.
    local spellBookSlot = FindSpellBookSlotByName(openerName)
    if spellBookSlot and CastSpell then
        local ok = pcall(CastSpell, spellBookSlot, BOOKTYPE_SPELL)
        if ok then return true end
    end

    -- Normal profession names are also castable by name from the user's
    -- hardware click. Keep this as the compatibility fallback.
    if CastSpellByName then
        local ok = pcall(CastSpellByName, openerName)
        if ok then return true end
    end

    return false
end

local function OpenProfessionByName(targetProfession, itemID)
    targetProfession = NormalizeProfessionName(targetProfession)
    if not targetProfession then return false end

    local currentProfession = CurrentProfession()
    if currentProfession == targetProfession then
        return false
    end

    local openerName = ProfessionOpener(targetProfession)
    if not openerName then return false end

    -- Opening a profession is a protected spell action, so this helper is only
    -- called from an actual mouse click (reagent, queue row, Craft Next/All).
    WPP.pendingItemID = itemID
    WPP.pendingProfession = targetProfession
    WPP.pendingAttempts = 0

    CacheCurrentProfessionRecipes()

    if not CastProfessionOpener(openerName) then
        WPP.pendingItemID = nil
        WPP.pendingProfession = nil
        WPP.pendingAttempts = nil
        return false
    end

    return true
end

local function OpenProfessionForItem(itemID)
    local targetProfession = ResolveOtherProfession(itemID)
    if not targetProfession then return false end
    return OpenProfessionByName(targetProfession, itemID)
end

local function FindWiderSkillByItemID(itemID)
    if not itemID or not main or not main.skillInfoDict then return nil end
    for _, list in pairs(main.skillInfoDict) do
        for _, skill in ipairs(list) do
            if tonumber(skill.skillId) == itemID then return skill end
        end
    end
    return nil
end

local function JumpToCraftable(itemID)
    if not itemID or main.windowType ~= "TradeSkill" then return false end
    local skill = FindWiderSkillByItemID(itemID)
    if not skill and CraftTradeSkillFrame and CraftTradeSkillFrame.searchBar then
        CraftTradeSkillFrame.searchBar:ClearFocus()
        CraftTradeSkillFrame.searchBar:SetText("")
        if main.FetchSkillData then main:FetchSkillData() end
        if main.RefreshList then main:RefreshList() end
        skill = FindWiderSkillByItemID(itemID)
    end
    if not skill then return false end

    if main.selectedSkill and main.selectedSkill ~= skill then
        WPP.backSkillID = tonumber(main.selectedSkill.skillId)
    end
    main:SetSkillDetails(skill)
    if main.RefreshList then main:RefreshList() end
    return true
end

local function FinishPendingProfessionJump()
    if not WPP.pendingItemID then return end
    if not main or main.windowType ~= "TradeSkill" then return end

    local pendingItemID = WPP.pendingItemID
    local currentProfession = CurrentProfession()

    -- Give Wider Professions a frame to rebuild its recipe dictionary after
    -- the Blizzard TRADE_SKILL_SHOW event.
    if CraftTradeSkillFrame and CraftTradeSkillFrame.searchBar then
        CraftTradeSkillFrame.searchBar:ClearFocus()
        CraftTradeSkillFrame.searchBar:SetText("")
    end
    if main.FetchSkillData then main:FetchSkillData() end
    if main.RefreshList then main:RefreshList() end

    CacheCurrentProfessionRecipes()

    if JumpToCraftable(pendingItemID) then
        WPP.pendingItemID = nil
        WPP.pendingProfession = nil
        WPP.pendingAttempts = nil
        return
    end

    WPP.pendingAttempts = (WPP.pendingAttempts or 0) + 1
    if WPP.pendingAttempts < 4 then
        C_Timer.After(0.10, FinishPendingProfessionJump)
    else
        local itemName = GetItemInfo(pendingItemID) or ("item:" .. tostring(pendingItemID))
        Print("Opened " .. tostring(currentProfession or "profession")
            .. ", but couldn't find " .. tostring(itemName)
            .. " in the known recipe list.")
        WPP.pendingItemID = nil
        WPP.pendingProfession = nil
        WPP.pendingAttempts = nil
    end
end

local function EnhanceReagentClicks(skill)
    if not skill or main.windowType ~= "TradeSkill" then return end
    for i, reagentData in ipairs(skill.reagents or {}) do
        local frame = _G["CraftTradeReagent" .. i]
        if frame then
            local original = frame:GetScript("OnMouseDown")
            local itemID = ItemIDFromLink(reagentData.link)
            frame:SetScript("OnMouseDown", function(self, button)
                if IsModifiedClick("CHATLINK") then
                    if original then original(self, button) end
                    return
                end
                if button == "LeftButton" and itemID then
                    if JumpToCraftable(itemID) or OpenProfessionForItem(itemID) then
                        PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
                        return
                    end
                end
                if original then original(self, button) end
            end)
        end
    end
end

local panel
local openButton
local queueAddButton
local UpdateQueueAddButton -- forward declaration; RefreshPanel calls this
local processing = nil
local craftAllState = nil
local ClearProductionSession

local function QueueBusy()
    return processing ~= nil or craftAllState ~= nil
end

local function SavedProductionSession()
    return InitDB().productionSession
end

ClearProductionSession = function()
    InitDB().productionSession = nil
end

local function ProductionGoalKey(entry)
    if not entry then return nil end
    return tostring(entry.itemID or entry.skillId or entry.name or "unknown")
        .. "|" .. tostring(entry.profession or "")
end

local function ClearProductionGoals()
    wipe(InitDB().productionGoals)
end

local function AddProductionGoal(entry, quantity)
    local key = ProductionGoalKey(entry)
    quantity = math.max(0, tonumber(quantity) or 0)
    if not key or quantity <= 0 then return end

    local goals = InitDB().productionGoals
    local goal = goals[key]
    if not goal then
        goal = {
            key = key,
            itemID = entry.itemID,
            skillId = entry.skillId,
            profession = entry.profession,
            name = entry.name or UNKNOWN,
            link = entry.link,
            icon = entry.icon,
            total = 0,
            completed = 0,
            order = GetTime(),
        }
        goals[key] = goal
    end
    goal.total = math.max(0, tonumber(goal.total) or 0) + quantity
end

local function RemoveFromProductionGoal(entry, quantity)
    local key = ProductionGoalKey(entry)
    local goals = InitDB().productionGoals
    local goal = key and goals[key]
    if not goal then return end
    goal.total = math.max(
        tonumber(goal.completed) or 0,
        (tonumber(goal.total) or 0) - math.max(0, tonumber(quantity) or 0)
    )
    if goal.total <= 0 then goals[key] = nil end
end

local function CompleteProductionGoal(entry)
    local key = ProductionGoalKey(entry)
    local goal = key and InitDB().productionGoals[key]
    if not goal then return end
    goal.completed = math.min(
        math.max(0, tonumber(goal.total) or 0),
        math.max(0, tonumber(goal.completed) or 0) + 1
    )
end

local function CurrentProductionGoal()
    local selected
    for _, goal in pairs(InitDB().productionGoals) do
        if type(goal) == "table" and (tonumber(goal.total) or 0) > 0 then
            if not selected
                or ((tonumber(goal.completed) or 0) < (tonumber(goal.total) or 0)
                    and (tonumber(selected.completed) or 0) >= (tonumber(selected.total) or 0))
                or ((tonumber(goal.order) or 0) < (tonumber(selected.order) or 0)) then
                selected = goal
            end
        end
    end
    return selected
end

local marketSummary

local function HideLogisticianCraftingBlock()
    -- Logistician's native Classic crafting-info block is two lines tall and
    -- Wider Professions historically anchors it at a fixed footer position.
    -- With 5+ reagents that can overlap the last reagent row, so WPP replaces
    -- it with a compact single-line summary below.
    if LogisticianCraftingInfo then
        LogisticianCraftingInfo:Hide()
    end
end

local function UpdateRecipeMarketSummary(skill)
    HideLogisticianCraftingBlock()

    if not marketSummary then return end

    local logisticianBridge = _G.WiderProfessionsLogisticianBridge
    if not skill
        or main.windowType ~= "TradeSkill"
        or CraftIsEnchanting()
        or not logisticianBridge
        or not logisticianBridge:IsAvailable()
        or not logisticianBridge:Has("GetAuctionPriceByItemID") then
        marketSummary:Hide()
        return
    end

    local data = ComputeProfit(skill)
    if not data then
        marketSummary:Hide()
        return
    end

    local costText = data.materials and MoneyText(data.materials) or "--"
    local profitText
    local profitColor = "|cffaaaaaa"

    if data.profit ~= nil then
        if data.profit >= 0 then
            profitColor = "|cff20d020"
            profitText = "+" .. MoneyText(data.profit)
        else
            profitColor = "|cffff3030"
            profitText = "-" .. MoneyText(-data.profit)
        end
    else
        profitText = "--"
    end

    marketSummary:SetText(
        "|cffffd100Cost|r " .. costText
        .. "  |cff888888•|r  "
        .. "|cffffd100Profit|r " .. profitColor .. profitText .. "|r"
    )
    marketSummary:Show()
end

local function AddProfitToInfoTooltip()
    if not InfoTooltip or not main.selectedSkill or main.windowType ~= "TradeSkill" then return end
    local data = ComputeProfit(main.selectedSkill)
    if not data then
        InfoTooltip:AddLine("Market price data unavailable", 0.65, 0.65, 0.65)
        InfoTooltip:Show()
        return
    end
    InfoTooltip:AddLine(" ")
    InfoTooltip:AddLine("Logistician Market", 1, 0.82, 0)
    InfoTooltip:AddDoubleLine("Crafted value:", MoneyText(data.output), 1, 1, 1, 1, 1, 1)
    InfoTooltip:AddDoubleLine(data.partial and "Known mat cost:" or "Material cost:", MoneyText(data.materials), 1, 1, 1, 1, 1, 1)
    if data.profit then
        if data.profit >= 0 then
            InfoTooltip:AddDoubleLine("Profit:", "+" .. MoneyText(data.profit), 1, 1, 1, 0.2, 1, 0.2)
        else
            InfoTooltip:AddDoubleLine("Profit:", "-" .. MoneyText(-data.profit), 1, 1, 1, 1, 0.25, 0.25)
        end
    else
        InfoTooltip:AddDoubleLine("Profit:", "Unknown reagent price", 1, 1, 1, 0.7, 0.7, 0.7)
    end
    InfoTooltip:Show()
end

local function PlanningOwnedCount(itemID)
    if not itemID then return 0 end

    -- Production planning must only count materials immediately accessible to
    -- the trade-skill API. Counting bank stock here suppresses prerequisite
    -- recipes even though DoTradeSkill cannot consume those banked items.
    -- The separate Materials view may still use broader ownership semantics.
    local ok, amount = pcall(GetItemCount, itemID, false)
    if not ok then
        amount = GetItemCount(itemID, false) or 0
    end
    return tonumber(amount) or 0
end

local function BuildKnownRecipeMap()
    local db = InitDB()
    local recipeMap = {}

    -- Cached recipes from every profession already opened on this character.
    for key, recipe in pairs(db.recipeCache or {}) do
        local itemID = tonumber(key) or recipe.itemID
        if itemID then
            recipeMap[itemID] = recipe
        end
    end

    -- Refresh/cache every recipe in the currently open profession.
    local currentProfession = CurrentProfession()
    for itemID, recipe in pairs(BuildRecipeMap()) do
        recipe.profession = currentProfession
        recipeMap[itemID] = recipe
        db.recipeProfession[tostring(itemID)] = currentProfession
        db.recipeCache[tostring(itemID)] =
            RecipeForStorage(recipe, currentProfession)
    end

    -- Queue rows carry complete recipe snapshots and may be newer than cache.
    for _, entry in ipairs(GetQueue(false) or {}) do
        if entry.itemID and entry.reagents and #entry.reagents > 0 then
            recipeMap[entry.itemID] = entry
        end
    end

    return recipeMap
end

local function BuildQueueProjectedStock(queue, recipeMap)
    local touched = {}
    local balance = {}

    local function GetBalance(itemID)
        if not itemID then return 0 end
        if balance[itemID] == nil then
            balance[itemID] = PlanningOwnedCount(itemID)
        end
        touched[itemID] = true
        return balance[itemID]
    end

    local function Change(itemID, delta)
        if not itemID then return end
        balance[itemID] = GetBalance(itemID) + delta
    end

    -- Simulate the queue exactly in its current order. A negative balance means
    -- an earlier row still needs outside acquisition; it is NOT treated as
    -- usable stock for the new recipe being appended.
    for _, entry in ipairs(queue or {}) do
        local recipe = nil
        if entry.reagents and #entry.reagents > 0 then
            recipe = entry
        elseif entry.itemID then
            recipe = recipeMap[entry.itemID]
        end

        if recipe then
            local crafts = math.max(0, tonumber(entry.quantity) or 0)

            for _, reagent in ipairs(recipe.reagents or {}) do
                if reagent.itemID then
                    Change(
                        reagent.itemID,
                        -((tonumber(reagent.count) or 0) * crafts)
                    )
                end
            end

            if entry.itemID then
                local yield = math.max(
                    1,
                    tonumber(recipe.minProduced)
                        or tonumber(entry.minProduced)
                        or 1
                )
                Change(entry.itemID, crafts * yield)
            end
        end
    end

    -- For NEW prerequisite planning, only positive leftover stock from the
    -- already-existing queue can be reused. Old shortages belong to older rows
    -- and cannot be repaired by inserting something after them.
    local stock = {}
    for itemID in pairs(touched) do
        stock[itemID] = math.max(0, balance[itemID] or 0)
    end

    return stock
end

local function MakeQueueEntryFromRecipe(recipe, crafts)
    if not recipe then return nil end

    local itemID = recipe.itemID or ItemIDFromLink(recipe.link)
    local profession = NormalizeProfessionName(recipe.profession)
        or (itemID and NormalizeProfessionName(
            InitDB().recipeProfession[tostring(itemID)]
        ))
        or CurrentProfession()

    local icon = recipe.icon or recipe.texture
    if not icon and itemID and GetItemIcon then
        icon = GetItemIcon(itemID)
    end

    return {
        profession = profession,
        skillId = tostring(recipe.skillId or itemID or recipe.name),
        itemID = itemID,
        name = recipe.name or (itemID and GetItemInfo(itemID)) or UNKNOWN,
        link = recipe.link,
        icon = icon,
        quantity = math.max(1, math.floor(tonumber(crafts) or 1)),
        minProduced = tonumber(recipe.minProduced) or 1,
        maxProduced = tonumber(recipe.maxProduced)
            or tonumber(recipe.minProduced)
            or 1,
        reagents = CopyReagentsForStorage(recipe.reagents),
        autoDependency = true,
    }
end

local function SameQueueRecipe(a, b)
    if not a or not b then return false end

    if a.itemID and b.itemID then
        return a.itemID == b.itemID
            and NormalizeProfessionName(a.profession)
                == NormalizeProfessionName(b.profession)
    end

    return tostring(a.skillId or a.name)
            == tostring(b.skillId or b.name)
        and NormalizeProfessionName(a.profession)
            == NormalizeProfessionName(b.profession)
end

local function AppendQueueEntry(queue, entry)
    if not queue or not entry then return false end

    -- Only adjacent operations may be combined. Matching recipes separated by
    -- another operation represent a real production boundary. For example,
    -- with materials for one final item the valid sequence is:
    --   Final x1 -> craft missing component -> Final x1
    -- Merging both Final rows across that component would make the queue
    -- impossible to execute in its displayed order.
    local existing = queue[#queue]
    if existing and SameQueueRecipe(existing, entry) then
        existing.quantity = (tonumber(existing.quantity) or 0)
        + (tonumber(entry.quantity) or 0)

        -- If either addition was manual, keep the merged row considered manual.
        existing.autoDependency = existing.autoDependency and entry.autoDependency

        -- Prefer whichever row carries the more complete cached snapshot.
        if (not existing.reagents or #existing.reagents == 0)
            and entry.reagents and #entry.reagents > 0 then
            existing.reagents = entry.reagents
        end
        existing.link = existing.link or entry.link
        existing.icon = existing.icon or entry.icon
        return false
    end

    table.insert(queue, entry)
    return true
end

local function CoalesceQueue(queue)
    if not queue or #queue < 2 then return 0 end

    local compact = {}
    local merged = 0

    for _, entry in ipairs(queue) do
        local wasNew = AppendQueueEntry(compact, entry)
        if not wasNew then merged = merged + 1 end
    end

    if merged > 0 then
        wipe(queue)
        for _, entry in ipairs(compact) do
            table.insert(queue, entry)
        end
    end

    return merged
end

local function AutoInsertPrerequisites(queue, finalRecipe, finalCrafts)
    if not finalRecipe then return 0, 0 end

    local recipeMap = BuildKnownRecipeMap()
    local stock = BuildQueueProjectedStock(queue, recipeMap)
    local visiting = {}
    local addedRows = 0
    local addedCrafts = 0

    local function Available(itemID)
        if not itemID then return 0 end
        if stock[itemID] == nil then
            stock[itemID] = PlanningOwnedCount(itemID)
        end
        return math.max(0, stock[itemID] or 0)
    end

    local function Consume(itemID, amount)
        if not itemID or amount <= 0 then return amount end

        local have = Available(itemID)
        local used = math.min(have, amount)
        stock[itemID] = have - used
        return amount - used
    end

    local function AddStock(itemID, amount)
        if not itemID or amount <= 0 then return end
        stock[itemID] = Available(itemID) + amount
    end

    local function Require(reagent, amount)
        amount = math.max(0, tonumber(amount) or 0)
        if amount <= 0 then return end

        local itemID = reagent.itemID
            or ItemIDFromLink(reagent.link)

        -- Use owned inventory and unused output from earlier queued recipes
        -- before scheduling any new prerequisite craft.
        local missing = itemID and Consume(itemID, amount) or amount
        if missing <= 0 then return end

        local craft = itemID and recipeMap[itemID]
        if not craft
            or not craft.reagents
            or #craft.reagents == 0
            or visiting[itemID] then
            -- Raw/unlearned material: Shopping will handle the acquisition.
            return
        end

        visiting[itemID] = true

        local yield = math.max(
            1,
            tonumber(craft.minProduced)
                or tonumber(craft.maxProduced)
                or 1
        )
        local craftsNeeded = math.ceil(missing / yield)

        -- Recursively schedule THIS recipe's prerequisites first.
        for _, sub in ipairs(craft.reagents or {}) do
            Require(
                sub,
                (tonumber(sub.count) or 0) * craftsNeeded
            )
        end

        visiting[itemID] = nil

        local dependencyEntry =
            MakeQueueEntryFromRecipe(craft, craftsNeeded)

        if dependencyEntry then
            local newRow = AppendQueueEntry(queue, dependencyEntry)
            if newRow then addedRows = addedRows + 1 end
            addedCrafts = addedCrafts + craftsNeeded

            -- The scheduled craft now exists before its consumer in the queue,
            -- so expose its output to sibling/later dependency calculations.
            local produced = craftsNeeded * yield
            AddStock(itemID, produced)

            -- Consume only what this caller actually needed; multi-output
            -- surplus remains available for later prerequisites/final recipes.
            Consume(itemID, missing)
        end
    end

    for _, reagent in ipairs(finalRecipe.reagents or {}) do
        Require(
            reagent,
            (tonumber(reagent.count) or 0) * finalCrafts
        )
    end

    return addedRows, addedCrafts
end

-- Rebuild the remaining production plan against accessible bag inventory.
-- Explicit/manual orders are authoritative; generated prerequisite rows are
-- disposable projections and are recreated at the precise point each unit
-- needs them.
local function ReconcileQueueWithInventory()
    if QueueBusy() then return false end

    local queue = GetQueue(false)
    if not queue or #queue == 0 then return false end

    local manual = {}
    for _, entry in ipairs(queue) do
        if not entry.autoDependency then
            table.insert(manual, entry)
        end
    end

    local rebuilt = {}
    for _, entry in ipairs(manual) do
        local quantity = math.max(0, tonumber(entry.quantity) or 0)
        if quantity > 0 then
            -- Strict manufacturing order: every missing intermediate operation
            -- for this order is consolidated before its final-product batch.
            -- Existing bag stock reduces prerequisite quantities, but never
            -- causes some final products to be placed ahead of prerequisites.
            AutoInsertPrerequisites(rebuilt, entry, quantity)

            local finalBatch = {}
            for key, value in pairs(entry) do finalBatch[key] = value end
            finalBatch.quantity = quantity
            finalBatch.autoDependency = false
            AppendQueueEntry(rebuilt, finalBatch)
        end
    end

    local changed = #queue ~= #rebuilt
    if not changed then
        for index, entry in ipairs(queue) do
            local replacement = rebuilt[index]
            if not replacement
                or not SameQueueRecipe(entry, replacement)
                or tonumber(entry.quantity) ~= tonumber(replacement.quantity)
                or (not not entry.autoDependency) ~= (not not replacement.autoDependency) then
                changed = true
                break
            end
        end
    end

    wipe(queue)
    for _, entry in ipairs(rebuilt) do
        table.insert(queue, entry)
    end
    return changed
end

local function AdjustProductionGoal(delta)
    if QueueBusy() then return end
    delta = delta < 0 and -1 or 1

    local goal = CurrentProductionGoal()
    if not goal then return end

    local completed = math.max(0, tonumber(goal.completed) or 0)
    local oldTotal = math.max(completed, tonumber(goal.total) or 0)
    local newTotal = math.max(completed, oldTotal + delta)
    if newTotal == oldTotal then return end

    local queue = GetQueue(true)
    local key = goal.key or ProductionGoalKey(goal)
    local finalEntry
    for index = #queue, 1, -1 do
        local entry = queue[index]
        if not entry.autoDependency and ProductionGoalKey(entry) == key then
            finalEntry = entry
            table.remove(queue, index)
        end
    end

    local remaining = newTotal - completed
    if remaining > 0 then
        if not finalEntry then
            local cached = goal.itemID
                and InitDB().recipeCache[tostring(goal.itemID)]
                or nil
            finalEntry = {
                profession = goal.profession,
                skillId = goal.skillId,
                itemID = goal.itemID,
                name = goal.name,
                link = goal.link,
                icon = goal.icon,
                minProduced = cached and cached.minProduced or 1,
                maxProduced = cached and cached.maxProduced or 1,
                reagents = cached and cached.reagents or {},
                autoDependency = false,
            }
        end
        finalEntry.quantity = remaining
        finalEntry.autoDependency = false
        table.insert(queue, finalEntry)
    end

    goal.total = newTotal
    ReconcileQueueWithInventory()

    local session = SavedProductionSession()
    if session then
        session.total = math.max(0, tonumber(session.completed) or 0)
            + QueueTotalCrafts(GetQueue(false))
        session.paused = true
    end
    WPP:RefreshPanel()
end

local function AddSelectedToQueue()
    if QueueBusy() then
        Print("Wait for the current production run to finish before changing the crafting queue.")
        return
    end
    if main.windowType ~= "TradeSkill" or not main.selectedSkill then
        Print("Open a profession recipe first.")
        return
    end

    local profession = CurrentProfession()
    if not profession then
        Print("Could not determine the current profession.")
        return
    end

    local quantity = 1
    if TradeSkillInputBox and TradeSkillInputBox.GetNumber then
        quantity = math.max(
            1,
            math.floor(TradeSkillInputBox:GetNumber() or 1)
        )
    end

    -- Make sure every currently-open profession recipe is cached before
    -- dependency planning begins.
    CacheCurrentProfessionRecipes()

    local skill = main.selectedSkill
    local itemID = ItemIDFromLink(skill.link)
    local key = itemID
        and tostring(itemID)
        or tostring(skill.skillId or skill.name)

    local queue = GetQueue(true)
    if #queue == 0 then
        -- A new order starts a new goal ledger. Completed goals remain visible
        -- until the player begins another order or explicitly clears the queue.
        ClearProductionGoals()
    end
    -- Repair duplicate rows created by older last-row-only merge behavior
    -- before calculating projected stock for this addition.
    CoalesceQueue(queue)
    local snapshot = GetRecipeSnapshot(skill.index) or skill
    snapshot.profession = profession

    local stored = RecipeForStorage(snapshot, profession) or {}

    -- Persist the final recipe itself before planning so it can participate in
    -- later dependency calculations immediately.
    if itemID then
        local db = InitDB()
        db.recipeProfession[tostring(itemID)] = profession
        db.recipeCache[tostring(itemID)] =
            RecipeForStorage(snapshot, profession)
    end

    ------------------------------------------------------------------------
    -- IMPORTANT: prerequisites are inserted FIRST.
    --
    -- Example:
    --   Smelt Copper
    --   Smelt Tin
    --   Smelt Bronze
    --   Whirring Bronze Gizmo
    --   Final Engineering item
    --
    -- Only missing intermediate quantities are scheduled; owned stock and
    -- surplus from existing queue rows are deducted first.
    ------------------------------------------------------------------------
    local dependencyRows, dependencyCrafts = 0, 0

    -- Add the explicit order, then run the same inventory-aware reconciler
    -- used by Stop/Resume. It always places all missing prerequisite batches
    -- before the consolidated final-product batch.
    local finalEntry = {
        profession = profession,
        skillId = key,
        itemID = itemID,
        name = skill.name,
        link = skill.link,
        icon = skill.texture
            or stored.icon
            or (itemID and GetItemIcon and GetItemIcon(itemID)),
        quantity = quantity,
        minProduced = stored.minProduced or skill.minProduced or 1,
        maxProduced = stored.maxProduced
            or skill.maxProduced
            or skill.minProduced
            or 1,
        reagents = stored.reagents
            or CopyReagentsForStorage(skill.reagents),
        autoDependency = false,
    }
    AppendQueueEntry(queue, finalEntry)
    AddProductionGoal(finalEntry, quantity)
    ReconcileQueueWithInventory()

    if dependencyCrafts > 0 then
        Print(
            "Added " .. quantity .. " x " .. skill.name
            .. " plus " .. dependencyCrafts
            .. " prerequisite craft"
            .. (dependencyCrafts == 1 and "" or "s")
            .. " to the crafting queue."
        )
    else
        Print(
            "Added " .. quantity .. " x " .. skill.name
            .. " [" .. profession .. "] to the crafting queue."
        )
    end

    WPP:RefreshPanel()
end

local function RemoveQueueEntry(index)
    local queue = GetQueue(false)
    if not queue or not queue[index] then return end
    if QueueBusy() then
        Print("Wait for the current production run to finish before changing the crafting queue.")
        return
    end
    local removed = queue[index]
    if removed and not removed.autoDependency then
        RemoveFromProductionGoal(removed, removed.quantity)
    end
    table.remove(queue, index)
    ReconcileQueueWithInventory()
    WPP:RefreshPanel()
end

local function ClearQueue()
    if QueueBusy() then
        Print("Wait for the current production run to finish before clearing the crafting queue.")
        return
    end
    local queue = GetQueue(false)
    if queue then wipe(queue) end
    ClearProductionSession()
    ClearProductionGoals()
    Print("Crafting queue and saved production progress cleared.")
    WPP:RefreshPanel()
end

local function MoveQueueEntry(fromIndex, toIndex)
    if QueueBusy() then return end
    local queue = GetQueue(false)
    if not queue
        or not queue[fromIndex]
        or not queue[toIndex]
        or fromIndex == toIndex then
        return
    end

    local entry = table.remove(queue, fromIndex)
    table.insert(queue, toIndex, entry)
    WPP:RefreshPanel()
end

local function SelectQueueEntry(entry)
    if not entry then return end

    local entryProfession = NormalizeProfessionName(entry.profession)
    local currentProfession = CurrentProfession()

    if entryProfession and entryProfession ~= currentProfession then
        if OpenProfessionByName(entryProfession, entry.itemID) then
            return
        end
        Print("Open " .. tostring(entryProfession) .. " to view " .. tostring(entry.name) .. ".")
        return
    end

    local index = FindTradeSkillIndex(entry)
    if not index then
        Print("Recipe is not available in the currently open profession.")
        return
    end
    if main.SelectCraftTrade then main:SelectCraftTrade(index) end
    if main.FetchSkillData then main:FetchSkillData() end
    local skill = entry.itemID and FindWiderSkillByItemID(entry.itemID) or nil
    if not skill and CraftTradeSkillFrame and CraftTradeSkillFrame.searchBar then
        CraftTradeSkillFrame.searchBar:ClearFocus()
        CraftTradeSkillFrame.searchBar:SetText("")
        if main.FetchSkillData then main:FetchSkillData() end
        skill = entry.itemID and FindWiderSkillByItemID(entry.itemID) or nil
    end
    if skill then main:SetSkillDetails(skill) end
    if main.RefreshList then main:RefreshList() end
end

local function SaveProductionProgress()
    if not craftAllState then return end
    local session = SavedProductionSession() or {}
    session.total = math.max(0, tonumber(craftAllState.total) or 0)
    session.completed = math.max(0, tonumber(craftAllState.completed) or 0)
    session.paused = true
    InitDB().productionSession = session
end

local function StopCraftAll(message, preserveSession)
    if message then Print(message) end
    if preserveSession then
        SaveProductionProgress()
    else
        ClearProductionSession()
    end
    craftAllState = nil
    processing = nil
    WPP:RefreshPanel()
end

local function StopProduction()
    if not craftAllState and not processing then return end

    if processing and craftAllState then
        -- TBC protects both SpellStopCasting and StopTradeSkillRepeat from
        -- addon code. Queue production is therefore dispatched one craft at a
        -- time; Stop safely lets the current cast finish, records it, and
        -- prevents the next craft from starting.
        craftAllState.stopRequested = true
        Print("Production will pause after the current operation finishes.")
        WPP:RefreshPanel()
        return
    end

    SaveProductionProgress()
    craftAllState = nil
    processing = nil
    Print("Production paused. Remaining queue and progress were saved.")
    WPP:RefreshPanel()
end

local function StartQueuedRecipe()
    local queue = GetQueue(false)

    if not queue or #queue == 0 then
        if craftAllState then
            Print("Crafting queue complete.")
            craftAllState = nil
            ClearProductionSession()
        end
        processing = nil
        WPP:RefreshPanel()
        return false
    end

    local entry = queue[1]
    local entryProfession = NormalizeProfessionName(entry.profession)
    local currentProfession = CurrentProfession()

    if entryProfession and currentProfession ~= entryProfession then
        if craftAllState then
            if craftAllState.waitingProfession ~= entryProfession then
                Print("Crafting queue paused. Next work center: " .. tostring(entryProfession)
                    .. ". Click Craft Queue to open it.")
            end
            craftAllState.waitingProfession = entryProfession
            craftAllState.waitingItemID = entry.itemID
            processing = nil
            WPP:RefreshPanel()
        else
            -- Craft Next was itself a hardware click, so it may safely open
            -- the required profession. The user then clicks Craft Next again.
            if OpenProfessionByName(entryProfession, entry.itemID) then
                Print("Opening " .. tostring(entryProfession) .. "... Click Craft Next again once it is open.")
            else
                local openerName = ProfessionOpener(entryProfession)
                Print("Could not open " .. tostring(entryProfession)
                    .. " (opener: " .. tostring(openerName or "unknown") .. ").")
            end
        end
        return false
    end

    if craftAllState then
        craftAllState.waitingProfession = nil
        craftAllState.waitingItemID = nil
    end

    local index = FindTradeSkillIndex(entry)
    if not index then
        local msg = "Can't find " .. tostring(entry.name) .. " in " .. tostring(currentProfession or "the current profession") .. "."
        if craftAllState then
            StopCraftAll("Crafting queue paused: " .. msg, true)
        else
            Print(msg)
        end
        return false
    end

    local name, skillType, numAvailable = GetTradeSkillInfo(index)
    if skillType == "header" then
        if craftAllState then StopCraftAll("Crafting queue paused on an invalid operation.", true) end
        return false
    end

    numAvailable = tonumber(numAvailable) or 0
    if numAvailable == 0 then
        local msg = "You don't currently have the materials to craft " .. tostring(entry.name) .. "."
        if craftAllState then
            StopCraftAll("Crafting queue paused at " .. tostring(entry.name) .. ": missing materials, tool, or work station.", true)
        else
            Print(msg)
        end
        return false
    end

    local requested = math.max(1, tonumber(entry.quantity) or 1)
    -- One hardware click may authorize an entire repeat batch for this recipe.
    -- Starting a different recipe later is a new protected action and requires
    -- another click, but all runs in this operation can proceed automatically.
    local count = requested
    if numAvailable > 0 then count = math.min(count, numAvailable) end

    SelectQueueEntry(entry)

    processing = {
        entry = entry,
        queueIndex = 1,
        name = name or entry.name,
        expected = count,
        completed = 0,
        skillId = tostring(entry.skillId or entry.itemID or entry.name),
        castStartMS = nil,
        castEndMS = nil,
    }

    WPP:RefreshPanel()

    local ok, err = pcall(DoTradeSkill, index, count)
    if not ok then
        local msg = "Could not start " .. tostring(entry.name) .. ": " .. tostring(err)
        if craftAllState then
            StopCraftAll("Crafting queue paused. " .. msg, true)
        else
            processing = nil
            Print(msg)
            WPP:RefreshPanel()
        end
        return false
    end

    return true
end

local function CraftNext()
    if craftAllState or processing then
        Print("A production run is already in progress.")
        return
    end

    local queue = GetQueue(false)
    if not queue or #queue == 0 then
        Print("The crafting queue is empty.")
        return
    end

    StartQueuedRecipe()
end

local function CraftAll()
    -- If Craft All is already paused at a profession boundary, this button
    -- becomes the protected hardware action which opens the next profession.
    if craftAllState then
        if processing then
            Print("The crafting queue is already running.")
            return
        end

        craftAllState.awaitingContinuation = nil

        local waiting = craftAllState.waitingProfession
        if waiting then
            if CurrentProfession() == waiting then
                -- The correct window is already open. A second hardware click
                -- continues queue processing.
                craftAllState.waitingProfession = nil
                craftAllState.waitingItemID = nil
                StartQueuedRecipe()
            else
                if OpenProfessionByName(waiting, craftAllState.waitingItemID) then
                    Print("Opening " .. tostring(waiting) .. "... Click Craft Queue again once it is open.")
                else
                    local openerName = ProfessionOpener(waiting)
                    Print("Could not open " .. tostring(waiting)
                        .. " (opener: " .. tostring(openerName or "unknown") .. ").")
                end
            end
            return
        end

        StartQueuedRecipe()
        return
    end

    if processing then
        Print("A production run is already in progress.")
        return
    end

    local queue = GetQueue(false)
    if not queue or #queue == 0 then
        Print("The crafting queue is empty.")
        return
    end

    -- Resume/start is the final authority boundary. Rebuild from current bags
    -- even if no BAG_UPDATE was observed while the panel was closed or the
    -- queue was paused.
    ReconcileQueueWithInventory()
    queue = GetQueue(false)

    local total = QueueTotalCrafts(queue)
    if total <= 0 then
        Print("The crafting queue is empty.")
        return
    end

    local saved = SavedProductionSession()
    local savedCompleted = saved and math.max(0, tonumber(saved.completed) or 0) or 0
    -- The queue is authoritative for work still outstanding, including any
    -- edits made while production was paused.
    local sessionTotal = savedCompleted + total

    craftAllState = {
        total = sessionTotal,
        completed = savedCompleted,
        waitingProfession = nil,
        waitingItemID = nil,
    }

    InitDB().productionSession = {
        total = sessionTotal,
        completed = savedCompleted,
        paused = false,
    }

    StartQueuedRecipe()
end


local function BuildShoppingList()
    local queue = GetQueue(false)
    local shopping = {}
    if not queue or #queue == 0 then return shopping end

    local db = InitDB()
    local recipeMap = {}

    -- Recipes remembered from every profession WPP has seen on this character.
    -- This lets Engineering requirements recursively expand through
    -- Mining/Smelting (and vice versa) without the other profession open.
    for key, stored in pairs(db.recipeCache or {}) do
        local itemID = tonumber(key) or stored.itemID
        if itemID then recipeMap[itemID] = stored end
    end

    -- Current profession data is always the freshest source.
    for itemID, recipe in pairs(BuildRecipeMap()) do
        recipe.profession = CurrentProfession()
        recipeMap[itemID] = recipe
        db.recipeCache[tostring(itemID)] =
            RecipeForStorage(recipe, CurrentProfession())
    end

    -- Shared-queue rows carry their own reagent snapshots. Prefer those when
    -- available so Shopping remains correct after switching professions.
    for _, queued in ipairs(queue) do
        if queued.itemID and queued.reagents and #queued.reagents > 0 then
            recipeMap[queued.itemID] = queued
        end
    end

    ------------------------------------------------------------------------
    -- Virtual stock ledger.
    --
    -- Each item begins with what the character already owns. Earlier queue
    -- outputs and sub-craft surplus are added to this same ledger and can be
    -- consumed by later requirements.
    ------------------------------------------------------------------------
    local stock = {}
    local visiting = {}

    local function OwnedCount(itemID)
        if not itemID then return 0 end

        -- Legacy Classic GetItemCount supports includeBank as argument #2.
        -- If this client variant rejects that form, fall back to bag-only.
        local ok, amount = pcall(GetItemCount, itemID, true)
        if not ok then
            amount = GetItemCount(itemID, false) or 0
        end
        return tonumber(amount) or 0
    end

    local function Available(itemID)
        if not itemID then return 0 end
        if stock[itemID] == nil then
            stock[itemID] = OwnedCount(itemID)
        end
        return stock[itemID]
    end

    local function AddStock(itemID, amount)
        amount = tonumber(amount) or 0
        if not itemID or amount <= 0 then return end
        stock[itemID] = Available(itemID) + amount
    end

    local function Consume(itemID, amount)
        amount = tonumber(amount) or 0
        if not itemID or amount <= 0 then return 0 end

        local have = Available(itemID)
        local used = math.min(have, amount)
        stock[itemID] = have - used
        return amount - used
    end

    local function AddRaw(reagent, amount)
        amount = tonumber(amount) or 0
        if amount <= 0 then return end

        local itemID = reagent.itemID
        local key = itemID or reagent.name
        local row = shopping[key]

        if not row then
            row = {
                itemID = itemID,
                name = reagent.name or UNKNOWN,
                link = reagent.link,
                icon = reagent.icon,
                count = 0,
            }
            shopping[key] = row
        end

        row.count = row.count + amount
    end

    ------------------------------------------------------------------------
    -- Resolve one requirement:
    --   1. consume existing / already-produced stock;
    --   2. if still missing and craftable, recursively resolve its reagents;
    --   3. preserve excess output from multi-output sub-crafts;
    --   4. only unresolved acquisition shortages reach Shopping.
    ------------------------------------------------------------------------
    local function Require(reagent, amount)
        amount = tonumber(amount) or 0
        if amount <= 0 then return end

        local itemID = reagent.itemID
        local missing = itemID and Consume(itemID, amount) or amount
        if missing <= 0 then return end

        local craft = itemID and recipeMap[itemID]
        local canExpand = InitDB().settings.expandCraftables
            and craft
            and craft.reagents
            and #craft.reagents > 0
            and not visiting[itemID]

        if canExpand then
            visiting[itemID] = true

            -- Conservative output for recipes with a variable result.
            local yield = math.max(
                1,
                tonumber(craft.minProduced)
                    or tonumber(craft.maxProduced)
                    or 1
            )

            local craftsNeeded = math.ceil(missing / yield)

            -- These sub-requirements also consume owned stock, including mats
            -- from another cached profession.
            for _, sub in ipairs(craft.reagents or {}) do
                Require(sub, (tonumber(sub.count) or 0) * craftsNeeded)
            end

            -- Example: Smelt Bronze can produce more than the current request.
            -- Keep that excess for later rows instead of throwing it away.
            local produced = craftsNeeded * yield
            local surplus = produced - missing
            if surplus > 0 then
                AddStock(itemID, surplus)
            end

            visiting[itemID] = nil
        else
            AddRaw(reagent, missing)
        end
    end

    ------------------------------------------------------------------------
    -- Simulate the shared queue in its actual drag/drop order.
    --
    -- Inputs are consumed first, then the queued recipe output is added.
    -- Thus an earlier Mining row can satisfy a later Engineering row.
    ------------------------------------------------------------------------
    for _, queued in ipairs(queue) do
        local recipe

        if queued.reagents and #queued.reagents > 0 then
            recipe = queued
        elseif queued.itemID then
            recipe = recipeMap[queued.itemID]
        end

        if recipe then
            local crafts = math.max(0, tonumber(queued.quantity) or 0)

            for _, reagent in ipairs(recipe.reagents or {}) do
                Require(reagent, (tonumber(reagent.count) or 0) * crafts)
            end

            if queued.itemID then
                local yield = math.max(
                    1,
                    tonumber(recipe.minProduced)
                        or tonumber(queued.minProduced)
                        or 1
                )
                AddStock(queued.itemID, crafts * yield)
            end
        end
    end

    local rows = {}
    for _, row in pairs(shopping) do
        if (tonumber(row.count) or 0) > 0 then
            table.insert(rows, row)
        end
    end

    table.sort(rows, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return rows
end

------------------------------------------------------------------------
-- Logistician Shopping integration
--
-- Logistician exposes list creation through its public API, which is wrapped
-- by LogisticianBridge.lua. Replace its generic Import/Export controls with a
-- single WPP import action when its legacy Shopping panel is available.
------------------------------------------------------------------------
local logisticianImportButton

local function ShoppingListNameFromQueue()
    local products = {}

    -- Automatically inserted prerequisite crafts are not end products. Rows
    -- from older WPP builds have no autoDependency flag and are treated as
    -- user-requested products for compatibility.
    for _, entry in ipairs(GetQueue(false) or {}) do
        if entry.autoDependency ~= true then
            table.insert(products, string.format(
                "%s x%d",
                entry.name or UNKNOWN,
                math.max(1, math.floor(tonumber(entry.quantity) or 1))
            ))
        end
    end

    if #products == 0 then
        return "WPP Bill of Materials"
    end

    return table.concat(products, " + ")
end

local function ImportShoppingListToLogistician()
    local rows = BuildShoppingList()
    if #rows == 0 then
        Print("The bill of materials is empty. Add recipes to the crafting queue first.")
        return
    end

    local bridge = _G.WiderProfessionsLogisticianBridge
    if not bridge or not bridge:IsAvailable() then
        Print("Auction-house module is not available.")
        return
    end

    local auctionRows = {}
    local vendorRows = 0
    for _, row in ipairs(rows) do
        if IsVendorSoldReagent(row.link, row.itemID) then
            vendorRows = vendorRows + 1
        else
            table.insert(auctionRows, row)
        end
    end

    if #auctionRows == 0 then
        Print(string.format(
            "The bill of materials contains only %d vendor-sold item%s; no procurement list was created.",
            vendorRows,
            vendorRows == 1 and "" or "s"
        ))
        return
    end

    local name = ShoppingListNameFromQueue()
    local ok, err = bridge:CreateShoppingList(name, auctionRows)
    if not ok then
        Print("Could not create the procurement list: " .. tostring(err))
        return
    end

    Print(string.format(
        "Imported %d material%s to procurement list '%s'%s.",
        #auctionRows,
        #auctionRows == 1 and "" or "s",
        name,
        vendorRows > 0 and string.format("; skipped %d vendor item%s", vendorRows, vendorRows == 1 and "" or "s") or ""
    ))
end

local function ButtonText(frame)
    if not frame or type(frame.GetText) ~= "function" then return nil end
    local ok, value = pcall(frame.GetText, frame)
    return ok and value or nil
end

local function KeepHidden(frame)
    if not frame or frame.WPPHidden then return end
    frame.WPPHidden = true
    frame:HookScript("OnShow", function(self)
        self:Hide()
    end)
    frame:Hide()
end

local function SetupLogisticianShoppingImport()
    if logisticianImportButton then return true end
    if not EnumerateFrames then return false end

    local imports = {}
    local exports = {}
    local frame = EnumerateFrames()

    while frame do
        if frame.GetObjectType and frame:GetObjectType() == "Button" then
            local text = ButtonText(frame)
            if text == "Import" then
                table.insert(imports, frame)
            elseif text == "Export" then
                table.insert(exports, frame)
            end
        end
        frame = EnumerateFrames(frame)
    end

    -- The two legacy controls shown in Logistician Shopping share a parent.
    -- Matching the pair avoids touching unrelated Import/Export buttons.
    for _, importButton in ipairs(imports) do
        for _, exportButton in ipairs(exports) do
            local parent = importButton:GetParent()
            if parent and parent == exportButton:GetParent() then
                logisticianImportButton = CreateFrame(
                    "Button",
                    "WiderProfessionsLogisticianImportButton",
                    parent,
                    "UIPanelButtonTemplate"
                )
                logisticianImportButton:SetPoint("TOPLEFT", importButton, "TOPLEFT", 0, 0)
                logisticianImportButton:SetPoint("BOTTOMRIGHT", exportButton, "BOTTOMRIGHT", 0, 0)
                logisticianImportButton:SetText("Import")
                logisticianImportButton:SetScript("OnClick", ImportShoppingListToLogistician)
                logisticianImportButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Import Bill of Materials", 1, 1, 1)
                    GameTooltip:AddLine(
                        "Creates a procurement list named for the end product and production quantity. Vendor-supplied components are excluded.",
                        nil, nil, nil, true
                    )
                    GameTooltip:Show()
                end)
                logisticianImportButton:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                KeepHidden(importButton)
                KeepHidden(exportButton)
                logisticianImportButton:Show()
                return true
            end
        end
    end

    return false
end

local function TrySetupLogisticianShoppingImport(attempt)
    if SetupLogisticianShoppingImport() then return end
    attempt = (attempt or 0) + 1
    if attempt < 10 then
        C_Timer.After(0.25, function()
            TrySetupLogisticianShoppingImport(attempt)
        end)
    end
end

------------------------------------------------------------------------
-- Logistician market-tooltip wording
--
-- Keep the label intentionally simple. Logistician may refresh this line
-- repeatedly, so correct each write immediately instead of adding overlays.
------------------------------------------------------------------------
local MARKET_TOOLTIP_LABEL = "Market (10" .. string.char(37) .. " depth)"

local function FixMarketTooltip(tooltip)
    if not tooltip or not tooltip.NumLines or not tooltip.GetName then return end
    local tooltipName = tooltip:GetName()
    if not tooltipName then return end

    for i = 1, tooltip:NumLines() do
        local left = _G[tooltipName .. "TextLeft" .. i]
        if left and left.GetText then
            local text = left:GetText()
            if type(text) == "string" and text:match("^Market%s*%(") then
                if not left.WPPMarketLabelHook then
                    left.WPPMarketLabelHook = true
                    hooksecurefunc(left, "SetText", function(self, newText)
                        if type(newText) == "string"
                            and newText ~= MARKET_TOOLTIP_LABEL
                            and newText:match("^Market%s*%(") then
                            self:SetText(MARKET_TOOLTIP_LABEL)
                        end
                    end)
                    hooksecurefunc(left, "SetFormattedText", function(self)
                        local formatted = self:GetText()
                        if type(formatted) == "string"
                            and formatted ~= MARKET_TOOLTIP_LABEL
                            and formatted:match("^Market%s*%(") then
                            self:SetText(MARKET_TOOLTIP_LABEL)
                        end
                    end)
                end
                if text ~= MARKET_TOOLTIP_LABEL then
                    left:SetText(MARKET_TOOLTIP_LABEL)
                end
            end
        end
    end
end

local function SetupMarketDepthTooltipFix()
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tooltip and not tooltip.WPPMarketDepthFix then
            tooltip.WPPMarketDepthFix = true
            tooltip:HookScript("OnTooltipSetItem", FixMarketTooltip)
            hooksecurefunc(tooltip, "AddLine", function(self)
                FixMarketTooltip(self)
            end)
            hooksecurefunc(tooltip, "AddDoubleLine", function(self)
                FixMarketTooltip(self)
            end)
        end
    end
end

local function FrameIsMouseOver(frame)
    if not frame then return false end
    if MouseIsOver then return MouseIsOver(frame) end
    if frame.IsMouseOver then return frame:IsMouseOver() end
    return false
end

local function FinishQueueDrag(sourceRow)
    if sourceRow then sourceRow:UnlockHighlight() end
    if not panel or not panel.dragSourceIndex then return end

    local fromIndex = panel.dragSourceIndex
    local toIndex = nil
    for _, row in ipairs(panel.rows or {}) do
        if row:IsShown() and FrameIsMouseOver(row) then
            toIndex = row.dataIndex
            break
        end
    end

    panel.dragSourceIndex = nil
    panel.suppressClickUntil = GetTime() + 0.15

    if toIndex and fromIndex ~= toIndex then
        MoveQueueEntry(fromIndex, toIndex)
    end
end

local function CreatePanel()
    if panel then return end
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    panel = CreateFrame("Frame", "WiderProfessionsPlusPanel", CraftTradeSkillFrame, template)
    panel:SetSize(390, 390)
    panel:SetPoint("TOPLEFT", CraftTradeSkillFrame, "TOPRIGHT", 4, -32)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:EnableMouseWheel(true)
    panel:Hide()

    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    else
        local bg = panel:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    end

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", 18, -17)
    panel.title:SetText("Logistician")

    panel.close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    panel.close:SetPoint("TOPRIGHT", -5, -5)

    panel.queueTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.queueTab:SetSize(110, 22)
    panel.queueTab:SetPoint("TOPLEFT", 16, -45)
    panel.queueTab:SetText("Crafting")
    panel.queueTab:SetScript("OnClick", function() panel.mode = "queue" WPP:RefreshPanel() end)

    panel.shopTab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.shopTab:SetSize(110, 22)
    panel.shopTab:SetPoint("LEFT", panel.queueTab, "RIGHT", 4, 0)
    panel.shopTab:SetText("Materials")
    panel.shopTab:SetScript("OnClick", function() panel.mode = "shopping" WPP:RefreshPanel() end)

    panel.header = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.header:SetPoint("TOPLEFT", 18, -78)
    panel.header:SetWidth(205)
    panel.header:SetJustifyH("LEFT")

    panel.qtyHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.qtyHeader:SetPoint("TOPRIGHT", -132, -78)
    panel.qtyHeader:SetWidth(60)
    panel.qtyHeader:SetJustifyH("RIGHT")
    panel.qtyHeader:SetText("Required")
    panel.qtyHeader:Hide()

    panel.costHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.costHeader:SetPoint("TOPRIGHT", -24, -78)
    panel.costHeader:SetWidth(98)
    panel.costHeader:SetJustifyH("RIGHT")
    panel.costHeader:SetText("Est. Cost")
    panel.costHeader:Hide()

    panel.rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, panel)
        row:SetSize(350, 23)
        row:SetPoint("TOPLEFT", 18, -94 - (i - 1) * 24)
        row:RegisterForClicks("LeftButtonUp")
        row:RegisterForDrag("LeftButton")

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", 0, 0)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
        row.text:SetWidth(160)
        row.text:SetJustifyH("LEFT")

        -- Shared queue: show which profession owns each recipe.
        row.profession = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.profession:SetPoint("RIGHT", -73, 0)
        row.profession:SetWidth(70)
        row.profession:SetJustifyH("RIGHT")
        row.profession:Hide()

        -- Dedicated shopping quantity column. Hidden in queue mode.
        row.qty = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.qty:SetPoint("RIGHT", -110, 0)
        row.qty:SetWidth(45)
        row.qty:SetJustifyH("RIGHT")
        row.qty:Hide()

        -- Queue quantity OR shopping total cost.
        row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.right:SetPoint("RIGHT", -22, 0)
        row.right:SetWidth(46)
        row.right:SetJustifyH("RIGHT")

        row.remove = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.remove:SetSize(20, 20)
        row.remove:SetPoint("RIGHT", 5, 0)
        row.remove:Hide()

        row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
        row.highlight:SetAllPoints()
        row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.highlight:SetBlendMode("ADD")

        row:SetScript("OnDragStart", function(self)
            if panel.mode ~= "queue" or QueueBusy() or not self.entry then return end
            panel.dragSourceIndex = self.dataIndex
            self:LockHighlight()
        end)
        row:SetScript("OnDragStop", function(self)
            FinishQueueDrag(self)
        end)

        panel.rows[i] = row
    end

    panel.summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.summary:SetPoint("BOTTOMLEFT", 18, 48)
    panel.summary:SetWidth(350)
    panel.summary:SetJustifyH("LEFT")

    panel.productionGoalHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.productionGoalHeader:SetPoint("BOTTOMLEFT", 18, 108)
    panel.productionGoalHeader:SetText("Production Goal")
    panel.productionGoalHeader:Hide()

    panel.productionGoal = CreateFrame("Frame", nil, panel)
    panel.productionGoal:SetSize(350, 20)
    panel.productionGoal:SetPoint("BOTTOMLEFT", 18, 84)
    panel.productionGoal.icon = panel.productionGoal:CreateTexture(nil, "ARTWORK")
    panel.productionGoal.icon:SetSize(20, 20)
    panel.productionGoal.icon:SetPoint("LEFT", 0, 0)
    panel.productionGoal.name = panel.productionGoal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.productionGoal.name:SetPoint("LEFT", panel.productionGoal.icon, "RIGHT", 5, 0)
    panel.productionGoal.name:SetWidth(190)
    panel.productionGoal.name:SetJustifyH("LEFT")
    panel.productionGoal.quantity = panel.productionGoal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.productionGoal.decrease = CreateFrame("Button", nil, panel.productionGoal, "UIPanelButtonTemplate")
    panel.productionGoal.decrease:SetSize(22, 20)
    panel.productionGoal.decrease:SetPoint("RIGHT", -76, 0)
    panel.productionGoal.decrease:SetText("-")
    panel.productionGoal.decrease:SetScript("OnClick", function() AdjustProductionGoal(-1) end)
    panel.productionGoal.quantity:SetPoint("LEFT", panel.productionGoal.decrease, "RIGHT", 3, 0)
    panel.productionGoal.quantity:SetWidth(45)
    panel.productionGoal.quantity:SetJustifyH("CENTER")
    panel.productionGoal.increase = CreateFrame("Button", nil, panel.productionGoal, "UIPanelButtonTemplate")
    panel.productionGoal.increase:SetSize(22, 20)
    panel.productionGoal.increase:SetPoint("LEFT", panel.productionGoal.quantity, "RIGHT", 3, 0)
    panel.productionGoal.increase:SetText("+")
    panel.productionGoal.increase:SetScript("OnClick", function() AdjustProductionGoal(1) end)
    panel.productionGoal:Hide()

    -- Overall queued-batch progress, using Blizzard Classic's own casting-bar
    -- art. The normal player cast bar still displays each individual craft.
    panel.progress = CreateFrame("StatusBar", nil, panel)
    -- UI-CastingBar-Border's native transparent center is approximately 195px
    -- wide. A wider StatusBar leaks its fill past both decorative end caps.
    panel.progress:SetSize(195, 13)
    panel.progress:SetPoint("BOTTOM", panel, "BOTTOM", 0, 51)
    panel.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    panel.progress:SetStatusBarColor(1.0, 0.70, 0.0)
    panel.progress:SetMinMaxValues(0, 1)
    panel.progress:SetValue(0)
    panel.progress:Hide()

    panel.progress.bg = panel.progress:CreateTexture(nil, "BACKGROUND")
    panel.progress.bg:SetAllPoints()
    panel.progress.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    panel.progress.bg:SetVertexColor(0.18, 0.12, 0.05, 0.85)

    panel.progress.border = panel.progress:CreateTexture(nil, "OVERLAY")
    panel.progress.border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
    panel.progress.border:SetSize(256, 64)
    panel.progress.border:SetPoint("CENTER", panel.progress, "CENTER", 0, 0)

    panel.progress.text = panel.progress:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.progress.text:SetPoint("CENTER", panel.progress, "CENTER", 0, 1)

    panel.progress:SetScript("OnUpdate", function(self)
        if not processing and not craftAllState then return end

        local expected
        local value
        local current
        local label

        if craftAllState then
            expected = math.max(1, craftAllState.total or 1)
            value = craftAllState.completed or 0
            current = math.min(expected, value + (processing and 1 or 0))
            label = "Production Progress"
        else
            expected = math.max(1, processing.expected or 1)
            value = processing.completed or 0
            current = math.min(expected, value + 1)
            label = "Production Progress"
        end

        if processing
            and processing.castStartMS
            and processing.castEndMS
            and processing.castEndMS > processing.castStartMS then
            local nowMS = GetTime() * 1000
            local fraction = (nowMS - processing.castStartMS) / (processing.castEndMS - processing.castStartMS)
            fraction = math.max(0, math.min(1, fraction))
            value = math.min(expected, value + fraction)
        end

        self:SetMinMaxValues(0, expected)
        self:SetValue(value)

        self.text:SetText(string.format("%s  %d/%d", label, current, expected))
    end)

    panel.prev = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.prev:SetSize(28, 20)
    panel.prev:SetPoint("BOTTOMLEFT", 18, 18)
    panel.prev:SetText("<")
    panel.prev:SetScript("OnClick", function() panel.offset = math.max(0, (panel.offset or 0) - MAX_ROWS) WPP:RefreshPanel() end)

    panel.next = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.next:SetSize(28, 20)
    panel.next:SetPoint("LEFT", panel.prev, "RIGHT", 4, 0)
    panel.next:SetText(">")
    panel.next:SetScript("OnClick", function() panel.offset = (panel.offset or 0) + MAX_ROWS WPP:RefreshPanel() end)

    panel.craftAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.craftAll:SetSize(150, 22)
    panel.craftAll:SetPoint("BOTTOMRIGHT", -18, 18)
    panel.craftAll:SetText("Craft Queue")
    panel.craftAll:SetScript("OnClick", CraftAll)

    panel.clear = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.clear:SetSize(70, 22)
    panel.clear:SetPoint("RIGHT", panel.craftAll, "LEFT", -6, 0)
    panel.clear:SetText("Clear")
    panel.clear:SetScript("OnClick", function()
        if QueueBusy() then
            StopProduction()
        else
            ClearQueue()
        end
    end)

    panel.mode = "queue"
    panel.offset = 0
    panel:SetScript("OnMouseWheel", function(self, delta)
        if delta < 0 then self.offset = (self.offset or 0) + MAX_ROWS else self.offset = math.max(0, (self.offset or 0) - MAX_ROWS) end
        WPP:RefreshPanel()
    end)
end

function WPP:RefreshPanel()
    if not panel or not panel:IsShown() then return end
    panel.offset = panel.offset or 0

    local data
    if panel.mode == "shopping" then
        data = BuildShoppingList()
        panel.header:SetText("Bill of Materials")
        panel.qtyHeader:Show()
        panel.costHeader:Show()
        panel.craftAll:Hide()
        panel.clear:Hide()
        panel.progress:Hide()
        panel.summary:Show()
        panel.productionGoalHeader:Hide()
        panel.productionGoal:Hide()
    else
        data = GetQueue(false) or {}
        panel.header:SetText("Crafting Queue")
        panel.qtyHeader:Hide()
        panel.costHeader:Hide()
        panel.craftAll:Show()
        panel.clear:Show()
        panel.productionGoalHeader:Show()
        panel.productionGoal:Show()
        if processing or craftAllState then
            panel.summary:Hide()
            panel.progress:Show()
        else
            panel.progress:Hide()
            panel.summary:Show()
        end
    end

    local maxOffset = math.max(0, #data - MAX_ROWS)
    if panel.offset > maxOffset then panel.offset = math.max(0, math.floor(maxOffset / MAX_ROWS) * MAX_ROWS) end

    for i = 1, MAX_ROWS do
        local dataIndex = panel.offset + i
        local entry = data[dataIndex]
        local row = panel.rows[i]
        if entry then
            row.dataIndex = dataIndex
            row.entry = entry
            row.icon:SetTexture(entry.icon or (entry.link and select(10, GetItemInfo(entry.link))) or "Interface\\Icons\\INV_Misc_QuestionMark")
            if panel.mode == "shopping" then
                row.profession:Hide()
                local vendorSold = IsVendorSoldReagent(entry.link, entry.itemID)
                local price = not vendorSold and MarketPrice(entry.link, entry.itemID) or nil
                row.text:SetText((entry.name or UNKNOWN) .. (vendorSold and " |cff40ff40(Vendor)|r" or ""))
                row.qty:SetText("x" .. tostring(entry.count or 0))
                row.qty:Show()

                row.right:ClearAllPoints()
                row.right:SetPoint("RIGHT", -2, 0)
                row.right:SetWidth(98)
                row.right:SetText(vendorSold and "Vendor" or (price and MoneyText(price * (entry.count or 0)) or "--"))

                row.remove:Hide()
                row:SetScript("OnClick", function(self)
                    if self.entry and self.entry.link then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(self.entry.link)
                        if IsVendorSoldReagent(self.entry.link, self.entry.itemID) then
                            GameTooltip:AddLine("Sold by profession-supply vendors", 0.25, 1, 0.25)
                        end
                        GameTooltip:Show()
                    end
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                row.text:SetText(entry.name or UNKNOWN)
                row.qty:Hide()
                row.profession:SetText(NormalizeProfessionName(entry.profession) or "?")
                row.profession:Show()

                row.right:ClearAllPoints()
                row.right:SetPoint("RIGHT", -22, 0)
                row.right:SetWidth(46)
                row.right:SetText("x" .. tostring(entry.quantity or 0))

                row.remove:Show()
                row.remove:SetScript("OnClick", function(self)
                    RemoveQueueEntry(self:GetParent().dataIndex)
                end)

                row:SetScript("OnClick", function(self)
                    if panel.suppressClickUntil and GetTime() < panel.suppressClickUntil then
                        return
                    end
                    SelectQueueEntry(self.entry)
                end)
                row:SetScript("OnEnter", function(self)
                    if not self.entry then return end
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.entry.name or UNKNOWN, 1, 0.82, 0)
                    GameTooltip:AddLine(NormalizeProfessionName(self.entry.profession) or "Unknown profession", 0.8, 0.8, 0.8)
                    GameTooltip:AddLine("Drag to reorder", 0.45, 1, 0.45)
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            row:Show()
        else
            row.qty:Hide()
            row.profession:Hide()
            row:Hide()
        end
    end

    if panel.offset > 0 then panel.prev:Enable() else panel.prev:Disable() end
    if panel.offset + MAX_ROWS < #data then panel.next:Enable() else panel.next:Disable() end

    if panel.mode == "shopping" then
        local totalCost, missing = 0, false
        for _, entry in ipairs(data) do
            if IsVendorSoldReagent(entry.link, entry.itemID) then
                missing = true
            else
                local price = MarketPrice(entry.link, entry.itemID)
                if price then totalCost = totalCost + price * (entry.count or 0) else missing = true end
            end
        end
        panel.summary:SetText(string.format(
            "%d component%s required%s",
            #data,
            #data == 1 and "" or "s",
            totalCost > 0 and (
                "  •  " .. (missing and "Known cost: " or "Estimated cost: ")
                .. MoneyText(totalCost)
            ) or ""
        ))
    else
        local crafts = QueueTotalCrafts(data)
        local saved = SavedProductionSession()

        local goal = CurrentProductionGoal()
        -- One-time compatibility for queues saved before per-product goal
        -- tracking existed. Their remaining final batches become fresh goals.
        if not goal then
            for _, entry in ipairs(data) do
                if not entry.autoDependency and (tonumber(entry.quantity) or 0) > 0 then
                    AddProductionGoal(entry, entry.quantity)
                end
            end
            goal = CurrentProductionGoal()
        end
        if goal then
            panel.productionGoal.icon:SetTexture(
                goal.icon
                or (goal.link and select(10, GetItemInfo(goal.link)))
                or (goal.itemID and GetItemIcon and GetItemIcon(goal.itemID))
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            )
            panel.productionGoal.name:SetText(goal.name or UNKNOWN)
            panel.productionGoal.quantity:SetText(string.format(
                "|cff40ff40%d|r/%d",
                math.max(0, tonumber(goal.completed) or 0),
                math.max(0, tonumber(goal.total) or 0)
            ))
            if QueueBusy() then
                panel.productionGoal.decrease:Disable()
                panel.productionGoal.increase:Disable()
            else
                panel.productionGoal.increase:Enable()
                if (tonumber(goal.total) or 0) > (tonumber(goal.completed) or 0) then
                    panel.productionGoal.decrease:Enable()
                else
                    panel.productionGoal.decrease:Disable()
                end
            end
            panel.productionGoal:Show()
        else
            panel.productionGoal:Hide()
        end

        if saved and #data > 0 then
            local completed = math.max(0, tonumber(saved.completed) or 0)
            local total = completed + crafts
            panel.summary:SetText(string.format(
                "Progress %d/%d  •  %d operation%s  •  %d run%s remaining",
                completed, total,
                #data, #data == 1 and "" or "s",
                crafts, crafts == 1 and "" or "s"))
        else
            panel.summary:SetText(string.format("%d operation%s  •  %d production run%s  •  drag to sequence",
                #data, #data == 1 and "" or "s",
                crafts, crafts == 1 and "" or "s"))
        end

        local currentProfession = CurrentProfession()

        -- Craft All is the single queue action. At profession boundaries the
        -- same button becomes Open <Profession> / Continue All.
        if craftAllState and not processing and craftAllState.waitingProfession then
            if currentProfession == craftAllState.waitingProfession then
                panel.craftAll:SetText("Continue Queue")
            else
                panel.craftAll:SetText("Open " .. craftAllState.waitingProfession)
            end
        elseif craftAllState and not processing and craftAllState.awaitingContinuation then
            panel.craftAll:SetText("Continue Queue")
        else
            panel.craftAll:SetText(saved and #data > 0 and "Resume Queue" or "Craft Queue")
        end

        if processing then
            panel.craftAll:SetText("In Production")
            panel.craftAll:Disable()
            panel.clear:SetText("Clear")
            panel.clear:Disable()
        elseif craftAllState then
            panel.craftAll:Enable()
            panel.clear:SetText("Clear")
            panel.clear:Disable()
        elseif #data > 0 then
            panel.clear:SetText("Clear")
            panel.craftAll:Enable()
            panel.clear:Enable()
        else
            panel.clear:SetText("Clear")
            panel.craftAll:Disable()
            panel.clear:Enable()
        end
    end

    UpdateQueueAddButton()
end

local function TogglePanel(mode)
    CreatePanel()
    if mode then panel.mode = mode end
    if panel:IsShown() then
        panel:Hide()
    else
        panel.offset = 0
        panel:Show()
        WPP:RefreshPanel()
    end
end

local function ShowQueuePanel()
    CreatePanel()
    panel.mode = "queue"
    panel:Show()
    WPP:RefreshPanel()
end

local function AddSelectedAndOpenQueue()
    if QueueBusy() then
        Print("Wait for the current production run to finish before adding another recipe.")
        return
    end

    AddSelectedToQueue()
    ShowQueuePanel()
end

UpdateQueueAddButton = function()
    if not queueAddButton then return end

    local usable = main
        and main.windowType == "TradeSkill"
        and main.selectedSkill ~= nil
        and not QueueBusy()

    queueAddButton:SetShown(main and main.windowType == "TradeSkill")
    if usable then
        queueAddButton:Enable()
    else
        queueAddButton:Disable()
    end
end

local function SetupUI()
    main = _G.WiderProfessionsAddon
    if not main then
        return false
    end
    if not CraftTradeSkillFrame or openButton then
        return false
    end

    -- WPP 0.1.13:
    -- Replace Blizzard's native Create All button with Add Selected.
    -- We copy Create All's exact anchor/size before suppressing it, so the
    -- bottom crafting controls keep the original Blizzard spacing.
    queueAddButton = CreateFrame(
        "Button",
        "WiderProfessionsPlusAddSelectedButton",
        CraftTradeSkillFrame,
        "UIPanelButtonTemplate"
    )
    queueAddButton:SetText("Add")
    queueAddButton:SetScript("OnClick", AddSelectedAndOpenQueue)
    queueAddButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Add", 1, 0.82, 0)
        GameTooltip:AddLine("Adds the selected recipe and quantity to the crafting queue.", 1, 1, 1, true)
        GameTooltip:AddLine("Missing craftable prerequisites are inserted before it automatically.", 0.45, 1, 0.45, true)
        GameTooltip:AddLine("Opens the Crafting Queue after adding.", 0.45, 1, 0.45)
        GameTooltip:Show()
    end)
    queueAddButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    if TradeSkillCreateAllButton and TradeSkillCreateButton then
        -- Preserve Create All's original right edge, but expand leftward so
        -- "Add Selected" fits without touching the quantity decrement button.
        queueAddButton:SetSize(82, math.max(22, TradeSkillCreateAllButton:GetHeight() or 22))
        queueAddButton:ClearAllPoints()
        queueAddButton:SetPoint("RIGHT", TradeSkillCreateButton, "LEFT", -90, 0)

        -- Blizzard/Wider Professions may try to show Create All again as the
        -- selected recipe changes. Keep it permanently suppressed while this
        -- enhanced build is loaded.
        TradeSkillCreateAllButton:Hide()
        TradeSkillCreateAllButton:HookScript("OnShow", function(self)
            self:Hide()
        end)
    else
        queueAddButton:SetSize(82, 22)
        queueAddButton:SetPoint("BOTTOMRIGHT", CraftTradeSkillFrame, "BOTTOMRIGHT", -213, 10)
    end

    queueAddButton:Hide()

    -- Compact Logistician-backed recipe value footer. This replaces the
    -- two-line LogisticianCraftingInfo block that can collide with reagent rows.
    marketSummary = CraftTradeReagentsInset:CreateFontString(
        "WiderProfessionsPlusMarketSummary",
        "OVERLAY",
        "GameFontNormalSmall"
    )

    -- Price summary lives on the same line as "Reagents:" rather than in a
    -- fixed footer. This makes it independent of reagent count and guarantees
    -- it cannot cover a reagent row or the Create controls.
    marketSummary:SetPoint("RIGHT", CraftTradeDetailReagents, "RIGHT", -4, 0)
    marketSummary:SetWidth(260)
    marketSummary:SetJustifyH("RIGHT")
    marketSummary:Hide()

    if LogisticianCraftingInfo and type(LogisticianCraftingInfo.AdjustPosition) == "function" then
        hooksecurefunc(LogisticianCraftingInfo, "AdjustPosition", function(self)
            -- Let Logistician update its internal values, then suppress its
            -- large frame and refresh our compact footer from the same API.
            C_Timer.After(0, function()
                self:Hide()
                UpdateRecipeMarketSummary(main.selectedSkill)
            end)
        end)
    end

    openButton = CreateFrame("Button", "WiderProfessionsPlusOpenButton", CraftTradeReagentsInset)
    openButton:SetSize(28, 28)

    -- Top-right launcher. The Favorite star sits immediately to its left.
    openButton:SetPoint("TOPRIGHT", CraftTradeReagentsInset, "TOPRIGHT", -8, -8)

    openButton.icon = openButton:CreateTexture(nil, "ARTWORK")
    openButton.icon:SetPoint("TOPLEFT", 4, -4)
    openButton.icon:SetPoint("BOTTOMRIGHT", -4, 4)
    openButton.icon:SetTexture("Interface\\AddOns\\!Logistician\\Images\\LogisticianIcon")
    openButton.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Classic action-button style border so it reads as an actual button.
    openButton.border = openButton:CreateTexture(nil, "OVERLAY")
    openButton.border:SetSize(46, 46)
    openButton.border:SetPoint("CENTER", 0, 0)
    openButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    openButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local highlight = openButton:GetHighlightTexture()
    if highlight then
        highlight:SetPoint("TOPLEFT", 2, -2)
        highlight:SetPoint("BOTTOMRIGHT", -2, 2)
    end
    openButton:SetScript("OnClick", function() TogglePanel("queue") end)
    openButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Logistician", 1, 0.82, 0)
        GameTooltip:AddLine("Crafting Queue & Bill of Materials", 1, 1, 1)
        GameTooltip:AddLine("Click craftable reagents to jump to their recipe, even in another profession.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    openButton:SetScript("OnLeave", function() GameTooltip:Hide() end)


    hooksecurefunc(main, "SetSkillDetails", function(_, skill)
        C_Timer.After(0, function()
            EnhanceReagentClicks(skill)
            UpdateRecipeMarketSummary(skill)
            UpdateQueueAddButton()
        end)
    end)

    CraftTradeSkillFrame:HookScript("OnShow", function()
        C_Timer.After(0, function()
            if main.windowType == "TradeSkill" then
                openButton:Show()
            else
                openButton:Hide()
            end
        end)
    end)
    CraftTradeSkillFrame:HookScript("OnHide", function()
        if queueAddButton then queueAddButton:Hide() end
        if panel then
            if WPP.pendingProfession or (craftAllState and craftAllState.waitingProfession) then
                panel.restoreAfterProfession = panel:IsShown()
            else
                panel:Hide()
            end
        end
        if marketSummary then marketSummary:Hide() end
    end)

    if main.selectedSkill then
        EnhanceReagentClicks(main.selectedSkill)
        UpdateRecipeMarketSummary(main.selectedSkill)
    else
        HideLogisticianCraftingBlock()
    end

    UpdateQueueAddButton()
    return true
end

local function TrySetupUI()
    if SetupUI() then
        return
    end
    C_Timer.After(0.5, SetupUI)
end

WPP:RegisterEvent("ADDON_LOADED")
WPP:RegisterEvent("PLAYER_LOGIN")
WPP:RegisterEvent("TRADE_SKILL_SHOW")
WPP:RegisterEvent("TRADE_SKILL_UPDATE")
WPP:RegisterEvent("AUCTION_HOUSE_SHOW")
WPP:RegisterEvent("BAG_UPDATE_DELAYED")
WPP:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
WPP:RegisterEvent("UNIT_SPELLCAST_START")
WPP:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
WPP:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
WPP:RegisterEvent("UNIT_SPELLCAST_FAILED")

WPP:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON_NAME then
            InitDB()
            main = _G.WiderProfessionsAddon
            SetupMarketDepthTooltipFix()
            C_Timer.After(0, TrySetupUI)
        end
        return
    elseif event == "PLAYER_LOGIN" then
        SetupMarketDepthTooltipFix()
        C_Timer.After(0.5, TrySetupUI)
        return
    elseif event == "TRADE_SKILL_SHOW" then
        C_Timer.After(0.05, function()
            CacheCurrentProfessionRecipes()
            FinishPendingProfessionJump()

            if panel and panel.restoreAfterProfession then
                panel.restoreAfterProfession = nil
                panel:Show()
            end
            WPP:RefreshPanel()
            UpdateQueueAddButton()
        end)
        return
    elseif event == "TRADE_SKILL_UPDATE" then
        C_Timer.After(0, CacheCurrentProfessionRecipes)
        return
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYERBANKSLOTS_CHANGED" then
        -- Bag updates often arrive in bursts (loot, purchases, mail, and each
        -- completed craft). Rebuild once after the client has finalized item
        -- counts. BuildShoppingList reads GetItemCount on every call, so this
        -- immediately subtracts newly owned materials and restores shortages
        -- when items leave inventory. The queue view is refreshed too, while
        -- its explicit production orders remain intact.
        self.inventoryRefreshSerial = (self.inventoryRefreshSerial or 0) + 1
        local serial = self.inventoryRefreshSerial
        C_Timer.After(0.12, function()
            if self.inventoryRefreshSerial ~= serial then return end
            ReconcileQueueWithInventory()
            WPP:RefreshPanel()
            UpdateQueueAddButton()
        end)
        return
    elseif event == "AUCTION_HOUSE_SHOW" then
        C_Timer.After(0, function()
            TrySetupLogisticianShoppingImport(0)
        end)
        return
    end

    local unit, castGUID, spellID = ...
    if unit ~= "player" or not processing then return end
    local spellName = spellID and GetSpellInfo(spellID) or nil

    if event == "UNIT_SPELLCAST_START" then
        if spellName == processing.name then
            local _, _, _, startMS, endMS = UnitCastingInfo("player")
            if startMS and endMS and endMS > startMS then
                processing.castStartMS = startMS
                processing.castEndMS = endMS
            end
            WPP:RefreshPanel()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if spellName == processing.name then
            local completedBatch = processing
            processing.castStartMS = nil
            processing.castEndMS = nil
            processing.completed = processing.completed + 1

            if not processing.entry.autoDependency then
                CompleteProductionGoal(processing.entry)
            end

            if craftAllState then
                craftAllState.completed = math.min(
                    craftAllState.total or 0,
                    (craftAllState.completed or 0) + 1
                )
                local session = SavedProductionSession() or {}
                session.total = craftAllState.total
                session.completed = craftAllState.completed
                session.paused = false
                InitDB().productionSession = session
            end

            processing.entry.quantity = math.max(0, (processing.entry.quantity or 1) - 1)

            if processing.entry.quantity <= 0 then
                local queue = GetQueue(false)
                if queue and queue[processing.queueIndex] == processing.entry then
                    table.remove(queue, processing.queueIndex)
                end
            end

            local batchFinished = processing.completed >= processing.expected
            if batchFinished then
                processing = nil
            end

            WPP:RefreshPanel()

            if batchFinished and craftAllState then
                local queue = GetQueue(false)

                if craftAllState.stopRequested then
                    SaveProductionProgress()
                    craftAllState = nil
                    processing = nil
                    Print("Production paused. Remaining queue and progress were saved.")
                    WPP:RefreshPanel()
                    C_Timer.After(0.2, function()
                        if not QueueBusy() then
                            ReconcileQueueWithInventory()
                            WPP:RefreshPanel()
                        end
                    end)
                elseif not queue or #queue == 0 then
                    craftAllState.completed = craftAllState.total
                    Print("Crafting queue complete.")
                    craftAllState = nil
                    ClearProductionSession()
                    WPP:RefreshPanel()
                else
                    -- DoTradeSkill is protected on TBC Anniversary. The click
                    -- that began the previous craft cannot authorize another
                    -- call from this spellcast event or a timer. Preserve the
                    -- active session and wait for a fresh hardware click.
                    craftAllState.awaitingContinuation = true
                    SaveProductionProgress()
                    WPP:RefreshPanel()
                end
            elseif craftAllState then
                -- On the TBC client a repeated DoTradeSkill batch can end
                -- without another spellcast event (for example when the
                -- client-side repeat count is exhausted). The old code then
                -- left `processing` alive forever and never advanced the
                -- production queue. After a generous inter-cast delay, verify
                -- that this exact batch is still idle. Releasing it lets the
                -- queue retry its remaining quantity or continue to the next
                -- operation using freshly updated reagent counts.
                C_Timer.After(0.75, function()
                    if not craftAllState or processing ~= completedBatch then return end
                    if UnitCastingInfo("player") then return end

                    local repeatCount = 0
                    if GetTradeSkillRepeatCount then
                        local ok, count = pcall(GetTradeSkillRepeatCount)
                        if ok then repeatCount = tonumber(count) or 0 end
                    end
                    if repeatCount > 0 then return end

                    processing = nil
                    craftAllState.awaitingContinuation = true
                    SaveProductionProgress()
                    WPP:RefreshPanel()
                end)
            end
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        local wasCraftAll = craftAllState ~= nil
        if wasCraftAll then SaveProductionProgress() end
        processing = nil
        craftAllState = nil
        if wasCraftAll then
            Print("Crafting queue paused because production was interrupted or failed. Progress was saved.")
        end
        WPP:RefreshPanel()
    end
end)

SLASH_WIDERPROFESSIONSPLUS1 = "/wpp"
SLASH_WIDERPROFESSIONSPLUS2 = "/logiplan"
SlashCmdList.WIDERPROFESSIONSPLUS = function(msg)
    msg = string.lower(msg or "")
    if msg == "status" then
        local function Loaded(name)
            if C_AddOns and C_AddOns.IsAddOnLoaded then
                return C_AddOns.IsAddOnLoaded(name)
            elseif IsAddOnLoaded then
                return IsAddOnLoaded(name)
            end
            return nil
        end

        local function Info(name)
            if C_AddOns and C_AddOns.GetAddOnInfo then
                local info = C_AddOns.GetAddOnInfo(name)
                if type(info) == "table" then
                    return info.title or info.name or "found"
                end
            elseif GetAddOnInfo then
                local n, title = GetAddOnInfo(name)
                return title or n
            end
            return nil
        end

        Print("self-contained build loaded: true"
            .. "; frame: " .. tostring(_G.WiderProfessionsAddon ~= nil)
            .. "; profession UI: " .. tostring(CraftTradeSkillFrame ~= nil)
            .. "; auction module bridge: " .. tostring(
                _G.WiderProfessionsLogisticianBridge
                and _G.WiderProfessionsLogisticianBridge:IsAvailable()
            )
            .. "; Logistician version: " .. tostring(
                _G.WiderProfessionsLogisticianBridge
                and _G.WiderProfessionsLogisticianBridge:GetVersion()
                or "not loaded"
            ))
        return
    elseif msg == "shop" or msg == "shopping" then
        TogglePanel("shopping")
    elseif msg == "clear" then
        ClearQueue()
    else
        TogglePanel("queue")
    end
end
