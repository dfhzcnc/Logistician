AuctionatorShoppingItemMixin = CreateFromMixins(AuctionatorEscapeToCloseMixin)

local NO_QUALITY = ""

local function SetResetEnabled(button, enabled)
  if enabled then
    button:Enable()
    button:SetAlpha(1)
  else
    button:Disable()
    button:SetAlpha(0.35)
  end
end

local function InitializeQualityDropDown(dropDown)
  local qualityStrings = {}
  local qualityIDs = {}

  for _, quality in ipairs(Auctionator.Constants.QualityIDs) do
    table.insert(qualityStrings, Auctionator.Utilities.CreateColoredQuality(quality))
    table.insert(qualityIDs, tostring(quality))
  end
  dropDown:InitMulti(qualityStrings, qualityIDs, AUCTIONATOR_L_ANY_UPPER)
end

local function InitializeTierDropDown(dropDown)
  local tierStrings = {}
  local tierIDs = {}

  table.insert(tierStrings, AUCTIONATOR_L_ANY_UPPER)
  table.insert(tierIDs, NO_QUALITY)

  if Auctionator.Constants.IsRetail then
    for tier = 1, 2 do
      table.insert(tierStrings, CreateAtlasMarkup("Professions-ChatIcon-Quality-12-Tier" .. tier) .. "/" .. CreateAtlasMarkup("Professions-Icon-Quality-Tier" .. tier .. "-Small", 17, 17))
      table.insert(tierIDs, tostring(tier))
    end
    do
      table.insert(tierStrings, CreateAtlasMarkup("Professions-Icon-Quality-Tier" .. 3 .. "-Small", 17, 17))
      table.insert(tierIDs, tostring(3))
    end
  end

  dropDown:InitAgain(tierStrings, tierIDs)
end

local function InitializeExpansionDropDown(dropDown)
  local expansionStrings = {}
  local expansionIDs = {}

  table.insert(expansionStrings, AUCTIONATOR_L_ANY_UPPER)
  table.insert(expansionIDs, NO_QUALITY)

  for i = 0, LE_EXPANSION_LEVEL_CURRENT do
    local name = _G["EXPANSION_NAME" .. i]

    table.insert(expansionStrings, name)
    table.insert(expansionIDs, tostring(i))
  end

  dropDown:InitAgain(expansionStrings, expansionIDs)
end

function AuctionatorShoppingItemMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  local _, rt, rp, ox, oy = self.Inset:GetPointByName("TOPLEFT")
  self.Inset:SetPoint("TOPLEFT", rt, rp, ox, -25)
  self.onFinishedClicked = function() end

  self.SearchContainer.ResetSearchStringButton:SetClickCallback(function()
    self.SearchContainer.SearchString:SetText("")
  end)

  self.QualityContainer.ResetQualityButton:SetClickCallback(function()
    self.QualityContainer.DropDown:SetValues({})
  end)

  self.TierContainer.ResetTierButton:SetClickCallback(function()
    self.TierContainer.DropDown:SetValue(NO_QUALITY)
  end)

  self.ExpansionContainer.ResetExpansionButton:SetClickCallback(function()
    self.ExpansionContainer.DropDown:SetValue(NO_QUALITY)
  end)

  local onEnterCallback = function()
    self:OnFinishedClicked()
  end

  self.LevelRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.ItemLevelRange:SetFocus()
    end
  })

  self.ItemLevelRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.PriceRange:SetFocus()
    end
  })

  self.PriceRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.CraftedLevelRange:SetFocus()
    end
  })

  self.CraftedLevelRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.SearchContainer.SearchString:SetFocus()
    end
  })

  InitializeExpansionDropDown(self.ExpansionContainer.DropDown)
  InitializeQualityDropDown(self.QualityContainer.DropDown)
  InitializeTierDropDown(self.TierContainer.DropDown)

  local update = function()
    self:UpdateResetStates()
  end
  self.SearchContainer.SearchString:HookScript("OnTextChanged", update)
  self.SearchContainer.IsExact:HookScript("OnClick", update)
  for _, range in ipairs({self.LevelRange, self.ItemLevelRange, self.PriceRange, self.CraftedLevelRange}) do
    range.MinBox:HookScript("OnTextChanged", update)
    range.MaxBox:HookScript("OnTextChanged", update)
  end
  self.PurchaseQuantity.InputBox:HookScript("OnTextChanged", update)
  self.FilterKeySelector:SetOnEntrySelected(update)
  self.QualityContainer.DropDown:SetOnValueChanged(update)
  self.ExpansionContainer.DropDown:SetOnValueChanged(update)
  self.TierContainer.DropDown:SetOnValueChanged(update)

  if Auctionator.Constants.IsRetail then
    self:SetHeight(470)
    self.TierContainer:Show()
    self.ExpansionContainer:Show()
  else
    self:SetHeight(390)
    self.TierContainer:Hide()
    self.ExpansionContainer:Hide()
  end

  Auctionator.EventBus:Register(self, {
    Auctionator.Shopping.Tab.Events.ListSearchStarted,
    Auctionator.Shopping.Tab.Events.ListSearchEnded
  })
end

function AuctionatorShoppingItemMixin:UpdateResetStates()
  local searchSet = self.SearchContainer.SearchString:GetText() ~= ""
  local classSet = self.FilterKeySelector:GetValue() ~= ""
  local levelSet = self.LevelRange.MinBox:GetText() ~= "" or self.LevelRange.MaxBox:GetText() ~= ""
  local itemLevelSet = self.ItemLevelRange.MinBox:GetText() ~= "" or self.ItemLevelRange.MaxBox:GetText() ~= ""
  local priceSet = self.PriceRange.MinBox:GetText() ~= "" or self.PriceRange.MaxBox:GetText() ~= ""
  local craftedSet = self.CraftedLevelRange.MinBox:GetText() ~= "" or self.CraftedLevelRange.MaxBox:GetText() ~= ""
  local qualitySet = #self.QualityContainer.DropDown:GetValues() > 0
  local expansionSet = self.ExpansionContainer.DropDown:GetValue() ~= NO_QUALITY
  local tierSet = self.TierContainer.DropDown:GetValue() ~= NO_QUALITY
  local quantitySet = self.PurchaseQuantity:GetNumber() > 0

  SetResetEnabled(self.SearchContainer.ResetSearchStringButton, searchSet)
  SetResetEnabled(self.FilterKeySelector.ResetButton, classSet)
  SetResetEnabled(self.LevelRange.ResetButton, levelSet)
  SetResetEnabled(self.ItemLevelRange.ResetButton, itemLevelSet)
  SetResetEnabled(self.PriceRange.ResetButton, priceSet)
  SetResetEnabled(self.CraftedLevelRange.ResetButton, craftedSet)
  SetResetEnabled(self.QualityContainer.ResetQualityButton, qualitySet)
  SetResetEnabled(self.ExpansionContainer.ResetExpansionButton, expansionSet)
  SetResetEnabled(self.TierContainer.ResetTierButton, tierSet)

  local anySet = searchSet or self.SearchContainer.IsExact:GetChecked() or classSet
    or levelSet or itemLevelSet or priceSet or craftedSet or qualitySet
    or expansionSet or tierSet or quantitySet
  SetResetEnabled(self.ResetAllButton, anySet)

  if self.requireChange then
    local changed = self.originalItemString ~= nil
      and self:GetItemString() ~= self.originalItemString
    if changed and not self.searchInProgress then
      self.Finished:Enable()
    else
      self.Finished:Disable()
    end
  end
end

function AuctionatorShoppingItemMixin:Init(title, finishedButtonText, requireChange)
  self:SetTitle(title)
  self.Finished:SetText(finishedButtonText)
  DynamicResizeButton_Resize(self.Finished)
  self.requireChange = requireChange == true
  self.originalItemString = nil
  self.searchInProgress = false
  if self.requireChange then
    self.Finished:Disable()
  else
    self.Finished:Enable()
  end
end

function AuctionatorShoppingItemMixin:OnShow()
  self:ResetAll()
  self.SearchContainer.SearchString:SetFocus()

  Auctionator.EventBus
    :RegisterSource(self, "add item dialog")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function AuctionatorShoppingItemMixin:OnHide()
  self:Hide()

  Auctionator.EventBus
    :RegisterSource(self, "add item dialog")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function AuctionatorShoppingItemMixin:OnCancelClicked()
  self:Hide()
end

function AuctionatorShoppingItemMixin:SetOnFinishedClicked(callback)
  self.onFinishedClicked = callback
end

function AuctionatorShoppingItemMixin:OnFinishedClicked()
  if not self.Finished:IsEnabled() then
    return
  end

  self:Hide()

  if self:HasItemInfo() then
    self.onFinishedClicked(self:GetItemString())
  else
    Auctionator.Utilities.Message(AUCTIONATOR_L_NO_ITEM_INFO_SPECIFIED)
  end
end

function AuctionatorShoppingItemMixin:HasItemInfo()
  return
    self:GetItemString()
      :gsub(Auctionator.Constants.AdvancedSearchDivider, "")
      :gsub("\"", "")
      :len() > 0
end

function AuctionatorShoppingItemMixin:GetItemString()
  local search = {
    searchString = self.SearchContainer.SearchString:GetText(),
    isExact = self.SearchContainer.IsExact:GetChecked(),
    categoryKey = self.FilterKeySelector:GetValue(),
    minLevel = self.LevelRange:GetMin(),
    maxLevel = self.LevelRange:GetMax(),
    minItemLevel = self.ItemLevelRange:GetMin(),
    maxItemLevel = self.ItemLevelRange:GetMax(),
    minCraftedLevel = self.CraftedLevelRange:GetMin(),
    maxCraftedLevel = self.CraftedLevelRange:GetMax(),
    minPrice = self.PriceRange:GetMin() * 10000,
    maxPrice = self.PriceRange:GetMax() * 10000,
    expansion = tonumber(self.ExpansionContainer.DropDown:GetValue()),
    qualities = self.QualityContainer.DropDown:GetValues(),
    tier = tonumber(self.TierContainer.DropDown:GetValue()),
    quantity = tonumber(self.PurchaseQuantity:GetNumber()),
  }
  
  return Auctionator.Search.ReconstituteAdvancedSearch(search)
end

function AuctionatorShoppingItemMixin:SetItemString(itemString)
  local search = Auctionator.Search.SplitAdvancedSearch(itemString)

  self.SearchContainer.IsExact:SetChecked(search.isExact)
  self.SearchContainer.SearchString:SetText(search.searchString)

  self.FilterKeySelector:SetValue(search.categoryKey)

  self.ItemLevelRange:SetMin(search.minItemLevel)
  self.ItemLevelRange:SetMax(search.maxItemLevel)

  self.LevelRange:SetMin(search.minLevel)
  self.LevelRange:SetMax(search.maxLevel)

  self.CraftedLevelRange:SetMin(search.minCraftedLevel)
  self.CraftedLevelRange:SetMax(search.maxCraftedLevel)

  if search.minPrice ~= nil then
    self.PriceRange:SetMin(search.minPrice/10000)
  else
    self.PriceRange:SetMin(nil)
  end

  if search.maxPrice ~= nil then
    self.PriceRange:SetMax(search.maxPrice/10000)
  else
    self.PriceRange:SetMax(nil)
  end

  if search.quantity == nil then
    self.PurchaseQuantity:SetNumber(0)
  else
    self.PurchaseQuantity:SetNumber(search.quantity)
  end

  local qualityValues = {}
  for _, quality in ipairs(search.qualities or {}) do
    table.insert(qualityValues, tostring(quality))
  end
  self.QualityContainer.DropDown:SetValues(qualityValues)

  if not Auctionator.Constants.IsRetail or search.tier == nil then
    self.TierContainer.DropDown:SetValue(NO_QUALITY)
  else
    self.TierContainer.DropDown:SetValue(tostring(search.tier))
  end

  if not Auctionator.Constants.IsRetail or search.expansion == nil then
    self.ExpansionContainer.DropDown:SetValue(NO_QUALITY)
  else
    self.ExpansionContainer.DropDown:SetValue(tostring(search.expansion))
  end
  if self.requireChange then
    -- Compare against the normalized value represented by the controls. This
    -- also lets the button disable again when a user reverts every edit.
    self.originalItemString = self:GetItemString()
  end
  self:UpdateResetStates()
end

function AuctionatorShoppingItemMixin:ResetAll()
  Auctionator.Debug.Message("AuctionatorShoppingItemMixin:ResetAll()")

  self.SearchContainer.SearchString:SetText("")
  self.SearchContainer.IsExact:SetChecked(false)

  self.FilterKeySelector:Reset()

  self.ItemLevelRange:Reset()
  self.LevelRange:Reset()
  self.PriceRange:Reset()
  self.CraftedLevelRange:Reset()
  self.QualityContainer.DropDown:SetValues({})
  self.PurchaseQuantity:SetNumber(0)
  self.TierContainer.DropDown:SetValue(NO_QUALITY)
  self.ExpansionContainer.DropDown:SetValue(NO_QUALITY)
  self:UpdateResetStates()
end

function AuctionatorShoppingItemMixin:ReceiveEvent(eventName)
  if eventName == Auctionator.Shopping.Tab.Events.ListSearchStarted then
    self.searchInProgress = true
    self.Finished:Disable()
  elseif eventName == Auctionator.Shopping.Tab.Events.ListSearchEnded then
    self.searchInProgress = false
    if self.requireChange then
      self:UpdateResetStates()
    else
      self.Finished:Enable()
    end
  end
end
