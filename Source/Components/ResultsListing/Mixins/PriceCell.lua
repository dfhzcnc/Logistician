AuctionatorPriceCellTemplateMixin = CreateFromMixins(AuctionatorCellMixin, AuctionatorRetailImportTableBuilderCellMixin)

function AuctionatorPriceCellTemplateMixin:Init(columnName)
  self.columnName = columnName
end

function AuctionatorPriceCellTemplateMixin:Populate(rowData, index)
  AuctionatorCellMixin.Populate(self, rowData, index)

  local isHistoryRow = rowData.rawDay ~= nil
  local isUnitPriceColumn = self.columnName == "minSeen" or self.columnName == "price"

  if isHistoryRow then
    self.MoneyDisplay:SetFontObject("GameFontHighlight")
  else
    self.MoneyDisplay:SetFontObject("GameFontHighlightSmall")
  end

  if self.MoneyDisplay.SilverDisplay then
    self.MoneyDisplay.SilverDisplay:SetShowsZeroAmount(not (isHistoryRow and isUnitPriceColumn))
  end

  if rowData[self.columnName] ~= nil then
    self.MoneyDisplay:SetAmount(rowData[self.columnName])
    self.MoneyDisplay:Show()
  else
    self.MoneyDisplay:Hide()
  end
end
