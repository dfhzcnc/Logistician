AuctionatorPageStatusDialogMixin = {}

function AuctionatorPageStatusDialogMixin:OnLoad()
  Auctionator.EventBus:Register(self, {
    Auctionator.AH.Events.ScanResultsUpdate,
    Auctionator.AH.Events.ScanAborted,
    Auctionator.AH.Events.ScanPageStart,
  })
  self:Hide()
end

function AuctionatorPageStatusDialogMixin:OnHide()
  self:Hide()
end

-- Same look as AuctionatorStatusDialogTemplate (bordered box + StatusText) but with no
-- built-in event handling, for reuse in places that want to drive Show/Hide/SetText themselves.
AuctionatorPlainStatusDialogMixin = {}

function AuctionatorPlainStatusDialogMixin:OnLoad()
end

function AuctionatorPlainStatusDialogMixin:OnHide()
  self:Hide()
end

function AuctionatorPageStatusDialogMixin:ReceiveEvent(eventName, ...)
  if eventName == Auctionator.AH.Events.ScanPageStart then
    -- The Shopping tab shows this same "Scanning page N..." message inline in its results
    -- panel instead (see Tabs/Shopping/Mixins/Main.lua), so don't double it up here.
    if AuctionatorShoppingFrame and AuctionatorShoppingFrame:IsVisible() then
      self:Hide()
      return
    end

    local page = ...
    self:Show()
    self.StatusText:SetText(AUCTIONATOR_L_SCANNING_PAGE_X:format(page + 1))

  elseif eventName == Auctionator.AH.Events.ScanResultsUpdate then
    local _, isComplete = ...
    if isComplete then
      self:Hide()
    end

  elseif eventName == Auctionator.AH.Events.ScanAborted then
    self:Hide()
  end
end

AuctionatorThrottlingTimeoutDialogMixin = {}

function AuctionatorThrottlingTimeoutDialogMixin:OnLoad()
  Auctionator.EventBus:Register(self, {
    Auctionator.AH.Events.CurrentThrottleTimeout,
  })
  self:Hide()
end

function AuctionatorThrottlingTimeoutDialogMixin:OnHide()
  self:Hide()
end

function AuctionatorThrottlingTimeoutDialogMixin:ReceiveEvent(eventName, ...)
  if eventName == Auctionator.AH.Events.CurrentThrottleTimeout then
    local timeout = ...
    if timeout < 8 then
      self:Show()
      self.StatusText:SetText(AUCTIONATOR_L_WAITING_AT_MOST_X_LONGER:format(math.ceil(timeout)))
    else
      if self:IsShown() then
        Auctionator.Utilities.Message(AUCTIONATOR_L_SERVER_TOOK_TOO_LONG)
      end
      self:Hide()
    end
  end
end
