SYSTEM_EVENTS = {
  "CHAT_MSG_SYSTEM", --ERR_AUCTION_STARTED "Auction created"
  "UI_ERROR_MESSAGE", --ERR_AUCTION_DATABASE_ERROR "Internal auction error"
}

LogisticianPostWatchMixin = {}

function LogisticianPostWatchMixin:StopWatching()
  self.details = nil
  if self.waitingForConfirmation then
    FrameUtil.UnregisterFrameForEvents(self, SYSTEM_EVENTS)
  end
  self.waitingForConfirmation = false
end

function LogisticianPostWatchMixin:ReceiveEvent(eventName, details)
  if eventName == Logistician.Selling.Events.PostAttempt then
    self.details = details
    self.details.numStacksReached = 0
    Logistician.Debug.Message("post attempt", self.details.itemInfo.itemLink)
    if not self.waitingForConfirmation then
      self.waitingForConfirmation = true
      FrameUtil.RegisterFrameForEvents(self, SYSTEM_EVENTS)
    end
  end
end

function LogisticianPostWatchMixin:OnEvent(eventName, eventData1, eventData2)
  if eventName == "CHAT_MSG_SYSTEM" and eventData1 == ERR_AUCTION_STARTED then
    self.details.numStacksReached = self.details.numStacksReached + 1

    if self.details.numStacksReached == self.details.numStacks then
      Logistician.Debug.Message("pass", self.details.itemInfo.itemLink)
      local details = self.details
      self:StopWatching()
      Logistician.EventBus:Fire(self, Logistician.Selling.Events.PostSuccessful, details)
    end
  elseif eventName == "UI_ERROR_MESSAGE" and eventData2 == ERR_AUCTION_DATABASE_ERROR then
    Logistician.Debug.Message("fail blizz internal auction error", self.details.itemInfo.itemLink)
    local details = self.details
    self:StopWatching()
    Logistician.EventBus:Fire(self, Logistician.Selling.Events.PostFailed, details)
  end
end

function LogisticianPostWatchMixin:OnShow()
  Logistician.EventBus:Register(self, {
    Logistician.Selling.Events.PostAttempt,
  })
  Logistician.EventBus:RegisterSource(self, "LogisticianPostWatchMixin")
end

function LogisticianPostWatchMixin:OnHide()
  self:StopWatching()
  Logistician.EventBus:Unregister(self, {
    Logistician.Selling.Events.PostAttempt,
  })
end
