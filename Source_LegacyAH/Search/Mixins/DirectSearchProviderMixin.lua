AuctionatorDirectSearchProviderMixin = CreateFromMixins(AuctionatorMultiSearchMixin, AuctionatorSearchProviderMixin)

local SEARCH_EVENTS = {
  Auctionator.AH.Events.ScanResultsUpdate,
  Auctionator.AH.Events.ScanAborted,
}

local function GetPrice(entry)
  return entry.info[Auctionator.Constants.AuctionItemInfo.Buyout] / entry.info[Auctionator.Constants.AuctionItemInfo.Quantity]
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
    total = total + entry.info[Auctionator.Constants.AuctionItemInfo.Quantity]
  end
  return total
end

local function GetOwned(entries)
  for _, entry in ipairs(entries) do
    if entry.info[Auctionator.Constants.AuctionItemInfo.Owner] == (GetUnitName("player")) then
      return true
    end
  end
  return false
end

local function GetIsTop(entries, minPrice)
  for _, entry in ipairs(entries) do
    if entry.info[Auctionator.Constants.AuctionItemInfo.Owner] == (GetUnitName("player")) and minPrice == GetPrice(entry) then
      return true
    end
  end
  return false
end

function AuctionatorDirectSearchProviderMixin:CreateSearchTerm(term, config)
  Auctionator.Debug.Message("AuctionatorDirectSearchProviderMixin:CreateSearchTerm()", term)

  local parsed = Auctionator.Search.SplitAdvancedSearch(term)
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
      itemClassFilters = Auctionator.Search.GetItemClassCategories(parsed.categoryKey),
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
      or Auctionator.Config.Get(Auctionator.Config.Options.SHOPPING_ALWAYS_LOAD_MORE)
      or config.searchAllPages
      or false,
  }
end

function AuctionatorDirectSearchProviderMixin:GetSearchProvider()
  Auctionator.Debug.Message("AuctionatorDirectSearchProviderMixin:GetSearchProvider()")

  --Run the query, and save extra filter data for processing
  return function(searchTerm)
    self.gotAllResults = false
    self.aborted = false
    self.searchAllPages = searchTerm.searchAllPages
    self.currentFilter = searchTerm.extraFilters
    self.resultMetadata = searchTerm.resultMetadata
    self.resultsByKey = {}
    self.individualResults = {}

    Auctionator.AH.QueryAuctionItems(searchTerm.query)
  end
end

function AuctionatorDirectSearchProviderMixin:HasCompleteTermResults()
  Auctionator.Debug.Message("AuctionatorDirectSearchProviderMixin:HasCompleteTermResults()")

  return self.gotAllResults
end

function AuctionatorDirectSearchProviderMixin:GetCurrentEmptyResult()
  local r = Auctionator.Search.GetEmptyResult(self:GetCurrentSearchParameter(), self:GetCurrentSearchIndex())
  r.complete = not self.aborted
  return r
end

function AuctionatorDirectSearchProviderMixin:AddFinalResults()
  local results = {}
  local waiting = #(Auctionator.Utilities.TableKeys(self.resultsByKey))
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
      Auctionator.Constants.AdvancedSearchDivider,
      1,
      true
    ) ~= nil
    if #results == 0
      and self.aborted
      and not isAdvanced
      and Auctionator.Config.Get(Auctionator.Config.Options.SEARCH_NO_FILTERS_MATCHED_ENTRY) then
      table.insert(results, self:GetCurrentEmptyResult())
    end
    Auctionator.Search.GroupResultsForDB(self.individualResults)
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
      if Auctionator.Search.CheckFilters(possibleResult, self.currentFilter) then
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

function AuctionatorDirectSearchProviderMixin:ProcessSearchResults(pageResults)
  Auctionator.Debug.Message("AuctionatorDirectSearchProviderMixin:ProcessSearchResults()")
  
  for _, entry in ipairs(pageResults) do

    local itemID = entry.info[Auctionator.Constants.AuctionItemInfo.ItemID]
    local itemString = Auctionator.Search.GetCleanItemLink(entry.itemLink)

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
    Auctionator.AH.AbortQuery()
  end

end

function AuctionatorDirectSearchProviderMixin:ReceiveEvent(eventName, results, gotAllResults)
  if eventName == Auctionator.AH.Events.ScanResultsUpdate then
    self.gotAllResults = gotAllResults
    self:ProcessSearchResults(results)
  elseif eventName == Auctionator.AH.Events.ScanAborted then
    self.gotAllResults = true
    self:ProcessSearchResults({})
  end
end


function AuctionatorDirectSearchProviderMixin:RegisterProviderEvents()
  if not self.registeredOnEventBus then
    self.registeredOnEventBus = true
    Auctionator.EventBus:Register(self, SEARCH_EVENTS)
  end
end

function AuctionatorDirectSearchProviderMixin:UnregisterProviderEvents()
  if self.registeredOnEventBus then
    self.registeredOnEventBus = false
    Auctionator.EventBus:Unregister(self, SEARCH_EVENTS)
  end

  if not self.gotAllResults then
    Auctionator.AH.AbortQuery()
  end
end
