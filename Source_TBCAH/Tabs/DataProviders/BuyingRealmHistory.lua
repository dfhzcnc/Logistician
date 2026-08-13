LogisticianBuyingRealmHistoryDataProviderMixin = CreateFromMixins(LogisticianHistoricalPriceProviderMixin)

function LogisticianBuyingRealmHistoryDataProviderMixin:SetItemLink(itemLink)
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeys)
    self:SetItem(dbKeys[1])
  end)
end

function LogisticianBuyingRealmHistoryDataProviderMixin:GetColumnHideStates()
  return Logistician.Config.Get(Logistician.Config.Options.COLUMNS_BUYING_HISTORICAL_PRICES)
end

function LogisticianBuyingRealmHistoryDataProviderMixin:GetRowTemplate()
  return "LogisticianBuyingHistoricalPriceRowTemplate"
end
