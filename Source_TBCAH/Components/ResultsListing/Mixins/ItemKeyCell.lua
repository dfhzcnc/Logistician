LogisticianItemKeyCellTemplateMixin = CreateFromMixins(LogisticianCellMixin, LogisticianTBCImportTableBuilderCellMixin)

function LogisticianItemKeyCellTemplateMixin:Init()
  self.Text:SetJustifyH("LEFT")
end

function LogisticianItemKeyCellTemplateMixin:Populate(rowData, index)
  LogisticianCellMixin.Populate(self, rowData, index)

  self.Text:SetText(rowData.itemName or "")

  if rowData.iconTexture ~= nil then
    self.Icon:SetTexture(rowData.iconTexture)
    self.Icon:Show()
  end

  self.Icon:SetAlpha(rowData.noneAvailable and 0.5 or 1.0)
end

function LogisticianItemKeyCellTemplateMixin:OnEnter()
  if self.rowData.itemLink then
    GameTooltip:SetOwner(self:GetParent(), "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.rowData.itemLink)
    GameTooltip:Show()
  end
  LogisticianCellMixin.OnEnter(self)
end

function LogisticianItemKeyCellTemplateMixin:OnLeave()
  if self.rowData.itemLink then
    GameTooltip:Hide()
  end
  LogisticianCellMixin.OnLeave(self)
end
