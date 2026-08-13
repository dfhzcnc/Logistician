LogisticianShoppingListMixin = {}

function LogisticianShoppingListMixin:Init(data, manager)
  assert(data)
  self.data = data
  self.manager = manager
end

function LogisticianShoppingListMixin:GetName()
  return self.data.name
end

function LogisticianShoppingListMixin:Rename(newName)
  assert(type(newName) == "string")
  assert(self.manager:GetIndexForName(newName) == nil, "New name already in use")

  self.data.name = newName

  self.manager:FireMetaChangeEvent(self:GetName())
end

function LogisticianShoppingListMixin:IsTemporary()
  return self.data.isTemporary
end

function LogisticianShoppingListMixin:MakePermanent()
  self.data.isTemporary = false

  self.manager:FireMetaChangeEvent(self:GetName())
end

function LogisticianShoppingListMixin:GetItemCount()
  return #self.data.items
end

function LogisticianShoppingListMixin:GetItemByIndex(index)
  return self.data.items[index]
end

function LogisticianShoppingListMixin:GetIndexForItem(item)
  return tIndexOf(self.data.items, item)
end

function LogisticianShoppingListMixin:GetAllItems()
  return CopyTable(self.data.items)
end

function LogisticianShoppingListMixin:DeleteItem(index)
  assert(self.data.items[index], "Nonexistent item")
  table.remove(self.data.items, index)

  self.manager:FireItemChangeEvent(self:GetName())
end

function LogisticianShoppingListMixin:AlterItem(index, newItem)
  assert(self.data.items[index], "Nonexistent item")
  assert(type(newItem) == "string")

  self.data.items[index] = newItem

  self.manager:FireItemChangeEvent(self:GetName())
end

function LogisticianShoppingListMixin:InsertItem(newItem, index)
  assert(type(newItem) == "string")
  if index ~= nil then
    table.insert(self.data.items, index, newItem)
  else
    table.insert(self.data.items, newItem)
  end

  self.manager:FireItemChangeEvent(self:GetName())
end

function LogisticianShoppingListMixin:ClearItems()
  self.data.items = {}
end

function LogisticianShoppingListMixin:AppendItems(newItems)
  for _, i in ipairs(newItems) do
    assert(type(i) == "string")
    table.insert(self.data.items, i)
  end

  self.manager:FireItemChangeEvent(self:GetName())
end

function LogisticianShoppingListMixin:Sort()
  table.sort(self.data.items, function(a, b)
    return a:lower():gsub("\"", "") < b:lower():gsub("\"", "")
  end)
  self.manager:FireItemChangeEvent(self:GetName())
end
