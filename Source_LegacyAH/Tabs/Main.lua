Auctionator.Tabs = {}

Auctionator.Tabs.State = {
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
function Auctionator.Tabs.Register(details)
  table.insert(Auctionator.Tabs.State.knownTabs, details)
end

Auctionator.Tabs.Register( {
  name = "Shopping",
  textLabel = AUCTIONATOR_L_SHOPPING_TAB,
  tabTemplate = "AuctionatorShoppingTabClassicFrameTemplate",
  tabHeader = AUCTIONATOR_L_SHOPPING_TAB_HEADER_2,
  tabFrameName = "AuctionatorShoppingFrame",
  tabOrder = 1,
})
Auctionator.Tabs.Register( {
  name = "Auctionator",
  textLabel = AUCTIONATOR_L_AUCTIONATOR,
  tabTemplate = "AuctionatorConfigurationTabFrameTemplate",
  tabHeader = AUCTIONATOR_L_INFO_TAB_HEADER,
  tabFrameName = "AuctionatorConfigFrame",
  tabOrder = 4,
})
