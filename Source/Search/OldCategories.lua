-- OLD: Kept to maintain compatibility with shopping lists existing prior to
-- April 2022.
--
-- This is the original mapping of category strings to a class id, subclass id,
-- and optionally inventory id.
--
--  Logistician.Search.OldCategories is an empty table on load, need to populate
--  with the possible categories
--
--  Here's what one entry looks like:
--  {
--    classID    = integer (corresponding to Logistician.Constants.ValidItemClassIDs )
--    name       = string  (resolved by GetItemClassInfo( classID ))
--    category     = table   (new QueryAuctionItems categoryData format, { classID, subClassID (nil), inventoryType (nil) } )
--    subClasses = {
--      classID  = integer (subClassID)
--      name     = string  (resolved by GetItemSubClassInfo( subClassID ))
--      category   = table   (new QueryAuctionItems categoryData format, { classID, subClassID, inventoryType? } )
--    }
--  }

local INVENTORY_TYPE_IDS = Logistician.Constants.INVENTORY_TYPE_IDS

local OldCategories = {}
local OldCategoryLookup = {}

Logistician.Search.OldCategory = {
  classID = 0,
  name = Logistician.Constants.CategoryDefault,
  key = 0,
  parentKey = nil,
  category = {},
  subClasses = {}
}

function Logistician.Search.OldCategory:new( options )
  options = options or {}
  setmetatable( options, self )
  self.__index = self

  return options
end

--Given a key and category (classID and subClassID supplied, assumed to be for
--armor), creates a new category for each possible inventory slot.
--Returns array of new categories
local function GenerateArmorInventorySlots(parentKey, parentCategory)
  local inventorySlots = {}
  for index = 1, #INVENTORY_TYPE_IDS do
    local name = C_Item.GetItemInventorySlotInfo(INVENTORY_TYPE_IDS[index])

    local category = {
      classID = parentCategory.classID,
      subClassID = parentCategory.subClassID,
      inventoryType = INVENTORY_TYPE_IDS[index],
    }
    local subSubClass = Logistician.Search.OldCategory:new({
      classID = INVENTORY_TYPE_IDS[index],
      name = name,
      key = parentKey .. [[/]] .. name,
      parentKey = parentKey,
      category = { category }
    })

    table.insert( inventorySlots, subSubClass )
  end
  return inventorySlots
end

local function GenerateSubClasses( classID, parentKey )
  local subClassesTable = Logistician.AH.GetAuctionItemSubClasses( classID )
  local subClasses = {}

  for index = 1, #subClassesTable do
    local subClassID = subClassesTable[ index ]
    local name = C_Item.GetItemSubClassInfo( classID, subClassID )

    if name then
      local category = { classID = classID, subClassID = subClassID }
      local subClass = Logistician.Search.OldCategory:new({
        classID = subClassID,
        name = name,
        key = parentKey .. [[/]] .. name,
        parentKey = parentKey,
        category = { category }
      })

      table.insert( subClasses, subClass )

      --Armor special case, adds inventory slot categories
      if classID == Enum.ItemClass.Armor then
        local inventorySlots = GenerateArmorInventorySlots(subClass.key, category)
        for _, slot in ipairs(inventorySlots) do
          table.insert(subClasses, slot)
        end
      end
    end
  end

  return subClasses
end

function Logistician.Search.InitializeOldCategories()
  for _, classID in ipairs( Logistician.Groups.Constants.ValidItemClassIDs ) do
    local key = C_Item.GetItemClassInfo( classID )
    local subClasses = GenerateSubClasses( classID, key )
    local category = {classID = classID}

    local categoryCategory = Logistician.Search.OldCategory:new({
      classID = classID,
      name = name,
      key = key,
      category = {category},
      subClasses = subClasses
    })

    table.insert( OldCategories, categoryCategory )
  end

  for _, category in ipairs( OldCategories ) do
    OldCategoryLookup[ category.key ] = category

    for i = 1, #category.subClasses do
      local subCategory = category.subClasses[ i ]

      OldCategoryLookup[ subCategory.key ] = subCategory
    end
  end
end

function Logistician.Search.GetItemClassOldCategories(categoryKey)
  local lookup = OldCategoryLookup[categoryKey]
  if lookup ~= nil then
    return lookup.category
  end
end
