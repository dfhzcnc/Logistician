LogisticianConfigMinMaxMixin = {}

function LogisticianConfigMinMaxMixin:OnLoad()
  self.onTabOut = function() end
  self.onEnter = function() end

  if self.titleText ~= nil then
    self.Title:SetText(self.titleText)
  end

  self.ResetButton:SetClickCallback(function()
    self:Reset()
  end)
end

function LogisticianConfigMinMaxMixin:SetFocus()
  self.MinBox:SetFocus()
end

function LogisticianConfigMinMaxMixin:SetCallbacks(callbacks)
  self.onTabOut = callbacks.OnTab or function() end
  self.onEnter = callbacks.OnEnter or function() end
end

function LogisticianConfigMinMaxMixin:OnEnterPressed()
  self.onEnter()
end

function LogisticianConfigMinMaxMixin:MinTabPressed()
  self.MaxBox:SetFocus()
end

function LogisticianConfigMinMaxMixin:MaxTabPressed()
  self.onTabOut()
end

function LogisticianConfigMinMaxMixin:GetMin()
  return self.MinBox:GetNumber()
end

function LogisticianConfigMinMaxMixin:GetMax()
  return self.MaxBox:GetNumber()
end

function LogisticianConfigMinMaxMixin:SetMin(value)
  if value == nil then
    self.MinBox:SetText("")
  else
    self.MinBox:SetNumber(value)
  end
end

function LogisticianConfigMinMaxMixin:SetMax(value)
  if value == nil then
    self.MaxBox:SetText("")
  else
    self.MaxBox:SetNumber(value)
  end
end

function LogisticianConfigMinMaxMixin:Reset()
  self.MinBox:SetText("")
  self.MaxBox:SetText("")
end
