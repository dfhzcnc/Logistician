-- Unit Price cell that swaps its displayed value to the total sale price while hovered.
AuctionatorLedgerUnitPriceCellTemplateMixin = CreateFromMixins(AuctionatorPriceCellTemplateMixin)

function AuctionatorLedgerUnitPriceCellTemplateMixin:Populate(rowData, index)
  AuctionatorPriceCellTemplateMixin.Populate(self, rowData, index)
  self.unitPrice = rowData.unitPrice
  self.totalPrice = rowData.totalPrice
  self.PulseAnim:Stop()
  self.TotalLabel:Hide()
end

function AuctionatorLedgerUnitPriceCellTemplateMixin:OnEnter()
  if self.totalPrice ~= nil then
    self.MoneyDisplay:SetAmount(self.totalPrice)
    self.TotalLabel:Show()
    self.PulseAnim:Play()
  end
  AuctionatorPriceCellTemplateMixin.OnEnter(self)
end

function AuctionatorLedgerUnitPriceCellTemplateMixin:OnLeave()
  self.PulseAnim:Stop()
  self.TotalLabel:Hide()
  self.TotalLabel:SetAlpha(1)
  if self.unitPrice ~= nil then
    self.MoneyDisplay:SetAmount(self.unitPrice)
  end
  AuctionatorPriceCellTemplateMixin.OnLeave(self)
end
