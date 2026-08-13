LogisticianBuyFrameMixin = {}

function LogisticianBuyFrameMixin:Init()
  Logistician.EventBus:RegisterSource(self, "LogisticianBuyFrameMixin")
  self.CurrentPrices:Init()
  self.HistoryPrices:Init()
end

function LogisticianBuyFrameMixin:Reset()
  if self.HistoryPrices:IsShown() then
    self:ToggleHistory()
  end

  self.HistoryPrices:Reset()
  self.CurrentPrices:Reset()
end

function LogisticianBuyFrameMixin:ToggleHistory()
  self.HistoryPrices:SetShown(not self.HistoryPrices:IsShown())
  self.CurrentPrices:SetShown(not self.CurrentPrices:IsShown())

  if self.HistoryPrices:IsShown() then
    self.HistoryButton:SetText(LOGISTICIAN_L_CURRENT)
  else
    self.HistoryButton:SetText(LOGISTICIAN_L_HISTORY)
  end
end

LogisticianBuyFrameMixinForShopping = CreateFromMixins(LogisticianBuyFrameMixin)

function LogisticianBuyFrameMixinForShopping:Init()
  LogisticianBuyFrameMixin.Init(self)
  self.CurrentPrices.SearchResultsListing:SetScrollBarOffsetX(2)
  Logistician.EventBus:Register(self, {
    Logistician.Buying.Events.ShowForShopping,
    Logistician.Shopping.Tab.Events.SearchStart,
  })
end

function LogisticianBuyFrameMixinForShopping:OnShow()
  self:GetParent().ResultsListing:Hide()
  self:GetParent().ExportCSV:Hide()
  self:GetParent().ShoppingResultsInset:Hide()
  self.wasParentLoadAllPagesVisible = self:GetParent().LoadAllPagesButton:IsShown()
  self:GetParent().LoadAllPagesButton:Hide()

  local addButton = self:GetParent().SearchOptions.AddToListButton
  self.originalAddToListOnClick = addButton:GetScript("OnClick")
  addButton:SetParent(self)
  addButton:ClearAllPoints()
  addButton:SetPoint("RIGHT", self.ItemHeader, "RIGHT", -8, 0)
  addButton:SetFrameLevel(self:GetFrameLevel() + 5)
  addButton:SetScript("OnClick", function()
    local list = self:GetParent().ListsContainer:GetExpandedList()
    if list and self.selectedItemName then
      -- A result opened from a broad or partial query must be stored as the
      -- exact resolved item, not as the query that happened to find it.
      list:InsertItem('"' .. self.selectedItemName .. '"')
      self:GetParent().ListsContainer:ScrollToListEnd()
    end
  end)
  addButton:Show()
  addButton:SetEnabled(
    self:GetParent().ListsContainer:GetExpandedList() ~= nil
      and self.selectedItemName ~= nil
  )
end

function LogisticianBuyFrameMixinForShopping:OnHide()
  self:Hide()

  self:GetParent().ResultsListing:Show()
  self:GetParent().ExportCSV:Show()
  self:GetParent().ShoppingResultsInset:Show()
  self:GetParent().LoadAllPagesButton:SetShown(self.wasParentLoadAllPagesVisible)

  local searchOptions = self:GetParent().SearchOptions
  local addButton = searchOptions.AddToListButton
  addButton:SetScript("OnClick", self.originalAddToListOnClick)
  addButton:SetParent(searchOptions)
  addButton:ClearAllPoints()
  addButton:SetPoint("BOTTOMLEFT", searchOptions.MoreButton, "BOTTOMRIGHT", 5, 0)
  addButton:SetFrameLevel(searchOptions:GetFrameLevel() + 1)
  searchOptions:UpdateAddToListButton()
end

function LogisticianBuyFrameMixinForShopping:ReceiveEvent(eventName, eventData, ...)
  if eventName == Logistician.Buying.Events.ShowForShopping then
    -- eventData.itemName is presentation text and can include an appended
    -- item level, for example "Deadly Blunderbuss (21)". Shopping searches
    -- must use the canonical name encoded in the item link.
    local rawItemName = eventData.itemLink and GetItemInfo(eventData.itemLink)
    self.selectedItemName = rawItemName or eventData.itemName
    -- Some Anniversary item links decorate their visible link text with the
    -- item level. Never allow that UI-only suffix into an exact search.
    if self.selectedItemName then
      self.selectedItemName = self.selectedItemName:gsub("%s+%(%d+%)$", "")
    end
    self:Show()

    self:Reset()

    local addButton = self:GetParent().SearchOptions.AddToListButton
    addButton:SetEnabled(
      self:GetParent().ListsContainer:GetExpandedList() ~= nil
        and self.selectedItemName ~= nil
    )

    if #eventData.entries > 0 then
      self.CurrentPrices.SearchDataProvider:SetQuery(eventData.entries[1].itemLink, function() 
        self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.entries[1].itemLink)
        self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.entries[1].itemLink)
      end)
    else
      self.CurrentPrices.SearchDataProvider:SetQuery(nil, function() end)
      self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(nil)
      self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(nil)
    end
    self.CurrentPrices.SearchDataProvider:SetAuctions(eventData.entries)

    self.CurrentPrices.SearchDataProvider:SetRequestAllResults(false)
    if not eventData.complete and #eventData.entries < Logistician.Constants.MaxResultsPerPage then
      self.CurrentPrices.SearchDataProvider:RefreshQuery()
    else
      self.CurrentPrices.gotCompleteResults = eventData.complete
      self.CurrentPrices:UpdateButtons()
    end
  elseif eventName == Logistician.Shopping.Tab.Events.SearchStart then
    self:Hide()
  end
end

LogisticianBuyFrameMixinForSelling = CreateFromMixins(LogisticianBuyFrameMixin)
local AUCTION_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
}

function LogisticianBuyFrameMixinForSelling:Init()
  LogisticianBuyFrameMixin.Init(self)
  Logistician.EventBus:Register(self, {
    Logistician.Selling.Events.RefreshBuying,
    Logistician.Selling.Events.RefreshHistoryOnly,
    Logistician.Selling.Events.StartFakeBuyLoading,
    Logistician.Selling.Events.StopFakeBuyLoading,
    Logistician.Selling.Events.AuctionCreated,
  })
end

function LogisticianBuyFrameMixinForSelling:Reset()
  LogisticianBuyFrameMixin.Reset(self)

  self.CurrentPrices.SearchDataProvider:SetIgnoreItemSuffix(Logistician.Config.Get(Logistician.Config.Options.SELLING_IGNORE_ITEM_SUFFIX))
  self.waitingOnNewAuction = false
end

function LogisticianBuyFrameMixinForSelling:OnShow()
  FrameUtil.RegisterFrameForEvents(self, AUCTION_EVENTS)
  self:Reset()
end

function LogisticianBuyFrameMixinForSelling:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, AUCTION_EVENTS)
end

function LogisticianBuyFrameMixinForSelling:ReceiveEvent(eventName, eventData, ...)
  if eventName == Logistician.Selling.Events.RefreshBuying then
    self:Reset()

    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.CurrentPrices.SearchDataProvider:SetQuery(eventData.itemLink, function()
      self.CurrentPrices.SearchDataProvider:SetRequestAllResults(Logistician.Config.Get(Logistician.Config.Options.SELLING_ALWAYS_LOAD_MORE))
      self.CurrentPrices.SearchDataProvider:RefreshQuery()
    end)

    self.CurrentPrices.RefreshButton:Enable()
    self.HistoryButton:Enable()
  elseif eventName == Logistician.Selling.Events.RefreshHistoryOnly then
    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
  elseif eventName == Logistician.Selling.Events.StartFakeBuyLoading then
    -- Used so that it is clear something is loading, even if the search can't
    -- be sent yet.
    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.CurrentPrices.SearchDataProvider:SetQuery(eventData.itemLink, function() end)
    self.CurrentPrices.SearchDataProvider.onSearchStarted()
  elseif eventName == Logistician.Selling.Events.StopFakeBuyLoading then
    self.CurrentPrices.SearchDataProvider.onSearchEnded()
    self:Reset()
    self.CurrentPrices.RefreshButton:Disable()
    self.HistoryButton:Disable()
  elseif eventName == Logistician.Selling.Events.AuctionCreated then
    self.waitingOnNewAuction = true
  end
end

function LogisticianBuyFrameMixinForSelling:OnEvent(eventName, ...)
  if eventName == "AUCTION_OWNED_LIST_UPDATE" and self.waitingOnNewAuction then
    self.waitingOnNewAuction = false
    self.CurrentPrices.SearchDataProvider:PurgeAndReplaceOwnedAuctions(Logistician.AH.DumpAuctions("owner"))
  end
end
