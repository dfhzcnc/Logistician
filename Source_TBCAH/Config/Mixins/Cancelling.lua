LogisticianConfigCancellingFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigCancellingFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigCancellingFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_CANCELLING_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

function LogisticianConfigCancellingFrameMixin:ShowSettings()
  self.UndercutItemsAhead:SetNumber(Logistician.Config.Get(Logistician.Config.Options.UNDERCUT_ITEMS_AHEAD))

  self.CancelUndercutShortcut:SetShortcut(Logistician.Config.Get(Logistician.Config.Options.CANCEL_UNDERCUT_SHORTCUT))
end

function LogisticianConfigCancellingFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigCancellingFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.UNDERCUT_ITEMS_AHEAD, math.min(self.UndercutItemsAhead:GetNumber(), 50))

  Logistician.Config.Set(Logistician.Config.Options.CANCEL_UNDERCUT_SHORTCUT, self.CancelUndercutShortcut:GetShortcut())
end

function LogisticianConfigCancellingFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigCancellingFrameMixin:Cancel()")
end
