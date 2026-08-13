function Logistician.Groups.DoesGroupExist(name)
  return Logistician.Groups.Utilities.IsContainedPredicate(LOGISTICIAN_SELLING_GROUPS.CustomGroups, function(item) return item.name == name end)
end
function Logistician.Groups.AddGroup(name)
  assert(not Logistician.Groups.DoesGroupExist(name), "Group already exists")

  table.insert(LOGISTICIAN_SELLING_GROUPS.CustomGroups, {
    name = name,
    type = Logistician.Groups.Constants.GroupType.List,
    list = {},
    hidden = false,
  })
end

function Logistician.Groups.GetGroupIndex(name)
  for index, s in ipairs(LOGISTICIAN_SELLING_GROUPS.CustomGroups) do
    if s.name == name then
      return index
    end
  end
  return nil
end

function Logistician.Groups.GetGroupNameByIndex(index)
  return LOGISTICIAN_SELLING_GROUPS.CustomGroups[index] and LOGISTICIAN_SELLING_GROUPS.CustomGroups[index].name
end

function Logistician.Groups.GetGroupList(name)
  return LOGISTICIAN_SELLING_GROUPS.CustomGroups[Logistician.Groups.GetGroupIndex(name)].list
end

function Logistician.Groups.HideItemLink(itemLink)
  table.insert(LOGISTICIAN_SELLING_GROUPS.HiddenItems, itemLink)
end

function Logistician.Groups.UnhideItemLink(itemLink)
  local index = tIndexOf(LOGISTICIAN_SELLING_GROUPS.HiddenItems, itemLink)
  if index ~= nil then
    table.remove(LOGISTICIAN_SELLING_GROUPS.HiddenItems, index)
  end
end

function Logistician.Groups.UnhideAll()
  LOGISTICIAN_SELLING_GROUPS.HiddenItems = {}
end

function Logistician.Groups.GetHiddenItemLinks()
  return LOGISTICIAN_SELLING_GROUPS.HiddenItems
end
