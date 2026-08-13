LogisticianConfigTooltipsFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigTooltipsFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigTooltipsFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_TOOLTIPS_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

function LogisticianConfigTooltipsFrameMixin:ShowSettings()
  self.MailboxTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.MAILBOX_TOOLTIPS))
  self.VendorTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.VENDOR_TOOLTIPS))
  self.AuctionTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.AUCTION_TOOLTIPS))
  self.EnchantTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.ENCHANT_TOOLTIPS))
  self.ProspectTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.PROSPECT_TOOLTIPS))
  self.MillTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.MILL_TOOLTIPS))
  self.ShiftStackTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SHIFT_STACK_TOOLTIPS))
  self.AuctionAgeTooltips:SetChecked(Logistician.Config.Get(Logistician.Config.Options.AUCTION_AGE_TOOLTIPS))
end

function LogisticianConfigTooltipsFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigTooltipsFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.MAILBOX_TOOLTIPS, self.MailboxTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.VENDOR_TOOLTIPS, self.VendorTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.AUCTION_TOOLTIPS, self.AuctionTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.ENCHANT_TOOLTIPS, self.EnchantTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.PROSPECT_TOOLTIPS, self.ProspectTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.MILL_TOOLTIPS, self.MillTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SHIFT_STACK_TOOLTIPS, self.ShiftStackTooltips:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.AUCTION_AGE_TOOLTIPS, self.AuctionAgeTooltips:GetChecked())
end

function LogisticianConfigTooltipsFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigTooltipsFrameMixin:Cancel()")
end
