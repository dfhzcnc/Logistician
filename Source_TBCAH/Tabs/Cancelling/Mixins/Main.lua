LogisticianCancellingFrameMixin = {}

function LogisticianCancellingFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianCancellingFrameMixin:OnLoad()")

  self.ResultsListing:SetScrollBarOffsetX(0)
  self.ResultsListing:Init(self.DataProvider)

  Logistician.EventBus:Register(self, {
    Logistician.Cancelling.Events.RequestCancel,
    Logistician.Cancelling.Events.TotalUpdated,
  })

  self.SearchFilter:HookScript("OnTextChanged", function()
    self.DataProvider:NoQueryRefresh()
  end)

  self:SetScript("OnUpdate", self.OnUpdate)
end

function LogisticianCancellingFrameMixin:OnUpdate()
  GetOwnerAuctionItems(0)
end

local ConfirmBidPricePopup = "LogisticianConfirmBidPricePopupDialog"

StaticPopupDialogs[ConfirmBidPricePopup] = {
  text = LOGISTICIAN_L_BID_EXISTING_ON_OWNED_AUCTION,
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function(self)
    Logistician.AH.CancelAuction(self.data)
    Logistician.EventBus:RegisterSource(self, "CancellingFramePopupDialog")
      :Fire(self, Logistician.Cancelling.Events.CancelConfirmed, self.data)
      :UnregisterSource(self)
  end,
  hasMoneyFrame = 1,
  showAlert = 1,
  timeout = 0,
  exclusive = 1,
  hideOnEscape = 1
}

function LogisticianCancellingFrameMixin:IsAuctionShown(auctionInfo)
  local searchString = self.SearchFilter:GetText()
  if searchString ~= "" then
    local exact = searchString:match("^\"(.*)\"$")
    local name = string.lower(Logistician.Utilities.GetNameFromLink(auctionInfo.itemLink))
    if exact then
      return name == exact
    else
      return string.find(name, string.lower(searchString), 1, true)
    end
  else
    return true
  end
end

function LogisticianCancellingFrameMixin:ReceiveEvent(eventName, ...)
  if eventName == Logistician.Cancelling.Events.RequestCancel then
    local auctionData = ...
    Logistician.Debug.Message("Executing cancel request", auctionData)

    -- Prevent cancelling auctions which someone has bid on
    local cancelCost = math.floor((auctionData.bidAmount * AUCTION_CANCEL_COST) / 100)
    if cancelCost > 0 then
      local dialog = StaticPopup_Show(ConfirmBidPricePopup)
      if dialog then
        dialog.data = auctionData
        MoneyFrame_Update(dialog.moneyFrame, cancelCost);
      end
    else
      Logistician.AH.CancelAuction(auctionData)
      Logistician.EventBus:RegisterSource(self, "CancellingFrame")
        :Fire(self, Logistician.Cancelling.Events.CancelConfirmed, auctionData)
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)

  elseif eventName == Logistician.Cancelling.Events.TotalUpdated then
    local totalOnSale, totalPending = ...

    local text = LOGISTICIAN_L_TOTAL_ON_SALE:format(
        GetMoneyString(totalOnSale, true)
      )
    if totalPending > 0 then
      text = text .. " " ..
      LOGISTICIAN_L_TOTAL_PENDING:format(
        GetMoneyString(totalPending, true)
      )
    end

    self.Total:SetText(text)
  end
end
