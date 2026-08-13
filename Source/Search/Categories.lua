local CategoryLookup = {}

local function SaveCategory(categories, prefix)
  prefix = prefix or ""

  for _, c in ipairs(categories) do
    local currentName = prefix .. c.name
    CategoryLookup[currentName] = c.filters

    if c.subCategories ~= nil then
      SaveCategory(c.subCategories, currentName .. "/")
    end
  end
end

function Auctionator.Search.InitializeCategories()
  Auctionator.Search.InitializeOldCategories()

  SaveCategory(AuctionCategories)
end

function Auctionator.Search.GetItemClassCategories(categoryKey)
  if categoryKey and string.find(categoryKey, "|", 1, true) then
    local combined = {}
    local seen = {}
    for key in string.gmatch(categoryKey, "[^|]+") do
      local filters = CategoryLookup[key] or Auctionator.Search.GetItemClassOldCategories(key)
      for _, filter in ipairs(filters or {}) do
        -- Parent and child categories can overlap; avoid sending duplicate
        -- class/subclass filters to QueryAuctionItems.
        local signature = tostring(filter.classID or filter.classIndex or "")
          .. ":" .. tostring(filter.subClassID or filter.subClassIndex or "")
          .. ":" .. tostring(filter.inventoryType or "")
        if not seen[signature] then
          seen[signature] = true
          table.insert(combined, filter)
        end
      end
    end
    return combined
  end
  local lookup = CategoryLookup[categoryKey]
  if lookup ~= nil then
    return lookup
  elseif categoryKey ~= "" then
    -- Compatibility with old category format
    return Auctionator.Search.GetItemClassOldCategories(categoryKey)
  end
end
