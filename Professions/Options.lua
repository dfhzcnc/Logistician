local main = WiderProfessionsAddon
local ALCHEMY_NAME = GetSpellInfo(2259) or "Alchemy" -- Alchemy spell id
local COOKING_NAME = GetSpellInfo(2550) or "Cooking" -- Cooking spell id
local ENCHANTING_NAME = GetSpellInfo(7412) or "Enchanting" -- Enchanting spell id
local PET_TRAINING_NAME = GetSpellInfo(5149) or "Beast Training" -- Beast Training spell id
local buildVersion = select(4, GetBuildInfo())

local defaultVariables = {
    favorites = {},
    favoriteMaterials = {},
    knownTradeskills = {},
    openedAddonFirstTimeForProfession = {}, -- This is used to initialize old skills so that they dont count as new.
    petFamiliesTrained = {},
    showAlchemyCategories = true,
    showCookingCategories = true,
    showEnchantingCategories = true,
    showPetCategories = true,
    skillColorMode = 0, -- vanilla, plus, plusRarity
    canDragFrame = false,
    showAlternateRanks = true,
    sortRoguePoisons = false,
    windowScale = 100,
    showHeaderTooltip = true,
    showFavoriteTooltip = true,
    showInformationButton = true,
    showAllItemDescriptions = true,
    maxSkillsShown = 16
}

function main:GetDefaultVariables()
    return defaultVariables
end

function main:CreateSettingsFrame()
    local category, layout
    if Auctionator
        and Auctionator.State
        and Auctionator.State.OptionsCategory
        and Settings.RegisterVerticalLayoutSubcategory then
        category, layout = Settings.RegisterVerticalLayoutSubcategory(
            Auctionator.State.OptionsCategory,
            "Professions & Skills"
        )
    else
        category, layout = Settings.RegisterVerticalLayoutCategory("Logistician - Professions & Skills")
    end

    local function createCheckBox(text, variableName, tooltipText, callback)
        local variableKey = variableName
        local defaultValue = defaultVariables[variableName]

        local setting = Settings.RegisterAddOnSetting(category, variableName, variableKey, WiderProfessions_DB, type(defaultValue), text, defaultValue)

        Settings.CreateCheckbox(category, setting, tooltipText)

        if callback == nil then return end
        setting:SetValueChangedCallback(callback)
    end

    local function createSlider(text, variableName, tooltipText, minValue, maxValue, step, callback)
        local defaultValue = defaultVariables[variableName]

        local function GetValue()
            return WiderProfessions_DB[variableName] or defaultValue
        end

        local function SetValue(value)
            WiderProfessions_DB[variableName] = value
        end

        local setting = Settings.RegisterProxySetting(category, variableName, type(defaultValue), text, defaultValue, GetValue, SetValue)

        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, setting, options, tooltipText)

        if callback == nil then return end
        setting:SetValueChangedCallback(callback)
    end

    if buildVersion < 40000 then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(main.ClientLocale.AdditionalCategories, main.ClientLocale.AdditionalCategoriesTooltip))
        createCheckBox(ALCHEMY_NAME, "showAlchemyCategories", main.ClientLocale.AddAlchemyTooltip)
        createCheckBox(COOKING_NAME, "showCookingCategories", main.ClientLocale.AddCookingTooltip)
        createCheckBox(ENCHANTING_NAME, "showEnchantingCategories", main.ClientLocale.AddEnchantingTooltip)
        createCheckBox(PET_TRAINING_NAME, "showPetCategories", main.ClientLocale.AddPetsTooltip)

        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(BINDING_HEADER_MISC))

        do
            local setting = Settings.RegisterAddOnSetting(category, "skillColorMode", "skillColorMode", WiderProfessions_DB, Settings.VarType.Number, main.ClientLocale.skillColor, 0)
            local function GetOptions()
                local container = Settings.CreateControlTextContainer();
                container:Add(0, main.ClientLocale.skillColor_Vanilla, main.ClientLocale.skillColor_VanillaTooltip);
                container:Add(1, main.ClientLocale.skillColor_Plus, main.ClientLocale.skillColor_PlusTooltip);
                container:Add(2, main.ClientLocale.skillColor_PlusRarity, main.ClientLocale.skillColor_PlusRarityTooltip);
                return container:GetData();
            end
            Settings.CreateDropdown(category, setting, GetOptions, main.ClientLocale.skillColorTooltip)
        end

        createCheckBox(main.ClientLocale.ShowAlternateRanks, "showAlternateRanks", main.ClientLocale.ShowAlternateRanksTooltip)
        createCheckBox(main.ClientLocale.ShowAllItemDescriptions, "showAllItemDescriptions", main.ClientLocale.ShowAllItemDescriptionsTooltip)
        createCheckBox(main.ClientLocale.SortPoisons, "sortRoguePoisons", main.ClientLocale.SortPoisonsTooltip)
    else
        WiderProfessions_DB.showAlchemyCategories = false
        WiderProfessions_DB.showCookingCategories = false
        WiderProfessions_DB.showEnchantingCategories = false
        WiderProfessions_DB.showPetCategories = false

        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(BINDING_HEADER_MISC))

        do
            local setting = Settings.RegisterAddOnSetting(category, "skillColorMode", "skillColorMode", WiderProfessions_DB, Settings.VarType.Number, main.ClientLocale.skillColor, 0)
            local function GetOptions()
                local container = Settings.CreateControlTextContainer();
                container:Add(0, main.ClientLocale.skillColor_Vanilla, main.ClientLocale.skillColor_VanillaTooltip);
                container:Add(1, main.ClientLocale.skillColor_Plus, main.ClientLocale.skillColor_PlusTooltip);
                container:Add(2, main.ClientLocale.skillColor_PlusRarity, main.ClientLocale.skillColor_PlusRarityTooltip);
                return container:GetData();
            end
            Settings.CreateDropdown(category, setting, GetOptions, main.ClientLocale.skillColorTooltip)
        end
    end
    
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(INTERFACE_LABEL))
    createCheckBox(main.ClientLocale.ShowFavoriteTooltip, "showFavoriteTooltip", main.ClientLocale.ShowFavoriteTooltipTooltip, main.HookFavoriteTooltips)
    createCheckBox(main.ClientLocale.ShowInformationButton, "showInformationButton", main.ClientLocale.ShowInformationButtonTooltip)
    createCheckBox(main.ClientLocale.ShowHeaderTooltip, "showHeaderTooltip", main.ClientLocale.ShowHeaderTooltipTooltip)
    createCheckBox(UNLOCK_FRAME, "canDragFrame", main.ClientLocale.CanDragFrameTooltip)
    createSlider(main.ClientLocale.MaxSkillsShown, "maxSkillsShown", main.ClientLocale.MaxSkillsShownTooltip, 16, 22, 1)
    createSlider(main.ClientLocale.WindowScale, "windowScale", main.ClientLocale.WindowScaleTooltip, 50, 300, 5, function(self, value)
        CraftTradeSkillFrame:SetScale(value/100)
        CraftTradeSkillFrame:Show()
    end)

    Settings.RegisterAddOnCategory(category)
end
