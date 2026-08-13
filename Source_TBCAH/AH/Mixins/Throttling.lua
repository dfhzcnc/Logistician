-- Call the appropriate method before doing the action to ensure the throttle
-- state is set correctly
-- :SearchQueried()
-- :AuctionsPosted()
-- :AuctionCancelled()
-- :BidPlaced()
LogisticianAHThrottlingFrameMixin = {}

local THROTTLING_EVENTS = {
  "AUCTION_HOUSE_CLOSED",
  "UI_ERROR_MESSAGE",
}
local NEW_AUCTION_EVENTS = {
  "NEW_AUCTION_UPDATE",
  "AUCTION_MULTISELL_START",
  "AUCTION_MULTISELL_UPDATE",
  "AUCTION_MULTISELL_FAILURE",
}
-- If we don't wait for the owned list to update before doing the next query it
-- sometimes never updates and requires that the AH is reopened to update again.
-- Includes alternate check for when the owned list doesn't update
local AUCTIONS_UPDATED_EVENTS = {
  "CHAT_MSG_SYSTEM",
}
local BID_PLACED_EVENTS = {
  "AUCTION_ITEM_LIST_UPDATE",
}
local TIMEOUT = 10

function LogisticianAHThrottlingFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianAHThrottlingFrameMixin:OnLoad")

  FrameUtil.RegisterFrameForEvents(self, THROTTLING_EVENTS)

  Logistician.EventBus:RegisterSource(self, "LogisticianAHThrottlingFrameMixin")

  self.oldReady = false
  self:ResetTimeout()
end

function LogisticianAHThrottlingFrameMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_HOUSE_CLOSED" then
    self:ResetWaiting()

  elseif eventName == "AUCTION_MULTISELL_START" then
    self:ResetTimeout()
    self.multisellInProgress = true

  elseif eventName == "NEW_AUCTION_UPDATE" then
    self:ResetTimeout()
    if not self.multisellInProgress then
      FrameUtil.UnregisterFrameForEvents(self, NEW_AUCTION_EVENTS)
      FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
      self.waitingForNewAuction = false
      self.waitingForStatusMessage = true
    end

  elseif eventName == "AUCTION_MULTISELL_UPDATE" then
    self:ResetTimeout()
    local progress, total = ...
    if progress == total then
      self.multisellInProgress = false
    end

  elseif eventName == "AUCTION_MULTISELL_FAILURE" then
    self:ResetTimeout()
    FrameUtil.UnregisterFrameForEvents(self, NEW_AUCTION_EVENTS)
    self.multisellInProgress = false
    self.waitingForNewAuction = false

  elseif eventName == "CHAT_MSG_SYSTEM" then
    local msg = ...
    -- Use "Auction ..." message to confirm the post/cancel went through
    if msg == ERR_AUCTION_STARTED or msg == ERR_AUCTION_REMOVED then
      self:ResetTimeout()
      FrameUtil.UnregisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
      self.waitingForStatusMessage = false
    end

  elseif eventName == "AUCTION_ITEM_LIST_UPDATE" then
    self:ComparePages()

  elseif eventName == "UI_ERROR_MESSAGE" then
    if AuctionFrame:IsShown() and self:AnyWaiting() then
      self:ResetWaiting()
    end
  end
end

function LogisticianAHThrottlingFrameMixin:OnUpdate(elapsed)
  if self:AnyWaiting() then
    self.timeout = self.timeout - elapsed
    if self.timeout <= 0 then
      self:ResetWaiting()
      self:ResetTimeout()
    end
  else
    self.timeout = TIMEOUT
  end
  if self.timeout ~= TIMEOUT then
    Logistician.EventBus:Fire(self, Logistician.AH.Events.CurrentThrottleTimeout, self.timeout)
  end

  local ready = self:IsReady()

  if ready and not self.oldReady then
    Logistician.EventBus:Fire(self, Logistician.AH.Events.Ready)
    Logistician.EventBus:Fire(self, Logistician.AH.Events.ThrottleUpdate, true)
  elseif self.oldReady ~= ready then
    Logistician.EventBus:Fire(self, Logistician.AH.Events.ThrottleUpdate, false)
  end

  self.oldReady = ready
end

function LogisticianAHThrottlingFrameMixin:SearchQueried()
end

function LogisticianAHThrottlingFrameMixin:IsReady()
  return (CanSendAuctionQuery()) and not self:AnyWaiting()
end

function LogisticianAHThrottlingFrameMixin:AnyWaiting()
  return self.waitingForNewAuction or self.multisellInProgress or self.waitingOnBid or self.waitingForStatusMessage
end

function LogisticianAHThrottlingFrameMixin:ResetTimeout()
  self.timeout = TIMEOUT
  Logistician.EventBus:Fire(self, Logistician.AH.Events.CurrentThrottleTimeout, self.timeout)
end

function LogisticianAHThrottlingFrameMixin:ResetWaiting()
  self.waitingForNewAuction = false
  self.multisellInProgress = false
  self.waitingOnBid = false
  self.waitingForStatusMessage = false
  FrameUtil.UnregisterFrameForEvents(self, BID_PLACED_EVENTS)
  FrameUtil.UnregisterFrameForEvents(self, NEW_AUCTION_EVENTS)
  FrameUtil.UnregisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)

  Logistician.EventBus:Fire(self, Logistician.AH.Events.ThrottleAbort)
end

function LogisticianAHThrottlingFrameMixin:AuctionsPosted()
  self:ResetTimeout()
  FrameUtil.RegisterFrameForEvents(self, NEW_AUCTION_EVENTS)
  self.waitingForNewAuction = true
  self.oldReady = false
end

function LogisticianAHThrottlingFrameMixin:AuctionCancelled()
  self:ResetTimeout()
  self.waitingForStatusMessage = true
  self.oldReady = false
  FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
end

function LogisticianAHThrottlingFrameMixin:BidPlaced()
  self:ResetTimeout()
  FrameUtil.RegisterFrameForEvents(self, BID_PLACED_EVENTS)
  self.currentPage = Logistician.AH.GetCurrentPage()
  self.waitingOnBid = true
  self.oldReady = false
end

function LogisticianAHThrottlingFrameMixin:ComparePages()
  local newPage = Logistician.AH.GetCurrentPage()
  if #newPage ~= #self.currentPage then
    self.waitingOnBid = false
    FrameUtil.UnregisterFrameForEvents(self, BID_PLACED_EVENTS)
    return
  end

  for index, auction in ipairs(self.currentPage) do
    local stackPrice = auction.info[Logistician.Constants.AuctionItemInfo.Buyout]
    local stackSize = auction.info[Logistician.Constants.AuctionItemInfo.Quantity]
    local minBid = auction.info[Logistician.Constants.AuctionItemInfo.MinBid]
    local bidAmount = auction.info[Logistician.Constants.AuctionItemInfo.BidAmount]
    local newStackPrice = newPage[index].info[Logistician.Constants.AuctionItemInfo.Buyout]
    local newStackSize = newPage[index].info[Logistician.Constants.AuctionItemInfo.Quantity]
    local newMinBid = newPage[index].info[Logistician.Constants.AuctionItemInfo.MinBid]
    local newBidAmount = newPage[index].info[Logistician.Constants.AuctionItemInfo.BidAmount]
    if stackPrice ~= newStackPrice or stackSize ~= newStackSize or
       minBid ~= newMinBid or bidAmount ~= newMinBidAmount or
       newPage[index].itemLink ~= auction.itemLink then
      self.waitingOnBid = false
      FrameUtil.UnregisterFrameForEvents(self, BID_PLACED_EVENTS)
      return
    end
  end
end
