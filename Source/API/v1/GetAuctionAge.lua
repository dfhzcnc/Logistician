-- Returns the number of days since the item was seen in the auction house,
-- except if the number of days exceeds 21, then it returns nil. It will return
-- nil if there is no auction ever seen in the auction house for the item.
function Logistician.API.v1.GetAuctionAgeByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionAgeByItemID(string, number)"
    )
  end

  if Logistician.Database == nil then
    return nil
  end

  return Logistician.Database:GetPriceAge(tostring(itemID))
end

function Logistician.API.v1.GetAuctionAgeByItemLink(callerID, itemLink)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionAgeByItemLink(string, string)"
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
    if #dbKeys > 2 then
      return Logistician.Database:GetPriceAge(dbKeys[1]) or Logistician.Database:GetPriceAge(dbKeys[2])
    else
      return Logistician.Database:GetPriceAge(dbKeys[1])
    end
  else
    return Logistician.Database:GetPriceAge(
      Logistician.Utilities.BasicDBKeyFromLink(itemLink)
    )
  end
end
