AuctionatorAHFrameMixin = {}

local function InitializeAuctionHouseTabs()
  if Auctionator.State.TabFrameRef == nil then
    Auctionator.State.TabFrameRef = CreateFrame(
      "Frame",
      "AuctionatorAHTabsContainer",
      AuctionFrame,
      "AuctionatorAHTabsContainerTemplate"
    )
  end
end

local function InitializeBuyFrame()
  if Auctionator.State.BuyFrameRef == nil then
    Auctionator.State.BuyFrameRef = CreateFrame(
      "Frame",
      "AuctionatorBuyFrame",
      AuctionatorShoppingFrame,
      "AuctionatorBuyFrameTemplateForShopping"
    )
  end
end

local function InitializePageStatusDialog()
  if Auctionator.State.PageStatusFrameRef == nil then
    Auctionator.State.PageStatusFrameRef = CreateFrame(
      "Frame",
      "AuctionatorPageStatusDialogFrame",
      AuctionFrame,
      "AuctionatorPageStatusDialogTemplate"
    )
  end
end

local function InitializeThrottlingTimeoutDialog()
  if Auctionator.State.ThrottlingTimeoutFrameRef == nil then
    Auctionator.State.ThrottlingTimeoutFrameRef = CreateFrame(
      "Frame",
      "AuctionatorThrottlingTimeoutDialogFrame",
      AuctionFrame,
      "AuctionatorThrottlingTimeoutDialogTemplate"
    )
  end
end

local function ShowDefaultTab()
  local tabs = AuctionatorAHTabsContainer.Tabs

  local chosenTab = tabs[Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_TAB)]

  if chosenTab then
    chosenTab:Click()
  end
end

local function InitializeFullScanFrame()
  if Auctionator.State.FullScanFrameRef == nil then
    Auctionator.State.FullScanFrameRef = CreateFrame(
      "FRAME",
      "AuctionatorFullScanFrame",
      AuctionHouseFrame,
      "AuctionatorFullScanFrameTemplate"
    )
  end
end

local setupSearchCategories = false
local function InitializeSearchCategories()
  if setupSearchCategories then
    return
  end

  Auctionator.Search.InitializeCategories()

  setupSearchCategories = true
end

-- In-memory only (not a SavedVariable), so the moved position lasts for the current login
-- session (survives closing/reopening the AH, and /reload) but resets back to default on
-- the next login.
local rememberedWindowPosition = nil
local movableWindowInitialized = false
local function InitializeMovableWindow()
  if movableWindowInitialized then
    return
  end
  movableWindowInitialized = true

  AuctionFrame:SetMovable(true)
  AuctionFrame:SetClampedToScreen(true)
  AuctionFrame:EnableMouse(true)
  AuctionFrame:RegisterForDrag("LeftButton")
  AuctionFrame:SetScript("OnDragStart", function(frame)
    frame:StartMoving()
  end)
  AuctionFrame:SetScript("OnDragStop", function(frame)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    rememberedWindowPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
  end)
end

local function RestoreWindowPosition()
  if rememberedWindowPosition then
    AuctionFrame:ClearAllPoints()
    AuctionFrame:SetPoint(
      rememberedWindowPosition.point,
      UIParent,
      rememberedWindowPosition.relativePoint,
      rememberedWindowPosition.x,
      rememberedWindowPosition.y
    )
  end
end

-- Blizzard's own FrameXML closes AuctionFrame when the auctioneer interaction ends, which also
-- happens automatically the instant combat starts. Rather than fight that (unregistering the
-- underlying event risks skipping other cleanup it does), just let it hide then immediately
-- reshow it while still in combat, keeping the window visually open through combat.
local combatKeepOpenInitialized = false
local function InitializeCombatKeepOpen()
  if combatKeepOpenInitialized then
    return
  end
  combatKeepOpenInitialized = true

  hooksecurefunc(AuctionFrame, "Hide", function()
    if InCombatLockdown() then
      ShowUIPanel(AuctionFrame)
    end
  end)
end

function AuctionatorAHFrameMixin:OnShow()
  Auctionator.Debug.Message("AuctionatorAHFrameMixin:OnShow()")

  InitializeSearchCategories()
  InitializeAuctionHouseTabs()
  InitializeBuyFrame()
  InitializePageStatusDialog()
  InitializeThrottlingTimeoutDialog()
  InitializeFullScanFrame()
  InitializeMovableWindow()
  InitializeCombatKeepOpen()
  RestoreWindowPosition()

  ShowDefaultTab()
  C_Timer.After(0, function()
    ShowDefaultTab()
  end)
end

function AuctionatorAHFrameMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_HOUSE_SHOW" then
    self:Show()
  elseif eventName == "AUCTION_HOUSE_CLOSED" then
    -- Entering combat also fires this (the auctioneer session ends), but keep the window
    -- visually open through combat instead of auto-hiding it.
    if InCombatLockdown() then return end
    self:Hide()
  end
end
