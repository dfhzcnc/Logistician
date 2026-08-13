-- query = {
--   searchString -> string
--   minLevel -> int?
--   maxLevel -> int?
--   itemClassFilters -> itemClassFilter[]
--   isExact -> boolean?
-- }
function Logistician.AH.QueryAuctionItems(query)
  Logistician.AH.Internals.scan:StartQuery(query, 0, -1)
end

function Logistician.AH.QueryAndFocusPage(query, page)
  Logistician.AH.Internals.scan:StartQuery(query, page, page)
end

function Logistician.AH.GetCurrentPage()
  return Logistician.AH.Internals.scan:GetCurrentPage()
end

function Logistician.AH.AbortQuery()
  Logistician.AH.Internals.scan:AbortQuery()
end

-- Event ThrottleUpdate will fire whenever the state changes
function Logistician.AH.IsNotThrottled()
  return Logistician.AH.Internals.throttling:IsReady()
end

function Logistician.AH.GetAuctionItemSubClasses(classID)
  return { GetAuctionItemSubClasses(classID) }
end

function Logistician.AH.PlaceAuctionBid(...)
  Logistician.AH.Internals.throttling:BidPlaced()
  PlaceAuctionBid("list", ...)
end

function Logistician.AH.PostAuction(...)
  Logistician.AH.Internals.throttling:AuctionsPosted()
  PostAuction(...)
end

-- view is a string and must be "list", "owner" or "bidder"
function Logistician.AH.DumpAuctions(view)
  local auctions = {}
  for index = 1, GetNumAuctionItems(view) do
    local auctionInfo = { GetAuctionItemInfo(view, index) }
    local itemLink = GetAuctionItemLink(view, index)
    local timeLeft = GetAuctionItemTimeLeft(view, index)
    local entry = {
      info = auctionInfo,
      itemLink = itemLink,
      timeLeft = timeLeft - 1, -- Normalize the API time-left value.
      index = index,
    }
    table.insert(auctions, entry)
  end
  return auctions
end

function Logistician.AH.CancelAuction(auction)
  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }

    local stackPrice = info[Logistician.Constants.AuctionItemInfo.Buyout]
    local stackSize = info[Logistician.Constants.AuctionItemInfo.Quantity]
    local bidAmount = info[Logistician.Constants.AuctionItemInfo.BidAmount]
    local saleStatus = info[Logistician.Constants.AuctionItemInfo.SaleStatus]
    local itemLink = GetAuctionItemLink("owner", index)

    if saleStatus ~= 1 and auction.bidAmount == bidAmount and auction.stackPrice == stackPrice and auction.stackSize == stackSize and Logistician.Search.GetCleanItemLink(itemLink) == Logistician.Search.GetCleanItemLink(auction.itemLink) then
      Logistician.AH.Internals.throttling:AuctionCancelled()
      CancelAuction(index)
      break
    end
  end
end
