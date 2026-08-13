AuctionatorConfigFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:OnLoad()")

  -- Classic's Settings list does not consistently resolve a TOC IconTexture
  -- when the visible category name differs from the addon folder (!Logistician).
  -- Embed the texture in the label so the same Pack Kodo badge is always shown.
  self.name = "|TInterface\\AddOns\\!Logistician\\Images\\LogisticianIcon:18:18:0:0|t Logistician"
  self:SetParent(SettingsPanel)

  self:SetupPanel()
end

function AuctionatorConfigFrameMixin:Show()

end

function AuctionatorConfigFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:Save()")
end

function AuctionatorConfigFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:Cancel()")
end
