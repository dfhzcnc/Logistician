LogisticianConfigBasicOptionsFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigBasicOptionsFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigBasicOptionsFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_BASIC_OPTIONS_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

function LogisticianConfigBasicOptionsFrameMixin:ShowSettings()
  self.DefaultTab:SetValue(tostring(Logistician.Config.Get(Logistician.Config.Options.DEFAULT_TAB)))
  self.ShowCraftingInfo:SetChecked(Logistician.Config.Get(Logistician.Config.Options.CRAFTING_INFO_SHOW))
  self.ShowCraftingCost:SetChecked(Logistician.Config.Get(Logistician.Config.Options.CRAFTING_INFO_SHOW_COST))
  self.ShowCraftingProfit:SetChecked(Logistician.Config.Get(Logistician.Config.Options.CRAFTING_INFO_SHOW_PROFIT))
end

function LogisticianConfigBasicOptionsFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigBasicOptionsFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.DEFAULT_TAB, tonumber(self.DefaultTab:GetValue()))
  Logistician.Config.Set(Logistician.Config.Options.CRAFTING_INFO_SHOW, self.ShowCraftingInfo:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.CRAFTING_INFO_SHOW_COST, self.ShowCraftingCost:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.CRAFTING_INFO_SHOW_PROFIT, self.ShowCraftingProfit:GetChecked())
end

function LogisticianConfigBasicOptionsFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigBasicOptionsFrameMixin:Cancel()")
end
