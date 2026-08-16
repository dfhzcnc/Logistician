AuctionatorShoppingTabFrameMixin = {}

local EVENTBUS_EVENTS = {
  Auctionator.Shopping.Events.ListImportFinished,
  Auctionator.Shopping.Tab.Events.ListSearchRequested,
  Auctionator.Shopping.Tab.Events.ShowHistoricalPrices,
  Auctionator.Shopping.Tab.Events.UpdateSearchTerm,
  Auctionator.Shopping.Tab.Events.BuyScreenShown,
}

function AuctionatorShoppingTabFrameMixin:DoSearch(terms, options)
  if #terms == 0 then
    return
  end

  -- The legacy AH API accepts exactly one quality per query. Rather than
  -- requesting every quality and filtering locally (which can produce an
  -- empty/fallback row), expand a multi-quality advanced search into one
  -- server-side query per selected quality and merge the normal results.
  if Auctionator.Constants.IsLegacyAH then
    local expanded = {}
    local didExpand = false
    for _, term in ipairs(terms) do
      local parsed = Auctionator.Search.SplitAdvancedSearch(term)
      if #(parsed.qualities or {}) > 1 then
        didExpand = true
        for _, quality in ipairs(parsed.qualities) do
          local variant = CopyTable(parsed)
          variant.qualities = {quality}
          variant.quality = quality
          table.insert(expanded, Auctionator.Search.ReconstituteAdvancedSearch(variant))
        end
      else
        table.insert(expanded, term)
      end
    end
    terms = expanded
    if didExpand then
      options = options or {}
      options.suppressMissingTerms = true
    end
  end

  if options == nil and Auctionator.Constants.IsLegacyAH and IsShiftKeyDown() then
    options = { searchAllPages = true }
  end

  self:StopSearch()

  self.singleResultAutoOpened = false
  self.searchRunning = true
  self:SetSearchPanelsLocked(true)
  Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.SearchStart, terms)
  self.SearchProvider:Search(terms, options or {})
  self:StartSpinner()
end

function AuctionatorShoppingTabFrameMixin:TryOpenSingleResult()
  if not Auctionator.Constants.IsLegacyAH
    or self.singleResultAutoOpened
    or self.searchRunning
    or not self.DataProvider.searchCompleted
    or self.DataProvider:GetCount() ~= 1 then
    return
  end

  local result = self.DataProvider:GetEntryAt(1)
  -- itemLink is added after the item cache has resolved. Requiring real
  -- auction entries excludes the synthetic row used for an unavailable item.
  if not result or not result.itemLink
    or not result.entries or #result.entries == 0 then
    return
  end

  self.singleResultAutoOpened = true
  Auctionator.EventBus:Fire(self, Auctionator.Buying.Events.ShowForShopping, result)
  Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.BuyScreenShown)
end

function AuctionatorShoppingTabFrameMixin:StopSearch()
  self.searchRunning = false
  self:StopLoadingTextAnimation()
  self.SearchProvider:AbortSearch()
  self:SetSearchPanelsLocked(false)
end

function AuctionatorShoppingTabFrameMixin:SetSearchPanelsLocked(locked)
  local alpha = locked and 0.35 or 1
  self.ListsContainer.ScrollBox:SetAlpha(alpha)
  self.ResultsListing.HeaderContainer:SetAlpha(alpha)
  self.ResultsListing.ScrollArea.ScrollBox:SetAlpha(alpha)

  self.ListsContainer.ScrollBox:EnableMouse(not locked)
  self.ResultsListing.ScrollArea.ScrollBox:EnableMouse(not locked)

  for _, button in ipairs({self.NewListButton, self.ImportButton, self.ExportButton}) do
    if locked then button:Disable() else button:Enable() end
  end
end

function AuctionatorShoppingTabFrameMixin:StartLoadingTextAnimation()
  self:ResetLoadingTextCycle()
  self:SetScript("OnUpdate", function(frame, elapsed)
    frame.loadingTextElapsed = frame.loadingTextElapsed + elapsed
    if frame.loadingTextElapsed < 0.45 then return end
    frame.loadingTextElapsed = 0
    frame.loadingTextDots = (frame.loadingTextDots + 1) % 4
    local dots = string.rep(".", frame.loadingTextDots)
    frame.ResultsListing.ScrollArea.ResultsText:SetText("Fetching item info" .. dots)
  end)
end

function AuctionatorShoppingTabFrameMixin:ResetLoadingTextCycle()
  self.loadingTextElapsed = 0
  self.loadingTextDots = 0
  self.ResultsListing.ScrollArea.ResultsText:SetText("Fetching item info")
end

function AuctionatorShoppingTabFrameMixin:StopLoadingTextAnimation()
  self:SetScript("OnUpdate", nil)
end

function AuctionatorShoppingTabFrameMixin:StartSpinner()
  self.ListsContainer.LoadingSpinner:Hide()
  self.ListsContainer.ResultsText:Hide()
  self:StartLoadingTextAnimation()
end

function AuctionatorShoppingTabFrameMixin:CloseAnyDialogs()
  for _, d in ipairs(self.dialogs) do
    if d:IsShown() then
      d:Hide()
    end
  end
end

function AuctionatorShoppingTabFrameMixin:OnLoad()
  Auctionator.EventBus:RegisterSource(self, "AuctionatorShoppingTabFrameMixin")

  self.ResultsListing:SetScrollBarOffsetX(2)
  self.ResultsListing:Init(self.DataProvider)

  -- The raw search callback can contain intermediate/duplicate groups. Base
  -- auto-opening on the finalized provider that backs the visible table.
  local listingOnUpdate = self.DataProvider.onUpdate
  self.DataProvider:SetOnUpdateCallback(function(...)
    listingOnUpdate(...)
    self:TryOpenSingleResult()
  end)
  local listingOnSearchEnded = self.DataProvider.onSearchEnded
  self.DataProvider:SetOnSearchEndedCallback(function(...)
    listingOnSearchEnded(...)
    self:TryOpenSingleResult()
  end)

  -- Shopping searches use compact, unobtrusive progress indicators.
  self.ListsContainer.LoadingSpinner:SetAlpha(0)
  self.ListsContainer.ResultsText:SetFontObject(GameFontNormalSmall)
  self.ListsContainer.ResultsText:ClearAllPoints()
  self.ListsContainer.ResultsText:SetPoint("CENTER", self.ListsContainer, "CENTER", 0, 0)
  self.ListsContainer.ResultsText:SetWidth(230)
  self.ListsContainer.ResultsText:SetJustifyH("CENTER")

  self.ResultsListing.ScrollArea.LoadingSpinner:SetAlpha(0)
  self.ResultsListing.ScrollArea.ResultsText:SetFontObject(GameFontNormalSmall)
  self.ResultsListing.ScrollArea.ResultsText:ClearAllPoints()
  self.ResultsListing.ScrollArea.ResultsText:SetPoint("CENTER", self.ResultsListing.ScrollArea, "CENTER", 0, 0)
  self.ResultsListing.ScrollArea.ResultsText:SetWidth(300)
  self.ResultsListing.ScrollArea.ResultsText:SetJustifyH("CENTER")

  self.dialogs = {}

  self.itemDialog = CreateFrame("Frame", "AuctionatorShoppingTabItemFrame", self, "AuctionatorShoppingItemTemplate")
  self.itemDialog:ClearAllPoints()
  self.itemDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.itemDialog)

  self.exportDialog = CreateFrame("Frame", "AuctionatorExportListFrame", self, "AuctionatorExportListTemplate")
  self.exportDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.exportDialog)

  self.importDialog = CreateFrame("Frame", "AuctionatorImportListFrame", self, "AuctionatorImportListTemplate")
  self.importDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.importDialog)

  self.exportCSVDialog = CreateFrame("Frame", nil, self, "AuctionatorExportTextFrame")
  self.exportCSVDialog:SetPoint("CENTER")
  table.insert(self.dialogs, self.exportCSVDialog)

  self.ExportButton:SetScript("OnClick", function()
    self:CloseAnyDialogs()
    self.exportDialog:Show()
  end)
  self.ImportButton:SetScript("OnClick", function()
    self:CloseAnyDialogs()
    self.importDialog:Show()
  end)

  self.itemHistoryDialog = CreateFrame("Frame", "AuctionatorItemHistoryFrame", self, "AuctionatorItemHistoryTemplate")
  self.itemHistoryDialog:SetPoint("CENTER")
  self.itemHistoryDialog:Init()

  self:SetupSearchProvider()

  self:SetupListsContainer()
  self:SetupRecentsContainer()
  self:SetupTopSearch()

  self.NewListButton:SetScript("OnClick", function()
    Auctionator.Dialogs.ShowEditBox(AUCTIONATOR_L_CREATE_LIST_DIALOG, ACCEPT, CANCEL, function(text)
      local name = Auctionator.Shopping.ListManager:GetUnusedName(text)
      Auctionator.Shopping.ListManager:Create(name)
      self.ListsContainer:ExpandList(Auctionator.Shopping.ListManager:GetByName(name))
    end)
  end)

  self.ContainerTabs:SetView(Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_LAST_CONTAINER_VIEW))

  self.shouldDefaultOpenOnShow = true
  if Auctionator.Constants.IsVanilla then
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")
  else
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
  end
  self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
end

function AuctionatorShoppingTabFrameMixin:SetupSearchProvider()
  local function CacheResultIcons(results)
    Auctionator.Shopping.ListIconCache = Auctionator.Shopping.ListIconCache or {}
    local changed = false
    for _, result in ipairs(results or {}) do
      local link = result.itemLink
        or (result.entries and result.entries[1] and result.entries[1].itemLink)
      local name, _, _, _, _, _, _, _, _, texture = link and GetItemInfo(link)
      -- Result callbacks can run before the asynchronous item cache has filled
      -- GetItemInfo. Auction links already contain the localized name, while
      -- GetItemInfoInstant can provide the icon immediately from the item ID.
      if link and (not name or not texture) then
        name = name or Auctionator.Utilities.GetNameFromLink(link)
        local _, _, _, _, instantTexture = C_Item.GetItemInfoInstant(link)
        texture = texture or instantTexture
      end
      if name and texture then
        Auctionator.Shopping.ListIconCache[string.lower(name)] = texture
        changed = true
      end
    end
    if changed and self.ListsContainer then self.ListsContainer:Populate() end
  end

  self.SearchProvider:InitSearch(
    function(results)
      CacheResultIcons(results)
      self.searchRunning = false
      self:StopLoadingTextAnimation()
      self:SetSearchPanelsLocked(false)
      Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.SearchEnd, results)
      self.ListsContainer.LoadingSpinner:Hide()
      self.ListsContainer.ResultsText:Hide()

    end,
    function(current, total, partialResults)
      CacheResultIcons(partialResults)
      Auctionator.EventBus:Fire(self, Auctionator.Shopping.Tab.Events.SearchIncrementalUpdate, partialResults, total, current)
      -- Multi-item searches begin a fresh visual cycle for every query.
      self:ResetLoadingTextCycle()
    end
  )
end

function AuctionatorShoppingTabFrameMixin:SetupListsContainer()
  self.ListsContainer:SetOnListExpanded(function()
    if Auctionator.Config.Get(Auctionator.Config.Options.AUTO_LIST_SEARCH) then
      self.singleSearch = false
      self:DoSearch(self.ListsContainer:GetExpandedList():GetAllItems())
    end
    self.SearchOptions:OnListExpanded()
  end)
  self.ListsContainer:SetOnListCollapsed(function()
    self:StopSearch()
    self.SearchOptions:OnListCollapsed()
  end)
  self.ListsContainer:SetOnSearchTermClicked(function(list, searchTerm, index)
    self.singleSearch = true
    self:DoSearch({searchTerm})
    self.SearchOptions:SetSearchTerm(searchTerm)
    self.ListsContainer:TemporarilySelectSearchTerm(index)
  end)
  self.ListsContainer:SetOnSearchTermDelete(function(list, searchTerm, index)
    list:DeleteItem(index)
  end)
  self.ListsContainer:SetOnSearchTermEdit(function(list, searchTerm, index)
    self:CloseAnyDialogs()
    self.itemDialog:Init(AUCTIONATOR_L_LIST_EDIT_ITEM_HEADER, "Save", true)
    self.itemDialog:SetOnFinishedClicked(function(newItemString)
      list:AlterItem(index, newItemString)
    end)
    self.itemDialog:Show()
    self.itemDialog:SetItemString(searchTerm)
  end)
  self.ListsContainer:SetOnListSearch(function(list)
    self.singleSearch = false
    self:DoSearch(list:GetAllItems())
  end)
  self.ListsContainer:SetOnListEdit(function(list)
    if list:IsTemporary() then
      Auctionator.Dialogs.ShowEditBox(AUCTIONATOR_L_MAKE_PERMANENT_CONFIRM:format(list:GetName()), ACCEPT, CANCEL, function(text)
        list:Rename(text)
        list:MakePermanent()
        self.ListsContainer:ScrollToList(list)
      end)
    else
      Auctionator.Dialogs.ShowEditBox(AUCTIONATOR_L_RENAME_LIST_CONFIRM:format(list:GetName()), ACCEPT, CANCEL, function(text)
        list:Rename(text)
        self.ListsContainer:ScrollToList(list)
      end)
    end
  end)
  self.ListsContainer:SetOnListDelete(function(list)
    Auctionator.Dialogs.ShowConfirm(AUCTIONATOR_L_DELETE_LIST_CONFIRM:format(list:GetName()):gsub("%%", "%%%%"), ACCEPT, CANCEL, function()
      if Auctionator.Shopping.ListManager:GetIndexForName(list:GetName()) ~= nil then
        Auctionator.Shopping.ListManager:Delete(list:GetName())
      end
    end)
  end)

  self.ListsContainer:SetOnListItemDrag(function(list, oldIndex, newIndex)
    if oldIndex ~= newIndex then
      local old = list:GetItemByIndex(oldIndex)
      list:DeleteItem(oldIndex)
      list:InsertItem(old, newIndex)
    end
  end)
  self.ListsContainer:SetOnListDrag(function(oldIndex, newIndex)
    Auctionator.Shopping.ListManager:Move(oldIndex, newIndex)
  end)
  self.ListsContainer:SetOnListItemMove(function(sourceList, sourceIndex, targetList)
    if sourceList:GetName() == targetList:GetName() then return end
    local item = sourceList:GetItemByIndex(sourceIndex)
    if not item then return end
    sourceList:DeleteItem(sourceIndex)
    targetList:InsertItem(item)
  end)
end

function AuctionatorShoppingTabFrameMixin:SetupRecentsContainer()
  self.RecentsContainer:SetOnSearchRecent(function(searchTerm)
    self.singleSearch = true
    self:DoSearch({searchTerm})
    self.SearchOptions:SetSearchTerm(searchTerm)
    self.RecentsContainer:TemporarilySelectSearchTerm(searchTerm)
  end)
  self.RecentsContainer:SetOnDeleteRecent(function(searchTerm)
    Auctionator.Shopping.Recents.DeleteEntry(searchTerm)
  end)
  self.RecentsContainer:SetOnCopyRecent(function(searchTerm)
    local list = self.ListsContainer:GetExpandedList()
    if list == nil then
      Auctionator.Utilities.Message(AUCTIONATOR_L_COPY_NO_LIST_SELECTED)
    else
      list:InsertItem(searchTerm)
      Auctionator.Utilities.Message(AUCTIONATOR_L_COPY_ITEM_ADDED:format(
        GREEN_FONT_COLOR:WrapTextInColorCode(Auctionator.Search.PrettifySearchString(searchTerm)),
        GREEN_FONT_COLOR:WrapTextInColorCode(list:GetName())
      ))
    end
  end)
end

function AuctionatorShoppingTabFrameMixin:SetupTopSearch()
  self.SearchOptions:SetOnSearch(function(searchTerm)
    if self.searchRunning then
      self:StopSearch()
    elseif searchTerm == "" and self.ListsContainer:GetExpandedList() ~= nil then
      self:DoSearch(self.ListsContainer:GetExpandedList():GetAllItems())
    else
      self.singleSearch = true
      self:DoSearch({searchTerm})
      Auctionator.Shopping.Recents.Save(searchTerm)
    end
  end)
  self.SearchOptions:SetOnMore(function(searchTerm)
    self:CloseAnyDialogs()
    self.itemDialog:Init(AUCTIONATOR_L_LIST_EXTENDED_SEARCH_HEADER, AUCTIONATOR_L_SEARCH)
    self.itemDialog:SetOnFinishedClicked(function(searchTerm)
      self.SearchOptions:SetSearchTerm(searchTerm)
      self.singleSearch = true
      self:DoSearch({searchTerm})
      Auctionator.Shopping.Recents.Save(searchTerm)
    end)

    self.itemDialog:Show()
    self.itemDialog:SetItemString(searchTerm)
  end)
  self.SearchOptions:SetOnAddToList(function(searchTerm)
    self.ListsContainer:GetExpandedList():InsertItem(searchTerm)
    self.ListsContainer:ScrollToListEnd()
  end)
end

function AuctionatorShoppingTabFrameMixin:GetAppropriateListSearchName()
  if self.singleSearch or not self.ListsContainer:GetExpandedList() then
    return AUCTIONATOR_L_NO_LIST
  else
    return self.ListsContainer:GetExpandedList():GetName()
  end
end

function AuctionatorShoppingTabFrameMixin:ReceiveEvent(eventName, eventData)
  if eventName == Auctionator.Shopping.Events.ListImportFinished then
    self.ListsContainer:ExpandList(Auctionator.Shopping.ListManager:GetByName(eventData))

  elseif eventName == Auctionator.Shopping.Tab.Events.ListSearchRequested then
    self.ContainerTabs:SetView(Auctionator.Constants.ShoppingListViews.Lists)
    self.ListsContainer:ExpandList(eventData)
    if not Auctionator.Config.Get(Auctionator.Config.Options.AUTO_LIST_SEARCH) then
      self.singleSearch = false
      self:DoSearch(eventData:GetAllItems())
    end

  elseif eventName == Auctionator.Shopping.Tab.Events.ShowHistoricalPrices then
    self:CloseAnyDialogs()
    self.itemHistoryDialog:Show()

  elseif eventName == Auctionator.Shopping.Tab.Events.UpdateSearchTerm then
    self.SearchOptions:SetSearchTerm(eventData)

  elseif eventName == Auctionator.Shopping.Tab.Events.BuyScreenShown then
    self:StopSearch()
  end
end

function AuctionatorShoppingTabFrameMixin:OnEvent(eventName, ...)
  if eventName == "GET_ITEM_INFO_RECEIVED" then
    -- GetItemInfo calls made while drawing saved shopping lists can complete
    -- asynchronously after login. Redraw to replace temporary question marks.
    if self:IsShown() and self.ListsContainer and self.ListsContainer:IsShown() then
      self.ListsContainer:Populate()
    end
  elseif eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local showType = ...
    if showType == Enum.PlayerInteractionType.Auctioneer then
      self.shouldDefaultOpenOnShow = true
    end
  elseif eventName == "AUCTION_HOUSE_CLOSED" then
    self.shouldDefaultOpenOnShow = true
  end
end

function AuctionatorShoppingTabFrameMixin:OnShow()
  self.SearchOptions:FocusSearchBox()
  Auctionator.EventBus:Register(self, EVENTBUS_EVENTS)

  if self.shouldDefaultOpenOnShow then
    self:OpenDefaultList()
    self.shouldDefaultOpenOnShow = false
  end
end

function AuctionatorShoppingTabFrameMixin:OnHide()
  if self.searchRunning then
    self:StopSearch()
  end
  Auctionator.EventBus:Unregister(self, EVENTBUS_EVENTS)
end

function AuctionatorShoppingTabFrameMixin:ExportCSVClicked()
  self:CloseAnyDialogs()
  self.DataProvider:GetCSV(function(result)
    self.exportCSVDialog:SetExportString(result)
    self.exportCSVDialog:Show()
  end)
end

function AuctionatorShoppingTabFrameMixin:OpenDefaultList()
  local listName = Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_LIST)

  if listName == Auctionator.Constants.NO_LIST then
    return
  end

  local listIndex = Auctionator.Shopping.ListManager:GetIndexForName(listName)

  if listIndex ~= nil then
    self.ListsContainer:CollapseList()
    self.ContainerTabs:SetView(Auctionator.Constants.ShoppingListViews.Lists)
    self.ListsContainer:ExpandList(Auctionator.Shopping.ListManager:GetByIndex(listIndex))
  end
end
