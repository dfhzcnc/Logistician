function Auctionator.API.v1.GetAuctionPriceByItemID(callerID, itemID)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionPriceByItemID(string, number)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  return Auctionator.Database:GetPrice(tostring(itemID))
end

function Auctionator.API.v1.GetAuctionPriceByItemLink(callerID, itemLink)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionPriceByItemLink(string, string)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    return Auctionator.Database:GetFirstPrice(dbKeys)
  else
    return Auctionator.Database:GetPrice(
      Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
    )
  end
end


-- Custom integrated build: richer current-market snapshot collected from the
-- same scan data Auctionator already receives. No extra AH query is performed.
function Auctionator.API.v1.GetMarketSnapshotByItemID(callerID, itemID)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetMarketSnapshotByItemID(string, number)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  return Auctionator.Database:GetMarketSnapshot(tostring(itemID))
end

function Auctionator.API.v1.GetMarketSnapshotByItemLink(callerID, itemLink)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetMarketSnapshotByItemLink(string, string)"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKeys = nil
  Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys and #dbKeys > 0 then
    for _, dbKey in ipairs(dbKeys) do
      local snapshot = Auctionator.Database:GetMarketSnapshot(dbKey)
      if snapshot ~= nil then
        return snapshot
      end
    end
    return nil
  end

  return Auctionator.Database:GetMarketSnapshot(
    Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
  )
end

function Auctionator.API.v1.GetMarketPriceByItemID(callerID, itemID)
  local snapshot =
    Auctionator.API.v1.GetMarketSnapshotByItemID(callerID, itemID)
  return snapshot and snapshot.marketPrice or nil
end

function Auctionator.API.v1.GetMarketPriceByItemLink(callerID, itemLink)
  local snapshot =
    Auctionator.API.v1.GetMarketSnapshotByItemLink(callerID, itemLink)
  return snapshot and snapshot.marketPrice or nil
end


-- Custom integrated build: robust historical average.
-- Returns price in copper. Additional return values are:
--   number of historical day samples, number of final Tukey-rejected samples.
function Auctionator.API.v1.GetAuctionAverageByItemID(callerID, itemID, days)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionAverageByItemID(string, number, [number])"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  return Auctionator.Database:GetRobustAveragePrice(
    tostring(itemID),
    days or Auctionator.Config.Get(
      Auctionator.Config.Options.AUCTION_MEAN_DAYS_LIMIT
    ) or 21
  )
end

function Auctionator.API.v1.GetAuctionAverageByItemLink(callerID, itemLink, days)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetAuctionAverageByItemLink(string, string, [number])"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKeys = nil
  Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  local window = days or Auctionator.Config.Get(
    Auctionator.Config.Options.AUCTION_MEAN_DAYS_LIMIT
  ) or 21

  if dbKeys and #dbKeys > 0 then
    for _, dbKey in ipairs(dbKeys) do
      local price, sampleCount, rejected =
        Auctionator.Database:GetRobustAveragePrice(dbKey, window)

      if price ~= nil then
        return price, sampleCount, rejected
      end
    end
    return nil
  end

  return Auctionator.Database:GetRobustAveragePrice(
    Auctionator.Utilities.BasicDBKeyFromLink(itemLink),
    window
  )
end


-- Custom integrated build: modeled sale likelihood / marketability score.
-- Returns:
--   score 0-100,
--   label ("Very Low".."Very High"),
--   confidence label,
--   details table.
-- This is NOT a calibrated completed-sale probability because Auctionator
-- observes market snapshots rather than verified outcomes for every auction.
function Auctionator.API.v1.GetSaleLikelihoodByItemID(callerID, itemID, days)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetSaleLikelihoodByItemID(string, number, [number])"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  return Auctionator.Database:GetSaleLikelihood(
    tostring(itemID),
    days or Auctionator.Config.Get(
      Auctionator.Config.Options.AUCTION_MEAN_DAYS_LIMIT
    ) or 21
  )
end

function Auctionator.API.v1.GetSaleLikelihoodByItemLink(callerID, itemLink, days)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetSaleLikelihoodByItemLink(string, string, [number])"
    )
  end

  if Auctionator.Database == nil then
    return nil
  end

  local dbKeys = nil
  Auctionator.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  local window = days or Auctionator.Config.Get(
    Auctionator.Config.Options.AUCTION_MEAN_DAYS_LIMIT
  ) or 21

  if dbKeys and #dbKeys > 0 then
    for _, dbKey in ipairs(dbKeys) do
      local score, label, confidence, details =
        Auctionator.Database:GetSaleLikelihood(dbKey, window)

      if score ~= nil then
        return score, label, confidence, details
      end
    end
    return nil
  end

  return Auctionator.Database:GetSaleLikelihood(
    Auctionator.Utilities.BasicDBKeyFromLink(itemLink),
    window
  )
end


-- Custom integrated build: compact expiration-aware exposure observations.
-- Intended primarily for diagnostics and future WPP/Auctionator interaction.
function Auctionator.API.v1.GetSaleExposureHistoryByItemID(callerID, itemID)
  Auctionator.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Auctionator.API.ComposeError(
      callerID,
      "Usage Auctionator.API.v1.GetSaleExposureHistoryByItemID(string, number)"
    )
  end

  if Auctionator.Database == nil then
    return {}
  end

  Auctionator.Database:WatchSaleExposure(tostring(itemID))
  return Auctionator.Database:GetSaleExposureHistory(tostring(itemID))
end
