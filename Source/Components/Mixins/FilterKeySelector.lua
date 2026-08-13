AuctionatorFilterKeySelectorMixin = {}

function AuctionatorFilterKeySelectorMixin:OnLoad()
  self.selectedCategories = {}
  self.onEntrySelected = function() end
  self.ResetButton:SetClickCallback(function()
    self:Reset()
  end)

  self.DropDown = CreateFrame("DropdownButton", nil, self, "WowStyle1DropdownTemplate")
  self.DropDown:SetPoint("TOPLEFT", 20, 0)
  self.DropDown:SetWidth(280)

  self.DropDown:SetupMenu(function(dropdown, rootDescription)
    self:InitializeLevels(rootDescription, 1, AuctionCategories)
  end)
  self:RefreshText()
end

function AuctionatorFilterKeySelectorMixin:GetValue()
  local values = {}
  for key in pairs(self.selectedCategories) do
    table.insert(values, key)
  end
  table.sort(values)
  return table.concat(values, "|")
end

function AuctionatorFilterKeySelectorMixin:SetValue(value)
  if value == nil then
    value = ""
  end

  self.selectedCategories = {}
  for key in string.gmatch(value, "[^|]+") do
    self.selectedCategories[key] = true
  end
  self.onEntrySelected(value)
  self:RefreshText()
  self.DropDown:GenerateMenu()
end

function AuctionatorFilterKeySelectorMixin:Reset()
  self.selectedCategories = {}
  self:RefreshText()
  self.DropDown:GenerateMenu()
  self.onEntrySelected("")
end

function AuctionatorFilterKeySelectorMixin:SetOnEntrySelected(callback)
  self.onEntrySelected = callback
end

function AuctionatorFilterKeySelectorMixin:EntrySelected(displayText)
  local prefix = displayText .. "/"
  local selectedInBranch = self.selectedCategories[displayText] ~= nil

  for selected in pairs(self.selectedCategories) do
    if string.sub(selected, 1, #prefix) == prefix then
      selectedInBranch = true
      break
    end
  end

  if selectedInBranch then
    -- Clicking a checked parent clears the whole branch. Clicking a checked
    -- leaf clears only that leaf.
    for selected in pairs(self.selectedCategories) do
      if selected == displayText or string.sub(selected, 1, #prefix) == prefix then
        self.selectedCategories[selected] = nil
      end
    end
  else
    -- A specific child supersedes a previously selected ancestor. This keeps
    -- the serialized filter precise instead of retaining a broader class too.
    for selected in pairs(self.selectedCategories) do
      local ancestorPrefix = selected .. "/"
      if string.sub(displayText, 1, #ancestorPrefix) == ancestorPrefix then
        self.selectedCategories[selected] = nil
      end
    end
    self.selectedCategories[displayText] = true
  end
  self.onEntrySelected(self:GetValue())
  self:RefreshText()
end

function AuctionatorFilterKeySelectorMixin:IsCategorySelected(key)
  if self.selectedCategories[key] then return true end

  -- A parent class reflects selections made below it. For example, selecting
  -- Bows and Crossbows checks Weapons while retaining the two precise filters.
  local prefix = key .. "/"
  for selected in pairs(self.selectedCategories) do
    if string.sub(selected, 1, #prefix) == prefix then
      return true
    end
  end
  return false
end

function AuctionatorFilterKeySelectorMixin:RefreshText()
  local count, only = 0, nil
  for key in pairs(self.selectedCategories) do
    count = count + 1
    only = key
  end
  local text = AUCTIONATOR_L_ANY_UPPER
  if count == 1 then
    text = only
  elseif count > 1 then
    text = tostring(count) .. " selected"
  end
  if self.DropDown.OverrideText then
    self.DropDown:OverrideText(text)
  end
end

function AuctionatorFilterKeySelectorMixin:InitializeLevels(rootDescription, level, allCategories, prefix)
  if allCategories == nil then
    return
  end

  prefix = prefix or ""

  for _, category in ipairs(allCategories) do 
    if not category:HasFlag("WOW_TOKEN_FLAG") and not category.implicitFilter then
      local key = prefix .. category.name
      -- Use a state-driven checkbox here instead of baking a checkbox texture
      -- into the label. TBC keeps active submenu descriptions alive during a
      -- refresh, while the selection callback is evaluated again immediately.
      local desc = rootDescription:CreateCheckbox(
        category.name,
        function() return self:IsCategorySelected(key) end,
        function() self:EntrySelected(key) end
      )
      -- SetResponse mutates the description but returns nil on the TBC client.
      -- Keep the original object so recursive subcategory construction has a
      -- valid parent description.
      desc:SetResponse(MenuResponse.Refresh)

      if category.subCategories ~= nil then
        local newPrefix = key .. "/"
        self:InitializeLevels(desc, level + 1, category.subCategories, newPrefix)
      end
    end
  end
end
