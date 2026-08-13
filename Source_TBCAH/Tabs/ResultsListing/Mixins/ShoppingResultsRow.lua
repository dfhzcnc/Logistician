LogisticianShoppingResultsRowMixin = CreateFromMixins(LogisticianResultsRowTemplateMixin)

function LogisticianShoppingResultsRowMixin:OnClick(button, ...)
  Logistician.Debug.Message("LogisticianShoppingResultsRowMixin:OnClick()")
  LogisticianResultsRowTemplateMixin.OnClick(self, button, ...)

  if self.rowData.itemLink == nil then
    return
  end

  if button == "RightButton" then
    Logistician.EventBus
      :RegisterSource(self, "ShoppingResultsRowMixin")
      :Fire(self, Logistician.Shopping.Tab.Events.ShowHistoricalPrices, self.rowData)
      :UnregisterSource(self)

  elseif IsShiftKeyDown() then
    Logistician.EventBus
      :RegisterSource(self, "ShoppingResultsRowMixin")
      :Fire(self, Logistician.Shopping.Tab.Events.UpdateSearchTerm, Logistician.Utilities.GetNameFromLink(self.rowData.itemLink))
      :UnregisterSource(self)
  else

    Logistician.EventBus
      :RegisterSource(self, "ShoppingResultsRowMixin")
      :Fire(self, Logistician.Buying.Events.ShowForShopping, self.rowData)
      :Fire(self, Logistician.Shopping.Tab.Events.BuyScreenShown)
      :UnregisterSource(self)
  end
end
