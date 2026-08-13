LogisticianCancellingListResultsRowMixin = CreateFromMixins(LogisticianResultsRowTemplateMixin)

function LogisticianCancellingListResultsRowMixin:OnClick(button, ...)
  Logistician.Debug.Message("LogisticianCancellingListResultsRowMixin:OnClick", self.rowData and self.rowData.id)

  if IsModifiedClick("DRESSUP") then
    DressUpLink(self.rowData.itemLink);

  elseif IsModifiedClick("CHATLINK") then
    Logistician.Utilities.InsertLink(self.rowData.itemLink)

  elseif button == "LeftButton" and Logistician.AH.IsNotThrottled() then
    self.rowData.cancelled = true
    self:ApplyFade()

    Logistician.EventBus
      :RegisterSource(self, "CancellingListResultRow")
      :Fire(self, Logistician.Cancelling.Events.RequestCancel, self.rowData)
      :UnregisterSource(self)
  elseif button == "RightButton" then
    Logistician.API.v1.MultiSearchExact(LOGISTICIAN_L_CANCELLING_TAB, { Logistician.Utilities.GetNameFromLink(self.rowData.itemLink) })
  end
end

function LogisticianCancellingListResultsRowMixin:OnEnter()
  if Logistician.AH.IsNotThrottled() then
    LogisticianResultsRowTemplateMixin.OnEnter(self)
  end
end

function LogisticianCancellingListResultsRowMixin:OnLeave()
  LogisticianResultsRowTemplateMixin.OnLeave(self)
end

function LogisticianCancellingListResultsRowMixin:Populate(rowData, dataIndex)
  LogisticianResultsRowTemplateMixin.Populate(self, rowData, dataIndex)

  self:ApplyFade()
  self:ApplyUndercutHighlight()
end

function LogisticianCancellingListResultsRowMixin:ApplyFade()
  --Fade while waiting for the cancel to take effect
  if self.rowData.cancelled then
    self:SetAlpha(0.5)
  else
    self:SetAlpha(1)
  end
end

function LogisticianCancellingListResultsRowMixin:ApplyUndercutHighlight()
  self.SelectedHighlight:SetShown(self.rowData.undercut == LOGISTICIAN_L_UNDERCUT_YES)
end

function LogisticianCancellingListResultsRowMixin:ApplyBidderHighlight()
  self.BidderHighlight:SetShown(self.rowData.bidder ~= nil)
end
