LogisticianConfigShoppingFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigShoppingFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigShoppingFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_SHOPPING_CATEGORY
  self.parent = "Logistician"

  self:SetupPanel()
end

local function GetShoppingListNames()
  local names = {LOGISTICIAN_L_NONE}
  local values = {Logistician.Constants.NO_LIST}

  if Logistician.Shopping.ListManager == nil then
    return names, values
  end

  for index = 1, Logistician.Shopping.ListManager:GetCount() do
    local list = Logistician.Shopping.ListManager:GetByIndex(index)
    table.insert(names, list:GetName())
    table.insert(values, list:GetName())
  end
  return names, values
end

function LogisticianConfigShoppingFrameMixin:ShowSettings()
  self.AutoListSearch:SetChecked(Logistician.Config.Get(Logistician.Config.Options.AUTO_LIST_SEARCH))

  self.DefaultShoppingList:InitAgain(GetShoppingListNames())

  local currentDefault = Logistician.Config.Get(Logistician.Config.Options.DEFAULT_LIST)
  if Logistician.Shopping.ListManager and Logistician.Shopping.ListManager:GetIndexForName(currentDefault) == nil then
    currentDefault = ""
  end

  self.DefaultShoppingList:SetValue(currentDefault)

  self.ListMissingTerms:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SHOPPING_LIST_MISSING_TERMS))
end

function LogisticianConfigShoppingFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigShoppingFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.AUTO_LIST_SEARCH, self.AutoListSearch:GetChecked())

  Logistician.Config.Set(Logistician.Config.Options.DEFAULT_LIST, self.DefaultShoppingList:GetValue())

  Logistician.Config.Set(Logistician.Config.Options.SHOPPING_LIST_MISSING_TERMS, self.ListMissingTerms:GetChecked())
end

function LogisticianConfigShoppingFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigShoppingFrameMixin:Cancel()")
end
