LogisticianConfigNumericInputMixin = {}

function LogisticianConfigNumericInputMixin:OnLoad()
  if self.labelText ~= nil then
    self.InputBox.Label:SetText(self.labelText)
  end
end

function LogisticianConfigNumericInputMixin:OnMouseUp()
  self.InputBox:SetFocus()
end

function LogisticianConfigNumericInputMixin:SetFocus()
  self.InputBox:SetFocus()
end

function LogisticianConfigNumericInputMixin:SetNumber(value)
  self.InputBox:SetNumber(value)
  self.InputBox:SetCursorPosition(0)
end

function LogisticianConfigNumericInputMixin:GetNumber(value)
  return self.InputBox:GetNumber(value)
end
