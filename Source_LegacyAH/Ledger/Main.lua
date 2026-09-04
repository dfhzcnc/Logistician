-- Watches for completed auction sales and records them into Auctionator.Ledger.
--
-- Two things are tracked:
-- 1. On CHAT_MSG_SYSTEM matching ERR_AUCTION_SOLD_S (same technique as the AuctionHouseNotifications
--    addon), capture the real sale timestamp the moment it happens - this fires immediately even
--    if the player isn't at the auction house, unlike the owner-list poll below. It only gives an
--    item NAME though, not price/quantity, so it's just used to correct the recorded date.
-- 2. On AUCTION_OWNED_LIST_UPDATE, scan owner auctions for ones that just flipped to "sold"
--    (an owner auction has no persistent ID across polls, so identical item+price auctions are
--    treated as fungible/interchangeable - the same simplification already used elsewhere in
--    this addon for undercut-scan matching). This is the only source for price/quantity/type,
--    and only has data while an AH session is actually open. The "Market" column is looked up
--    fresh at this same moment (the current Market (10% depth) value, same as the item tooltip),
--    representing the market price at the time of the sale, not at posting time.
--
-- Caveats (inherent to the AH API, not fixable): original quantity is only known if this addon
-- was loaded and the auction was seen at least once before it sold. If the player never revisits
-- the AH after a sale, the CHAT_MSG_SYSTEM signal alone can't fill in price/quantity - those
-- fields simply won't be recorded until the next AH visit resolves them.

local AuctionItemInfo = Auctionator.Constants.AuctionItemInfo

local function GetCleanLink(itemLink)
  return Auctionator.Search.GetCleanItemLink(itemLink)
end

-- Used to identify/diff individual owner auctions across polls. Owner auctions have no
-- persistent ID, so this composite (item + stack buyout + min bid + quantity) is used as a
-- pseudo-ID instead - the same technique used by the AuctionHouseNotifications addon. Auctions
-- that are truly identical in all four of these fields are still treated as interchangeable.
local function MakeIdentityKey(cleanLink, buyoutTotal, minBid, quantity)
  return cleanLink .. "\031" .. tostring(buyoutTotal) .. "\031" .. tostring(minBid) .. "\031" .. tostring(quantity)
end

-- FIFO queue of real sale timestamps per item NAME, learned from the "sold" system message the
-- instant it arrives (works even when the player isn't at the auction house).
local soldMessagePattern = ERR_AUCTION_SOLD_S and string.gsub(ERR_AUCTION_SOLD_S, "%%s", "(.+)")
local pendingSoldTimestamps = {}

local function PushSoldTimestamp(itemName)
  pendingSoldTimestamps[itemName] = pendingSoldTimestamps[itemName] or {}
  table.insert(pendingSoldTimestamps[itemName], time())
end

local function PopSoldTimestamp(itemName)
  local queue = pendingSoldTimestamps[itemName]
  if queue and #queue > 0 then
    return table.remove(queue, 1)
  end
  return nil
end

-- Last-known quantity of each still-active (unsold) owner auction, keyed the same way, so once an
-- auction sells (and the API zeroes its Quantity) we still know the original stack size.
-- Last-known quantity of each still-active (unsold) owner auction, and the sold-count snapshot
-- from the last poll, both persisted via Auctionator.Ledger:GetScanState() (see its definition
-- for why this must survive a /reload).

local function ScanOwnedAuctions()
  local scanState = Auctionator.Ledger:GetScanState()
  local previousSoldCounts = scanState.previousSoldCounts
  local knownActiveQuantity = scanState.knownActiveQuantity
  local currentSoldCounts = {}
  local soldEntriesThisPoll = {}
  local currentActiveQuantity = {}

  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local itemLink = GetAuctionItemLink("owner", index)
    if itemLink then
      local saleStatus = info[AuctionItemInfo.SaleStatus]
      local quantity = info[AuctionItemInfo.Quantity] or 0
      local buyoutTotal = info[AuctionItemInfo.Buyout] or 0
      local bidAmount = info[AuctionItemInfo.BidAmount] or 0
      local minBid = info[AuctionItemInfo.MinBid] or 0
      local isSold = saleStatus == 1 or quantity <= 0
      local cleanLink = GetCleanLink(itemLink)

      if not isSold then
        local key = MakeIdentityKey(cleanLink, buyoutTotal, minBid, quantity)
        currentActiveQuantity[key] = quantity
      else
        -- Quantity reads 0 once sold, so the identity key here can only use buyout+bid (the
        -- fields still populated after sale) - matched against the LAST active quantity seen
        -- for that (buyout, minBid) pair below, not the current (already-zeroed) quantity.
        local key = MakeIdentityKey(cleanLink, buyoutTotal, minBid, "sold")
        currentSoldCounts[key] = (currentSoldCounts[key] or 0) + 1
        soldEntriesThisPoll[key] = soldEntriesThisPoll[key] or {}
        table.insert(soldEntriesThisPoll[key], {
          itemLink = itemLink,
          cleanLink = cleanLink,
          buyoutTotal = buyoutTotal,
          bidAmount = bidAmount,
          minBid = minBid,
        })
      end
    end
  end

  for key, count in pairs(currentSoldCounts) do
    local newCount = count - (previousSoldCounts[key] or 0)
    if newCount > 0 then
      local entries = soldEntriesThisPoll[key]
      for i = #entries - newCount + 1, #entries do
        local entry = entries[i]
        local proceeds = math.max(entry.bidAmount, entry.minBid)

        if proceeds > 0 then
          -- Recover the original (pre-sale) quantity by scanning the active-quantity cache for
          -- a matching (item, buyout, minBid) combo, since the sold entry's own Quantity is 0.
          local originalQuantity
          for activeKey, activeQuantity in pairs(knownActiveQuantity) do
            if activeKey == MakeIdentityKey(entry.cleanLink, entry.buyoutTotal, entry.minBid, activeQuantity) then
              originalQuantity = activeQuantity
              break
            end
          end
          originalQuantity = originalQuantity or 1

          local saleType = (entry.buyoutTotal > 0 and entry.bidAmount == entry.buyoutTotal) and "buyout" or "bid"
          local itemName = entry.itemLink:match("%[(.-)%]")
          local saleTime = itemName and PopSoldTimestamp(itemName)

          -- Market price is looked up fresh right now (the moment the sale is noticed), not
          -- correlated back to posting time - DBKeyFromLink is async so AddSale is called from
          -- its callback.
          Auctionator.Utilities.DBKeyFromLink(entry.itemLink, function(dbKeys)
            local marketSnapshot = dbKeys[1] and Auctionator.Database and Auctionator.Database:GetMarketSnapshot(dbKeys[1])

            Auctionator.Ledger:AddSale({
              itemLink = entry.itemLink,
              quantity = originalQuantity,
              unitPrice = math.floor(proceeds / originalQuantity + 0.5),
              saleType = saleType,
              marketPrice = marketSnapshot and marketSnapshot.marketPrice or nil,
              time = saleTime,
            })
          end)
        end
      end
    end
  end

  scanState.previousSoldCounts = currentSoldCounts
  scanState.knownActiveQuantity = currentActiveQuantity
end

local ledgerScanFrame = CreateFrame("Frame")
ledgerScanFrame:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
ledgerScanFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
if soldMessagePattern then
  ledgerScanFrame:RegisterEvent("CHAT_MSG_SYSTEM")
end
ledgerScanFrame:SetScript("OnEvent", function(_, event, message)
  if event == "AUCTION_HOUSE_SHOW" then
    GetOwnerAuctionItems(0)
  elseif event == "CHAT_MSG_SYSTEM" then
    local itemName = string.match(message, soldMessagePattern)
    if itemName then
      PushSoldTimestamp(itemName)
      -- In case an AH session happens to already be open, resolve price/quantity immediately
      -- instead of waiting for the next natural AUCTION_OWNED_LIST_UPDATE. Harmless no-op if not.
      GetOwnerAuctionItems(0)
    end
  else
    ScanOwnedAuctions()
  end
end)
