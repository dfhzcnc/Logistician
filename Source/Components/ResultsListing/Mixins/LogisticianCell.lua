LogisticianCellMixin = {}

function LogisticianCellMixin:Populate(rowData, index)
  self.rowData = rowData
  self.index = index
end

function LogisticianCellMixin:OnEnter()
  if self:GetParent().OnEnter ~= nil then
    self:GetParent():OnEnter()
  end
end

function LogisticianCellMixin:OnLeave()
  if self:GetParent().OnLeave ~= nil then
    self:GetParent():OnLeave()
  end
end

function LogisticianCellMixin:OnClick(...)
  if self:GetParent().OnClick ~= nil then
    self:GetParent():OnClick(...)

    Logistician.Debug.Message("index", self.index)

  end
end
