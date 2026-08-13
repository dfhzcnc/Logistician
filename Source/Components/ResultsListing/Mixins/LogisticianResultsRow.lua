LogisticianResultsRowTemplateMixin = {}

function LogisticianResultsRowTemplateMixin:OnClick(...)
  Logistician.Debug.Message("LogisticianResultsRowTemplateMixin:OnClick()", ...)
end

function LogisticianResultsRowTemplateMixin:OnEnter(...)
  self.HighlightTexture:Show()
end

function LogisticianResultsRowTemplateMixin:OnLeave(...)
  self.HighlightTexture:Hide()
end

function LogisticianResultsRowTemplateMixin:Populate(rowData, dataIndex)
  self.rowData = rowData
  self.dataIndex = dataIndex
end