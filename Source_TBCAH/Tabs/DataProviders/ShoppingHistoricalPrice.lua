LogisticianShoppingHistoricalPriceProviderMixin = CreateFromMixins(LogisticianHistoricalPriceProviderMixin)

function LogisticianShoppingHistoricalPriceProviderMixin:OnLoad()
  LogisticianHistoricalPriceProviderMixin.OnLoad(self)

  Logistician.EventBus:Register( self, { Logistician.Shopping.Tab.Events.ShowHistoricalPrices })
end

function LogisticianShoppingHistoricalPriceProviderMixin:ReceiveEvent(event, itemInfo)
  if event == Logistician.Shopping.Tab.Events.ShowHistoricalPrices then
    Logistician.Utilities.DBKeyFromLink(itemInfo.itemLink, function(dbKeys)
      self:SetItem(dbKeys[1])
    end)
  end
end

function LogisticianShoppingHistoricalPriceProviderMixin:GetColumnHideStates()
  return Logistician.Config.Get(Logistician.Config.Options.COLUMNS_SHOPPING_HISTORICAL_PRICES)
end
