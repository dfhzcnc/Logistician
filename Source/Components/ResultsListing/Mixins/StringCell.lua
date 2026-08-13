LogisticianStringCellTemplateMixin = CreateFromMixins(LogisticianCellMixin, LogisticianTBCImportTableBuilderCellMixin)

function LogisticianStringCellTemplateMixin:Init(columnName, fontObjectName)
  self.columnName = columnName

  self.text:SetJustifyH("LEFT")
  if fontObjectName ~= nil and _G[fontObjectName] ~= nil then
    self.text:SetFontObject(_G[fontObjectName])
  end
end

function LogisticianStringCellTemplateMixin:Populate(rowData, index)
  LogisticianCellMixin.Populate(self, rowData, index)

  self.text:SetText(rowData[self.columnName])
end

function LogisticianStringCellTemplateMixin:OnHide()
  self.text:Hide()
end

function LogisticianStringCellTemplateMixin:OnShow()
  self.text:Show()
end
