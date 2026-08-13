LogisticianAHFrameMixin = {}

local function InitializeAuctionHouseTabs()
  if Logistician.State.TabFrameRef == nil then
    Logistician.State.TabFrameRef = CreateFrame(
      "Frame",
      "LogisticianAHTabsContainer",
      AuctionFrame,
      "LogisticianAHTabsContainerTemplate"
    )
  end
end

local function InitializeBuyFrame()
  if Logistician.State.BuyFrameRef == nil then
    Logistician.State.BuyFrameRef = CreateFrame(
      "Frame",
      "LogisticianBuyFrame",
      LogisticianShoppingFrame,
      "LogisticianBuyFrameTemplateForShopping"
    )
  end
end

local function InitializePageStatusDialog()
  if Logistician.State.PageStatusFrameRef == nil then
    Logistician.State.PageStatusFrameRef = CreateFrame(
      "Frame",
      "LogisticianPageStatusDialogFrame",
      AuctionFrame,
      "LogisticianPageStatusDialogTemplate"
    )
  end
end

local function InitializeThrottlingTimeoutDialog()
  if Logistician.State.ThrottlingTimeoutFrameRef == nil then
    Logistician.State.ThrottlingTimeoutFrameRef = CreateFrame(
      "Frame",
      "LogisticianThrottlingTimeoutDialogFrame",
      AuctionFrame,
      "LogisticianThrottlingTimeoutDialogTemplate"
    )
  end
end

local function ShowDefaultTab()
  local tabs = LogisticianAHTabsContainer.Tabs

  local chosenTab = tabs[Logistician.Config.Get(Logistician.Config.Options.DEFAULT_TAB)]

  if chosenTab then
    chosenTab:Click()
  end
end

local function InitializeFullScanFrame()
  if Logistician.State.FullScanFrameRef == nil then
    Logistician.State.FullScanFrameRef = CreateFrame(
      "FRAME",
      "LogisticianFullScanFrame",
      AuctionHouseFrame,
      "LogisticianFullScanFrameTemplate"
    )
  end
end

local setupSearchCategories = false
local function InitializeSearchCategories()
  if setupSearchCategories then
    return
  end

  Logistician.Search.InitializeCategories()

  setupSearchCategories = true
end

function LogisticianAHFrameMixin:OnShow()
  Logistician.Debug.Message("LogisticianAHFrameMixin:OnShow()")

  InitializeSearchCategories()
  InitializeAuctionHouseTabs()
  InitializeBuyFrame()
  InitializePageStatusDialog()
  InitializeThrottlingTimeoutDialog()
  InitializeFullScanFrame()

  ShowDefaultTab()
  C_Timer.After(0, function()
    ShowDefaultTab()
  end)
end

function LogisticianAHFrameMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_HOUSE_SHOW" then
    self:Show()
  elseif eventName == "AUCTION_HOUSE_CLOSED" then
    self:Hide()
  end
end
