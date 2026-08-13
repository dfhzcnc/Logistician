local CANCELLING_TABLE_LAYOUT = {
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "name" },
    headerText = LOGISTICIAN_L_NAME,
    cellTemplate = "LogisticianItemKeyCellTemplate",
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_QUANTITY,
    headerParameters = { "stackSize" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "availablePretty" },
    width = 110,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_UNIT_PRICE,
    headerParameters = { "unitPrice" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "unitPrice" },
    width = 150,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_STACK_PRICE,
    headerParameters = { "stackPrice" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "stackPrice" },
    defaultHide = true,
    width = 150,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_BID_PRICE,
    headerParameters = { "minBid" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "minBid" },
    defaultHide = true,
    width = 150,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_BIDDER,
    headerParameters = { "bidder" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "bidder" },
    defaultHide = true,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_TIME_LEFT,
    headerParameters = { "timeLeft" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "timeLeftPretty" },
    width = 90,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_IS_UNDERCUT,
    headerParameters = { "undercut" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "undercut" },
    width = 90,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_UNDERCUT_PRICE,
    headerParameters = { "undercutPrice" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "undercutPrice" },
    width = 150,
    defaultHide = true,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_ITEMS_AHEAD,
    headerParameters = { "itemsAhead" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "itemsAheadPretty" },
    width = 90,
  },
}

local DATA_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
}

local EVENT_BUS_EVENTS = {
  Logistician.Cancelling.Events.UndercutStatus,
  Logistician.Cancelling.Events.UndercutScanStart,
  Logistician.AH.Events.ThrottleUpdate,
}

LogisticianCancellingDataProviderMixin = CreateFromMixins(LogisticianDataProviderMixin, LogisticianItemStringLoadingMixin)

function LogisticianCancellingDataProviderMixin:OnLoad()
  LogisticianDataProviderMixin.OnLoad(self)
  LogisticianItemStringLoadingMixin.OnLoad(self)

  self.undercutCutoff = {}
end

function LogisticianCancellingDataProviderMixin:OnShow()
  Logistician.EventBus:Register(self, EVENT_BUS_EVENTS)

  self:NoQueryRefresh()

  FrameUtil.RegisterFrameForEvents(self, DATA_EVENTS)
end

function LogisticianCancellingDataProviderMixin:OnHide()
  Logistician.EventBus:Unregister(self, EVENT_BUS_EVENTS)

  FrameUtil.UnregisterFrameForEvents(self, DATA_EVENTS)
end

function LogisticianCancellingDataProviderMixin:NoQueryRefresh()
  self.onPreserveScroll()
  self:PopulateAuctions()
end

local COMPARATORS = {
  unitPrice = Logistician.Utilities.NumberComparator,
  stackPrice = Logistician.Utilities.NumberComparator,
  bidAmount = Logistician.Utilities.NumberComparator,
  name = Logistician.Utilities.StringComparator,
  bidder = Logistician.Utilities.StringComparator,
  stackSize = Logistician.Utilities.NumberComparator,
  timeLeft = Logistician.Utilities.NumberComparator,
  undercut = Logistician.Utilities.StringComparator,
  undercutPrice = Logistician.Utilities.NumberComparator,
  itemsAhead = Logistician.Utilities.NumberComparator,
}

function LogisticianCancellingDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function LogisticianCancellingDataProviderMixin:OnEvent(eventName, auctionID, ...)
  if eventName == "AUCTION_OWNED_LIST_UPDATE" then
    self:NoQueryRefresh()
  end
end

function LogisticianCancellingDataProviderMixin:ReceiveEvent(eventName, eventData, ...)
  if eventName == Logistician.Cancelling.Events.UndercutScanStart then
    self.undercutCutoff = {}

    self:NoQueryRefresh()

  elseif eventName == Logistician.Cancelling.Events.UndercutStatus then
    local positions, maxItemsAhead, minPrice = ...
    self.undercutCutoff[eventData] = { positions = positions, maxItemsAhead = maxItemsAhead, minPrice = minPrice }

    self:NoQueryRefresh()
  elseif eventName == Logistician.AH.Events.ThrottleUpdate then
    if eventData then
      self:NoQueryRefresh()
    end
  end
end

function LogisticianCancellingDataProviderMixin:IsValidAuction(auctionInfo)
  return not auctionInfo.isSold and (auctionInfo.stackPrice ~= 0 or auctionInfo.minBid ~= 0)
end

function LogisticianCancellingDataProviderMixin:IsSoldAuction(auctionInfo)
  return auctionInfo.isSold and auctionInfo.stackPrice ~= 0
end


function LogisticianCancellingDataProviderMixin:FilterAuction(auctionInfo)
  return self:GetParent():IsAuctionShown(auctionInfo)
end

local function ToUniqueKey(entry)
  return Logistician.Search.GetCleanItemLink(entry.itemLink) .. " " .. entry.stackPrice .. " " .. entry.stackSize .. " " .. tostring(entry.isSold) .. " " .. tostring(entry.bidAmount) .. " " .. tostring(entry.minBid) .. " " .. tostring(entry.bidder) .. " " .. entry.timeLeft
end

local function GroupAuctions(allAuctions)
  local seenDetails = {}

  local results = {}
  for index, auction in ipairs(allAuctions) do
    local newEntry = {
      itemLink = auction.itemLink,
      unitPrice = Logistician.Utilities.ToUnitPrice(auction),
      stackPrice = auction.info[Logistician.Constants.AuctionItemInfo.Buyout],
      stackSize = auction.info[Logistician.Constants.AuctionItemInfo.Quantity],
      isSold = auction.info[Logistician.Constants.AuctionItemInfo.SaleStatus] == 1,
      numStacks = 1,
      isOwned = true,
      bidAmount = auction.info[Logistician.Constants.AuctionItemInfo.BidAmount],
      minBid = auction.info[Logistician.Constants.AuctionItemInfo.MinBid],
      bidder = auction.info[Logistician.Constants.AuctionItemInfo.Bidder],
      timeLeft = auction.timeLeft,
      index = index,
    }
    if newEntry.itemLink ~= nil then
      local key = ToUniqueKey(newEntry)
      if seenDetails[key] then
        seenDetails[key].numStacks = seenDetails[key].numStacks + 1
      else
        seenDetails[key] = newEntry
        table.insert(results, newEntry)
      end
    end
  end

  table.sort(results, function(a, b)
    if a.bidAmount > 0 and b.bidAmount == 0 then
      return true
    elseif b.bidAmount > 0 and a.bidAmount == 0 then
      return false
    elseif a.bidAmount > 0 and b.bidAmount > 0 then
      return a.bidAmount > b.bidAmount
    else
      return a.index < b.index
    end
  end)

  return results
end

local function GetItemsAhead(unitPrice, positions, maxItemsAhead)
  for _, p in ipairs(positions) do
    if p.unitPrice == unitPrice then
      return p.itemsAhead, FormatLargeNumber(p.itemsAhead)
    end
  end
  return maxItemsAhead, FormatLargeNumber(maxItemsAhead) .. "+"
end

function LogisticianCancellingDataProviderMixin:PopulateAuctions()
  self:Reset()
  local allAuctions = GroupAuctions(Logistician.AH.DumpAuctions("owner"))
  local totalOnSale = 0
  local totalPending = 0

  local results = {}
  for _, auction in ipairs(allAuctions) do

    --Only display unsold and uncancelled (yet) auctions
    if self:IsValidAuction(auction)  then
      if self:FilterAuction(auction) then
        totalOnSale = totalOnSale + auction.stackPrice * auction.numStacks

        local cleanLink = Logistician.Search.GetCleanItemLink(auction.itemLink)
        local undercutStatus
        local undercutPrice
        local itemsAhead, itemsAheadPretty
        if auction.bidAmount ~= 0 then
          undercutStatus = LOGISTICIAN_L_UNDERCUT_BID
        elseif self.undercutCutoff[cleanLink] == nil then
          undercutStatus = LOGISTICIAN_L_UNDERCUT_UNKNOWN
        elseif auction.unitPrice > self.undercutCutoff[cleanLink].minPrice then
          undercutPrice = self.undercutCutoff[cleanLink].minPrice
          itemsAhead, itemsAheadPretty = GetItemsAhead(auction.unitPrice, self.undercutCutoff[cleanLink].positions, self.undercutCutoff[cleanLink].maxItemsAhead)
          if itemsAhead > Logistician.Config.Get(Logistician.Config.Options.UNDERCUT_ITEMS_AHEAD) then
            undercutStatus = LOGISTICIAN_L_UNDERCUT_YES
          else
            undercutStatus = LOGISTICIAN_L_UNDERCUT_NO
          end
        else
          itemsAhead = 0
          itemsAheadPretty = tostring(itemsAhead)
          undercutStatus = LOGISTICIAN_L_UNDERCUT_NO
        end
        table.insert(results, {
          numStacks = auction.numStacks,
          stackSize = auction.stackSize,
          stackPrice = auction.stackPrice,
          minBid = auction.minBid,
          itemString = cleanLink,
          unitPrice = auction.unitPrice,
          bidder = auction.bidder or "",
          bidAmount = auction.bidAmount,
          itemLink = auction.itemLink, -- Used for tooltips
          timeLeft = auction.timeLeft,
          timeLeftPretty = Logistician.Utilities.FormatTimeLeftBand(auction.timeLeft),
          undercut = undercutStatus,
          undercutPrice = undercutPrice,
          itemsAhead = itemsAhead,
          itemsAheadPretty = itemsAheadPretty,
        })
        Logistician.Utilities.SetStacksText(results[#results])
      end
    elseif self:IsSoldAuction(auction) then
      totalPending = totalPending + auction.stackPrice * auction.numStacks
    end
  end
  self:AppendEntries(results, true)

  Logistician.EventBus:RegisterSource(self, "CancellingDataProvider")
    :Fire(self, Logistician.Cancelling.Events.TotalUpdated, totalOnSale, totalPending)
    :UnregisterSource(self)
end

function LogisticianCancellingDataProviderMixin:UniqueKey(entry)
  return tostring(entry)
end

function LogisticianCancellingDataProviderMixin:GetTableLayout()
  return CANCELLING_TABLE_LAYOUT
end

function LogisticianCancellingDataProviderMixin:GetColumnHideStates()
  return Logistician.Config.Get(Logistician.Config.Options.COLUMNS_CANCELLING)
end

function LogisticianCancellingDataProviderMixin:GetRowTemplate()
  return "LogisticianCancellingListResultsRowTemplate"
end
