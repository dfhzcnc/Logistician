function Logistician.API.v1.GetAuctionPriceByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionPriceByItemID(string, number)"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  return Logistician.Database:GetPrice(tostring(itemID))
end

function Logistician.API.v1.GetAuctionPriceByItemLink(callerID, itemLink)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionPriceByItemLink(string, string)"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    return Logistician.Database:GetFirstPrice(dbKeys)
  else
    return Logistician.Database:GetPrice(
      Logistician.Utilities.BasicDBKeyFromLink(itemLink)
    )
  end
end


-- Custom integrated build: richer current-market snapshot collected from the
-- same scan data Logistician already receives. No extra AH query is performed.
function Logistician.API.v1.GetMarketSnapshotByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetMarketSnapshotByItemID(string, number)"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  return Logistician.Database:GetMarketSnapshot(tostring(itemID))
end

function Logistician.API.v1.GetMarketSnapshotByItemLink(callerID, itemLink)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetMarketSnapshotByItemLink(string, string)"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  local dbKeys = nil
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys and #dbKeys > 0 then
    for _, dbKey in ipairs(dbKeys) do
      local snapshot = Logistician.Database:GetMarketSnapshot(dbKey)
      if snapshot ~= nil then
        return snapshot
      end
    end
    return nil
  end

  return Logistician.Database:GetMarketSnapshot(
    Logistician.Utilities.BasicDBKeyFromLink(itemLink)
  )
end

function Logistician.API.v1.GetMarketPriceByItemID(callerID, itemID)
  local snapshot =
    Logistician.API.v1.GetMarketSnapshotByItemID(callerID, itemID)
  return snapshot and snapshot.marketPrice or nil
end

function Logistician.API.v1.GetMarketPriceByItemLink(callerID, itemLink)
  local snapshot =
    Logistician.API.v1.GetMarketSnapshotByItemLink(callerID, itemLink)
  return snapshot and snapshot.marketPrice or nil
end


-- Custom integrated build: robust historical average.
-- Returns price in copper. Additional return values are:
--   number of historical day samples, number of final Tukey-rejected samples.
function Logistician.API.v1.GetAuctionAverageByItemID(callerID, itemID, days)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionAverageByItemID(string, number, [number])"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  return Logistician.Database:GetRobustAveragePrice(
    tostring(itemID),
    days or Logistician.Config.Get(
      Logistician.Config.Options.AUCTION_MEAN_DAYS_LIMIT
    ) or 21
  )
end

function Logistician.API.v1.GetAuctionAverageByItemLink(callerID, itemLink, days)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionAverageByItemLink(string, string, [number])"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  local dbKeys = nil
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  local window = days or Logistician.Config.Get(
    Logistician.Config.Options.AUCTION_MEAN_DAYS_LIMIT
  ) or 21

  if dbKeys and #dbKeys > 0 then
    for _, dbKey in ipairs(dbKeys) do
      local price, sampleCount, rejected =
        Logistician.Database:GetRobustAveragePrice(dbKey, window)

      if price ~= nil then
        return price, sampleCount, rejected
      end
    end
    return nil
  end

  return Logistician.Database:GetRobustAveragePrice(
    Logistician.Utilities.BasicDBKeyFromLink(itemLink),
    window
  )
end


-- Custom integrated build: modeled sale likelihood / marketability score.
-- Returns:
--   score 0-100,
--   label ("Very Low".."Very High"),
--   confidence label,
--   details table.
-- This is NOT a calibrated completed-sale probability because Logistician
-- observes market snapshots rather than verified outcomes for every auction.
function Logistician.API.v1.GetSaleLikelihoodByItemID(callerID, itemID, days)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetSaleLikelihoodByItemID(string, number, [number])"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  return Logistician.Database:GetSaleLikelihood(
    tostring(itemID),
    days or Logistician.Config.Get(
      Logistician.Config.Options.AUCTION_MEAN_DAYS_LIMIT
    ) or 21
  )
end

function Logistician.API.v1.GetSaleLikelihoodByItemLink(callerID, itemLink, days)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetSaleLikelihoodByItemLink(string, string, [number])"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  local dbKeys = nil
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  local window = days or Logistician.Config.Get(
    Logistician.Config.Options.AUCTION_MEAN_DAYS_LIMIT
  ) or 21

  if dbKeys and #dbKeys > 0 then
    for _, dbKey in ipairs(dbKeys) do
      local score, label, confidence, details =
        Logistician.Database:GetSaleLikelihood(dbKey, window)

      if score ~= nil then
        return score, label, confidence, details
      end
    end
    return nil
  end

  return Logistician.Database:GetSaleLikelihood(
    Logistician.Utilities.BasicDBKeyFromLink(itemLink),
    window
  )
end


-- Custom integrated build: compact expiration-aware exposure observations.
-- Intended primarily for diagnostics and future WPP/Logistician interaction.
function Logistician.API.v1.GetSaleExposureHistoryByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetSaleExposureHistoryByItemID(string, number)"
    )
  end

  if Logistician.Database == nil then
    return {}
  end

  Logistician.Database:WatchSaleExposure(tostring(itemID))
  return Logistician.Database:GetSaleExposureHistory(tostring(itemID))
end
