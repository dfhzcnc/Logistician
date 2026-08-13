function Logistician.API.v1.GetVendorPriceByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetVendorPriceByItemID(string, number)"
    )
  end

  return LOGISTICIAN_VENDOR_PRICE_CACHE[tostring(itemID)]
end

function Logistician.API.v1.GetVendorPriceByItemLink(callerID, itemLink)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetVendorPriceByItemLink(string, string)"
    )
  end

  local dbKeys = nil
  -- Use that the callback is called immediately (and populates dbKeys) if the
  -- item info for item levels is available now.
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeysCallback)
    dbKeys = dbKeysCallback
  end)

  if dbKeys then
    for _, key in ipairs(dbKeys) do
      if LOGISTICIAN_VENDOR_PRICE_CACHE[key] then
        return LOGISTICIAN_VENDOR_PRICE_CACHE[key]
      end
    end
  else
    return LOGISTICIAN_VENDOR_PRICE_CACHE[Logistician.Utilities.BasicDBKeyFromLink(itemLink)]
  end
end
