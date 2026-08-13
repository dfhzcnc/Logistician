function Logistician.API.v1.GetDisenchantPriceByItemID(callerID, itemID)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionPriceByItemID(string, number)"
    )
  end

  local itemInfo = { C_Item.GetItemInfo(itemID) }
  local itemLink = itemInfo[2]

  if itemLink ~= nil then
    return Logistician.Enchant.GetDisenchantAuctionPrice(itemLink, itemInfo)
  else
    return nil
  end
end

function Logistician.API.v1.GetDisenchantPriceByItemLink(callerID, itemLink)
  Logistician.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetAuctionPriceByItemLink(string, string)"
    )
  end

  local itemInfo = { C_Item.GetItemInfo(itemLink) }

  if #itemInfo > 0 then
    return Logistician.Enchant.GetDisenchantAuctionPrice(itemLink, itemInfo)
  else
    return nil
  end
end
