Logistician.Constants.MaxResultsPerPage = 50
Logistician.Constants.ITEM_LEVEL_THRESHOLD = 0

Logistician.Constants.AuctionItemInfo = {
  Buyout = 10,
  Quantity = 3,
  Owner = 14,
  ItemID = 17,
  Level = 6,
  MinBid = 8,
  BidAmount = 11,
  Bidder = 12,
  SaleStatus = 16,
}

Logistician.Constants.PriceIncreaseWarningDuration = 5
Logistician.Constants.PriceIncreaseWarningThreshold = 40

--FIXME: Added to correct Blizzard error
if CASTING_BAR_ALPHA_STEP == nil then
  CASTING_BAR_ALPHA_STEP = 0.05
end
