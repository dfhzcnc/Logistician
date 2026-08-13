local main = WiderProfessionsAddon
local playerLocale = GetLocale() or "enUS"
local ALCHEMY_NAME = GetSpellInfo(2259) -- Alchemy spell id
local COOKING_NAME = GetSpellInfo(2550) -- Cooking spell id
local buildVersion = select(4, GetBuildInfo())
local NEW_WORD = string.lower(NEW)
local USE_WORD = USE_COLON.. " "
local USE_WORD_SIZE = string.len(USE_WORD)
local EQUIP_WORD = ITEM_SPELL_TRIGGER_ONEQUIP.. " "
local EQUIP_WORD_SIZE = string.len(EQUIP_WORD)
local REQUIRES_WORD = string.gsub(ERR_USE_LOCKED_WITH_ITEM_S, "%%s", "")
local qualityTextLower = {}
for index = 0, 5 do
    local qualityName = _G["ITEM_QUALITY".. index.. "_DESC"]
    qualityTextLower[index] = string.lower(qualityName)
end

local function renameTransmuteSkill(skillName)
    local transmuteString = {
        ["enUS"] = "Transmute: ",
        ["deDE"] = "Transmutieren: ",
        ["frFR"] = "Transmutation : ",
        ["esES"] = "Transmutar: ",
        ["esMX"] = "Transmutar: ",
        ["ruRU"] = "Трансмутация ",
    }

    -- Remove the transmute prefix from the skill name if it exists.
    local displayName = string.gsub(skillName, transmuteString[playerLocale], "")
    if displayName == skillName then
        return skillName
    end

    -- If it's spanish or mexican, capitalize the first letter of what remains
    if playerLocale == "esES" or playerLocale == "esMX" then
        displayName = string.upper(string.sub(displayName, 1, 1)).. string.sub(displayName, 2)
    end
    return displayName
end

function main:FetchTradeSkills(filterWord)
    local skillInfoDict = {}
    local headersList = {}

    local showOnlyTrain = ShowTrainTradeCrafts:GetChecked()
    local selectedExists = false

    local profession = select(1, GetTradeSkillLine())
    local recentHeader = nil
    local mustUpdateFavoritesDueToOldVersionConversion = false
    local shouldInitializeOldSkills = WiderProfessions_DB.openedAddonFirstTimeForProfession[profession] == nil
    if shouldInitializeOldSkills then
        WiderProfessions_DB.openedAddonFirstTimeForProfession[profession] = 0
    end

    for index = 1, GetNumTradeSkills() do
        local skillName, rankEfficiencyOrHeader, numAvailable, isExpanded = GetTradeSkillInfo(index)
        local displayName = skillName
        local skillDescription = GetTradeSkillDescription(index) -- [string|nil]
        local searchableDescription = ""
        local texture = GetTradeSkillIcon(index)

        WiderProfessionsSpellReadingTooltip:SetOwner(CraftTradeDetailIcon, "ANCHOR_NONE")
        WiderProfessionsSpellReadingTooltip:SetTradeSkillItem(index)
        WiderProfessionsSpellReadingTooltip:Show()
        local maxLines = WiderProfessionsSpellReadingTooltip:NumLines()
        if skillDescription == nil and WiderProfessions_DB.showAllItemDescriptions then
            if maxLines > 1 then
                local text = _G["WiderProfessionsSpellReadingTooltipTextLeft".. maxLines]:GetText()
                local textColorR = _G["WiderProfessionsSpellReadingTooltipTextLeft".. maxLines]:GetTextColor()
                if textColorR == 0 and skillDescription == nil then
                    skillDescription = text
                    -- Remove USE_WORD from the begining of the text if present.
                    if string.sub(skillDescription, 1, USE_WORD_SIZE) == USE_WORD then
                        skillDescription = string.sub(skillDescription, USE_WORD_SIZE + 1)
                    elseif string.sub(skillDescription, 1, EQUIP_WORD_SIZE) == EQUIP_WORD then
                        skillDescription = string.sub(skillDescription, EQUIP_WORD_SIZE + 1)
                    end
                end
            end
        end
        searchableDescription = skillDescription or ""
        for i = 3, maxLines - 1 do
            local lineL = _G["WiderProfessionsSpellReadingTooltipTextLeft"..i]
            if lineL ~= nil and lineL:GetText() ~= nil then
                if not string.find(lineL:GetText(), REQUIRES_WORD) then
                    searchableDescription = searchableDescription.. " ".. lineL:GetText()
                end
            end
        end
        WiderProfessionsSpellReadingTooltip:Hide()
        
        if rankEfficiencyOrHeader == "header" or rankEfficiencyOrHeader == nil then
            recentHeader = skillName
            -- Also expand the header if it is not expanded.
            if not isExpanded then
                ExpandTradeSkillSubClass(index)
            end
        end
        local skillType = recentHeader
        if skillType == nil then return skillInfoDict, headersList end
        
        local failedTrainedFilter = showOnlyTrain and rankEfficiencyOrHeader == "trivial"-- or (not main.canRankUp and WiderProfessions_DB.skillColorMode ~= 0))

        if rankEfficiencyOrHeader ~= "header" and not failedTrainedFilter then
            local skillLink = GetTradeSkillItemLink(index) --or ""
            local _, _, itemQuality, _, _, _, _, _, _, _, vendorProfit = GetItemInfo(skillLink) -- I call it itemName, but I guess its just skillName.
            local minProduced, maxProduced = GetTradeSkillNumMade(index)
            vendorProfit = vendorProfit * (minProduced + maxProduced) / 2 -- Average profit if there is a range.
            local skillId = nil
            if buildVersion >= 40000 then
                skillLink = skillLink or GetTradeSkillRecipeLink(index)
                skillId = string.match(skillLink, "item:(%d+)") or string.match(skillLink, "enchant:(%d+)")
                displayName, _ = main:FindEnchantType(skillName, skillLink)
            else
                skillId = string.match(skillLink, "item:(%d+)") -- I call it skillID, but I guess its just createdItemID.
            end
            if shouldInitializeOldSkills and skillId then
                WiderProfessions_DB.knownTradeskills[skillId] = 0
            end

            if profession == ALCHEMY_NAME then
                if WiderProfessions_DB.showAlchemyCategories then--and skillType == "Consumable" then
                    skillType = main.alchemyCategoryMap[skillName] or skillType
                end
                displayName = renameTransmuteSkill(skillName)
            elseif profession == COOKING_NAME and WiderProfessions_DB.showCookingCategories then
                skillType = main.cookingCategoryMap[skillId] or MINIMAP_TRACKING_VENDOR_FOOD
            end
            
            local rarityColor = "|c7c7c7c7c"
            if WiderProfessions_DB.skillColorMode == 2 and (itemQuality ~= nill and itemQuality > 1) then
                rarityColor = ITEM_QUALITY_COLORS[itemQuality > 1 and itemQuality or 0].hex
            end

            local reagents = {}
            for reagentIndex = 1, GetTradeSkillNumReagents(index) do
                local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(index, reagentIndex)
                local reagentLink = GetTradeSkillReagentItemLink(index, reagentIndex)
                vendorProfit = vendorProfit - (select(11, GetItemInfo(reagentLink)) or 0) * reagentCount
                table.insert(reagents, {name = reagentName, link = reagentLink, icon = reagentTexture, count = reagentCount, playerCount = playerReagentCount})
            end

            local hasPassedFilter = true
            if filterWord then
                hasPassedFilter = string.find(string.lower(skillName), filterWord)
                if filterWord == NEW_WORD then
                    hasPassedFilter = hasPassedFilter or WiderProfessions_DB.knownTradeskills[skillId] == nil
                end
                hasPassedFilter = hasPassedFilter or string.find(qualityTextLower[itemQuality], filterWord)
                hasPassedFilter = hasPassedFilter or string.find(string.lower(skillType), filterWord)
                hasPassedFilter = hasPassedFilter or string.find(string.lower(searchableDescription), filterWord)
                for _, reagent in ipairs(reagents) do
                    if reagent.name == nil then
                        hasPassedFilter = false
                    else
                        hasPassedFilter = hasPassedFilter or string.find(string.lower(reagent.name), filterWord)
                    end
                end
            end

            if hasPassedFilter then

                if WiderProfessions_DB.favorites[profession] == nil then
                    WiderProfessions_DB.favorites[profession] = {}
                end

                local favoriteEntry = WiderProfessions_DB.favorites[profession][skillId]
                if favoriteEntry ~= nil then
                    skillType = FAVORITES
                    if type(favoriteEntry) ~= "table" then
                        mustUpdateFavoritesDueToOldVersionConversion = true
                        main:AddFavoriteEntry(profession, skillId, reagents)
                    end
                end

                if skillInfoDict[skillType] == nil then
                    skillInfoDict[skillType] = {}
                    
                    table.insert(headersList, skillType)
                end
                
                table.insert(skillInfoDict[skillType], {
                    name = skillName,
                    displayName = displayName,
                    description = skillDescription,
                    texture = texture,
                    link = skillLink,
                    rarityColor = rarityColor,
                    -- rarity = itemQuality,
                    rankEfficiency = rankEfficiencyOrHeader,
                    numAvailable = numAvailable,
                    reagents = reagents,
                    category = skillType,
                    index = index, -- The index of the craft at the original window.
                    position = #skillInfoDict[skillType] +1,
                    profession = profession,
                    skillId = skillId,
                    minProduced = minProduced,
                    maxProduced = maxProduced,
                    vendorProfit = vendorProfit,
                })

                -- If there are multiple ways to create an items, then this breaks...
                if main.selectedSkill and main.selectedSkill.skillId == skillId then
                    selectedExists = true
                end
            end
        end
    end

    if not selectedExists then
        main:CleanSkillDetails()
    end

    if mustUpdateFavoritesDueToOldVersionConversion then
        main:UpdateFavoriteReagents()
    end
    return skillInfoDict, headersList
end

main.TRADE_SKILL_SHOW = function(self, event, ...)
    if CraftFrame and CraftFrame:IsVisible() then main.ForceCRAFT_CLOSE() end
    ShowTrainTradeCrafts:Show()
    ShowNewPetSkillsTradeCrafts:Hide()
    -- Reset filters when opening the profession window.
    SetTradeSkillSubClassFilter(0, true)
    SetTradeSkillInvSlotFilter(0, true)

    main:CleanSkillDetails()
    main:CleanStolenButtons()
    main:CleanOriginalFrameAttributes()

    main:HideOriginalCraftFrame("TradeSkillFrame")
    
    ShowUIPanel(CraftTradeSkillFrame)
    main:HideOriginalFrames()
    
    local name, rank, maxRank = GetTradeSkillLine()
    main.canRankUp = rank < maxRank
    main.windowType = "TradeSkill"

    main:StealButton(TradeSkillCreateButton)

    TradeSkillIncrementButton:SetParent(CraftTradeSkillFrame)
    TradeSkillIncrementButton:SetPoint("BOTTOMRIGHT", TradeSkillCreateButton, "BOTTOMRIGHT", -10, 0)

    TradeSkillInputBox:ClearAllPoints()
    TradeSkillInputBox:SetParent(CraftTradeSkillFrame)
    TradeSkillInputBox:SetPoint("RIGHT", TradeSkillCreateButton, "LEFT", -28, 0)
    TradeSkillDecrementButton:ClearAllPoints()
    TradeSkillDecrementButton:SetParent(CraftTradeSkillFrame)
    TradeSkillDecrementButton:SetPoint("RIGHT", TradeSkillCreateButton, "LEFT", -65, 0)

    TradeSkillCreateAllButton:SetParent(CraftTradeSkillFrame)
    TradeSkillCreateAllButton:SetPoint("RIGHT", TradeSkillCreateButton, "LEFT", -90, 0)
    CraftTradeDetailReagents:SetText(MINIMAP_TRACKING_VENDOR_REAGENT.. ":")

    TradeSkillRankBar.Text:SetText(rank.. "/".. maxRank)
    TradeSkillRankBar:SetMinMaxValues(0, maxRank)
    TradeSkillRankBar:SetValue(rank)
    
    if TradeSkillInvSlotDropdown then
        TradeSkillInvSlotDropdown:SetParent(CraftTradeSkillFrame)
        TradeSkillInvSlotDropdown:ClearAllPoints()
        TradeSkillInvSlotDropdown:SetPoint("RIGHT", ShowTrainTradeCrafts, "LEFT", -5, 2)
        TradeSkillInvSlotDropdown:SetScale(0.96)
        TradeSkillInvSlotDropdown:Show()
    end
    if TradeSkillSubClassDropdown then
        TradeSkillSubClassDropdown:SetParent(CraftTradeSkillFrame)
        TradeSkillSubClassDropdown:ClearAllPoints()
        TradeSkillSubClassDropdown:SetPoint("RIGHT", TradeSkillInvSlotDropdown, "LEFT", -5, 0)
        TradeSkillSubClassDropdown:SetScale(0.96)
        TradeSkillSubClassDropdown:Show()
    end
    
    CraftTradeSkillFrame.TitleText:SetText(name)
    local texture = select(3, GetSpellInfo(name))
    -- I think this localization mess is fixed in TBC onwards.
    if name == "Secourisme" then -- In French, First Aid is "Secourisme", but spell is "Premiers soins".
        texture = 135966
    elseif name == "Ingénierie" then -- In French, Engineering is "Ingénierie" but spell is "Ingénieur".
        texture = 136243
    elseif name == "Marroquinería" then -- In Spanish, Leatherworking is "Peletería" but spell is "Marroquinería".
        texture = 133611
    elseif name == "Costura" then -- In Spanish, Tailoring is called "Sastrería" but the spell name is "Costura".
        texture = 136249
    end

    if texture ~= nil then
        CraftTradeSkillFrame:SetPortraitTextureRaw(texture)
    else
        CraftTradeSkillFrame:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Book_09")
    end

    main:CRAFT_TRADE_UPDATE()

    main:RegisterEvent("TRADE_SKILL_UPDATE")
end

main.TRADE_SKILL_UPDATE = main.CRAFT_TRADE_UPDATE
main.TRADE_SKILL_CLOSE = function() main.CRAFT_TRADE_CLOSE() main:UnregisterEvent("TRADE_SKILL_UPDATE") end
main.ForceTRADE_SKILL_CLOSE = function()
    -- This is to avoid running main.CRAFT_TRADE_CLOSE() and simply close the window.
    main:UnregisterEvent("TRADE_SKILL_CLOSE")
    main:UnregisterEvent("TRADE_SKILL_UPDATE")
    
    HideUIPanel(TradeSkillFrame)
    C_Timer.After(0.1, function() -- Wait a frame to ensure the event unregistration is processed.
        main:RegisterEvent("TRADE_SKILL_CLOSE")
    end)
end

main:RegisterEvent("TRADE_SKILL_SHOW")
main:RegisterEvent("TRADE_SKILL_CLOSE")
