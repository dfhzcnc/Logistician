LogisticianBuyingPostingHistoryRowMixin = CreateFromMixins(LogisticianResultsRowTemplateMixin)

function LogisticianBuyingPostingHistoryRowMixin:OnClick(button, ...)
  Logistician.Debug.Message("LogisticianBuyingPostingHistoryRowMixin:OnClick()")

  if button == "LeftButton" then
    Logistician.EventBus
      :RegisterSource(self, "BuyingPostingHistoryRow")
      :Fire(self, Logistician.Buying.Events.HistoricalPrice, self.rowData.price)
      :UnregisterSource(self)
  end
end
