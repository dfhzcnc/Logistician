LogisticianPageStatusDialogMixin = {}

function LogisticianPageStatusDialogMixin:OnLoad()
  Logistician.EventBus:Register(self, {
    Logistician.AH.Events.ScanResultsUpdate,
    Logistician.AH.Events.ScanAborted,
    Logistician.AH.Events.ScanPageStart,
  })
  self:Hide()
end

function LogisticianPageStatusDialogMixin:OnHide()
  self:Hide()
end

function LogisticianPageStatusDialogMixin:ReceiveEvent(eventName, ...)
  if eventName == Logistician.AH.Events.ScanPageStart then
    local page = ...
    self:Show()
    self.StatusText:SetText(LOGISTICIAN_L_SCANNING_PAGE_X:format(page + 1))

  elseif eventName == Logistician.AH.Events.ScanResultsUpdate then
    local _, isComplete = ...
    if isComplete then
      self:Hide()
    end

  elseif eventName == Logistician.AH.Events.ScanAborted then
    self:Hide()
  end
end

LogisticianThrottlingTimeoutDialogMixin = {}

function LogisticianThrottlingTimeoutDialogMixin:OnLoad()
  Logistician.EventBus:Register(self, {
    Logistician.AH.Events.CurrentThrottleTimeout,
  })
  self:Hide()
end

function LogisticianThrottlingTimeoutDialogMixin:OnHide()
  self:Hide()
end

function LogisticianThrottlingTimeoutDialogMixin:ReceiveEvent(eventName, ...)
  if eventName == Logistician.AH.Events.CurrentThrottleTimeout then
    local timeout = ...
    if timeout < 8 then
      self:Show()
      self.StatusText:SetText(LOGISTICIAN_L_WAITING_AT_MOST_X_LONGER:format(math.ceil(timeout)))
    else
      if self:IsShown() then
        Logistician.Utilities.Message(LOGISTICIAN_L_SERVER_TOOK_TOO_LONG)
      end
      self:Hide()
    end
  end
end
