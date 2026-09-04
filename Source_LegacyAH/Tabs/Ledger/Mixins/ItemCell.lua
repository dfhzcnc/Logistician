-- Simpler icon+name cell than AuctionatorItemKeyCellTemplate: no atlas-based border, no
-- equipment-comparison/dress-up preview - just a plain icon texture + name, guaranteed to
-- render correctly regardless of which retail-only atlases exist on this client.
AuctionatorLedgerItemCellTemplateMixin = CreateFromMixins(AuctionatorCellMixin)

function AuctionatorLedgerItemCellTemplateMixin:Populate(rowData, index)
  AuctionatorCellMixin.Populate(self, rowData, index)

  self.Text:SetText(rowData.itemName or "")
  self.Text:SetTextColor(rowData.qualityR or 1, rowData.qualityG or 1, rowData.qualityB or 1)

  if rowData.iconTexture then
    self.Icon:SetTexture(rowData.iconTexture)
    self.Icon:Show()
  else
    self.Icon:Hide()
  end
end

function AuctionatorLedgerItemCellTemplateMixin:OnEnter()
  if self.rowData.itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.rowData.itemLink)
    GameTooltip:Show()
  end
  AuctionatorCellMixin.OnEnter(self)
end

function AuctionatorLedgerItemCellTemplateMixin:OnLeave()
  GameTooltip:Hide()
  AuctionatorCellMixin.OnLeave(self)
end
