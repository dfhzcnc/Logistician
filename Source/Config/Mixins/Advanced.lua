LogisticianConfigAdvancedFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigAdvancedFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigAdvancedFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_ADVANCED_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

function LogisticianConfigAdvancedFrameMixin:ShowSettings()
  self.ReplicateScan:SetChecked(Logistician.Config.Get(Logistician.Config.Options.REPLICATE_SCAN))
  self.Debug:SetChecked(Logistician.Config.Get(Logistician.Config.Options.DEBUG))
end

function LogisticianConfigAdvancedFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigAdvancedFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.REPLICATE_SCAN, self.ReplicateScan:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.DEBUG, self.Debug:GetChecked())
end

function LogisticianConfigAdvancedFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigAdvancedFrameMixin:Cancel()")
end
