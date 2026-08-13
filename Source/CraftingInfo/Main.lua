local GetMerchantItemInfo = GetMerchantItemInfo or function(index)
  local info = C_MerchantFrame.GetItemInfo(index);
  if info then
    return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isPurchasable, info.isUsable, info.hasExtendedCost, info.currencyID, info.spellID;
  end
end
function Logistician.CraftingInfo.CacheVendorPrices()
  for i = 1, GetMerchantNumItems() do
    local itemID = GetMerchantItemID(i)
    if itemID ~= nil then
      local item = Item:CreateFromItemID(itemID)
      if not item:IsItemEmpty() then
        item:ContinueOnItemLoad(function()
          local price, stack, numAvailable = select(3, GetMerchantItemInfo(i))
          local itemLink = GetMerchantItemLink(i)
          local dbKey = Logistician.Utilities.BasicDBKeyFromLink(itemLink)
          if dbKey ~= nil and price ~= 0 and numAvailable == -1 then
            local oldPrice = LOGISTICIAN_VENDOR_PRICE_CACHE[dbKey]
            local newPrice = price / stack
            LOGISTICIAN_VENDOR_PRICE_CACHE[dbKey] = newPrice
          elseif dbKey ~= nil then
            LOGISTICIAN_VENDOR_PRICE_CACHE[dbKey] = nil
          end
        end)
      end
    end
  end
end

function Logistician.CraftingInfo.GetProfitWarning(profit, age, anyPrice, exact)
  if not exact and anyPrice then
    return " " .. LOGISTICIAN_L_PROFIT_WARNING_NOT_EXACT_ITEM
  elseif age == nil then
    return " " .. LOGISTICIAN_L_PROFIT_WARNING_MISSING
  elseif age > 10 then
    return " " .. LOGISTICIAN_L_PROFIT_WARNING_AGE
  else
    return ""
  end
end
