local main = WiderProfessionsAddon
local isTooltipHooked = false
local favoriteBagButtons = setmetatable({}, { __mode = "k" })
local bagnoniumHooked = false

local function IsFavoriteItemID(itemID)
    return itemID ~= nil
        and WiderProfessions_DB ~= nil
        and type(WiderProfessions_DB.favoriteMaterials) == "table"
        and WiderProfessions_DB.favoriteMaterials[tostring(itemID)] ~= nil
end

local function UpdateBagFavoriteMarker(button, itemID)
    if not button then return end

    if not button.LogisticianFavoriteMaterialIcon then
        local marker = button:CreateTexture(nil, "OVERLAY", nil, 7)
        -- FavoritesIcon has transparent padding around the visible star, so
        -- use a larger texture and a slight negative offset to keep the gold
        -- star itself compactly seated in the slot's bottom-left corner.
        marker:SetSize(26, 26)
        marker:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -4, -4)
        marker:SetTexture("Interface\\Common\\FavoritesIcon")
        marker:SetVertexColor(1, 1, 1, 1)
        button.LogisticianFavoriteMaterialIcon = marker
    end

    button.LogisticianFavoriteMaterialItemID = itemID
    button.LogisticianFavoriteMaterialIcon:SetShown(IsFavoriteItemID(itemID))
    favoriteBagButtons[button] = true
end

function main:RefreshMaterialFavoriteMarkers()
    for button in pairs(favoriteBagButtons) do
        UpdateBagFavoriteMarker(button, button.LogisticianFavoriteMaterialItemID)
    end
end

local function GetBlizzardBagButtonItemID(button)
    local bag = button.GetBagID and button:GetBagID()
        or (button:GetParent() and button:GetParent():GetID())
    local slot = button.GetID and button:GetID()
    if bag == nil or slot == nil then return nil end

    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    end
    return GetContainerItemID and GetContainerItemID(bag, slot)
end

local function HookBagDisplays()
    if ContainerFrameItemButton_Update and not main.blizzardBagFavoriteHooked then
        main.blizzardBagFavoriteHooked = true
        hooksecurefunc("ContainerFrameItemButton_Update", function(button)
            UpdateBagFavoriteMarker(button, GetBlizzardBagButtonItemID(button))
        end)
    end

    local bagAddon = Bagnonium or BagBrother
    if not bagnoniumHooked and bagAddon and bagAddon.ContainerItem then
        bagnoniumHooked = true
        hooksecurefunc(bagAddon.ContainerItem, "Update", function(button)
            local info = button.info
            UpdateBagFavoriteMarker(button, info and info.itemID)
        end)
    end
end

local bagHookEvents = CreateFrame("Frame")
bagHookEvents:RegisterEvent("PLAYER_LOGIN")
bagHookEvents:RegisterEvent("ADDON_LOADED")
bagHookEvents:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" or addonName == "BagBrother" or addonName == "Bagnonium" then
        HookBagDisplays()
    end
end)

local function MaterialKey(reagent)
    if not reagent then return nil end

    local itemID = tonumber(reagent.itemID)
    if reagent.link then
        local getItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        if not itemID and getItemInfoInstant then
            itemID = getItemInfoInstant(reagent.link)
        end
    end
    if itemID then return tostring(itemID) end
    if reagent.name then return "name:" .. string.lower(reagent.name) end
end

local function FavoriteMaterialRecord(reagent)
    local key = MaterialKey(reagent)
    if not key then return nil end

    local itemID = tonumber(key)
    local name = reagent.name
    local link = reagent.link
    local icon = reagent.icon
    if itemID then
        local cachedName, cachedLink, _, _, _, _, _, _, _, cachedIcon = GetItemInfo(itemID)
        name = name or cachedName
        link = link or cachedLink
        icon = icon or cachedIcon
        if not icon and GetItemIcon then icon = GetItemIcon(itemID) end
    end

    return {
        key = key,
        itemID = itemID or tonumber(reagent.itemID),
        name = name or UNKNOWN,
        link = link,
        icon = icon,
    }
end

function main:IsMaterialFavorite(reagent)
    local key = MaterialKey(reagent)
    return key ~= nil
        and type(WiderProfessions_DB.favoriteMaterials) == "table"
        and WiderProfessions_DB.favoriteMaterials[key] ~= nil
end

function main:ToggleMaterialFavorite(reagent)
    WiderProfessions_DB.favoriteMaterials = WiderProfessions_DB.favoriteMaterials or {}
    local key = MaterialKey(reagent)
    if not key then return false end

    if WiderProfessions_DB.favoriteMaterials[key] ~= nil then
        WiderProfessions_DB.favoriteMaterials[key] = nil
    else
        -- Store enough information to render the Favorites view immediately,
        -- while still retaining the numeric item key for bag-slot markers.
        WiderProfessions_DB.favoriteMaterials[key] = FavoriteMaterialRecord(reagent)
    end
    main:UpdateFavoriteReagents()
    main:RefreshMaterialFavoriteMarkers()
    if WiderProfessionsPlusController and WiderProfessionsPlusController.RefreshPanel then
        WiderProfessionsPlusController:RefreshPanel()
    end
    return main:IsMaterialFavorite(reagent)
end

function main:GetFavoriteMaterials()
    local materials = {}
    for key, saved in pairs(WiderProfessions_DB.favoriteMaterials or {}) do
        local record
        if type(saved) == "table" then
            record = FavoriteMaterialRecord({
                itemID = saved.itemID or tonumber(key),
                name = saved.name,
                link = saved.link,
                icon = saved.icon,
            })
            -- Legacy or uncached records may need their ID restored from the
            -- saved table key rather than from an item link.
            if record and not record.itemID and tonumber(key) then
                local itemID = tonumber(key)
                local name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                record.key = key
                record.itemID = itemID
                record.name = name or saved.name or UNKNOWN
                record.link = link or saved.link
                record.icon = icon or saved.icon or (GetItemIcon and GetItemIcon(itemID))
            end
        else
            local itemID = tonumber(key)
            local name, link, _, _, _, _, _, _, _, icon
            if itemID then name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemID) end
            record = {
                key = key,
                itemID = itemID,
                name = name or (type(saved) == "string" and saved) or UNKNOWN,
                link = link,
                icon = icon or (itemID and GetItemIcon and GetItemIcon(itemID)),
            }
        end
        if record then table.insert(materials, record) end
    end

    table.sort(materials, function(a, b)
        local aName = string.lower(a.name or "")
        local bName = string.lower(b.name or "")
        if aName == bName then return tostring(a.key or "") < tostring(b.key or "") end
        return aName < bName
    end)
    return materials
end

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

    for _, saved in pairs(WiderProfessions_DB.favoriteMaterials or {}) do
        local reagentName = type(saved) == "table" and saved.name or saved
        if type(reagentName) == "string" then
            main.FavoriteReagents[reagentName] = true
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

    -- The queue launcher now lives beside Add, leaving Favorite as the sole
    -- compact control in the recipe header.
    CraftTradeFavorite:SetPoint("TOPRIGHT", CraftTradeReagentsInset, "TOPRIGHT", -11, -11)
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
