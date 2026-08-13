function Logistician.Utilities.ToUnitPrice(entry)
  local quantity = entry.info[Logistician.Constants.AuctionItemInfo.Quantity]
  if quantity ~= 0 then
    return math.ceil(entry.info[Logistician.Constants.AuctionItemInfo.Buyout] / quantity)
  else
    return 0
  end
end
