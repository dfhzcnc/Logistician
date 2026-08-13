function Logistician.Utilities.IsVendorable(itemInfo)
  local sellPrice = itemInfo[Logistician.Constants.ITEM_INFO.SELL_PRICE]
  local isReagent = itemInfo[Logistician.Constants.ITEM_INFO.REAGENT]
  local isArtifact = itemInfo[Logistician.Constants.ITEM_INFO.RARITY] == Enum.ItemQuality.Artifact
  local isLegendary = itemInfo[Logistician.Constants.ITEM_INFO.RARITY] == Enum.ItemQuality.Legendary

  return sellPrice ~= nil and sellPrice > 0 and not isArtifact and (isReagent or not isLegendary)
end
