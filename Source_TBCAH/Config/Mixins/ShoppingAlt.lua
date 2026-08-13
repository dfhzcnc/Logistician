LogisticianConfigShoppingAltFrameMixin = CreateFromMixins(LogisticianConfigShoppingFrameMixin)

function LogisticianConfigShoppingAltFrameMixin:ShowSettings()
  LogisticianConfigShoppingFrameMixin.ShowSettings(self)

  self.AlwaysLoadMore:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SHOPPING_ALWAYS_LOAD_MORE))
end

function LogisticianConfigShoppingAltFrameMixin:Save()
  LogisticianConfigShoppingFrameMixin.Save(self)

  Logistician.Config.Set(Logistician.Config.Options.SHOPPING_ALWAYS_LOAD_MORE, self.AlwaysLoadMore:GetChecked())
end
