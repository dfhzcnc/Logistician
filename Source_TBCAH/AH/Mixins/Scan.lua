LogisticianAHScanFrameMixin = {}

local SCAN_EVENTS = {
  "AUCTION_ITEM_LIST_UPDATE",
}

local function ParamsForBlizzardAPI(query, page)
  return query.searchString, query.minLevel, query.maxLevel, page, nil, query.quality, false, query.isExact or false, query.itemClassFilters
end

function LogisticianAHScanFrameMixin:OnLoad()
  self.scanRunning = false
  Logistician.EventBus:RegisterSource(self, "LogisticianAHScanFrameMixin")
end

function LogisticianAHScanFrameMixin:IsOnLastPage()
  Logistician.Debug.Message("LogisticianAHScanFrameMixin:IsOnLastPage()")

  --Loaded all the terms from API
  return (
    (self.endPage ~= -1 and self.nextPage > self.endPage) or
    GetNumAuctionItems("list") < Logistician.Constants.MaxResultsPerPage
  )
end

function LogisticianAHScanFrameMixin:GotAllOwners()
  local result = true
  local allAuctions = Logistician.AH.DumpAuctions("list")
  for _, auction in ipairs(allAuctions) do
    result = result and auction.info[Logistician.Constants.AuctionItemInfo.Owner] ~= nil
  end

  return result
end

function LogisticianAHScanFrameMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_ITEM_LIST_UPDATE" and self.waitingOnPage and self.sentQuery and self:GotAllOwners() then
    self.waitingOnPage = false
    self:ProcessSearchResults()
  end
end

function LogisticianAHScanFrameMixin:ReceiveEvent(eventName, ...)
  if eventName == Logistician.AH.Events.ThrottleAbort then
    self:AbortQuery()
  end
end

function LogisticianAHScanFrameMixin:StartQuery(query, startPage, endPage)
  if self.scanRunning then
    error("Scan already running")
  end
  self:RegisterEvents()

  self.scanRunning = true

  self.nextPage = startPage
  self.endPage = endPage
  self.query = query
  self:DoNextSearchQuery()
end

function LogisticianAHScanFrameMixin:AbortQuery()
  if self.scanRunning then
    Logistician.AH.Queue:Remove(self.lastQueuedItem)
    self.scanRunning = false
    self:UnregisterEvents()
    Logistician.EventBus:Fire(self, Logistician.AH.Events.ScanAborted)
  end
end

function LogisticianAHScanFrameMixin:DoNextSearchQuery()
  local page = self.nextPage
  self.sentQuery = false

  self.lastQueuedItem = function()
    self.sentQuery = true
    SortAuctionSetSort("list", "unitprice")
    QueryAuctionItems(ParamsForBlizzardAPI(self.query, page))
  end
  Logistician.AH.Queue:Enqueue(self.lastQueuedItem)

  self.waitingOnPage = true
  self.nextPage = self.nextPage + 1

  Logistician.EventBus:Fire(self, Logistician.AH.Events.ScanPageStart, page)
end

function LogisticianAHScanFrameMixin:ProcessSearchResults()
  Logistician.Debug.Message("LogisticianAHScanFrameMixin:ProcessSearchResults()")

  local results = self:GetCurrentPage()

  if self:IsOnLastPage() then
    self.scanRunning = false
    self:UnregisterEvents()
  else
    self:DoNextSearchQuery()
  end
  Logistician.EventBus:Fire(self, Logistician.AH.Events.ScanResultsUpdate, results, not self.scanRunning)
end

function LogisticianAHScanFrameMixin:GetCurrentPage()
  local results = Logistician.AH.DumpAuctions("list")
  for _, entry in ipairs(results) do
    entry.query = self.query
    entry.page = self.nextPage - 1
  end

  return results
end

function LogisticianAHScanFrameMixin:RegisterEvents()
  FrameUtil.RegisterFrameForEvents(self, SCAN_EVENTS)

  Logistician.EventBus:Register(self, {
    Logistician.AH.Events.ThrottleAbort
  })
end

function LogisticianAHScanFrameMixin:UnregisterEvents()
  FrameUtil.UnregisterFrameForEvents(self, SCAN_EVENTS)

  Logistician.EventBus:Unregister(self, {
    Logistician.AH.Events.ThrottleAbort
  })
end
