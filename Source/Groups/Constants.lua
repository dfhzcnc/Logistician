Logistician.Groups.Constants = {
  IsTBC = true,
  BagIDs = {-2, 0, 1, 2, 3, 4},
  ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Miscellaneous,
  },
}

Logistician.Groups.Constants.Events = {
  "BagCacheUpdated",
  "ViewGroupToggled",
  "ViewComplete",
  "BagCacheOff",
  "BagCacheOn",
  "BagUse.BagItemClicked",
  "BagUse.AddToDefaultGroup",
  "Customise.EditMade",
}
