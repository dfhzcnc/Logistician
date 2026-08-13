LogisticianConfigCheckboxMixin = {}

function LogisticianConfigCheckboxMixin:OnLoad()
  if self.labelText ~= nil then
    self.CheckBox.Label:SetText(self.labelText)
  end
end

function LogisticianConfigCheckboxMixin:SetText(text)
  self.labelText = text
  self.CheckBox.Label:SetText(self.labelText)
end

function LogisticianConfigCheckboxMixin:GetText()
  return self.CheckBox.Label:GetText()
end

function LogisticianConfigCheckboxMixin:SetChecked(value)
  self.CheckBox:SetChecked(value)
end

-- Makes clicking on the text flip the toggle
function LogisticianConfigCheckboxMixin:OnMouseUp()
  self.CheckBox:Click()
end

function LogisticianConfigCheckboxMixin:OnEnter()
  self.CheckBox:LockHighlight()

  LogisticianConfigTooltipMixin.OnEnter(self)
end

function LogisticianConfigCheckboxMixin:OnLeave()
  self.CheckBox:UnlockHighlight()

  LogisticianConfigTooltipMixin.OnLeave(self)
end

function LogisticianConfigCheckboxMixin:GetChecked()
  return self.CheckBox:GetChecked()
end
