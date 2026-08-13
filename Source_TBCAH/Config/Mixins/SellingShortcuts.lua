LogisticianConfigSellingShortcutsFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigSellingShortcutsFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigSellingShortcutsFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_SELLING_SHORTCUTS_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

function LogisticianConfigSellingShortcutsFrameMixin:ShowSettings()
  self.BagSelectShortcut:SetValue(Logistician.Config.Get(Logistician.Config.Options.SELLING_BAG_SELECT_SHORTCUT))

  self.PostShortcut:SetShortcut(Logistician.Config.Get(Logistician.Config.Options.SELLING_POST_SHORTCUT))
  self.SkipShortcut:SetShortcut(Logistician.Config.Get(Logistician.Config.Options.SELLING_SKIP_SHORTCUT))
  self.PrevShortcut:SetShortcut(Logistician.Config.Get(Logistician.Config.Options.SELLING_PREV_SHORTCUT))
end

function LogisticianConfigSellingShortcutsFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigSellingShortcutsFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.SELLING_BAG_SELECT_SHORTCUT, self.BagSelectShortcut:GetValue())

  Logistician.Config.Set(Logistician.Config.Options.SELLING_POST_SHORTCUT, self.PostShortcut:GetShortcut())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_SKIP_SHORTCUT, self.SkipShortcut:GetShortcut())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_PREV_SHORTCUT, self.PrevShortcut:GetShortcut())
end

function LogisticianConfigSellingShortcutsFrameMixin:UnhideAllClicked()
  Logistician.Config.Set(Logistician.Config.Options.SELLING_IGNORED_KEYS, {})
  self.UnhideAll:Disable()
end

function LogisticianConfigSellingShortcutsFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigSellingShortcutsFrameMixin:Cancel()")
end
