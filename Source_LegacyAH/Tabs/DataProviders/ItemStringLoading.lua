AuctionatorItemStringLoadingMixin = {}

function AuctionatorItemStringLoadingMixin:OnLoad()
  self:SetOnEntryProcessedCallback(function(entry)
    local item = Item:CreateFromItemID((C_Item.GetItemInfoInstant(entry.itemString)))
    local complete = false
    item:ContinueOnItemLoad(function()
      -- Check to avoid overwriting name on empty results
      if entry.itemName == nil then
        self:ProcessItemString(entry, { C_Item.GetItemInfo(entry.itemString) })
      end
      complete = true
    end)
    if complete then
      self:NotifyCacheUsed()
    end
  end)
end

function AuctionatorItemStringLoadingMixin:ProcessItemString(rowEntry, itemInfo)
  local name = itemInfo[Auctionator.Constants.ITEM_INFO.NAME]
  local qualityColor = ITEM_QUALITY_COLORS[itemInfo[Auctionator.Constants.ITEM_INFO.RARITY]].color

  rowEntry.itemLink = itemInfo[Auctionator.Constants.ITEM_INFO.LINK]

  rowEntry.name = name
  rowEntry.itemName = qualityColor:WrapTextInColorCode(rowEntry.name)

  rowEntry.iconTexture = itemInfo[Auctionator.Constants.ITEM_INFO.TEXTURE]

  rowEntry.noneAvailable = rowEntry.totalQuantity == 0

  self:SetDirty()
end
