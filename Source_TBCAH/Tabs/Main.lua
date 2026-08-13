Logistician.Tabs = {}

Logistician.Tabs.State = {
  knownTabs = {}
}

-- details = {
--  name, -> string
--  textLabel, -> string
--  tabTemplate, -> string
--  tabHeader, -> string
--  displayModeKey, -> string
--  tabOrder -> number
-- }
function Logistician.Tabs.Register(details)
  table.insert(Logistician.Tabs.State.knownTabs, details)
end

Logistician.Tabs.Register( {
  name = "Shopping",
  textLabel = LOGISTICIAN_L_SHOPPING_TAB,
  tabTemplate = "LogisticianShoppingTabClassicFrameTemplate",
  tabHeader = LOGISTICIAN_L_SHOPPING_TAB_HEADER_2,
  tabFrameName = "LogisticianShoppingFrame",
  tabOrder = 1,
})
Logistician.Tabs.Register( {
  name = "Logistician",
  textLabel = LOGISTICIAN_L_LOGISTICIAN,
  tabTemplate = "LogisticianConfigurationTabFrameTemplate",
  tabHeader = LOGISTICIAN_L_INFO_TAB_HEADER,
  tabFrameName = "LogisticianConfigFrame",
  tabOrder = 4,
})
Logistician.Tabs.Register( {
  name = "Cancelling",
  textLabel = LOGISTICIAN_L_CANCELLING_TAB,
  tabTemplate = "LogisticianCancellingTabFrameNoRefreshTemplate",
  tabHeader = LOGISTICIAN_L_CANCELLING_TAB_HEADER,
  tabFrameName = "LogisticianCancellingFrame",
  tabOrder = 3,
})
Logistician.Tabs.Register( {
  name = "Selling",
  textLabel = LOGISTICIAN_L_SELLING_TAB,
  tabTemplate = "LogisticianSellingTabFrameTemplate",
  tabHeader = LOGISTICIAN_L_SELLING_TAB_HEADER,
  tabFrameName = "LogisticianSellingFrame",
  tabOrder = 2,
})
