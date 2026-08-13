LogisticianDropDownMixin = {}

local ARRAY_DELIMITER = ";"
local function splitStrArray(arrayString)
  return {strsplit(ARRAY_DELIMITER, arrayString)}
end

local function localizeArray(array)
  for index, itm in ipairs(array) do
    array[index] = Logistician.Locales.Apply(itm)
  end

  return array
end

function LogisticianDropDownMixin:OnLoad()
  self.onValueChanged = function() end
  if self.textString ~= nil and self.valuesString ~= nil then
    self:InitAgain(
      localizeArray(splitStrArray(self.textString)),
      splitStrArray(self.valuesString)
    )
  end
  self.DropDown:SetWidth(180)

  if self.labelText ~= nil then
    self.Label:SetText(self.labelText)
  end
end

function LogisticianDropDownMixin:InitAgain(labels, values)
  local entries = {}
  for index = 1, #labels do
    table.insert(entries, {labels[index], values[index]})
  end
  self.value = values[1]
  MenuUtil.CreateRadioMenu(self.DropDown, function(value)
    return value == self.value
  end, function(value)
    self.value = value
    self.onValueChanged()
  end, unpack(entries))
end

-- Checkbox-based variant used by fields that allow several simultaneous
-- filters (for example Shopping rarity). Values are stored as a lookup table.
function LogisticianDropDownMixin:InitMulti(labels, values, anyLabel)
  self.multiLabels = labels
  self.multiValues = values
  self.multiAnyLabel = anyLabel or LOGISTICIAN_L_ANY_UPPER
  self.values = self.values or {}

  self.DropDown:SetupMenu(function(dropdown, rootDescription)
    for index, value in ipairs(self.multiValues) do
      local label = self.multiLabels[index]
      local checked = self.values[value] == true
      local box = checked
        and "|TInterface\\Buttons\\UI-CheckBox-Check:18:18:0:0|t "
        or "|TInterface\\Buttons\\UI-CheckBox-Up:18:18:0:0|t "
      rootDescription:CreateButton(box .. label, function()
        self.values[value] = not self.values[value]
        self:RefreshMultiText()
        self.onValueChanged()
      end):SetResponse(MenuResponse.Refresh)
    end
  end)
  self:RefreshMultiText()
end

function LogisticianDropDownMixin:RefreshMultiText()
  if not self.multiValues then return end
  local labels = {}
  for index, value in ipairs(self.multiValues) do
    if self.values[value] then
      table.insert(labels, self.multiLabels[index])
    end
  end
  local text
  if #labels == 0 then
    text = self.multiAnyLabel
  elseif #labels == 1 then
    text = labels[1]
  else
    text = tostring(#labels) .. " selected"
  end
  if self.DropDown.OverrideText then
    self.DropDown:OverrideText(text)
  end
  self.DropDown:GenerateMenu()
end

function LogisticianDropDownMixin:SetValues(values)
  self.values = {}
  for _, value in ipairs(values or {}) do
    self.values[tostring(value)] = true
  end
  self:RefreshMultiText()
  self.onValueChanged()
end

function LogisticianDropDownMixin:GetValues()
  local result = {}
  for _, value in ipairs(self.multiValues or {}) do
    if self.values[value] then
      table.insert(result, value)
    end
  end
  return result
end

function LogisticianDropDownMixin:SetValue(...)
  self.value = ...
  self.DropDown:GenerateMenu()
  self.onValueChanged()
end

function LogisticianDropDownMixin:SetOnValueChanged(callback)
  self.onValueChanged = callback or function() end
end

function LogisticianDropDownMixin:GetValue(...)
  return self.value
end
