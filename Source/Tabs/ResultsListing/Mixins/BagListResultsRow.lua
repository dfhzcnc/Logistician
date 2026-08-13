LogisticianBagListResultsRowMixin = CreateFromMixins(LogisticianResultsRowTemplateMixin)

function LogisticianBagListResultsRowMixin:OnClick(...)
  Logistician.Debug.Message("LogisticianBagListResultsRowMixin:OnClick()")
  Logistician.Utilities.TablePrint(self.rowData)

end
