LogisticianBuyingHistoricalPriceRowMixin = CreateFromMixins(LogisticianResultsRowTemplateMixin)

function LogisticianBuyingHistoricalPriceRowMixin:OnClick(button, ...)
  Logistician.Debug.Message("LogisticianBuyingHistoricalPriceRowMixin:OnClick()")

  if button == "LeftButton" then
    Logistician.EventBus
      :RegisterSource(self, "BuyingHistoricalPriceRow")
      :Fire(self, Logistician.Buying.Events.HistoricalPrice, self.rowData.minSeen)
      :UnregisterSource(self)
  elseif button == "RightButton" then
    Logistician.EventBus
      :RegisterSource(self, "BuyingHistoricalPriceRow")
      :Fire(self, Logistician.Buying.Events.HistoricalPrice, self.rowData.maxSeen)
      :UnregisterSource(self)
  end
end
