LogisticianPriceCellTemplateMixin = CreateFromMixins(LogisticianCellMixin, LogisticianTBCImportTableBuilderCellMixin)

function LogisticianPriceCellTemplateMixin:Init(columnName)
  self.columnName = columnName
end

function LogisticianPriceCellTemplateMixin:Populate(rowData, index)
  LogisticianCellMixin.Populate(self, rowData, index)

  if rowData[self.columnName] ~= nil then
    self.MoneyDisplay:SetAmount(rowData[self.columnName])
    self.MoneyDisplay:Show()
  else
    self.MoneyDisplay:Hide()
  end
end
