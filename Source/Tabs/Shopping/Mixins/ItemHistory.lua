LogisticianItemHistoryFrameMixin = CreateFromMixins(LogisticianEscapeToCloseMixin)

function LogisticianItemHistoryFrameMixin:Init()
  self.ResultsListing:Init(self.DataProvider)

  Logistician.EventBus:Register(self, { Logistician.Shopping.Tab.Events.ShowHistoricalPrices })
  self.isDocked = false
end

function LogisticianItemHistoryFrameMixin:OnShow()
  Logistician.Debug.Message("LogisticianItemHistoryFrameMixin:OnShow()")

  Logistician.EventBus
    :RegisterSource(self, "lists item history dialog")
    :Fire(self, Logistician.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function LogisticianItemHistoryFrameMixin:OnHide()
  self:Hide()

  Logistician.EventBus
    :RegisterSource(self, "lists item history 1")
    :Fire(self, Logistician.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function LogisticianItemHistoryFrameMixin:ReceiveEvent(event, itemInfo)
  if event == Logistician.Shopping.Tab.Events.ShowHistoricalPrices then
    self.Title:SetText(LOGISTICIAN_L_X_PRICE_HISTORY:format(itemInfo.name))
  end
end

function LogisticianItemHistoryFrameMixin:OnDockDialogClicked()
  self:ClearAllPoints()
  if self.isDocked then
    self:SetPoint("CENTER", self:GetParent(), "CENTER")
    --Reset flipping
    self.Dock.Arrow:SetTexCoord(0, 1, 0, 1)
  else
    self:SetPoint("LEFT", AuctionHouseFrame or AuctionFrame, "RIGHT")
    --Flip the texture to point back in
    self.Dock.Arrow:SetTexCoord(1, 0, 0, 1)
  end

  self.isDocked = not self.isDocked
end

function LogisticianItemHistoryFrameMixin:OnCloseDialogClicked()
  self:Hide()
end
