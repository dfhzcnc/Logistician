-- Watches for completed auction sales and records them into Auctionator.Ledger.
--
-- Three things are tracked:
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
-- 3. On MAIL_INBOX_UPDATE, scan for "seller" auction invoice mail (the gold you're actually
--    paid). This is a fallback for sales that #2 can never see - if the player was offline the
--    whole time from posting to selling to mail delivery, the auction never appeared as "active"
--    in any owner-list poll, so the diff in #2 has nothing to compare against and silently
--    misses it. Mail is the one source guaranteed to eventually be seen (you have to open it to
--    collect the gold), at the cost of no market price (mail carries an item NAME only, not a
--    link - Auctionator.Ledger:AddSale resolves a real itemLink from the item cache when
--    possible, so icon/quality/tooltip still work; GET_ITEM_INFO_RECEIVED below backfills it
--    later for the rare case the item wasn't cached yet).
--
-- Caveats (inherent to the AH API, not fixable): original quantity is only known if this addon
-- was loaded and the auction was seen at least once before it sold. If the player never revisits
-- the AH after a sale, the CHAT_MSG_SYSTEM signal alone can't fill in price/quantity - those
-- fields simply won't be recorded until the next AH visit resolves them (or the mail fallback
-- above catches it instead).

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

-- Shared between the owner-scan (below) and the mail-scan (further down) so the same sale never
-- gets logged twice - once when the owner-scan notices it sold, and again later when the payout
-- mail is collected. itemName+quantity+grossTotal is the only data both sources agree on (mail
-- has no buyout/minBid/link, only a plain name and the gross gold amount).
local function MakeSaleIdentityKey(itemName, quantity, grossTotal)
  return tostring(itemName) .. "\031" .. tostring(quantity) .. "\031" .. tostring(grossTotal)
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
  local knownItemLinksByName = scanState.knownItemLinksByName
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

      -- Remembered so the mail-scan below can resolve an icon/quality/tooltip for this item by
      -- name later, even if it's never independently seen in the local item cache.
      local itemName = itemLink:match("%[(.-)%]")
      if itemName then
        knownItemLinksByName[itemName] = itemLink
      end

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

          -- If this auction was never seen active (e.g. it sold while the AH was closed, or
          -- fully sold between two polls), the real stack size is unknowable here - guessing 1
          -- would wrongly record the WHOLE stack's proceeds as a size-1 unit price. Skip logging
          -- it and let the mail fallback below catch it instead, since invoice mail always
          -- carries the correct item count.
          if originalQuantity then
            local itemName = entry.itemLink:match("%[(.-)%]")
            local saleKey = MakeSaleIdentityKey(itemName, originalQuantity, proceeds)

            if not scanState.processedSaleKeys[saleKey] then
              scanState.processedSaleKeys[saleKey] = true

              local saleType = (entry.buyoutTotal > 0 and entry.bidAmount == entry.buyoutTotal) and "buyout" or "bid"
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

-- Fallback path: scan the mailbox for auction "seller" invoice mail (the gold you're paid),
-- so a sale is still captured even if the player was offline for the whole posting-to-selling
-- window and the owner-list poll above never saw the auction while it was still active.
local function MakeMailIdentityKey(itemName, playerName, bid, buyout, count)
  return table.concat({ itemName or "", playerName or "", tostring(bid), tostring(buyout), tostring(count) }, "\031")
end

local function ScanMailForSoldAuctions()
  local scanState = Auctionator.Ledger:GetScanState()
  local processedMailKeys = scanState.processedMailKeys

  for index = 1, GetInboxNumItems() do
    local _, _, _, _, money = GetInboxHeaderInfo(index)
    local invoiceType, itemName, playerName, bid, buyout, deposit, consignment, _, _, _, count =
      GetInboxInvoiceInfo(index)

    -- A "seller" invoice with money attached is the actual sale payment (as opposed to the
    -- zero-money "Sale Pending" notice sent before the payment delay finishes).
    if invoiceType == "seller" and money and money > 0 and itemName then
      count = (count and count > 0) and count or 1
      local key = MakeMailIdentityKey(itemName, playerName, bid, buyout, count)

      if not processedMailKeys[key] then
        processedMailKeys[key] = true

        -- Payment includes the refunded deposit and excludes the AH cut. Reverse both
        -- adjustments to match the gross winning price recorded by the owner-list scan.
        local gross = money + (consignment or 0) - (deposit or 0)
        local saleKey = MakeSaleIdentityKey(itemName, count, gross)

        -- Skip if the owner-scan above already logged this exact sale - mail is only meant to
        -- catch sales the owner-scan could never see (see file header), not to double-log ones
        -- it already recorded correctly.
        if not scanState.processedSaleKeys[saleKey] then
          scanState.processedSaleKeys[saleKey] = true
          local saleType = (buyout and buyout > 0 and gross == buyout) and "buyout" or "bid"
          local resolvedLink = Auctionator.Ledger:ResolveItemLink(itemName)

          local function LogSale(marketPrice)
            Auctionator.Ledger:AddSale({
              -- AddSale falls back to resolving a link from the name itself if this is nil.
              itemLink = resolvedLink,
              itemName = itemName,
              quantity = count,
              unitPrice = math.floor(gross / count + 0.5),
              saleType = saleType,
              -- Mail can arrive well after the sale, so this is the CURRENT market snapshot,
              -- not one taken at the actual moment of sale (unlike the owner-scan above).
              marketPrice = marketPrice,
              time = time(),
            })
          end

          if resolvedLink then
            Auctionator.Utilities.DBKeyFromLink(resolvedLink, function(dbKeys)
              local marketSnapshot = dbKeys[1] and Auctionator.Database and Auctionator.Database:GetMarketSnapshot(dbKeys[1])
              LogSale(marketSnapshot and marketSnapshot.marketPrice or nil)
            end)
          else
            LogSale(nil)
          end
        end
      end
    end
  end
end

local ledgerIconBackfillFrame = CreateFrame("Frame")
ledgerIconBackfillFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
ledgerIconBackfillFrame:SetScript("OnEvent", function()
  Auctionator.Ledger:ResolveMissingIcons()
end)

local mailScanFrame = CreateFrame("Frame")
mailScanFrame:RegisterEvent("MAIL_SHOW")
mailScanFrame:RegisterEvent("MAIL_INBOX_UPDATE")
mailScanFrame:SetScript("OnEvent", function(_, event)
  if event == "MAIL_SHOW" then
    CheckInbox()
  else
    ScanMailForSoldAuctions()
  end
end)
