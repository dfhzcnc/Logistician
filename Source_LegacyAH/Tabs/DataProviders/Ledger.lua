-- Same as Auctionator.Utilities.PrettyDate, but abbreviated to 3-char weekday/month (e.g. "Mon, Aug 25")
-- since PrettyDate itself is shared with PostingHistory/Database and shouldn't change for them.
local function FormatLedgerDate(when)
  local details = date("*t", when)
  local currentDay = date("*t", time())

  if details.year == currentDay.year and details.month == currentDay.month and details.day == currentDay.day then
    return AUCTIONATOR_L_TODAY
  end

  local shortWeekDay = Auctionator.Locales.Apply("DAY_"..tostring(details.wday)):sub(1, 3)
  local shortMonth = Auctionator.Locales.Apply("MONTH_"..tostring(details.month)):sub(1, 3)

  if GetLocale() == "koKR" then
    return date("%Y.%m.%d", when) .. " [" .. shortWeekDay .. "]"
  end

  return shortWeekDay .. ", " .. shortMonth .. " " .. details.day
end

local LEDGER_TABLE_LAYOUT = {
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerParameters = { "itemName" },
    headerText = AUCTIONATOR_L_NAME,
    cellTemplate = "AuctionatorLedgerItemCellTemplate",
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_LEDGER_STACK_SIZE,
    headerParameters = { "quantity" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "quantityFormatted" },
    width = 60,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_LEDGER_SOLD_UNIT_PRICE,
    headerParameters = { "unitPrice" },
    cellTemplate = "AuctionatorLedgerUnitPriceCellTemplate",
    cellParameters = { "unitPrice" },
    width = 160,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_DATE,
    headerParameters = { "rawDay" },
    cellTemplate = "AuctionatorStringCellTemplate",
    cellParameters = { "date" },
    width = 155,
  },
  {
    headerTemplate = "AuctionatorStringColumnHeaderTemplate",
    headerText = AUCTIONATOR_L_LEDGER_MARKET_WHEN_SOLD,
    headerParameters = { "marketPrice" },
    cellTemplate = "AuctionatorPriceCellTemplate",
    cellParameters = { "marketPrice" },
    width = 140,
  },
}

AuctionatorLedgerDataProviderMixin = CreateFromMixins(AuctionatorDataProviderMixin)

function AuctionatorLedgerDataProviderMixin:OnLoad()
  AuctionatorDataProviderMixin.OnLoad(self)

  Auctionator.EventBus:Register(self, {
    Auctionator.LedgerEvents.EntryAdded,
  })
end

function AuctionatorLedgerDataProviderMixin:OnShow()
  self:RefreshEntries()
end

function AuctionatorLedgerDataProviderMixin:ReceiveEvent(eventName)
  if eventName == Auctionator.LedgerEvents.EntryAdded then
    self:RefreshEntries()
  end
end

function AuctionatorLedgerDataProviderMixin:SetOnTotalChangedCallback(callback)
  self.onTotalChanged = callback
end

function AuctionatorLedgerDataProviderMixin:SetFilterText(filterText)
  self.filterText = filterText
  self:RefreshEntries()
end

-- Matches typed keywords against every visible column (name/size/price/date/sale type/market
-- price), not just the item name, so e.g. "50" or "buyout" or "aug 25" all work as filters too.
local function EntryMatchesFilter(entry, tokens)
  if #tokens == 0 then
    return true
  end

  local haystack = table.concat({
    entry.itemName or "",
    entry.date or "",
    entry.quantityFormatted or "",
    GetMoneyString(entry.unitPrice or 0, true) or "",
    GetMoneyString(entry.totalPrice or 0, true) or "",
    entry.saleTypeFormatted or "",
    entry.marketPrice and GetMoneyString(entry.marketPrice, true) or "",
  }, " "):lower()

  for _, token in ipairs(tokens) do
    if not haystack:find(token, 1, true) then
      return false
    end
  end
  return true
end

function AuctionatorLedgerDataProviderMixin:RefreshEntries()
  self:Reset()
  self.onSearchStarted()

  local tokens = {}
  for token in (self.filterText or ""):lower():gmatch("%S+") do
    table.insert(tokens, token)
  end

  local entries = {}
  local totalGold = 0
  for _, record in ipairs(Auctionator.Ledger:GetEntries()) do
    local entry = {
      itemLink = record.itemLink,
      itemName = record.itemName,
      iconTexture = record.iconTexture,
      qualityR = record.qualityR,
      qualityG = record.qualityG,
      qualityB = record.qualityB,
      -- record.quantity is the stack size of the sold auction, not a running sold-count total.
      quantity = record.quantity,
      quantityFormatted = tostring(record.quantity),
      rawDay = record.time,
      date = FormatLedgerDate(record.time),
      unitPrice = record.unitPrice,
      totalPrice = record.unitPrice * record.quantity,
      saleType = record.saleType,
      saleTypeFormatted = record.saleType == "buyout" and AUCTIONATOR_L_SALE_TYPE_BUYOUT or AUCTIONATOR_L_SALE_TYPE_BID,
      marketPrice = record.marketPrice,
    }

    if EntryMatchesFilter(entry, tokens) then
      totalGold = totalGold + entry.totalPrice
      table.insert(entries, entry)
    end
  end

  if self.onTotalChanged then
    self.onTotalChanged(totalGold)
  end

  self:AppendEntries(entries, true)
end

function AuctionatorLedgerDataProviderMixin:GetTableLayout()
  return LEDGER_TABLE_LAYOUT
end

function AuctionatorLedgerDataProviderMixin:GetColumnHideStates()
  return Auctionator.Config.Get(Auctionator.Config.Options.COLUMNS_LEDGER)
end

function AuctionatorLedgerDataProviderMixin:UniqueKey(entry)
  return tostring(entry.rawDay) .. "\031" .. tostring(entry.unitPrice) .. "\031" .. tostring(entry.itemLink)
end

local COMPARATORS = {
  itemName = Auctionator.Utilities.StringComparator,
  quantity = Auctionator.Utilities.NumberComparator,
  rawDay = Auctionator.Utilities.NumberComparator,
  unitPrice = Auctionator.Utilities.NumberComparator,
  totalPrice = Auctionator.Utilities.NumberComparator,
  saleType = Auctionator.Utilities.StringComparator,
  marketPrice = Auctionator.Utilities.NumberComparator,
}

function AuctionatorLedgerDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end
