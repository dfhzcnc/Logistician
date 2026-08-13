local function SatisfiesLimit(value, limits)
  return (
      limits.min == nil or
      limits.min <= value
    ) and (
      limits.max == nil or
      limits.max >= value
    )
end

local ALL_FILTERS = {}

function ALL_FILTERS.itemLevel(resultWithKey, limits)
  local itemLevel = GetDetailedItemLevelInfo(resultWithKey.entries[1].itemLink)
  return SatisfiesLimit(itemLevel, limits)
end

function ALL_FILTERS.craftedLevel(resultWithKey, limits)
  if limits.min == nil and limits.max == nil then
    return true
  end

  local level = resultWithKey.entries[1].info[Logistician.Constants.AuctionItemInfo.Level]
  return SatisfiesLimit(level, limits)
end

function ALL_FILTERS.price(resultWithKey, limits)
  return SatisfiesLimit(resultWithKey.minPrice, limits)
end

function ALL_FILTERS.quality(resultWithKey, quality)
  local resultQuality = select(Logistician.Constants.ITEM_INFO.RARITY, C_Item.GetItemInfo(resultWithKey.entries[1].itemLink))
  if type(quality) == "table" then
    for _, allowed in ipairs(quality) do
      if resultQuality == allowed then return true end
    end
    return false
  end
  return resultQuality == quality
end

function Logistician.Search.CheckFilters(resultWithKey, filters)
  for filterName, limits in pairs(filters) do
    if not ALL_FILTERS[filterName](resultWithKey, limits) then
      return false
    end
  end
  return true
end
