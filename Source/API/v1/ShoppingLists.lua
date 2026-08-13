---@class Logistician.Search.SearchTerm
---@field searchString string
---@field categoryKey string?
---@field isExact boolean?
---@field minLevel number?
---@field maxLevel number?
---@field minPrice number?
---@field maxPrice number?
---@field minItemLevel number?
---@field maxItemLevel number?
---@field minCraftedLevel number?
---@field maxCraftedLevel number?
---@field quality number?
---@field tier number? -- dragonflight crafted reagent quality ([1,5])
---@field expansion string?
---@field quantity number?


---@param callerID string
---@param term Logistician.Search.SearchTerm
---@return string searchString
function Logistician.API.v1.ConvertToSearchString(callerID, term)
  if not term or not term.searchString or type(term.searchString) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.ConvertToSearchString(table)"
    )
  end
  return Logistician.Search.ReconstituteAdvancedSearch(term)
end

---@param callerID string
---@param searchString string
---@return Logistician.Search.SearchTerm searchTerm
function Logistician.API.v1.ConvertFromSearchString(callerID, searchString)
  if not searchString or type(searchString) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.ConvertFromSearchString(string)"
    )
  end
  return Logistician.Search.SplitAdvancedSearch(searchString)
end

---@param callerID string
---@param shoppingListName string
---@return string[]
function Logistician.API.v1.GetShoppingListItems(callerID, shoppingListName)
  Logistician.API.InternalVerifyID(callerID)

  if type(shoppingListName) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.GetShoppingListItems(string, string)"
    )
  end

  local listIndex = Logistician.Shopping.ListManager:GetIndexForName(shoppingListName)

  if not listIndex then
    Logistician.API.ComposeError(
      callerID,
      "Logistician.API.v1.GetShoppingListItems: List does not exist: " .. tostring(shoppingListName)
    )
  end

  local shoppingList = Logistician.Shopping.ListManager:GetByIndex(listIndex)

  return shoppingList:GetAllItems()
end

--- Creates an Logistician Shopping List and if at the AH, starts searching immediately. If a shopping list with the given name already exists it will be replaced
---@param callerID string
---@param name string
---@param searchStrings string[]
function Logistician.API.v1.CreateShoppingList(callerID, name, searchStrings)
  Logistician.API.InternalVerifyID(callerID)

  if type(name) ~= "string" or type(searchStrings) ~= "table" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.CreateShoppingList(string, string, string[])"
    )
  end

  local listExists = Logistician.Shopping.ListManager:GetIndexForName(name)
  if listExists then
      Logistician.Shopping.ListManager:Delete(name)
  end

  Logistician.Shopping.ListManager:Create(name)
  local list = Logistician.Shopping.ListManager:GetByName(name)
  list:AppendItems(searchStrings)

  Logistician.EventBus
    :RegisterSource(Logistician.API.v1.CreateShoppingList, "Logistician.API.v1.CreateShoppingList")
    :Fire(Logistician.API.v1.CreateShoppingList, Logistician.Shopping.Events.ListImportFinished, name)
end

---@param callerID string
---@param shoppingListName string
---@param itemSearchString string
function Logistician.API.v1.DeleteShoppingListItem(callerID, shoppingListName, itemSearchString)
  Logistician.API.InternalVerifyID(callerID)

  if type(shoppingListName) ~= "string" or type(itemSearchString) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.DeleteShoppingListItem(string, string, string)"
    )
  end

  local listIndex = Logistician.Shopping.ListManager:GetIndexForName(shoppingListName)
  if not listIndex then
    Logistician.API.ComposeError(
      callerID,
      "Logistician.API.v1.DeleteShoppingListItem ShoppingList does not exist: " .. tostring(shoppingListName)
    )
  end

  local shoppingList = Logistician.Shopping.ListManager:GetByIndex(listIndex)

  local itemIndex = shoppingList:GetIndexForItem(itemSearchString)
  if itemIndex then
    shoppingList:DeleteItem(itemIndex)
  end
end

---@param callerID string
---@param shoppingListName string
---@param oldItemSearchString string
---@param newItemSearchString string
function Logistician.API.v1.AlterShoppingListItem(callerID, shoppingListName, oldItemSearchString, newItemSearchString)
  Logistician.API.InternalVerifyID(callerID)

  if type(shoppingListName) ~= "string" or type(oldItemSearchString) ~= "string" or type(newItemSearchString) ~= "string" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.AlterShoppingListItem(string, string, string, string)"
    )
  end

  local listIndex = Logistician.Shopping.ListManager:GetIndexForName(shoppingListName)
  if not listIndex then
    Logistician.API.ComposeError(
      callerID,
      "Logistician.API.v1.AlterShoppingListItem ShoppingList does not exist: " .. tostring(shoppingListName)
    )
  end

  local shoppingList = Logistician.Shopping.ListManager:GetByIndex(listIndex)

  local oldItemIndex = shoppingList:GetIndexForItem(oldItemSearchString)
  if oldItemIndex then
    shoppingList:AlterItem(oldItemIndex, newItemSearchString)
  else
    Logistician.API.ComposeError(
        callerID,
        "Error in Logistician.API.v1.AlterShoppingListItem: Could not find item in shopping list:\n" .. tostring(oldItemSearchString)
        )
  end
end

--- Very Simple Testing of API
function Logistician.API.v1.ShoppingListAPITests()
  local callerID = "APITest"
  local shoppingListName = "APITestShoppingList"
  local creationTerms = {
    {
        searchString="Draconium Ore",
        isExact=true,
        categoryKey="",
        tier=2,
        quantity=15,
    },
    {
        searchString="Serevite Ore",
        isExact=true,
        categoryKey="",
        tier=3,
        quantity=10,   
    }
  }
  local searchStrings = {}
  for _, term in ipairs(creationTerms) do
    table.insert(searchStrings, Logistician.API.v1.ConvertToSearchString(callerID, term))
  end

  local s1, e1 = pcall(Logistician.API.v1.CreateShoppingList, callerID, shoppingListName, searchStrings)
  assert(s1, "CreateShoppingList failed: " .. tostring(e1))

  local s2, items = pcall(Logistician.API.v1.GetShoppingListItems, callerID, shoppingListName)
  assert(s2, "GetShoppingListItems failed: " .. tostring(items))

  assert(items[1] == '"Draconium Ore";;;;;;;;;;;2;;15', "Shopping List Creation failed")
  assert(items[2] == '"Serevite Ore";;;;;;;;;;;3;;10', "Shopping List Creation failed")

  local s3, e3 = pcall(Logistician.API.v1.DeleteShoppingListItem, callerID, shoppingListName, searchStrings[1])

  assert(s3, "DeleteShoppingListItem failed: " .. tostring(e3))

  items = Logistician.API.v1.GetShoppingListItems(callerID, shoppingListName)

  assert(items[1] == '"Serevite Ore";;;;;;;;;;;3;;10', "DeleteShoppingListItem failed")
  assert(#items < 2, "DeleteShoppingListItem failed")

  local s4, e4 = pcall(Logistician.API.v1.AlterShoppingListItem, callerID, shoppingListName,
  Logistician.API.v1.ConvertToSearchString(callerID, {
        searchString="Serevite Ore",
        isExact=true,
        tier=3,
        quantity=10,
  }), Logistician.API.v1.ConvertToSearchString(callerID, {
        searchString="Draconium Ore",
        isExact=true,
        tier=2,
        quantity=5,      
  }))
  assert(s4, "AlterShoppingListItem failed: " .. tostring(e4))

  items = Logistician.API.v1.GetShoppingListItems(callerID, shoppingListName)

  assert(items[1] == '"Draconium Ore";;;;;;;;;;;2;;5', "AlterShoppingListItem failed")
  assert(#items <  2, "AlterShoppingListItem failed")

  print("ShoppingListAPITests Successful")
end
