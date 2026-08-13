function Logistician.API.v1.IsAuctionDataExactByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.IsAuctionDataExactByItemID(string, number)"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  return Logistician.Database:GetPrice(tostring(itemID)) ~= nil
end

function Logistician.API.v1.IsAuctionDataExactByItemLink(callerID, itemLink)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.IsAuctionDataExactByItemLink(string, string)"
    )
  end

  if Logistician.Database == nil then
    return false
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    if #dbKeys > 2 then
      return Logistician.Database:GetPrice(dbKeys[1]) ~= nil or Logistician.Database:GetPrice(dbKeys[2]) ~= nil
    else
      return Logistician.Database:GetPrice(dbKeys[1]) ~= nil
    end
  else
    return Logistician.Database:GetPrice(
      Logistician.Utilities.BasicDBKeyFromLink(itemLink)
    ) ~= nil
  end
end
