local POSTING_HISTORY_PROVIDER_LAYOUT ={
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_UNIT_PRICE,
    headerParameters = { "price" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "price" }
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_BID_PRICE,
    headerParameters = { "bidPrice" },
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "bidPrice" },
    defaultHide = Logistician.Constants.IsLegacyAH,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_QUANTITY,
    headerParameters = { "quantity" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "quantity" },
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

LogisticianPostingHistoryProviderMixin = CreateFromMixins(LogisticianDataProviderMixin)

function LogisticianPostingHistoryProviderMixin:OnLoad()
  LogisticianDataProviderMixin.OnLoad(self)
end

function LogisticianPostingHistoryProviderMixin:OnShow()
  self:Reset()
end

function LogisticianPostingHistoryProviderMixin:SetItem(dbKey)
  self:Reset()

  -- Reset columns
  self.onSearchStarted()

  local entries = Logistician.PostingHistory:GetPriceHistory(dbKey)
  table.sort(entries, function(a, b) return b.rawDay < a.rawDay end)

  self:AppendEntries(entries, true)
end

function LogisticianPostingHistoryProviderMixin:GetTableLayout()
  return POSTING_HISTORY_PROVIDER_LAYOUT
end

function LogisticianPostingHistoryProviderMixin:UniqueKey(entry)
  return tostring(tostring(entry.price) .. tostring(entry.rawDay))
end

local COMPARATORS = {
  price = Logistician.Utilities.NumberComparator,
  bidPrice = Logistician.Utilities.NumberComparator,
  quantity = Logistician.Utilities.NumberComparator,
  rawDay = Logistician.Utilities.StringComparator
}

function LogisticianPostingHistoryProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end
