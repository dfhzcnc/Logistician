LogisticianBuyAuctionsResultsRowMixin = CreateFromMixins(LogisticianResultsRowTemplateMixin)

function LogisticianBuyAuctionsResultsRowMixin:Populate(...)
  LogisticianResultsRowTemplateMixin.Populate(self, ...)

  self.SelectedHighlight:SetShown(self.rowData.isSelected)
  self:SetAlpha(self.rowData.numStacks == 0 and 0.5 or 1.0)
end

function LogisticianBuyAuctionsResultsRowMixin:OnEnter()
  if not self.rowData.itemLink then
    return
  end

  if not self.rowData.notReady then
    LogisticianResultsRowTemplateMixin.OnEnter(self)
  end
  if Logistician.Utilities.IsEquipment(select(6, C_Item.GetItemInfoInstant(self.rowData.itemLink))) then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.rowData.itemLink)
    GameTooltip:Show()
  end
end

function LogisticianBuyAuctionsResultsRowMixin:OnLeave()
  if not self.rowData or not self.rowData.notReady then
    LogisticianResultsRowTemplateMixin.OnLeave(self)
  end
  GameTooltip:Hide()
end

function LogisticianBuyAuctionsResultsRowMixin:OnClick(button, ...)
  Logistician.Debug.Message("LogisticianBuyAuctionsResultsRowMixin:OnClick()")

  if self.rowData.numStacks < 1 or self.rowData.stackPrice == nil or self.rowData.notReady then
    return
  end
  self.rowData.isSelected = not self.rowData.isSelected

  if self.rowData.isSelected then
    Logistician.EventBus
      :RegisterSource(self, "BuyAuctionResultsRow")
      :Fire(self, Logistician.Buying.Events.AuctionFocussed, self.rowData)
      :UnregisterSource(self)
  else
    Logistician.EventBus
      :RegisterSource(self, "BuyAuctionResultsRow")
      :Fire(self, Logistician.Buying.Events.AuctionFocussed, nil)
      :UnregisterSource(self)
  end
end
