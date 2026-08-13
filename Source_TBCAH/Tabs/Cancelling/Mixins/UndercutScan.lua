LogisticianUndercutScanMixin = {}

local ABORT_EVENTS = {
  "AUCTION_HOUSE_CLOSED"
}

local QUERY_EVENTS = {
  Logistician.AH.Events.ScanResultsUpdate,
  Logistician.AH.Events.ScanAborted,
}

local THROTTLE_EVENTS = {
  Logistician.AH.Events.Ready,
}

local function IsCancelPossible(info)
  return info[Logistician.Constants.AuctionItemInfo.SaleStatus] ~= 1 and
      info[Logistician.Constants.AuctionItemInfo.BidAmount] == 0
end

function LogisticianUndercutScanMixin:OnLoad()
  Logistician.EventBus:RegisterSource(self, "LogisticianUndercutScanMixin")
  Logistician.EventBus:Register(self, {
    Logistician.Cancelling.Events.RequestCancel,
    Logistician.Cancelling.Events.RequestCancelUndercut,
  })

  self.seenUndercutDetails = {}

  self:SetCancel()
end

local function UndercutCheck(unitPrice, positions, maxItemsAhead, minPrice)
  local seenItemsAhead = Logistician.Constants.MaxResultsPerPage + 1
  for _, p in ipairs(positions) do
    if p.unitPrice == unitPrice then
      seenItemsAhead = p.itemsAhead
      break
    end
  end
  return seenItemsAhead > Logistician.Config.Get(Logistician.Config.Options.UNDERCUT_ITEMS_AHEAD)
end

function LogisticianUndercutScanMixin:AnyUndercutItems()
  local allAuctions = Logistician.AH.DumpAuctions("owner")
  for _, auction in ipairs(allAuctions) do
    local details = self.seenUndercutDetails[Logistician.Search.GetCleanItemLink(auction.itemLink)]
    if IsCancelPossible(auction.info) and details ~= nil and UndercutCheck(Logistician.Utilities.ToUnitPrice(auction), details.positions, details.maxItemsAhead, details.minPrice) then
      return true
    end
  end
end

function LogisticianUndercutScanMixin:OnShow()
  SetOverrideBinding(self, false, Logistician.Config.Get(Logistician.Config.Options.CANCEL_UNDERCUT_SHORTCUT), "CLICK LogisticianCancelUndercutButton:LeftButton")
  Logistician.EventBus:Register(self, THROTTLE_EVENTS)
end

function LogisticianUndercutScanMixin:OnHide()
  ClearOverrideBindings(self)
  Logistician.EventBus:Unregister(self, THROTTLE_EVENTS)

  -- Stop scan when changing away from the Cancelling tab
  Logistician.AH.AbortQuery()
  self:EndScan()
end

function LogisticianUndercutScanMixin:StartScan()
  Logistician.Debug.Message("LogisticianUndercutScanMixin:OnUndercutScanButtonClick()")

  self.allOwnedAuctions = Logistician.AH.DumpAuctions("owner")
  self.scanIndex = 0
  self.seenUndercutDetails = {}

  Logistician.EventBus:Fire(self, Logistician.Cancelling.Events.UndercutScanStart)

  FrameUtil.RegisterFrameForEvents(self, ABORT_EVENTS)

  self.StartScanButton:SetEnabled(false)
  self:SetCancel()

  self:NextStep()
end

function LogisticianUndercutScanMixin:SetCancel()
  self.CancelNextButton:SetEnabled(self:AnyUndercutItems() and Logistician.AH.IsNotThrottled())
end

function LogisticianUndercutScanMixin:EndScan()
  Logistician.Debug.Message("undercut scan ended")

  FrameUtil.UnregisterFrameForEvents(self, ABORT_EVENTS)
  Logistician.EventBus:Unregister(self, QUERY_EVENTS)

  self.StartScanButton:SetEnabled(true)

  self:SetCancel()
end

function LogisticianUndercutScanMixin:NextStep()
  Logistician.Debug.Message("undercut scan: next step")
  self.scanIndex = self.scanIndex + 1

  if self.scanIndex > #self.allOwnedAuctions then
    self:EndScan()
    return
  end

  self.currentAuction = self.allOwnedAuctions[self.scanIndex]
  local info = self.currentAuction.info
  local cleanLink = Logistician.Search.GetCleanItemLink(self.currentAuction.itemLink)

  if (not IsCancelPossible(info) or
      not self:GetParent():IsAuctionShown(self.currentAuction)) then
    Logistician.Debug.Message("undercut scan skip", self.currentAuction.itemLink)

    self:NextStep()
  elseif self.seenUndercutDetails[cleanLink] ~= nil then
    --The price has already been seen and reported by an event, so move on.
    self:NextStep()
  else
    Logistician.Debug.Message("undercut scan searching for undercuts", self.currentAuction.itemLink, cleanLink)

    self:SearchForUndercuts(self.currentAuction)
  end
end

function LogisticianUndercutScanMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_HOUSE_CLOSED" then
    self:EndScan()
  end
end

function LogisticianUndercutScanMixin:ReceiveEvent(eventName, ...)
  if eventName == Logistician.Cancelling.Events.RequestCancel then
    self.CancelNextButton:Disable()

  elseif eventName == Logistician.AH.Events.Ready then
    self:SetCancel()

  elseif eventName == Logistician.Cancelling.Events.RequestCancelUndercut then
    if self.CancelNextButton:IsEnabled() then
      self:CancelNextAuction()
    end

  elseif eventName == Logistician.AH.Events.ScanResultsUpdate then
    local results, gotAllResults = ...
    local itemID = C_Item.GetItemInfoInstant(self.currentAuction.itemLink)
    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(function()
      self:ProcessScanResult(results, gotAllResults)
    end)

  elseif eventName == Logistician.AH.Events.ScanAborted then
    Logistician.Debug.Message("undercut scan: aborting", self.currentAuction and self.currentAuction.itemLink)
    Logistician.EventBus:Unregister(self, QUERY_EVENTS)
  end
end

function LogisticianUndercutScanMixin:SearchForUndercuts(auction)
  Logistician.Debug.Message("undercut scan: searching", name)

  Logistician.AH.AbortQuery()

  Logistician.EventBus:Register(self, QUERY_EVENTS)

  if Logistician.Config.Get(Logistician.Config.Options.SELLING_IGNORE_ITEM_SUFFIX) and Logistician.Utilities.IsEquipment(select(6, C_Item.GetItemInfoInstant(self.currentAuction.itemLink))) then
    Logistician.AH.QueryAuctionItems({
      searchString = C_Item.GetItemNameByID((C_Item.GetItemInfoInstant(self.currentAuction.itemLink))),
      isExact = false,
    })
  else
    Logistician.AH.QueryAuctionItems({
      searchString = Logistician.Utilities.GetNameFromLink(auction.itemLink),
      isExact = true,
    })
  end
end

function LogisticianUndercutScanMixin:ProcessScanResult(results, gotAllResults)
  local cleanLink = Logistician.Search.GetCleanItemLink(self.currentAuction.itemLink)

  local itemIDWanted = C_Item.GetItemInfoInstant(self.currentAuction.itemLink)
  local itemLevelWanted = GetDetailedItemLevelInfo(self.currentAuction.itemLink)

  local ignoreItemSuffix = Logistician.Config.Get(Logistician.Config.Options.SELLING_IGNORE_ITEM_SUFFIX)

  local positions = {}
  local itemsAhead = 0
  local minPrice
  local playerName = UnitName("player")
  local seenUnitPrices = {}
  for _, r in ipairs(results) do
    local resultCleanLink = Logistician.Search.GetCleanItemLink(r.itemLink)
    local unitPrice = Logistician.Utilities.ToUnitPrice(r)
    local itemID = C_Item.GetItemInfoInstant(resultCleanLink)
    -- Assumes that scan results are sorted by Blizzard column unitprice
    if unitPrice ~= 0 and (
        cleanLink == resultCleanLink or
        (ignoreItemSuffix and itemID == itemIDWanted)) then
      if r.info[Logistician.Constants.AuctionItemInfo.Owner] == playerName and seenUnitPrices[unitPrice] == nil then
        seenUnitPrices[unitPrice] = true
        table.insert(positions, {
          unitPrice = unitPrice,
          itemsAhead = itemsAhead,
        })
      end
      if minPrice == nil then
        minPrice = unitPrice
      end
      itemsAhead = itemsAhead + r.info[Logistician.Constants.AuctionItemInfo.Quantity]
    end
  end
  if minPrice == nil then
    minPrice = 0
  end
  if itemsAhead > 0 or gotAllResults then
    self.seenUndercutDetails[cleanLink] = {
      positions = positions,
      minPrice = minPrice,
      maxItemsAhead = itemsAhead,
    }
    Logistician.Debug.Message("undercut scan: next step", self.currentAuction and self.currentAuction.itemLink)
    if not gotAllResults then
      Logistician.AH.AbortQuery()
    else
      Logistician.EventBus:Unregister(self, QUERY_EVENTS)
    end

    Logistician.EventBus:Fire(self, Logistician.Cancelling.Events.UndercutStatus, cleanLink, positions, itemsAhead, minPrice)
    self:NextStep()
  end
end

function LogisticianUndercutScanMixin:CancelNextAuction()
  Logistician.Debug.Message("LogisticianUndercutScanMixin:CancelNextAuction()")

  local allAuctions = Logistician.AH.DumpAuctions("owner")
  for _, auction in ipairs(allAuctions) do
    local details = self.seenUndercutDetails[Logistician.Search.GetCleanItemLink(auction.itemLink)]
    local undercut = IsCancelPossible(auction.info) and details ~= nil and UndercutCheck(Logistician.Utilities.ToUnitPrice(auction), details.positions, details.maxItemsAhead, details.minPrice)
    if undercut then
      Logistician.EventBus:Fire(self, Logistician.Cancelling.Events.RequestCancel, {
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
      })
      return
    end
  end
end
