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

Logistician.Groups.Constants.GroupType = {
  List = 1,
  ClassID = 2,
}

Logistician.Groups.Constants.DefaultGroups = {}

local seenNames = {}
for _, classID in ipairs(Logistician.Groups.Constants.ValidItemClassIDs) do
  local name = C_Item.GetItemClassInfo(classID)
  if seenNames[name] then
    seenNames[name] = seenNames[name] + 1
    name = name .. (seenNames[name] + 1)
  else
    seenNames[name] = 1
  end
  table.insert(Logistician.Groups.Constants.DefaultGroups, {
    name = name,
    type = Logistician.Groups.Constants.GroupType.ClassID,
    classID = classID,
  })
end
