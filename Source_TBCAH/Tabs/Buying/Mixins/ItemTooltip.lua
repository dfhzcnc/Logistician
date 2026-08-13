LogisticianBuyingItemTooltipMixin = {}

function LogisticianBuyingItemTooltipMixin:OnLoad()
  Logistician.EventBus:Register(self, {
    Logistician.Buying.Events.ShowForShopping
  })
end

function LogisticianBuyingItemTooltipMixin:OnEnter()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetHyperlink(self.itemLink)
  GameTooltip:Show()
end

function LogisticianBuyingItemTooltipMixin:OnLeave()
  GameTooltip:Hide()
end

function LogisticianBuyingItemTooltipMixin:OnMouseUp()
  if IsModifiedClick("CHATLINK") then
    Logistician.Utilities.InsertLink(self.itemLink)
  else
    if self.itemLink ~= nil then
      -- Search for item in the browse tab (so that someone can check the bid
      -- prices)
      if BrowseResetButton then
        -- BrowseResetButton doesn't exist on classic era
        BrowseResetButton:Click()
      end
      BrowseName:SetText(Logistician.Utilities.GetNameFromLink(self.itemLink))
      AuctionFrameTab1:Click()
      AuctionFrameBrowse_Search()
    end
  end
end

function LogisticianBuyingItemTooltipMixin:ReceiveEvent(eventName, eventData)
  self.itemLink = eventData.itemLink
  self.Icon:SetTexture(eventData.iconTexture)
  self.Text:SetText(eventData.itemName)

  local vendorPrice = Logistician.API.v1.GetVendorPriceByItemLink("!Logistician", eventData.itemLink)
  if not vendorPrice then
    -- The vendor cache is populated as items are encountered. Item info can
    -- already contain the sell price before that cache has learned the item.
    vendorPrice = select(11, GetItemInfo(eventData.itemLink))
  end
  local averagePrice = Logistician.API.v1.GetAuctionAverageByItemLink("!Logistician", eventData.itemLink, 21)
  local unavailable = "|cff888888--|r"
  local vendorText = vendorPrice and GetMoneyString(vendorPrice, true) or unavailable
  local averageText = averagePrice and GetMoneyString(averagePrice, true) or unavailable
  self.PriceSummary:SetText(
    "|cffffd100Vendor:|r " .. vendorText
      .. "    |cffffd100Avg 21d:|r " .. averageText
  )
end
