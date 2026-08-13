LogisticianConfigTextInputMixin = {}

function LogisticianConfigTextInputMixin:OnLoad()
  Logistician.Debug.Message("HERE HERE HERE HERE HERE HERE HERE")
end

function LogisticianConfigTextInputMixin:OnMouseUp()
  self.InputBox:SetFocus()
end

function LogisticianConfigTextInputMixin:SetFocus()
  self.InputBox:SetFocus()
end

function LogisticianConfigTextInputMixin:SetText(value)
  self.InputBox:SetText(value)
  self.InputBox:SetCursorPosition(0)
end

function LogisticianConfigTextInputMixin:GetText()
  return self.InputBox:GetText()
end
