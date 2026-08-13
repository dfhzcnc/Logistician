LogisticianConfigProfileFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigProfileFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigProfileFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_PROFILE_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

function LogisticianConfigProfileFrameMixin:ShowSettings()
  self.ProfileToggle:SetChecked(Logistician.Config.IsCharacterConfig())
end

function LogisticianConfigProfileFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigProfileFrameMixin:Save()")

  Logistician.Config.SetCharacterConfig(self.ProfileToggle:GetChecked())
end

function LogisticianConfigProfileFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigProfileFrameMixin:Cancel()")
end
