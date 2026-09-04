local GetMerchantItemInfo = GetMerchantItemInfo or function(index)
  local info = C_MerchantFrame.GetItemInfo(index);
  if info then
    return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isPurchasable, info.isUsable, info.hasExtendedCost, info.currencyID, info.spellID;
  end
end
function Auctionator.CraftingInfo.CacheVendorPrices()
  for i = 1, GetMerchantNumItems() do
    local itemID = GetMerchantItemID(i)
    if itemID ~= nil then
      local item = Item:CreateFromItemID(itemID)
      if not item:IsItemEmpty() then
        item:ContinueOnItemLoad(function()
          local price, stack, numAvailable, isPurchasable, isUsable, hasExtendedCost = select(3, GetMerchantItemInfo(i))
          local itemLink = GetMerchantItemLink(i)
          local dbKey = Auctionator.Utilities.BasicDBKeyFromLink(itemLink)
          -- numAvailable being finite (not -1/unlimited) just means limited stock, e.g. most
          -- recipes/formulas - still a valid gold price, so don't exclude on that alone.
          -- hasExtendedCost (reputation/currency-token vendors) does NOT mean price is invalid -
          -- Blizzard's price is always the real gold portion of the cost, even for items that
          -- ALSO require a token/reputation (common for enchanting formula vendors). A purely
          -- non-gold item already reports price == 0, which the check below already excludes.
          if dbKey ~= nil and price ~= 0 then
            local oldPrice = AUCTIONATOR_VENDOR_PRICE_CACHE[dbKey]
            local newPrice = price / stack
            AUCTIONATOR_VENDOR_PRICE_CACHE[dbKey] = newPrice
          elseif dbKey ~= nil then
            AUCTIONATOR_VENDOR_PRICE_CACHE[dbKey] = nil
          end
        end)
      end
    end
  end
end

function Auctionator.CraftingInfo.GetProfitWarning(profit, age, anyPrice, exact)
  if not exact and anyPrice then
    return " " .. AUCTIONATOR_L_PROFIT_WARNING_NOT_EXACT_ITEM
  elseif age == nil then
    return " " .. AUCTIONATOR_L_PROFIT_WARNING_MISSING
  elseif age > 10 then
    return " " .. AUCTIONATOR_L_PROFIT_WARNING_AGE
  else
    return ""
  end
end
