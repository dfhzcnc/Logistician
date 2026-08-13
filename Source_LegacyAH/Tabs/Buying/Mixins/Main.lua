AuctionatorBuyFrameMixin = {}

function AuctionatorBuyFrameMixin:Init()
  Auctionator.EventBus:RegisterSource(self, "AuctionatorBuyFrameMixin")
  self.CurrentPrices:Init()
  self.HistoryPrices:Init()
end

function AuctionatorBuyFrameMixin:Reset()
  if self.HistoryPrices:IsShown() then
    self:ToggleHistory()
  end

  self.HistoryPrices:Reset()
  self.CurrentPrices:Reset()
end

function AuctionatorBuyFrameMixin:ToggleHistory()
  self.HistoryPrices:SetShown(not self.HistoryPrices:IsShown())
  self.CurrentPrices:SetShown(not self.CurrentPrices:IsShown())

  if self.HistoryPrices:IsShown() then
    self.HistoryButton:SetText(AUCTIONATOR_L_CURRENT)
  else
    self.HistoryButton:SetText(AUCTIONATOR_L_HISTORY)
  end
end

AuctionatorBuyFrameMixinForShopping = CreateFromMixins(AuctionatorBuyFrameMixin)

function AuctionatorBuyFrameMixinForShopping:Init()
  AuctionatorBuyFrameMixin.Init(self)
  self.CurrentPrices.SearchResultsListing:SetScrollBarOffsetX(2)
  Auctionator.EventBus:Register(self, {
    Auctionator.Buying.Events.ShowForShopping,
    Auctionator.Shopping.Tab.Events.SearchStart,
  })
end

function AuctionatorBuyFrameMixinForShopping:OnShow()
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

function AuctionatorBuyFrameMixinForShopping:OnHide()
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

function AuctionatorBuyFrameMixinForShopping:ReceiveEvent(eventName, eventData, ...)
  if eventName == Auctionator.Buying.Events.ShowForShopping then
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
    if not eventData.complete and #eventData.entries < Auctionator.Constants.MaxResultsPerPage then
      self.CurrentPrices.SearchDataProvider:RefreshQuery()
    else
      self.CurrentPrices.gotCompleteResults = eventData.complete
      self.CurrentPrices:UpdateButtons()
    end
  elseif eventName == Auctionator.Shopping.Tab.Events.SearchStart then
    self:Hide()
  end
end

AuctionatorBuyFrameMixinForSelling = CreateFromMixins(AuctionatorBuyFrameMixin)
local AUCTION_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
}

function AuctionatorBuyFrameMixinForSelling:Init()
  AuctionatorBuyFrameMixin.Init(self)
  Auctionator.EventBus:Register(self, {
    Auctionator.Selling.Events.RefreshBuying,
    Auctionator.Selling.Events.RefreshHistoryOnly,
    Auctionator.Selling.Events.StartFakeBuyLoading,
    Auctionator.Selling.Events.StopFakeBuyLoading,
    Auctionator.Selling.Events.AuctionCreated,
  })
end

function AuctionatorBuyFrameMixinForSelling:Reset()
  AuctionatorBuyFrameMixin.Reset(self)

  self.CurrentPrices.SearchDataProvider:SetIgnoreItemSuffix(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_IGNORE_ITEM_SUFFIX))
  self.waitingOnNewAuction = false
end

function AuctionatorBuyFrameMixinForSelling:OnShow()
  FrameUtil.RegisterFrameForEvents(self, AUCTION_EVENTS)
  self:Reset()
end

function AuctionatorBuyFrameMixinForSelling:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, AUCTION_EVENTS)
end

function AuctionatorBuyFrameMixinForSelling:ReceiveEvent(eventName, eventData, ...)
  if eventName == Auctionator.Selling.Events.RefreshBuying then
    self:Reset()

    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.CurrentPrices.SearchDataProvider:SetQuery(eventData.itemLink, function()
      self.CurrentPrices.SearchDataProvider:SetRequestAllResults(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_ALWAYS_LOAD_MORE))
      self.CurrentPrices.SearchDataProvider:RefreshQuery()
    end)

    self.CurrentPrices.RefreshButton:Enable()
    self.HistoryButton:Enable()
  elseif eventName == Auctionator.Selling.Events.RefreshHistoryOnly then
    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
  elseif eventName == Auctionator.Selling.Events.StartFakeBuyLoading then
    -- Used so that it is clear something is loading, even if the search can't
    -- be sent yet.
    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.CurrentPrices.SearchDataProvider:SetQuery(eventData.itemLink, function() end)
    self.CurrentPrices.SearchDataProvider.onSearchStarted()
  elseif eventName == Auctionator.Selling.Events.StopFakeBuyLoading then
    self.CurrentPrices.SearchDataProvider.onSearchEnded()
    self:Reset()
    self.CurrentPrices.RefreshButton:Disable()
    self.HistoryButton:Disable()
  elseif eventName == Auctionator.Selling.Events.AuctionCreated then
    self.waitingOnNewAuction = true
  end
end

function AuctionatorBuyFrameMixinForSelling:OnEvent(eventName, ...)
  if eventName == "AUCTION_OWNED_LIST_UPDATE" and self.waitingOnNewAuction then
    self.waitingOnNewAuction = false
    self.CurrentPrices.SearchDataProvider:PurgeAndReplaceOwnedAuctions(Auctionator.AH.DumpAuctions("owner"))
  end
end
