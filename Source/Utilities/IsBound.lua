local unboundConstants = {
  LE_ITEM_BIND_NONE or Enum.ItemBind.None,
  LE_ITEM_BIND_ON_EQUIP or Enum.ItemBind.OnEquip,
  LE_ITEM_BIND_ON_USE or Enum.ItemBind.OnUse,
}
function Logistician.Utilities.IsBound(itemInfo)
  local bindType = itemInfo[Logistician.Constants.ITEM_INFO.BIND_TYPE]

  return tIndexOf(unboundConstants, bindType) == nil
end
