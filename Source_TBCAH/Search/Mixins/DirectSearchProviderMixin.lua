LogisticianDirectSearchProviderMixin = CreateFromMixins(LogisticianMultiSearchMixin, LogisticianSearchProviderMixin)

local SEARCH_EVENTS = {
  Logistician.AH.Events.ScanResultsUpdate,
  Logistician.AH.Events.ScanAborted,
}

local function GetPrice(entry)
  return entry.info[Logistician.Constants.AuctionItemInfo.Buyout] / entry.info[Logistician.Constants.AuctionItemInfo.Quantity]
end

local function GetMinPrice(entries)
  local minPrice = nil
  for _, entry in ipairs(entries) do
    local buyout = GetPrice(entry)
    if buyout ~= 0 then
      if minPrice == nil then
        minPrice = buyout
      else
        minPrice = math.min(minPrice, buyout)
      end
    end
  end
  return math.ceil(minPrice or 0)
end

local function GetQuantity(entries)
  local total = 0
  for _, entry in ipairs(entries) do
    total = total + entry.info[Logistician.Constants.AuctionItemInfo.Quantity]
  end
  return total
end

local function GetOwned(entries)
  for _, entry in ipairs(entries) do
    if entry.info[Logistician.Constants.AuctionItemInfo.Owner] == (GetUnitName("player")) then
      return true
    end
  end
  return false
end

local function GetIsTop(entries, minPrice)
  for _, entry in ipairs(entries) do
    if entry.info[Logistician.Constants.AuctionItemInfo.Owner] == (GetUnitName("player")) and minPrice == GetPrice(entry) then
      return true
    end
  end
  return false
end

function LogisticianDirectSearchProviderMixin:CreateSearchTerm(term, config)
  Logistician.Debug.Message("LogisticianDirectSearchProviderMixin:CreateSearchTerm()", term)

  local parsed = Logistician.Search.SplitAdvancedSearch(term)
  local hasClientFilters = #(parsed.qualities or {}) > 1
    or parsed.minItemLevel ~= nil
    or parsed.maxItemLevel ~= nil
    or parsed.minCraftedLevel ~= nil
    or parsed.maxCraftedLevel ~= nil
    or parsed.minPrice ~= nil
    or parsed.maxPrice ~= nil

  return {
    query = {
      searchString = parsed.searchString,
      minLevel = parsed.minLevel,
      maxLevel = parsed.maxLevel,
      itemClassFilters = Logistician.Search.GetItemClassCategories(parsed.categoryKey),
      isExact = parsed.isExact,
      quality = parsed.quality, -- Only useful for the backward-compatible single-rarity case
    },
    extraFilters = {
      itemLevel = {
        min = parsed.minItemLevel,
        max = parsed.maxItemLevel,
      },
      craftedLevel = {
        min = parsed.minCraftedLevel,
        max = parsed.maxCraftedLevel,
      },
      price = {
        min = parsed.minPrice,
        max = parsed.maxPrice,
      },
      quality = (#(parsed.qualities or {}) > 0) and parsed.qualities or nil,
    },
    resultMetadata = {
      quantity = parsed.quantity,
    },
    -- Force searchAllPages when the config UI forces it
    -- The legacy AH query can only send one rarity and cannot send item-level,
    -- crafted-level, or price filters. Those filters are applied locally, so
    -- stopping after page one can incorrectly show no results. Scan every page
    -- whenever the requested search relies on client-side filtering.
    searchAllPages = hasClientFilters
      or Logistician.Config.Get(Logistician.Config.Options.SHOPPING_ALWAYS_LOAD_MORE)
      or config.searchAllPages
      or false,
  }
end

function LogisticianDirectSearchProviderMixin:GetSearchProvider()
  Logistician.Debug.Message("LogisticianDirectSearchProviderMixin:GetSearchProvider()")

  --Run the query, and save extra filter data for processing
  return function(searchTerm)
    self.gotAllResults = false
    self.aborted = false
    self.searchAllPages = searchTerm.searchAllPages
    self.currentFilter = searchTerm.extraFilters
    self.resultMetadata = searchTerm.resultMetadata
    self.resultsByKey = {}
    self.individualResults = {}

    Logistician.AH.QueryAuctionItems(searchTerm.query)
  end
end

function LogisticianDirectSearchProviderMixin:HasCompleteTermResults()
  Logistician.Debug.Message("LogisticianDirectSearchProviderMixin:HasCompleteTermResults()")

  return self.gotAllResults
end

function LogisticianDirectSearchProviderMixin:GetCurrentEmptyResult()
  local r = Logistician.Search.GetEmptyResult(self:GetCurrentSearchParameter(), self:GetCurrentSearchIndex())
  r.complete = not self.aborted
  return r
end

function LogisticianDirectSearchProviderMixin:AddFinalResults()
  local results = {}
  local waiting = #(Logistician.Utilities.TableKeys(self.resultsByKey))
  local completed = false
  local function DoComplete()
    table.sort(results, function(a, b)
      return a.minPrice > b.minPrice
    end)
    -- Do not turn an advanced filter expression into a synthetic auction row.
    -- On the legacy AH only the current page may have been loaded, so a
    -- zero-price row named "[Armor/Leather/Chest, ...]" is both misleading and
    -- visually indistinguishable from a real result. Leave the list empty and
    -- let the existing "Load more results" action continue the search.
    local currentTerm = self:GetCurrentSearchParameter() or ""
    local isAdvanced = currentTerm:find(
      Logistician.Constants.AdvancedSearchDivider,
      1,
      true
    ) ~= nil
    if #results == 0
      and self.aborted
      and not isAdvanced
      and Logistician.Config.Get(Logistician.Config.Options.SEARCH_NO_FILTERS_MATCHED_ENTRY) then
      table.insert(results, self:GetCurrentEmptyResult())
    end
    Logistician.Search.GroupResultsForDB(self.individualResults)
    self:AddResults(results)
  end

  for key, entries in pairs(self.resultsByKey) do
    local minPrice = GetMinPrice(entries)
    local possibleResult = {
      itemString = key,
      minPrice = GetMinPrice(entries),
      totalQuantity = GetQuantity(entries),
      containsOwnerItem = GetOwned(entries),
      isTopItem = GetIsTop(entries, minPrice),
      entries = entries,
      complete = not self.aborted,
      purchaseQuantity = self.resultMetadata.quantity,
    }
    local item = Item:CreateFromItemID(C_Item.GetItemInfoInstant(key))
    item:ContinueOnItemLoad(function()
      waiting = waiting - 1
      if Logistician.Search.CheckFilters(possibleResult, self.currentFilter) then
        table.insert(results, possibleResult)
      end
      if waiting == 0 then
        completed = true
        DoComplete()
      end
    end)
  end
  if waiting == 0 and not completed then
    DoComplete()
  end
end

function LogisticianDirectSearchProviderMixin:ProcessSearchResults(pageResults)
  Logistician.Debug.Message("LogisticianDirectSearchProviderMixin:ProcessSearchResults()")
  
  for _, entry in ipairs(pageResults) do

    local itemID = entry.info[Logistician.Constants.AuctionItemInfo.ItemID]
    local itemString = Logistician.Search.GetCleanItemLink(entry.itemLink)

    if self.resultsByKey[itemString] == nil then
      self.resultsByKey[itemString] = {}
    end

    table.insert(self.resultsByKey[itemString], entry)
    table.insert(self.individualResults, entry)
  end

  if self:HasCompleteTermResults() then
    self:AddFinalResults()
  elseif not self.searchAllPages then
    self.aborted = true
    Logistician.AH.AbortQuery()
  end

end

function LogisticianDirectSearchProviderMixin:ReceiveEvent(eventName, results, gotAllResults)
  if eventName == Logistician.AH.Events.ScanResultsUpdate then
    self.gotAllResults = gotAllResults
    self:ProcessSearchResults(results)
  elseif eventName == Logistician.AH.Events.ScanAborted then
    self.gotAllResults = true
    self:ProcessSearchResults({})
  end
end


function LogisticianDirectSearchProviderMixin:RegisterProviderEvents()
  if not self.registeredOnEventBus then
    self.registeredOnEventBus = true
    Logistician.EventBus:Register(self, SEARCH_EVENTS)
  end
end

function LogisticianDirectSearchProviderMixin:UnregisterProviderEvents()
  if self.registeredOnEventBus then
    self.registeredOnEventBus = false
    Logistician.EventBus:Unregister(self, SEARCH_EVENTS)
  end

  if not self.gotAllResults then
    Logistician.AH.AbortQuery()
  end
end
