local main = WiderProfessionsAddon
local isTooltipHooked = false

-- Recalculates the list of reagent names appearing in the favorites.
function main:UpdateFavoriteReagents()
    wipe(main.FavoriteReagents)

    for profession, favoriteSkills in pairs(WiderProfessions_DB.favorites) do
        for skillId, reagentNameList in pairs(favoriteSkills) do
            if type(reagentNameList) == "table" then -- In case of old version.
                for _, reagentName in ipairs(reagentNameList) do
                    main.FavoriteReagents[reagentName] = true
                end
            end
        end
    end
end

-- Versions before 1.10.1 didn't save reagent information, we overwrite that to ensure smooth transition to the new version.
function main:AddFavoriteEntry(profession, skillId, reagents)
    local reagentNameList = {}
    for _, reagent in pairs(reagents) do
        if reagent.name == nil then -- If item isn't cached we return, and it will be fixed the second time this is called.
            return
        end
        table.insert(reagentNameList, reagent.name)
    end
    WiderProfessions_DB.favorites[profession][skillId] = reagentNameList
end

function main:IsSkillFavorite(skillInfo)
    local professionFavorites = WiderProfessions_DB.favorites[skillInfo.profession]
    if professionFavorites == nil then return false end
    
    return professionFavorites[skillInfo.skillId] ~= nil
end

main.HookFavoriteTooltips = function()
    if not WiderProfessions_DB.showFavoriteTooltip or isTooltipHooked then return end

    isTooltipHooked = true -- Avoid hooking multiple if the option is toggled multiple times.

    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        if InCombatLockdown() then return end
        if WiderProfessions_DB.showFavoriteTooltip == false then
            return
        end
        local itemName = select(1, self:GetItem()) or "Error"
        if main.FavoriteReagents[itemName] == nil then return end

        GameTooltip:SetPadding(25, 0, 0, 0)
        TooltipFavoriteIcon:Show()
    end)

    GameTooltip:HookScript("OnTooltipCleared", function(self)
        TooltipFavoriteIcon:Hide()
        GameTooltip:SetPadding(0, 0, 0, 0)
    end)
end

function main:CreateFavoriteButton()
    CreateFrame("Button", "CraftTradeFavorite", CraftTradeReagentsInset)
    CraftTradeFavorite:SetSize(22, 22)

    -- Compact top-right controls:
    -- Favorite sits immediately left of the WPP launcher, keeping both
    -- controls out of the description/reagent content area.
    CraftTradeFavorite:SetPoint("TOPRIGHT", CraftTradeReagentsInset, "TOPRIGHT", -43, -11)
    CraftTradeFavorite:SetNormalTexture("Interface\\Common\\FavoritesIcon")
    CraftTradeFavorite:SetHighlightTexture("Interface\\Common\\FavoritesIcon", "ADD")
    -- Highlight texture alpha to 0.5
    CraftTradeFavorite:GetHighlightTexture():SetAlpha(0.4)
    CraftTradeFavorite:SetAlpha(0.5)
    CraftTradeFavorite:Hide()
    
    ----------- Tooltips
    local TooltipFavoriteIcon = GameTooltip:CreateTexture("TooltipFavoriteIcon", "OVERLAY")
    TooltipFavoriteIcon:SetSize(30, 30)
    TooltipFavoriteIcon:SetPoint("TOPRIGHT", 0, -5)
    TooltipFavoriteIcon:SetTexture("Interface\\Common\\FavoritesIcon")
    TooltipFavoriteIcon:SetAlpha(1)
    TooltipFavoriteIcon:Hide()

    main.FavoriteReagents = {}
    main:UpdateFavoriteReagents()
    main.HookFavoriteTooltips()
    -----------
    
    CraftTradeFavorite:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(BATTLE_PET_FAVORITE, 1, 1, 1)
        if C_CVar.GetCVarBool("showNewbieTips") == true then
            GameTooltip:AddLine(main.ClientLocale.FavoriteTooltip, nil, nil, nil, true)
        end
        GameTooltip:Show()

        self:SetAlpha(1)
    end)

    CraftTradeFavorite:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        -- Unhighlight the button
        local skill = main.selectedSkill
        if skill == nil then return end
        
        local favoriteTable = WiderProfessions_DB.favorites[skill.profession]
        if favoriteTable ~= nil and favoriteTable[skill.skillId] ~= nil then
            self:SetAlpha(1)
        else
            self:SetAlpha(0.5)
        end
    end)

    CraftTradeFavorite:SetScript("OnClick", function(self)
        local skill = main.selectedSkill
        local favoriteTable = WiderProfessions_DB.favorites[skill.profession]
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

        local entryAlreadyExists = favoriteTable[skill.skillId] ~= nil

        if entryAlreadyExists then
            favoriteTable[skill.skillId] = nil
            main:UpdateFavoriteReagents()
            self:SetAlpha(0.5)
        else
            if favoriteTable == nil then
                WiderProfessions_DB.favorites[skill.profession] = {}
            end

            self:SetAlpha(1)
            main:AddFavoriteEntry(skill.profession, skill.skillId, skill.reagents)
            main:UpdateFavoriteReagents()
        end

        -- Update the list to reflect the change in the headers.
        main:FetchSkillData()
        main:RefreshList()
    end)
end
