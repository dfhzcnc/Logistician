local main = WiderProfessionsAddon

function main:CreateInfoTooltipButton()
    -- WPP 0.1.9 removes the visible Information button. Wider Professions
    -- still references InfoButton in a few code paths, so retain a hidden
    -- compatibility frame rather than changing unrelated base logic.
    InfoButton = CreateFrame("Button", "CraftTradeInfoButton", CraftTradeReagentsInset)
    InfoButton:SetSize(1, 1)
    InfoButton:SetPoint("TOPRIGHT", CraftTradeReagentsInset, "TOPRIGHT", 0, 0)
    InfoButton:Hide()

    function InfoButton:SetShownByOption(show)
        self:Hide()
    end

    -- Keep the tooltip object for the existing crafted-count bookkeeping code,
    -- but there is no visible control which opens it.
    InfoTooltip = CreateFrame("GameTooltip", "WiderProfessionsInfoTooltip", nil, "GameTooltipTemplate")
    InfoTooltip:Hide()
end

function UpdateInfoTooltip()
    if main.selectedSkill == nil then return end
    
    InfoTooltip:SetOwner(InfoButton, "ANCHOR_RIGHT")
    InfoTooltip:AddLine(main.ClientLocale.InfoButtonTitle, 1, 1, 1)
    local profit = main.selectedSkill.vendorProfit or 0
    if profit > 0 then
        InfoTooltip:AddDoubleLine(main.ClientLocale.InfoButtonVendorProfit.. ":", "|cffffffff".. GetCoinTextureString(profit).. "|r", nil, nil, nil, "RIGHT")
    elseif profit < 0 then
        InfoTooltip:AddDoubleLine(main.ClientLocale.InfoButtonVendorLoss.. ":", "|cffff0000".. GetCoinTextureString(-profit).. "|r", nil, nil, nil, "RIGHT")
    end
    -- Add crafted times info.
    local craftedTimes = WiderProfessions_DB.knownTradeskills[main.selectedSkill.skillId] or 0
    InfoTooltip:AddDoubleLine(main.ClientLocale.InfoButtonCrafted.. ":", "|cffffffff".. craftedTimes.. "|r", nil, nil, nil, "RIGHT")
    InfoTooltip:Show()
end


main.lastCastedSpellGUID = nil
main:RegisterEvent("UNIT_SPELLCAST_START")
main.UNIT_SPELLCAST_START = function(self, event, unitTarget, castGUID, spellID)
    if unitTarget ~= "player" then return end
    if not select(6, UnitCastingInfo("player")) then return end -- IsTradeSkill, doesn't recognise enchanting...

    main.lastCastedSpellGUID = castGUID
end

main:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
main.UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitTarget, castGUID, spellID)
    if unitTarget ~= "player" then return end
    if castGUID == nil or castGUID ~= main.lastCastedSpellGUID then return end
    main.lastCastedSpellGUID = nil

    local spellName = GetSpellInfo(spellID)
    local itemID = select(1, GetItemInfoInstant(spellName))
    -- Log Item.
    if itemID ~= nil then
        -- LogItem
        logCraftedItem(itemID)
        return
    end
    -- Wait 1 second, try again. if it's still nil, give up.
    C_Timer.After(1.5, function()
        itemID = select(1, GetItemInfoInstant(spellName))
        if itemID == nil then return end
        logCraftedItem(itemID)
    end)

    
end

function logCraftedItem(itemID)
    local itemID = tostring(itemID)
    local entry = WiderProfessions_DB.knownTradeskills[itemID]
    if entry == nil then
        WiderProfessions_DB.knownTradeskills[itemID] = 1
    else
        WiderProfessions_DB.knownTradeskills[itemID] = entry +1
    end

    if InfoTooltip:IsShown() then
        UpdateInfoTooltip()
    end
end
