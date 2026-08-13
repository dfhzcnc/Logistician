LogisticianConfigFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigFrameMixin:OnLoad()")

  -- Classic's Settings list does not consistently resolve a TOC IconTexture
  -- when the visible category name differs from the addon folder (!Logistician).
  -- Embed the texture in the label so the same Pack Kodo badge is always shown.
  self.name = "|TInterface\\AddOns\\!Logistician\\Images\\LogisticianIcon:18:18:0:0|t Logistician"
  self:SetParent(SettingsPanel)

  self:SetupPanel()
end

function LogisticianConfigFrameMixin:Show()

end

function LogisticianConfigFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigFrameMixin:Save()")
end

function LogisticianConfigFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigFrameMixin:Cancel()")
end
