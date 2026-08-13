local main = WiderProfessionsAddon

function main:AddSearchBar()
    CraftTradeSkillFrame.searchBar = CreateFrame("EditBox", "CraftTradeSkillFrameSearchBar", CraftTradeSkillFrame, "SearchBoxTemplate")
    CraftTradeSkillFrame.searchBar:SetSize(main.LIST_WIDTH-17, 20)
    CraftTradeSkillFrame.searchBar:SetPoint("TOPLEFT", CraftTradeListInset, "TOPLEFT", 9.5, -3)
    CraftTradeSkillFrame.searchBar:SetAutoFocus(false)
    CraftTradeSkillFrame.searchBar.Instructions:SetText(SEARCH)
    
    CraftTradeSkillFrame.searchBar:SetScript("OnTextChanged", function(self)
        -- This fires immediately when it first appears for whatever reason.
        local inputText = self:GetText()
        if inputText == "" then
            main:FetchSkillData()
            main:RefreshList()
            self.clearButton:Hide()
            return
        end
        
        self.clearButton:Show()
        main:FetchSkillData()
        main:RefreshList()
    end)

    CraftTradeSkillFrame:SetScript("OnMouseDown", function(self)
        if not CraftTradeSkillFrame.searchBar:HasFocus() then return end
        CraftTradeSkillFrame.searchBar:ClearFocus()
    end)

    CraftTradeSkillFrame.searchBar:SetScript("OnEscapePressed", CraftTradeSkillFrame.searchBar.ClearFocus)
    CraftTradeSkillFrame.searchBar:SetScript("OnEnterPressed", CraftTradeSkillFrame.searchBar.ClearFocus)

    CraftTradeSkillFrame.searchBar:SetScript("OnEditFocusLost", function(self)
        local inputText = self:GetText()
        if inputText == "" or string.match(inputText, "^%s*$") then
            self.Instructions:Show()
            self:SetText("")
        end

        self:HighlightText(0, 0)

        main:RefreshList()
    end)

    CraftTradeSkillFrame.searchBar:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
        self.Instructions:Hide()
    end)

    CraftTradeSkillFrame.searchBar.clearButton:HookScript("OnClick", function(self)
        CraftTradeSkillFrame.searchBar.Instructions:Show()
    end)

    CraftTradeSkillFrame:SetScript("OnMouseDown", function(self)
        CraftTradeSkillFrame.searchBar:ClearFocus()
    end)
end

function main:AddShowTrainCheckBox()
    local checkbox = CreateFrame("CheckButton", "ShowTrainTradeCrafts", CraftTradeSkillFrame, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)
    
    checkbox.text:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 20, -3.5)
    checkbox.text:SetText(main.ClientLocale.CanRankUp)
    checkbox.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
    local maxStringWidth = 110 -- To avoid pushing other buttons too far.
    checkbox.text:SetJustifyH("LEFT")
    if maxStringWidth < checkbox.text:GetStringWidth() then
        checkbox.text:SetWidth(min(checkbox.text:GetStringWidth(), maxStringWidth))
        checkbox.text:SetWordWrap(false)
    end
    checkbox:SetPoint("TOPRIGHT", CraftTradeSkillFrame, "TOPRIGHT", -checkbox.text:GetStringWidth() -15, -54)
    checkbox:SetChecked(false)

    checkbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end

        main:FetchSkillData()
        main:RefreshList()
    end)

    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(main.ClientLocale.CanRankUp, 1, 1, 1)
        if C_CVar.GetCVarBool("showNewbieTips") == true then
            GameTooltip:AddLine(main.ClientLocale.CanRankUpTooltip, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)

    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function main:AddShowNewPetSkillsCheckBox()
    local checkbox = CreateFrame("CheckButton", "ShowNewPetSkillsTradeCrafts", CraftTradeSkillFrame, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)
    
    checkbox.text:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 20, -3.5)
    checkbox.text:SetText(main.ClientLocale.petCanLearn)
    checkbox.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
    checkbox.text:SetJustifyH("LEFT")
    checkbox:SetPoint("TOPRIGHT", CraftTradeSkillFrame, "TOPRIGHT", -checkbox.text:GetStringWidth() -15, -55)
    checkbox:SetChecked(false)

    checkbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end
        
        main:FetchSkillData()
        main:RefreshList()
    end)

    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(main.ClientLocale.petCanLearn, 1, 1, 1)
        if C_CVar.GetCVarBool("showNewbieTips") == true then
            GameTooltip:AddLine(main.ClientLocale.petCanLearnTooltip, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)

    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end
