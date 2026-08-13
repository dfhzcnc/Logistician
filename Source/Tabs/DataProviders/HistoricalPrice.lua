local HISTORICAL_PRICE_PROVIDER_LAYOUT ={
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_UNIT_PRICE,
    headerParameters = { "minSeen" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "minSeen" }
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_UPPER_UNIT_PRICE,
    headerParameters = { "maxSeen" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "maxSeen" },
    defaultHide = true
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_RESULTS_AVAILABLE_COLUMN,
    headerParameters = { "available" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "availableFormatted" },
    width = 100
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_DATE,
    headerParameters = { "rawDay" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "date" }
  },
}

LogisticianHistoricalPriceProviderMixin = CreateFromMixins(LogisticianDataProviderMixin)

function LogisticianHistoricalPriceProviderMixin:OnShow()
  self:Reset()
end

function LogisticianHistoricalPriceProviderMixin:SetItem(dbKey)
  self:Reset()

  -- Reset columns
  self.onSearchStarted()

  local entries = Logistician.Database:GetPriceHistory(dbKey)

  for _, entry in ipairs(entries) do
    if entry.available then
      entry.availableFormatted = FormatLargeNumber(entry.available)
    else
      entry.availableFormatted = ""
    end
  end

  self:AppendEntries(entries, true)
end

function LogisticianHistoricalPriceProviderMixin:GetTableLayout()
  return HISTORICAL_PRICE_PROVIDER_LAYOUT
end

function LogisticianHistoricalPriceProviderMixin:UniqueKey(entry)
  return tostring(entry.rawDay)
end

local COMPARATORS = {
  minSeen = Logistician.Utilities.NumberComparator,
  maxSeen = Logistician.Utilities.NumberComparator,
  available = Logistician.Utilities.NumberComparator,
  rawDay = Logistician.Utilities.StringComparator
}

function LogisticianHistoricalPriceProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end
