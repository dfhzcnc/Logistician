local BUY_AUCTIONS_TABLE_LAYOUT = {
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "unitPrice" },
    headerText = LOGISTICIAN_L_UNIT_PRICE,
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "unitPrice" },
    width = 145,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_RESULTS_AVAILABLE_COLUMN,
    headerParameters = { "stackSize" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "availablePretty" },
    width = 120,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "stackPrice" },
    headerText = LOGISTICIAN_L_RESULTS_STACK_PRICE_COLUMN,
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "stackPrice" },
    width = 145,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "otherSellers" },
    headerText = LOGISTICIAN_L_SELLERS_COLUMN,
    cellTemplate = "LogisticianTooltipStringCellTemplate",
    cellParameters = { "otherSellers" },
    defaultHide = true,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "otherSellers" },
    headerText = "Poster",
    cellTemplate = "LogisticianTooltipStringCellTemplate",
    cellParameters = { "otherSellers", "GameFontHighlightSmall" },
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "timeLeft" },
    headerText = LOGISTICIAN_L_TIME_LEFT,
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "timeLeftPretty" },
    defaultHide = true,
  },
}

local BUY_EVENTS = {
  Logistician.AH.Events.ScanResultsUpdate,
  Logistician.AH.Events.ScanAborted,
}

LogisticianBuyAuctionsDataProviderMixin = CreateFromMixins(LogisticianDataProviderMixin)

function LogisticianBuyAuctionsDataProviderMixin:OnLoad()
  Logistician.Debug.Message("LogisticianBuyAuctionsDataProviderMixin:OnLoad()")
  Logistician.EventBus:RegisterSource(self, "LogisticianBuyAuctionsDataProviderMixin")

  LogisticianDataProviderMixin.OnLoad(self)
  self:SetUpEvents()
  self.gotAllResults = true
  self.requestAllResults = true
  self.ignoreItemSuffix = false
  self.itemLevelMatch = false
end

function LogisticianBuyAuctionsDataProviderMixin:SetIgnoreItemSuffix(state)
  self.ignoreItemSuffix = state
end

function LogisticianBuyAuctionsDataProviderMixin:SetUpEvents()
  Logistician.EventBus:RegisterSource(self, "Buy Auctions Data Provider")

  Logistician.EventBus:Register( self, {
    Logistician.Buying.Events.AuctionFocussed,
    Logistician.Buying.Events.StacksUpdated,
  })
end

function LogisticianBuyAuctionsDataProviderMixin:SetAuctions(entries)
  local itemID = C_Item.GetItemInfoInstant(self.searchKey)
  local item = Item:CreateFromItemID(itemID)
  item:ContinueOnItemLoad(function()
    self.allAuctions = {}
    self:ImportAdditionalResults(entries)
    self:PopulateAuctions()
    self:SetSelectedIndex(1)
  end)
end

function LogisticianBuyAuctionsDataProviderMixin:SetQuery(itemLink, callback)
  self:Reset()

  if itemLink == nil then
    self.query = nil
    self.searchKey = nil
    callback()
  else
    self.searchKey = Logistician.Search.GetCleanItemLink(itemLink)
    local itemID = C_Item.GetItemInfoInstant(self.searchKey)
    -- Searching without the gear item suffix if the option is turned on
    local isExact = not self.ignoreItemSuffix or not Logistician.Utilities.IsEquipment(select(6, C_Item.GetItemInfoInstant(itemLink)))
    if isExact then
      self.query = {
        searchString = Logistician.Utilities.GetNameFromLink(itemLink),
        minLevel = nil, maxLevel = nil,
        itemClassFilters = {},
        isExact = isExact,
      }
      callback()
    else
      Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
        self.query = {
          searchString = C_Item.GetItemNameByID(itemID),
          minLevel = nil, maxLevel = nil,
          itemClassFilters = {},
          isExact = isExact,
        }
        callback()
      end)
    end
  end
end

function LogisticianBuyAuctionsDataProviderMixin:SetRequestAllResults(newValue)
  self.requestAllResults = newValue
end

function LogisticianBuyAuctionsDataProviderMixin:GetRequestAllResults()
  return self.requestAllResults
end

function LogisticianBuyAuctionsDataProviderMixin:ReceiveEvent(eventName, eventData, ...)
  if eventName == Logistician.AH.Events.ScanResultsUpdate then
    self.gotAllResults = ...
    if self.gotAllResults then
      Logistician.EventBus:Unregister(self, BUY_EVENTS)
    end
    local itemID = C_Item.GetItemInfoInstant(self.searchKey)
    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(function()
      self:ImportAdditionalResults(eventData)

      if not self.requestAllResults and #self.allAuctions > 0 then
        Logistician.AH.AbortQuery()
        self.gotAllResults = true
      end

      self:PopulateAuctions()

      if self.gotAllResults then
        self:ReportNewMinPrice()
        self:SetSelectedIndex(1)

        Logistician.EventBus:Fire(self, Logistician.Buying.Events.ViewSetup, result)
      end
    end)

  elseif eventName == Logistician.AH.Events.ScanAborted then
    Logistician.EventBus:Unregister(self, BUY_EVENTS)
    if self.currentResults then
      self:SetSelectedIndex(1)
    end
    self.onSearchEnded()
  elseif eventName == Logistician.Buying.Events.AuctionFocussed and self:IsShown() then
    for _, entry in ipairs(self.results) do
      entry.isSelected = entry == eventData
    end
    self:SetDirty()
  elseif eventName == Logistician.Buying.Events.StacksUpdated and self:IsShown() then
    self:SetDirty()
  end
end

function LogisticianBuyAuctionsDataProviderMixin:RefreshQuery()
  self:Reset()

  if self.query ~= nil then
    Logistician.AH.AbortQuery()

    self.onSearchStarted()

    self.allAuctions = {}
    self.gotAllResults = false
    Logistician.EventBus:Register(self, BUY_EVENTS)
    Logistician.AH.QueryAuctionItems(self.query)
  end
end

function LogisticianBuyAuctionsDataProviderMixin:HasAllQueriedResults()
  return self.gotAllResults
end

function LogisticianBuyAuctionsDataProviderMixin:EndAnyQuery()
  Logistician.AH.AbortQuery()
  Logistician.EventBus:Unregister(self, BUY_EVENTS)
end

function LogisticianBuyAuctionsDataProviderMixin:ImportAdditionalResults(results)
  local itemIDWanted = C_Item.GetItemInfoInstant(self.searchKey)
  local itemLevelWanted = GetDetailedItemLevelInfo(self.searchKey)

  local waiting = #results
  for _, entry in ipairs(results) do
    local itemID = entry.info[Logistician.Constants.AuctionItemInfo.ItemID]
    local itemString = Logistician.Search.GetCleanItemLink(entry.itemLink)
    if (self.searchKey == itemString) or
      (self.ignoreItemSuffix and itemID == itemIDWanted) then
      table.insert(self.allAuctions, entry)
    end
  end
end

local function ToStackSize(entry)
  return entry.info[Logistician.Constants.AuctionItemInfo.Quantity]
end
local function ToOwner(entry)
  return tostring(entry.info[Logistician.Constants.AuctionItemInfo.Owner])
end

function LogisticianBuyAuctionsDataProviderMixin:PopulateAuctions()
  self:Reset()

  table.sort(self.allAuctions, function(a, b)
    local unitA = Logistician.Utilities.ToUnitPrice(a)
    local unitB = Logistician.Utilities.ToUnitPrice(b)
    if unitA == unitB then
      local stackA = ToStackSize(a)
      local stackB = ToStackSize(b)
      if stackA == stackB then
        local ownerA = ToOwner(a)
        local ownerB = ToOwner(b)
        return ownerA < ownerB
      else
        return stackA > stackB
      end
    else
      return unitA < unitB
    end
  end)

  local bidOnlyItems = false
  local results = {}
  for _, auction in ipairs(self.allAuctions) do
    local newEntry = {
      itemLink = auction.itemLink,
      unitPrice = Logistician.Utilities.ToUnitPrice(auction),
      stackPrice = auction.info[Logistician.Constants.AuctionItemInfo.Buyout],
      stackSize = auction.info[Logistician.Constants.AuctionItemInfo.Quantity],
      numStacks = 1,
      isOwned = ToOwner(auction) == (GetUnitName("player")),
      otherSellers = ToOwner(auction),
      bidAmount = auction.info[Logistician.Constants.AuctionItemInfo.BidAmount],
      isSelected = false, --Used by rows to determine highlight
      notReady = true,
      query = auction.query,
      page = auction.page,
      timeLeft = auction.timeLeft,
      timeLeftPretty = Logistician.Utilities.FormatTimeLeftBand(auction.timeLeft),
    }
    if newEntry.unitPrice == 0 then
      newEntry.unitPrice = nil
      newEntry.stackPrice = nil
    end

    if newEntry.isOwned then
      newEntry.otherSellers = GREEN_FONT_COLOR:WrapTextInColorCode(LOGISTICIAN_L_YOU)
      newEntry.isOwnedText = LOGISTICIAN_L_UNDERCUT_YES
    else
      newEntry.isOwnedText = ""
    end
    Logistician.Utilities.SetStacksText(newEntry)

    if newEntry.unitPrice == nil then
      bidOnlyItems = true
    else
      local prevResult = results[#results] or {}
      if prevResult.unitPrice == newEntry.unitPrice and
         prevResult.stackSize == newEntry.stackSize and
         prevResult.itemLink == newEntry.itemLink and
         prevResult.otherSellers == newEntry.otherSellers then
        prevResult.numStacks = prevResult.numStacks + 1
        Logistician.Utilities.SetStacksText(prevResult)
      else
        prevResult.nextEntry = newEntry
        table.insert(results, newEntry)
      end
      results[#results].page = math.min(results[#results].page, auction.page)
    end
  end

  if bidOnlyItems then
    table.insert(results, {
      itemLink = self.query.itemLink,
      unitPrice = nil,
      stackPrice = nil,
      stackSize = 0,
      numStacks = 0,
      isOwned = false,
      otherSellers = "",
      isSelected = false,
      notReady = true,
      query = self.query,
      page = 0,
    })
    results[#results].availablePretty = LOGISTICIAN_L_BID_ONLY_AVAILABLE
  end

  self:AppendEntries(results, self.gotAllResults)
  self.currentResults = results
end

function LogisticianBuyAuctionsDataProviderMixin:PurgeAndReplaceOwnedAuctions(ownedAuctions)
  if self.query ~= nil then
    local itemID = C_Item.GetItemInfoInstant(self.searchKey)
    local item = Item:CreateFromItemID(itemID)
      item:ContinueOnItemLoad(function()
      self.onPreserveScroll()
      local prevSelectedIndex = self:GetSelectedIndex()

      local newAllAuctions = {}
      for _, entry in ipairs(self.allAuctions) do
        if ToOwner(entry) ~= (GetUnitName("player")) then
          table.insert(newAllAuctions, entry)
        end
      end

      self.allAuctions = newAllAuctions

      for _, entry in ipairs(ownedAuctions) do
        entry.page = 0
        entry.query = self.query
      end

      self:ImportAdditionalResults(ownedAuctions)
      self:PopulateAuctions()

      self:SetSelectedIndex(prevSelectedIndex or 1)
      self:SetDirty()
    end)
  end
end

-- Set a new price in the price database based on the current results.
-- Assumes being called after PopulateAuctions which will have sorted the
-- auctions from min price to max AND that all the results have been acquired
function LogisticianBuyAuctionsDataProviderMixin:ReportNewMinPrice()
  if #self.allAuctions > 0 then
    local minPrice = 0
    local index = 1
    while minPrice == 0 and index <= #self.allAuctions do
      minPrice = Logistician.Utilities.ToUnitPrice(self.allAuctions[index])
      index = index + 1
    end

    local available = 0
    for _, auction in ipairs(self.allAuctions) do
      available = available + auction.info[Logistician.Constants.AuctionItemInfo.Quantity]
    end

    if minPrice ~= 0 and available > 0 then
      Logistician.Utilities.DBKeyFromLink(self.allAuctions[1].itemLink, function(dbKeys)
        for _, key in ipairs(dbKeys) do
          Logistician.Database:SetPrice(key, minPrice, available)
        end
      end)
    end
  end
end

function LogisticianBuyAuctionsDataProviderMixin:GetSelectedIndex()
  for index, result in ipairs(self.currentResults) do
    if result.isSelected then
      return index
    end
  end
end

function LogisticianBuyAuctionsDataProviderMixin:SetSelectedIndex(newSelectedIndex)
  self.onPreserveScroll()
  for index, result in ipairs(self.currentResults) do
    result.notReady = false
    result.isSelected = false

    if index == newSelectedIndex and result.unitPrice ~= nil then
      result.isSelected = true
      Logistician.EventBus:Fire(self, Logistician.Buying.Events.AuctionFocussed, result)
    end
  end
end

function LogisticianBuyAuctionsDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

local COMPARATORS = {
  unitPrice = Logistician.Utilities.NumberComparator,
  stackPrice = Logistician.Utilities.NumberComparator,
  name = Logistician.Utilities.StringComparator,
  stackSize = Logistician.Utilities.StringComparator,
  numStacks = Logistician.Utilities.NumberComparator,
  otherSellers = Logistician.Utilities.StringComparator,
  isOwnedText = Logistician.Utilities.StringComparator,
  timeLeft = Logistician.Utilities.NumberComparator,
}

function LogisticianBuyAuctionsDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function LogisticianBuyAuctionsDataProviderMixin:GetTableLayout()
  return BUY_AUCTIONS_TABLE_LAYOUT
end

function LogisticianBuyAuctionsDataProviderMixin:GetColumnHideStates()
  return Logistician.Config.Get(Logistician.Config.Options.COLUMNS_BUY_AUCTIONS)
end

function LogisticianBuyAuctionsDataProviderMixin:GetRowTemplate()
  return "LogisticianBuyAuctionsResultsRowTemplate"
end
