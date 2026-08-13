LogisticianConfigRadioButtonGroupMixin = {}

function LogisticianConfigRadioButtonGroupMixin:InitializeRadioButtonGroup()
  Logistician.Debug.Message("LogisticianConfigRadioButtonGroupMixin:InitializeRadioButtonGroup()")

  if self.groupHeadingText ~= nil then
    self.GroupHeading.subHeadingText = self.groupHeadingText
    self.GroupHeading:InitializeSubHeading()
  end

  self.radioButtons = {}
  self:SetupRadioButtons()
  self.radioButtonGroupOnChangeEvent = function() end
  self:Show()
end

function LogisticianConfigRadioButtonGroupMixin:SetupRadioButtons()
  local children = { self:GetChildren() }
  local size = 0

  for _, child in ipairs(children) do
    if child.isLogisticianRadio then
      table.insert(self.radioButtons, child)

      child:SetPoint("TOPLEFT", 0, size * -1)
      child.RadioButton.Label:SetPoint("TOPLEFT", 20, -2)

      child.onSelectedCallback = function()
        self:RadioSelected(child)
      end
    end

    size = size + (child:GetHeight() or 20)
  end

  -- 8 is for bottom padding
  self:SetHeight(size + 8)
end

function LogisticianConfigRadioButtonGroupMixin:SetSelectedValue(value)
  self.selectedValue = value
  self:Refresh()
end

function LogisticianConfigRadioButtonGroupMixin:SetOnChange(callback)
  self.radioButtonGroupOnChangeEvent = callback
end

function LogisticianConfigRadioButtonGroupMixin:RadioSelected(radio)
  self.selectedValue = radio:GetValue()
  self.radioButtonGroupOnChangeEvent(self.selectedValue)

  self:Refresh()
end

function LogisticianConfigRadioButtonGroupMixin:Refresh()
  Logistician.Debug.Message("LogisticianConfigRadioButtonGroupMixin:Refresh()", self.selectedValue)

  for _, button in ipairs(self.radioButtons) do
    button:SetChecked(button:GetValue() == self.selectedValue)
  end
end

function LogisticianConfigRadioButtonGroupMixin:GetValue()
  return self.selectedValue
end
