LogisticianConfigRadioButtonMixin = {}

function LogisticianConfigRadioButtonMixin:OnLoad()
  -- This field is used by the RadioButtonGroup to ensure that the UI child it is positioning
  -- is an logistician radio button
  self.isLogisticianRadio = true

  if self.value == nil then
    error("A value is required for the radio button.")
  end

  if self.labelText ~= nil then
    self.RadioButton.Label:SetText(self.labelText)
  end
end

function LogisticianConfigRadioButtonMixin:OnMouseUp()
  self.RadioButton:Click()
end

function LogisticianConfigRadioButtonMixin:OnEnter()
  self.RadioButton:LockHighlight()
end

function LogisticianConfigRadioButtonMixin:OnLeave()
  self.RadioButton:UnlockHighlight()
end

function LogisticianConfigRadioButtonMixin:SetChecked(value)
  self.RadioButton:SetChecked(value)
end

function LogisticianConfigRadioButtonMixin:GetChecked()
  return self.RadioButton:GetChecked()
end

function LogisticianConfigRadioButtonMixin:GetValue()
  return self.value
end

function LogisticianConfigRadioButtonMixin:OnClick()
  if self.onSelectedCallback ~= nil then
    self.onSelectedCallback()
  end
end
