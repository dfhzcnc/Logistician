local SHOPPING_LIST_TABLE_LAYOUT = {
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "minPrice" },
    headerText = LOGISTICIAN_L_RESULTS_PRICE_COLUMN,
    cellTemplate = "LogisticianPriceCellTemplate",
    cellParameters = { "minPrice" },
    width = 140
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "name" },
    headerText = LOGISTICIAN_L_RESULTS_NAME_COLUMN,
    cellTemplate = "LogisticianItemKeyCellTemplate"
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "isOwned" },
    headerText = LOGISTICIAN_L_OWNED_COLUMN,
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "isOwned" },
    defaultHide = true,
    width = 70,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerParameters = { "isTop" },
    headerText = LOGISTICIAN_L_IS_TOP_COLUMN,
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "isTop" },
    defaultHide = true,
    width = 70,
  },
  {
    headerTemplate = "LogisticianStringColumnHeaderTemplate",
    headerText = LOGISTICIAN_L_RESULTS_AVAILABLE_COLUMN,
    headerParameters = { "totalQuantity" },
    cellTemplate = "LogisticianStringCellTemplate",
    cellParameters = { "totalQuantityString" },
    width = 70
  }
}

LogisticianShoppingTabDataProviderMixin = CreateFromMixins(LogisticianDataProviderMixin, LogisticianItemStringLoadingMixin)

function LogisticianShoppingTabDataProviderMixin:OnLoad()
  Logistician.Debug.Message("LogisticianShoppingTabDataProviderMixin:OnLoad()")

  self:SetUpEvents()

  LogisticianDataProviderMixin.OnLoad(self)
  LogisticianItemStringLoadingMixin.OnLoad(self)
end

function LogisticianShoppingTabDataProviderMixin:SetUpEvents()
  Logistician.EventBus:RegisterSource(self, "Shopping List Data Provider")

  Logistician.EventBus:Register( self, {
    Logistician.Shopping.Tab.Events.SearchStart,
    Logistician.Shopping.Tab.Events.SearchEnd,
    Logistician.Shopping.Tab.Events.SearchIncrementalUpdate,
  })
end

function LogisticianShoppingTabDataProviderMixin:ReceiveEvent(eventName, eventData, ...)
  if eventName == Logistician.Shopping.Tab.Events.SearchStart then
    self:Reset()
    self.onSearchStarted()
  elseif eventName == Logistician.Shopping.Tab.Events.SearchEnd then
    self:AppendEntries(self:AddDetails(eventData), true)
  elseif eventName == Logistician.Shopping.Tab.Events.SearchIncrementalUpdate then
    self:AppendEntries(self:AddDetails(eventData))
  end
end

function LogisticianShoppingTabDataProviderMixin:AddDetails(entries)
  for _, entry in ipairs(entries) do
    if entry.containsOwnerItem then
      entry.isOwned = LOGISTICIAN_L_UNDERCUT_YES
    else
      entry.isOwned = ""
    end

    if entry.isTopItem then
      entry.isTop = GREEN_FONT_COLOR:WrapTextInColorCode(LOGISTICIAN_L_UNDERCUT_YES)
    else
      entry.isTop = RED_FONT_COLOR:WrapTextInColorCode(LOGISTICIAN_L_UNDERCUT_NO)
    end

    if not entry.complete then
      entry.totalQuantityString = LOGISTICIAN_L_UNDERCUT_UNKNOWN
    else
      entry.totalQuantityString = tostring(entry.totalQuantity)
    end
  end

  return entries
end

function LogisticianShoppingTabDataProviderMixin:UniqueKey(entry)
  return entry.itemString
end

local COMPARATORS = {
  minPrice = Logistician.Utilities.NumberComparator,
  name = Logistician.Utilities.StringComparator,
  isOwned = Logistician.Utilities.StringComparator,
  totalQuantity = Logistician.Utilities.NumberComparator
}

function LogisticianShoppingTabDataProviderMixin:Sort(fieldName, sortDirection)
  local comparator = COMPARATORS[fieldName](sortDirection, fieldName)

  table.sort(self.results, function(left, right)
    return comparator(left, right)
  end)

  self:SetDirty()
end

function LogisticianShoppingTabDataProviderMixin:GetTableLayout()
  return SHOPPING_LIST_TABLE_LAYOUT
end

function LogisticianShoppingTabDataProviderMixin:GetColumnHideStates()
  return Logistician.Config.Get(Logistician.Config.Options.COLUMNS_SHOPPING)
end

function LogisticianShoppingTabDataProviderMixin:GetRowTemplate()
  return "LogisticianShoppingResultsRowTemplate"
end
