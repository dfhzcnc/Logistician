Logistician.Groups.Utilities = {}
function Logistician.Groups.Utilities.IsContainedPredicate(list, pred)
  for _, item in ipairs(list) do
    if (pred(item)) then
      return true
    end
  end
  return false
end

function Logistician.Groups.Utilities.ToPostingItem(info)
  return {
    itemLink = info.itemLink,
    itemID = info.itemID,
    itemName = info.itemName,
    itemLevel = info.itemLevel,
    iconTexture = info.iconTexture,
    quality = info.quality,
    count = info.itemCount,
    location = info.locations[1],
    classId = info.classID,
    auctionable = true,
    bagListing = true,
    nextItem = nil,
    prevItem = nil,
    sortKey = info.sortKey,
  }
end

function Logistician.Groups.Utilities.QueryItem(sortKey)
  return LogisticianBagCacheFrame:GetByKey(sortKey)
end
