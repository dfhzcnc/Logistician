LogisticianShoppingTabSearchOptionsMixin = {}

function LogisticianShoppingTabSearchOptionsMixin:OnLoad()
  self.lastSearchTerm = ""

  self.AddToListButton:Disable()

  self.AddToListButton:SetScript("OnClick", function()
    if self.onAddToList then
      self.onAddToList(self:GetSearchTerm())
    end
  end)

  self.SearchButton:SetScript("OnClick", function()
    if self.onSearch then
      self.onSearch(self:GetSearchTerm())
    end
  end)

  self.MoreButton:SetScript("OnClick", function()
    if self.onMore then
      self.onMore(self:GetSearchTerm())
    end
  end)

  self.OptionsClearButton = CreateFrame("Button", nil, self.MoreButton, "LogisticianResetButton")
  self.OptionsClearButton:SetPoint("LEFT", 7, 0)
  self.OptionsClearButton:SetFrameLevel(self.MoreButton:GetFrameLevel() + 5)
  self.OptionsClearButton:SetScript("OnClick", function(button)
    self:ClearSearchTerm()
  end)
  self.OptionsClearButton:Hide()

  self:UpdateOptionsButton(false)

  Logistician.EventBus:Register(self, {
    Logistician.Shopping.Tab.Events.SearchStart,
    Logistician.Shopping.Tab.Events.SearchEnd,
  })

  -- Autocompletion with recents and shopping list terms for the search box
  self.SearchString:SetScript("OnTextChanged", function(editBox, isUserInput)
    self:UpdateNameClearButton()
    self:UpdateAddToListButton()
    if isUserInput and not editBox:IsInIMECompositionMode() then
      local current = editBox:GetText():lower()
      if current == "" or (editBox.prevCurrent ~= nil and #editBox.prevCurrent >= #current) then
        editBox.prevCurrent = current
        return
      end
      editBox.prevCurrent = current

      local function CompareSearch(toCompare)
        if toCompare:lower():sub(1, #current) == current then
          local split = Logistician.Search.SplitAdvancedSearch(toCompare)
          local searchString = split.searchString
          if split.isExact then
            searchString = "\"" .. searchString .. "\""
          end
          editBox:SetText(searchString)
          editBox:SetCursorPosition(#current)
          editBox:HighlightText(#current, #searchString)
          return true
        else
          return false
        end
      end

      for _, recent in ipairs(Logistician.Shopping.Recents.GetAll()) do
        if CompareSearch(recent) then
          return
        end
      end

      for i = 1, Logistician.Shopping.ListManager:GetCount() do
        local list = Logistician.Shopping.ListManager:GetByIndex(i)
        for j = 1, list:GetItemCount() do
          local search = list:GetItemByIndex(j)
          if CompareSearch(search) then
            return
          end
        end
      end
    end
  end)
  self:UpdateNameClearButton()
end

function LogisticianShoppingTabSearchOptionsMixin:UpdateNameClearButton()
  local enabled = not self.extendedOptionsActive and self.SearchString:GetText() ~= ""
  if enabled then
    self.ResetSearchStringButton:Enable()
    self.ResetSearchStringButton:SetAlpha(1)
  else
    self.ResetSearchStringButton:Disable()
    self.ResetSearchStringButton:SetAlpha(0.35)
  end
end

function LogisticianShoppingTabSearchOptionsMixin:UpdateAddToListButton()
  local parent = self:GetParent()
  local hasList = parent and parent.ListsContainer
    and parent.ListsContainer:GetExpandedList() ~= nil
  local hasSearch = self:GetSearchTerm() ~= ""
  if hasList and hasSearch then
    self.AddToListButton:Enable()
  else
    self.AddToListButton:Disable()
  end
end

local function TintButtonArtwork(frame, active)
  local regions = {frame:GetRegions()}
  for _, region in ipairs(regions) do
    if region:GetObjectType() == "Texture" then
      region:SetDesaturated(active)
      if active then
        -- A rich emerald metal tint: recognizable as an enabled/ready state
        -- in TBC without carrying the urgency of red or orange.
        region:SetVertexColor(0.42, 1, 0.5)
      else
        region:SetVertexColor(1, 1, 1)
      end
    end
  end

  local children = {frame:GetChildren()}
  for _, child in ipairs(children) do
    TintButtonArtwork(child, active)
  end
end

function LogisticianShoppingTabSearchOptionsMixin:UpdateOptionsButton(active)
  self.extendedOptionsActive = active
  self.MoreButton:SetText(active and "Edit Options" or LOGISTICIAN_L_SEARCH_OPTIONS)
  DynamicResizeButton_Resize(self.MoreButton)

  self.OptionsClearButton:SetShown(active)
  if active then
    self.SearchButton:SetText("Refresh")
  else
    self.SearchButton:SetText(LOGISTICIAN_L_SEARCH)
  end
  self:UpdateNameClearButton()
  DynamicResizeButton_Resize(self.SearchButton)

  -- WoW's edit-box Disable() only blocks input; it does not provide a strong
  -- disabled appearance. Fade the complete field and its label, while leaving
  -- the adjacent clear button bright and available.
  self.SearchString:SetAlpha(active and 0.35 or 1)
  if active then
    self.SearchLabel:SetTextColor(0.5, 0.5, 0.5)
  else
    self.SearchLabel:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  end

  -- Dynamic resize buttons use several regions and nested frame pieces. Tint
  -- all of them so none of the original red artwork remains visible.
  TintButtonArtwork(self.MoreButton, active)
  -- The nested clear control is intentionally red, both for contrast and to
  -- preserve WoW's familiar destructive/reset visual language.
  TintButtonArtwork(self.OptionsClearButton, false)
end

function LogisticianShoppingTabSearchOptionsMixin:ClearSearchTerm()
  self.lastSearchTerm = ""
  self.SearchString:Enable()
  self.SearchString:SetText("")
  self:UpdateOptionsButton(false)
end

function LogisticianShoppingTabSearchOptionsMixin:ReceiveEvent(eventName, ...)
  -- Change text to Cancel when a list search is ongoing and swap back to Search
  -- when the search is over
  if eventName == Logistician.Shopping.Tab.Events.SearchStart then
    self.SearchButton:SetText(LOGISTICIAN_L_CANCEL)
  elseif eventName == Logistician.Shopping.Tab.Events.SearchEnd then
    self.SearchButton:SetText(self.extendedOptionsActive and "Refresh" or LOGISTICIAN_L_SEARCH)
  end
  DynamicResizeButton_Resize(self.SearchButton)
end

function LogisticianShoppingTabSearchOptionsMixin:OnListExpanded()
  self:UpdateAddToListButton()
end

function LogisticianShoppingTabSearchOptionsMixin:OnListCollapsed()
  self.AddToListButton:Disable()
end

function LogisticianShoppingTabSearchOptionsMixin:SetOnAddToList(func)
  self.onAddToList = func
end

function LogisticianShoppingTabSearchOptionsMixin:SetOnSearch(func)
  self.onSearch = func
end

function LogisticianShoppingTabSearchOptionsMixin:SetOnMore(func)
  self.onMore = func
end

local function GetAppropriateText(searchTerm)
  local search = Logistician.Search.SplitAdvancedSearch(searchTerm)
  local newSearch = search.searchString
  for key, value in pairs(search) do
    if key == "isExact" then
      if value then
        newSearch = "\"" .. newSearch .. "\""
      end
    elseif key == "categoryKey" then
      if value ~= "" then
        return LOGISTICIAN_L_EXTENDED_SEARCH_ACTIVE_TEXT
      end
    elseif key ~= "searchString" then
      return LOGISTICIAN_L_EXTENDED_SEARCH_ACTIVE_TEXT
    end
  end
  return newSearch
end

function LogisticianShoppingTabSearchOptionsMixin:SetSearchTerm(searchTerm)
  self.lastSearchTerm = searchTerm
  local displayText = GetAppropriateText(searchTerm)
  local extendedActive = displayText == LOGISTICIAN_L_EXTENDED_SEARCH_ACTIVE_TEXT

  if extendedActive then
    self.SearchString:ClearFocus()
    self.SearchString:SetText("")
    self.SearchString:Disable()
  else
    self.SearchString:Enable()
    self.SearchString:SetText(displayText)
  end
  self:UpdateOptionsButton(extendedActive)
end

-- Used by modified item clicks. Bag links should behave like typing an item
-- name into the main Shopping field, never like loading an advanced query.
function LogisticianShoppingTabSearchOptionsMixin:SetPlainSearchText(text)
  self.lastSearchTerm = text or ""
  self.SearchString:Enable()
  self.SearchString:SetText(text or "")
  self.SearchString:SetFocus()
  self.SearchString:HighlightText()
  self:UpdateOptionsButton(false)
  self:UpdateAddToListButton()
end

function LogisticianShoppingTabSearchOptionsMixin:GetSearchTerm()
  if self.extendedOptionsActive then
    return self.lastSearchTerm
  end
  return self.SearchString:GetText()
end

function LogisticianShoppingTabSearchOptionsMixin:FocusSearchBox()
  if not self.extendedOptionsActive then
    self.SearchString:SetFocus()
  end
end
