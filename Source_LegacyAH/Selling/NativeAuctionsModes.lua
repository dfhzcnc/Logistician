-- Adds a Logistician buyout-posting mode to Blizzard's native Auctions page.
-- Bid mode deliberately leaves Blizzard's original controls and posting path intact.

local controller = CreateFrame("Frame")
local initialized = false

local function SavePoints(frame)
  local points = {}
  for index = 1, frame:GetNumPoints() do
    points[index] = { frame:GetPoint(index) }
  end
  return points
end

local function RestorePoints(frame, points)
  frame:ClearAllPoints()
  for _, point in ipairs(points) do
    frame:SetPoint(unpack(point))
  end
end

local function NudgePoints(frame, dx, dy)
  local points = {}
  for index = 1, frame:GetNumPoints() do
    points[index] = { frame:GetPoint(index) }
  end
  frame:ClearAllPoints()
  for _, point in ipairs(points) do
    local relPoint, relTo, relRelPoint, x, y = unpack(point)
    frame:SetPoint(relPoint, relTo, relRelPoint, x + dx, y + dy)
  end
end

local function SetPoint(frame, point, relativeTo, relativePoint, x, y)
  frame:ClearAllPoints()
  frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

local function FindFrameFontString(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region:GetObjectType() == "FontString" then
      return region
    end
  end
end

local function GetSelectedItemInfo()
  local name, texture, count, quality, canUse, vendorPrice, pricePerUnit,
    stackCount, totalCount, itemID = GetAuctionSellItemInfo()
  if not name then
    return nil
  end

  local maxStack = itemID and select(8, GetItemInfo(itemID)) or count
  local itemLink = itemID and select(2, GetItemInfo(itemID))
  return {
    name = name,
    itemLink = itemLink,
    itemID = itemID,
    count = count or 0,
    totalCount = totalCount or count or 0,
    maxStack = maxStack or count or 1,
    quality = quality,
  }
end

local function GetAutoBid(stackPrice)
  local percent = Auctionator.Config.Get(
    Auctionator.Config.Options.STARTING_PRICE_PERCENTAGE
  ) or 100
  return math.ceil(stackPrice * percent / 100)
end

local MONEY_GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:10:0:-1|t"
local MONEY_SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
local MONEY_COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t"
local BROWSE_MONEY_GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:13:11:0:-1|t"
local BROWSE_MONEY_SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:13:13:0:0|t"
local BROWSE_MONEY_COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:13:13:0:0|t"

-- Fixed offsets (from the row's RIGHT edge) for each denomination column.
-- Every column is anchored independently so its icon lines up across rows
-- regardless of how many digits the gold/silver/copper amount has; chaining
-- one column's anchor to another's rendered text width let their icons
-- drift out of alignment with each other.
local MONEY_COPPER_COLUMN_OFFSET = -8
local MONEY_SILVER_COLUMN_OFFSET = -46
local MONEY_GOLD_COLUMN_OFFSET = -84
local MONEY_COPPER_COLUMN_WIDTH = 34
local MONEY_SILVER_COLUMN_WIDTH = 34
local MONEY_GOLD_COLUMN_WIDTH = 50

local function GetMoneyColumns(amount, browseStyle)
  amount = math.floor(amount)
  local gold = math.floor(amount / 10000)
  local silver = math.floor(amount / 100) % 100
  local copper = amount % 100
  local goldIcon = browseStyle and BROWSE_MONEY_GOLD_ICON or MONEY_GOLD_ICON
  local silverIcon = browseStyle and BROWSE_MONEY_SILVER_ICON or MONEY_SILVER_ICON
  local copperIcon = browseStyle and BROWSE_MONEY_COPPER_ICON or MONEY_COPPER_ICON
  local goldText = gold > 0 and (gold .. goldIcon) or ""
  local silverText = (gold > 0 or silver > 0) and (silver .. silverIcon) or ""
  local copperText = copper .. copperIcon
  return goldText, silverText, copperText
end

local function PositionPriceLabel(label, price)
  label:ClearAllPoints()
  label:SetPoint("RIGHT", price, "RIGHT", -price:GetStringWidth() - 3, 0)
end

local MONEY_ICON_TEXTURES = {
  "Interface\\MoneyFrame\\UI-GoldIcon",
  "Interface\\MoneyFrame\\UI-SilverIcon",
  "Interface\\MoneyFrame\\UI-CopperIcon",
}

local function SetStackedMoneyVisible(priceText, shown)
  if priceText then
    priceText:SetShown(shown)
  end
  for _, icon in ipairs((priceText and priceText.LogisticianMoneyIcons) or {}) do
    icon:SetShown(shown and icon.LogisticianShown == true)
  end
end

local function SetStackedMoneyDisplay(priceText, amount)
  if not priceText then
    return
  end

  amount = math.floor(amount or 0)
  local gold = math.floor(amount / 10000)
  local silver = math.floor(amount / 100) % 100
  local copper = amount % 100
  local rows = {}
  if gold > 0 then
    table.insert(rows, { amount = gold, icon = 1 })
  end
  if gold > 0 or silver > 0 then
    table.insert(rows, { amount = silver, icon = 2 })
  end
  table.insert(rows, { amount = copper, icon = 3 })

  local textRows = {}
  for _, row in ipairs(rows) do
    table.insert(textRows, tostring(row.amount))
  end
  priceText:SetText(table.concat(textRows, "\n"))
  -- Keep a little separation without pushing the copper row outside the
  -- duration panel.
  priceText:SetSpacing(3)

  priceText.LogisticianMoneyIcons = priceText.LogisticianMoneyIcons or {}
  local parent = priceText:GetParent()
  for index = 1, 3 do
    local icon = priceText.LogisticianMoneyIcons[index]
    if not icon and parent then
      icon = parent:CreateTexture(nil, "OVERLAY")
      icon:SetSize(12, 12)
      priceText.LogisticianMoneyIcons[index] = icon
    end
    local row = rows[index]
    if icon and row then
      icon:SetTexture(MONEY_ICON_TEXTURES[row.icon])
      icon:ClearAllPoints()
      -- Match the FontString's line stride and center each icon against its
      -- corresponding number.
      icon:SetPoint("TOPLEFT", priceText, "TOPRIGHT", 2, 1 - (index - 1) * 15)
      icon.LogisticianShown = true
      icon:SetShown(priceText:IsShown())
    elseif icon then
      icon.LogisticianShown = false
      icon:Hide()
    end
  end
end

local function GetAmountWithUndercut(amount)
  local salesPreference = Auctionator.Config.Get(
    Auctionator.Config.Options.AUCTION_SALES_PREFERENCE
  )
  local undercutAmount = 0
  if salesPreference == Auctionator.Config.SalesTypes.STATIC then
    undercutAmount = Auctionator.Config.Get(
      Auctionator.Config.Options.UNDERCUT_STATIC_VALUE
    )
  else
    undercutAmount = math.ceil(
      amount * Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_PERCENTAGE) / 100
    )
  end
  -- 1 copper is the minimum price the AH accepts; undercutting a 1-copper
  -- listing (or anything the undercut amount would otherwise zero out)
  -- must never round down to 0.
  return math.max(1, amount - undercutAmount)
end

local function PlayAuctionSlotItemCue(itemInfo)
  if not itemInfo or not (itemInfo.itemLink or itemInfo.itemID) then
    return
  end

  local source = itemInfo.itemLink or itemInfo.itemID
  if type(PlayItemSound) == "function" then
    if pcall(PlayItemSound, source, "PutDown") then
      return
    end
    if pcall(PlayItemSound, source, "Use") then
      return
    end
    if pcall(PlayItemSound, source) then
      return
    end
  end

  local classID
  if C_Item and C_Item.GetItemInfoInstant then
    classID = select(6, C_Item.GetItemInfoInstant(source))
  end

  local weaponClass = LE_ITEM_CLASS_WEAPON or
    (Enum and Enum.ItemClass and Enum.ItemClass.Weapon)
  local armorClass = LE_ITEM_CLASS_ARMOR or
    (Enum and Enum.ItemClass and Enum.ItemClass.Armor)
  local consumableClass = LE_ITEM_CLASS_CONSUMABLE or
    (Enum and Enum.ItemClass and Enum.ItemClass.Consumable)

  local soundKit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  if classID == weaponClass or classID == armorClass then
    soundKit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN
  elseif classID == consumableClass then
    soundKit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
  end
  if soundKit then
    PlaySound(soundKit)
  end
end

local function PlayAuctionCancelCue()
  local soundKit = SOUNDKIT and (
    SOUNDKIT.IG_MAINMENU_CLOSE or SOUNDKIT.IG_CHARACTER_INFO_CLOSE
  )
  if soundKit then
    PlaySound(soundKit)
  end
end

local RESULT_ROW_HEIGHT = 40
local RESULT_ROW_COUNT = 8
local CANCEL_TIMEOUT = 10
-- Shared by Bid Mode and Buyout Mode results rows/headers alike so neither
-- the header row nor the row columns shift width when switching modes.
local RESULTS_COLUMN_X = 235
local RESULTS_POSTER_X = 330
local RESULTS_PRICE_X = 420
local RESULTS_COPPER_X = 516
local CANCEL_CONFIRM_POPUP = "LogisticianConfirmAuctionCancel"

local function SetPageStatusSuppressed(suppressed)
  controller.suppressPageStatusDialog = suppressed == true
  local frame = Auctionator and Auctionator.State and Auctionator.State.PageStatusFrameRef
  if not frame then
    return
  end
  if not frame.logisticianSuppressHooked then
    frame:HookScript("OnShow", function(statusFrame)
      if controller.suppressPageStatusDialog then
        statusFrame:Hide()
      end
    end)
    frame.logisticianSuppressHooked = true
  end
  if controller.suppressPageStatusDialog then
    frame:Hide()
  end
end

local function SetNativeResultsHidden(self, hidden)
  if not self.nativeResultFrames then
    self.nativeResultFrames = {}
    self.nativeResultFramesSeen = {}
  end
  local function Add(frame)
    if frame and not self.nativeResultFramesSeen[frame] then
      self.nativeResultFramesSeen[frame] = true
      table.insert(self.nativeResultFrames, {
        frame = frame,
        alpha = frame:GetAlpha(),
        mouse = frame.IsMouseEnabled and frame:IsMouseEnabled() or nil,
      })
    end
  end
  local function AddTree(frame)
    if not frame then
      return
    end
    Add(frame)
    for _, child in ipairs({ frame:GetChildren() }) do
      AddTree(child)
    end
  end
  AddTree(_G.AuctionsScrollFrame)
  AddTree(_G.AuctionsQualitySort)
  AddTree(_G.AuctionsDurationSort)
  AddTree(_G.AuctionsHighBidderSort)
  AddTree(_G.AuctionsBidSort)
  local index = 1
  while _G["AuctionsButton" .. index] do
    AddTree(_G["AuctionsButton" .. index])
    index = index + 1
  end
  for _, state in ipairs(self.nativeResultFrames) do
    state.frame:SetAlpha(hidden and 0 or state.alpha)
    if state.mouse ~= nil and state.frame.EnableMouse then
      state.frame:EnableMouse(hidden and false or state.mouse)
    end
  end
end

-- The staged item's name label defaults to a flat highlight color; recolor
-- it to match the item's rarity, like the results list already does.
local function NormalizeWhitespace(text)
  if not text then
    return ""
  end
  return tostring(text):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function StripColorCodes(text)
  if not text then
    return ""
  end
  return tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function CollectMatchingFontStrings(frame, normalizedItemName, output)
  if not frame then
    return
  end

  for _, region in ipairs({ frame:GetRegions() }) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      local current = NormalizeWhitespace(StripColorCodes(region:GetText())):lower()
      if current == normalizedItemName or
          string.find(current, normalizedItemName, 1, true) then
        table.insert(output, region)
      end
    end
  end

  for _, child in ipairs({ frame:GetChildren() }) do
    CollectMatchingFontStrings(child, normalizedItemName, output)
  end
end

local function UpdateItemNameQualityColor()
  local item = GetSelectedItemInfo()
  local quality = item and item.quality or nil
  if not quality and item and item.itemLink then
    quality = select(3, GetItemInfo(item.itemLink))
  end
  if not quality and item and item.itemID then
    quality = select(3, GetItemInfo(item.itemID))
  end
  local color = quality and ITEM_QUALITY_COLORS[quality]

  local itemName = item and item.name or nil
  local normalizedItemName = NormalizeWhitespace(StripColorCodes(itemName)):lower()

  local border = (AuctionsItemButton and (AuctionsItemButton.IconBorder or
    _G.AuctionsItemButtonIconBorder)) or nil
  local iconTexture = AuctionsItemButton and AuctionsItemButton.icon or
    (AuctionsItemButton and _G[(AuctionsItemButton:GetName() or "") .. "Icon"]) or nil

  local function ApplyColorToVisibleItemName(r, g, b)
    if AuctionsItemName then
      AuctionsItemName:SetTextColor(r, g, b)
    end
    if normalizedItemName == "" then
      controller.cachedItemNameTargets = nil
      controller.cachedItemNameValue = nil
      return
    end

    if controller.cachedItemNameValue ~= normalizedItemName then
      controller.cachedItemNameTargets = {}
      controller.cachedItemNameValue = normalizedItemName
      if AuctionFrameAuctions then
        CollectMatchingFontStrings(AuctionFrameAuctions, normalizedItemName,
          controller.cachedItemNameTargets)
      end
    end

    for _, fontString in ipairs(controller.cachedItemNameTargets or {}) do
      if fontString and fontString.SetTextColor then
        fontString:SetTextColor(r, g, b)
      end
    end
  end

  if color then
    ApplyColorToVisibleItemName(color.r, color.g, color.b)
    if iconTexture and iconTexture.SetVertexColor then
      iconTexture:SetVertexColor(1, 1, 1)
    end
    if border and border.SetVertexColor then
      border:SetVertexColor(color.r, color.g, color.b)
      if border.Show then border:Show() end
    end
  else
    ApplyColorToVisibleItemName(1, 1, 1)
    if iconTexture and iconTexture.SetVertexColor then
      iconTexture:SetVertexColor(1, 1, 1)
    end
    if border and border.SetVertexColor then
      border:SetVertexColor(0.62, 0.62, 0.62)
      if border.Show then border:Show() end
    end
  end
end

local function SetResultSort(self, key)
  if self.resultSortKey == key then
    self.resultSortAscending = not self.resultSortAscending
  else
    self.resultSortKey = key
    self.resultSortAscending = true
  end
  self.ResultsProvider:Sort(key, self.resultSortAscending and
    Auctionator.Constants.SORT.ASCENDING or Auctionator.Constants.SORT.DESCENDING)
  if self.ResultsProvider then
    self.ResultsProvider.sortedGeneration = self.ResultsProvider.populateGeneration
  end
  for _, header in ipairs(self.ResultsHeaders or {}) do
    header.Arrow:SetShown(header.sortKey == key)
    if header.sortKey == key then
      header.Arrow:SetTexCoord(0, 1, self.resultSortAscending and 0 or 1,
        self.resultSortAscending and 1 or 0)
    end
  end
end

-- A column sort picked in one mode's header (e.g. Buyout Mode's "Unit
-- Price") has no matching column/meaning in another mode's headers, so
-- switching modes should drop back to that mode's default order and clear
-- the arrow rather than carrying over a stale, mismatched sort column.
local function ResetResultSort(self)
  self.resultSortKey = nil
  self.resultSortAscending = nil
  for _, header in ipairs(self.ResultsHeaders or {}) do
    header.Arrow:Hide()
  end
end

-- Both modes' queries already ask to come back sorted this way (RefreshResults
-- sets query.sortKey = "bid"/"unitprice"), so reflect that as the active
-- sort/arrow on entry instead of leaving the header unmarked until the
-- player clicks it themselves. Only kicks in when nothing has been
-- explicitly chosen yet (i.e. right after ResetResultSort).
local DEFAULT_RESULT_SORT_KEY_BY_MODE = {
  bid = "currentBid",
  buyout = "unitPrice",
}
local function ApplyDefaultResultSort(self)
  local defaultKey = DEFAULT_RESULT_SORT_KEY_BY_MODE[self.mode]
  if not defaultKey or self.resultSortKey ~= nil then
    return
  end
  self.resultSortKey = defaultKey
  self.resultSortAscending = true
  for _, header in ipairs(self.ResultsHeaders or {}) do
    header.Arrow:SetShown(header.sortKey == self.resultSortKey)
    if header.sortKey == self.resultSortKey then
      header.Arrow:SetTexCoord(0, 1, 0, 1)
    end
  end
end

local function GetSelectedResult(self)
  local provider = self.ResultsProvider
  if not provider then
    return nil
  end
  for index = 1, provider:GetCount() do
    local result = provider:GetEntryAt(index)
    if result and result.isSelected then
      return result
    end
  end
end

local function SetCustomSelectedResult(self, selectedIndex)
  local provider = self.ResultsProvider
  if not provider then
    return
  end

  provider.onPreserveScroll()
  for index, result in ipairs(provider.currentResults or {}) do
    result.notReady = false
    result.isSelected = index == selectedIndex
  end
  provider:SetDirty()
end

local function CountMatchingOwnedAuctions(result)
  if not result or not result.itemLink then
    return 0
  end
  local wantedLink = Auctionator.Search.GetCleanItemLink(result.itemLink)
  local count = 0
  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local itemLink = GetAuctionItemLink("owner", index)
    local cleanLink = itemLink and Auctionator.Search.GetCleanItemLink(itemLink)
    local stackPrice = info[Auctionator.Constants.AuctionItemInfo.Buyout]
    local stackSize = info[Auctionator.Constants.AuctionItemInfo.Quantity]
    local bidAmount = info[Auctionator.Constants.AuctionItemInfo.BidAmount]
    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus]
    local resultStackPrice = result.stackPrice or 0
    if saleStatus ~= 1 and cleanLink == wantedLink and
        stackPrice == resultStackPrice and stackSize == result.stackSize and
        bidAmount == result.bidAmount then
      count = count + 1
    end
  end
  return count
end

local function SetCancelLocked(self, locked)
  if self.ResultsCancelButton then
    self.ResultsCancelButton:SetText(locked and "Cancelling..." or "Cancel Auction")
    self.ResultsCancelButton:SetEnabled(false)
  end
  if self.ModeButton then self.ModeButton:SetEnabled(not locked) end
  if self.ModeToggleButton then self.ModeToggleButton:SetEnabled(not locked) end
  local hasSelectedItem = GetSelectedItemInfo() ~= nil
  if self.ResultsRefreshButton then
    self.ResultsRefreshButton:SetEnabled(
      not locked and (hasSelectedItem or self.resultsItemLink ~= nil))
  end
  if self.ResultsHistoryButton then
    self.ResultsHistoryButton:SetEnabled(not locked and hasSelectedItem)
  end
end

local function UpdateCancelButton(self)
  if not self.ResultsCancelButton then
    return
  end
  local result = GetSelectedResult(self)
  self.ResultsCancelButton:SetShown(
    (self.mode == "bid" or self.mode == "buyout") and
    self.ResultsPanel and self.ResultsPanel:IsShown())
  self.ResultsCancelButton:SetEnabled(
    self.cancelPending == nil and result ~= nil and result.isOwned == true and
    (result.numStacks or 0) > 0 and Auctionator.AH.IsNotThrottled())
end

local function FinishCancelWaiting(self, errorMessage)
  self.cancelPending = nil
  SetCancelLocked(self, false)
  UpdateCancelButton(self)
  if errorMessage and UIErrorsFrame then
    UIErrorsFrame:AddMessage(errorMessage, 1, 0.1, 0.1, 1)
  end
end

local RefreshResults

local function TryFinishCancellation(self)
  local pending = self.cancelPending
  if not pending or not pending.removalConfirmed or not pending.ownerCountDecreased then
    return
  end
  local itemLink = pending.itemLink
  self.resultViewRestore = pending.resultViewRestore
  FinishCancelWaiting(self)
  C_Timer.After(0, function()
    if (self.mode == "bid" or self.mode == "buyout") and
        self.ResultsPanel and self.ResultsPanel:IsShown() then
      RefreshResults(self, itemLink)
    end
  end)
end

local function StartCancellation(self, result)
  local beforeCount = CountMatchingOwnedAuctions(result)
  if beforeCount < 1 then
    if UIErrorsFrame then
      UIErrorsFrame:AddMessage("Auction could not be found. Refresh and try again.",
        1, 0.1, 0.1, 1)
    end
    return
  end

  local pending = {
    itemLink = result.itemLink,
    result = result,
    beforeCount = beforeCount,
    removalConfirmed = false,
    ownerCountDecreased = false,
    resultViewRestore = {
      itemLink = Auctionator.Search.GetCleanItemLink(result.itemLink),
      stackPrice = result.stackPrice,
      stackSize = result.stackSize,
      bidAmount = result.bidAmount,
      isOwned = result.isOwned,
      requestAllResults = self.ResultsProvider and
        self.ResultsProvider:GetRequestAllResults() or false,
      scrollOffset = self.ResultsScroll and
        FauxScrollFrame_GetOffset(self.ResultsScroll) or 0,
    },
  }
  self.cancelPending = pending
  SetCancelLocked(self, true)
  Auctionator.AH.CancelAuction(result)
  C_Timer.After(CANCEL_TIMEOUT, function()
    if self.cancelPending == pending then
      FinishCancelWaiting(self,
        "Cancellation could not be confirmed. Refresh before trying again.")
    end
  end)
end

local function RestoreResultView(self)
  local restore = self.resultViewRestore
  if not restore or not restore.ready then
    return
  end
  self.resultViewRestore = nil

  local provider = self.ResultsProvider
  local count = provider and provider:GetCount() or 0
  local maxOffset = math.max(0, count - RESULT_ROW_COUNT)
  local offset = math.min(restore.scrollOffset or 0, maxOffset)
  FauxScrollFrame_SetOffset(self.ResultsScroll, offset)
  if self.ResultsScrollBar then
    self.ResultsScrollBar:SetValue(offset * RESULT_ROW_HEIGHT)
  end

  for index = 1, count do
    local result = provider:GetEntryAt(index)
    local cleanLink = result and result.itemLink and
      Auctionator.Search.GetCleanItemLink(result.itemLink)
    if result and cleanLink == restore.itemLink and
        result.stackPrice == restore.stackPrice and
        result.stackSize == restore.stackSize and
        result.bidAmount == restore.bidAmount and
        result.isOwned == restore.isOwned then
      provider:SetSelectedIndex(index)
      break
    end
  end
end

local function FocusOwnedBidResult(self)
  if self.mode ~= "bid" or not self.ResultsProvider then
    return
  end
  local count = self.ResultsProvider:GetCount()
  for index = 1, count do
    local result = self.ResultsProvider:GetEntryAt(index)
    if result and result.isOwned then
      self.ResultsProvider:SetSelectedIndex(index)
      local maxOffset = math.max(0, count - RESULT_ROW_COUNT)
      local offset = math.min(math.max(0,
        index - math.ceil(RESULT_ROW_COUNT / 2)), maxOffset)
      FauxScrollFrame_SetOffset(self.ResultsScroll, offset)
      if self.ResultsScrollBar then
        self.ResultsScrollBar:SetValue(offset * RESULT_ROW_HEIGHT)
      end
      return
    end
  end
end

local function RenderResults(self)
  if not self.ResultsPanel or not self.ResultsPanel:IsShown() then return end
  local provider = self.ResultsProvider
  local count = provider and provider:GetCount() or 0
  local selectedItem = GetSelectedItemInfo()
  if self.ResultsRefreshButton then
    self.ResultsRefreshButton:SetEnabled(
      (selectedItem ~= nil or self.resultsItemLink ~= nil) and
      self.cancelPending == nil)
  end
  if self.ResultsHistoryButton then
    self.ResultsHistoryButton:SetEnabled(selectedItem ~= nil and self.cancelPending == nil)
  end
  -- Provider callbacks can still arrive while the history view is open.
  -- Keep those updates from exposing current-price rows underneath it.
  if self.resultsHistoryShown then return end
  RestoreResultView(self)
  -- Buyout Mode still waits for the search to fully conclude before seeding
  -- (per an earlier explicit request, to avoid any partial/not-yet-final
  -- result set being used). Bid Mode (below) is different: its query is
  -- already sorted ascending by current bid server-side (see
  -- RefreshResults), so the first entry is reliably the cheapest as soon as
  -- any page arrives - waiting for the whole search left Starting Unit
  -- Price/Total Price/Deposit blank and popping in late instead of updating
  -- promptly.
  local searchConcluded = not self.resultsSearching
  if self.mode == "buyout" and count > 0 and searchConcluded and not self.pricesSeededForSearch then
    local first = provider:GetEntryAt(1)
    if first and first.unitPrice and first.stackPrice then
      self.pricesSeededForSearch = true
      local unitPrice = first.isOwned and first.unitPrice or
        GetAmountWithUndercut(first.unitPrice)
      local stackSize = math.max(1, self.Stacks.StackSize:GetNumber())
      local stackPrice = unitPrice * stackSize
      MoneyInputFrame_SetCopper(StartPrice, unitPrice)
      MoneyInputFrame_SetCopper(BuyoutPrice, stackPrice)
      self.previousUnitPrice = unitPrice
      self.previousStackPrice = stackPrice
    end
  elseif self.mode == "bid" and count > 0 and not self.pricesSeededForSearch then
    -- Unlike Buyout Mode, Bid Mode's query already asks the server to sort
    -- pages by current bid ascending (see RefreshResults), so the first
    -- entry is already reliably the cheapest as soon as ANY page has
    -- arrived - no need to wait for the whole multi-page search to finish,
    -- which was leaving Starting Unit Price/Total Price/Deposit blank and
    -- popping in late instead of updating promptly.
    local first = provider:GetEntryAt(1)
    if first and first.currentBid then
      self.pricesSeededForSearch = true
      local unitBid = first.isOwned and first.currentBid or
        GetAmountWithUndercut(first.currentBid)
      MoneyInputFrame_SetCopper(StartPrice, unitBid)
    end
  end
  FauxScrollFrame_Update(self.ResultsScroll, count, RESULT_ROW_COUNT, RESULT_ROW_HEIGHT)
  -- Blizzard hides a FauxScrollFrame scrollbar when there is nothing to
  -- scroll. Keep the empty, disabled-looking track visible like Selling.
  if self.ResultsScrollBar then
    self.ResultsScrollBar:Show()
    self.ResultsScrollBar:SetAlpha(1)
    self.ResultsScrollBar:SetFrameLevel(self.ResultsPanel:GetFrameLevel() + 20)
    if self.ResultsNativeScrollUpButton then self.ResultsNativeScrollUpButton:Hide() end
    if self.ResultsNativeScrollDownButton then self.ResultsNativeScrollDownButton:Hide() end
    local offset = FauxScrollFrame_GetOffset(self.ResultsScroll)
    if self.ResultsScrollUpButton and self.ResultsScrollDownButton then
      if count > RESULT_ROW_COUNT and offset > 0 then
        self.ResultsScrollUpButton:Enable()
      else
        self.ResultsScrollUpButton:Disable()
      end
      if count > RESULT_ROW_COUNT and offset < count - RESULT_ROW_COUNT then
        self.ResultsScrollDownButton:Enable()
      else
        self.ResultsScrollDownButton:Disable()
      end
      self.ResultsScrollUpButton:Show()
      self.ResultsScrollDownButton:Show()
    end
  end
  local offset = FauxScrollFrame_GetOffset(self.ResultsScroll)

  for index, row in ipairs(self.ResultsRows) do
    local result = provider and provider:GetEntryAt(offset + index)
    row.result = result
    row.resultIndex = offset + index
    row:SetShown(result ~= nil)
    if result then
      -- Shared by both modes so switching Bid/Buyout doesn't shift columns.
      local columnX = RESULTS_COLUMN_X
      local posterX = RESULTS_POSTER_X
      local priceX = RESULTS_PRICE_X
      local copperX = RESULTS_COPPER_X
      row.Available:ClearAllPoints()
      row.Available:SetPoint("LEFT", row, "LEFT", columnX, 0)
      row.Poster:ClearAllPoints()
      row.Poster:SetPoint("LEFT", row, "LEFT", posterX, 0)
      row.UnitLabel:ClearAllPoints()
      row.UnitLabel:SetPoint("LEFT", row, "LEFT", priceX, -9)
      row.UnitPrice:ClearAllPoints()
      row.UnitPrice:SetPoint("LEFT", row, "LEFT", priceX, -9)
      row.UnitCopper:ClearAllPoints()
      row.UnitCopper:SetPoint("LEFT", row, "LEFT", copperX, -9)
      row.BidQuantity:ClearAllPoints()
      row.BidQuantity:SetPoint("LEFT", row, "LEFT", priceX, 9)
      row.BidPrice:ClearAllPoints()
      row.BidPrice:SetPoint("LEFT", row, "LEFT", priceX, 9)
      row.BidCopper:ClearAllPoints()
      row.BidCopper:SetPoint("LEFT", row, "LEFT", copperX, 9)
      row.BuyoutLabel:ClearAllPoints()
      row.BuyoutLabel:SetPoint("LEFT", row, "LEFT", priceX, -9)
      row.BuyoutPrice:ClearAllPoints()
      row.BuyoutPrice:SetPoint("LEFT", row, "LEFT", priceX, -9)
      row.BuyoutCopper:ClearAllPoints()
      row.BuyoutCopper:SetPoint("LEFT", row, "LEFT", copperX, -9)
      local texture = result.itemLink and select(10, GetItemInfo(result.itemLink))
      if not texture and result.itemLink and GetItemIcon then
        texture = GetItemIcon(result.itemLink)
      end
      if not texture and not result.unitPrice then
        texture = select(2, GetAuctionSellItemInfo())
      end
      SetItemButtonTexture(row.Icon,
        texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      SetItemButtonCount(row.Icon, result.stackSize or 0)
      local iconCount = row.Icon.Count or row.Icon.count
      if iconCount then
        local countFont, countSize = iconCount:GetFont()
        if countFont then
          iconCount:SetFont(countFont, countSize, "THICKOUTLINE")
        end
      end
      row.OwnerLabel:SetShown(result.isOwned == true)
      local itemName = result.name
      local itemQuality
      if not itemName and result.itemLink then
        itemName, _, itemQuality = GetItemInfo(result.itemLink)
      elseif result.itemLink then
        itemQuality = select(3, GetItemInfo(result.itemLink))
      end
      local displayName = itemName or ""
      row.Name:SetText(displayName)
      if self.mode == "bid" and (result.numStacks or 1) > 1 then
        row.NameQuantity:SetText("x" .. result.numStacks)
        row.NameQuantity:ClearAllPoints()
        row.NameQuantity:SetPoint(
          "LEFT", row.Name, "LEFT", math.min(row.Name:GetStringWidth() + 6, 180), 6
        )
        row.NameQuantity:Show()
      else
        row.NameQuantity:Hide()
      end
      local qualityColor = itemQuality and ITEM_QUALITY_COLORS[itemQuality]
      if qualityColor then
        row.Name:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b, 1)
      else
        row.Name:SetTextColor(1, 1, 1, 1)
      end
      if self.mode == "bid" then
        row.Name:Show()
        row.Name:SetWordWrap(false)
        row.Name:SetMaxLines(1)
        row.UnitLabel:Hide()
        row.UnitPrice:Hide()
        row.UnitCopper:Hide()
        row.UnitGold:Hide()
        row.Available:Show()
        row.Poster:Show()
        row.BidOnly:Hide()
        row.Available:SetFontObject("GameFontHighlightSmall")
        row.Available:SetText(result.timeLeftPretty or "")
        local hasBid = (result.bidAmount or 0) > 0
        local highBidder = result.highBidder
        if not highBidder and self.detailsHighBidder and
            self.detailsItemLink and result.itemLink and
            Auctionator.Search.GetCleanItemLink(self.detailsItemLink) ==
              Auctionator.Search.GetCleanItemLink(result.itemLink) and
            self.detailsBuyout == (result.stackPrice or 0) and
            self.detailsQuantity == (result.stackSize or 0) and
            self.detailsBidAmount == (result.bidAmount or 0) and
            self.detailsMinBid == (result.minBid or 0) then
          highBidder = self.detailsHighBidder
        end
        row.Poster:SetText(hasBid and (highBidder or "?") or "|cffff2020No Bids|r")
        local bidTotal = hasBid and result.bidAmount or result.minBid
        local stackSize = result.stackSize or 1
        local bidGoldText, bidSilverText, bidCopperText = GetMoneyColumns(
          math.ceil((bidTotal or 0) / math.max(1, stackSize)), true)
        local buyoutGoldText, buyoutSilverText, buyoutCopperText = GetMoneyColumns(result.unitPrice or 0, true)
        row.BidCopper:ClearAllPoints()
        row.BidCopper:SetPoint("RIGHT", row, "RIGHT", MONEY_COPPER_COLUMN_OFFSET, 9)
        row.BidPrice:ClearAllPoints()
        row.BidPrice:SetPoint("RIGHT", row, "RIGHT", MONEY_SILVER_COLUMN_OFFSET, 9)
        row.BidGold:ClearAllPoints()
        row.BidGold:SetPoint("RIGHT", row, "RIGHT", MONEY_GOLD_COLUMN_OFFSET, 9)
        row.BidGold:SetText(bidTotal and bidGoldText or "")
        row.BidGold:SetShown(bidTotal ~= nil and bidGoldText ~= "")
        row.BidPrice:SetText(bidTotal and bidSilverText or "")
        row.BidPrice:SetShown(bidTotal ~= nil)
        row.BidCopper:SetText(bidCopperText)
        row.BidCopper:Show()
        row.BidOnlyPriceLabel:SetShown(result.unitPrice == nil)
        row.BidQuantity:SetText(stackSize .. "x")
        row.BidQuantity:SetShown(stackSize > 1)
        PositionPriceLabel(row.BidQuantity,
          (bidGoldText ~= "" and row.BidGold) or
            (bidSilverText ~= "" and row.BidPrice) or row.BidCopper)
        row.BuyoutLabel:SetText("Buyout")
        row.BuyoutLabel:SetShown(result.unitPrice ~= nil)
        row.BuyoutCopper:ClearAllPoints()
        row.BuyoutCopper:SetPoint("RIGHT", row, "RIGHT", MONEY_COPPER_COLUMN_OFFSET, -9)
        row.BuyoutPrice:ClearAllPoints()
        row.BuyoutPrice:SetPoint("RIGHT", row, "RIGHT", MONEY_SILVER_COLUMN_OFFSET, -9)
        row.BuyoutGold:ClearAllPoints()
        row.BuyoutGold:SetPoint("RIGHT", row, "RIGHT", MONEY_GOLD_COLUMN_OFFSET, -9)
        row.BuyoutGold:SetText(buyoutGoldText)
        row.BuyoutGold:SetShown(result.unitPrice ~= nil and buyoutGoldText ~= "")
        row.BuyoutPrice:SetText(buyoutSilverText)
        row.BuyoutPrice:SetShown(result.unitPrice ~= nil)
        row.BuyoutCopper:SetText(buyoutCopperText)
        row.BuyoutCopper:SetShown(result.unitPrice ~= nil)
        PositionPriceLabel(row.BuyoutLabel,
          (buyoutGoldText ~= "" and row.BuyoutGold) or
            (buyoutSilverText ~= "" and row.BuyoutPrice) or row.BuyoutCopper)
      elseif result.unitPrice and result.stackPrice then
        local unitGoldText, unitSilverText, unitCopperText = GetMoneyColumns(result.unitPrice, true)
        row.UnitCopper:ClearAllPoints()
        row.UnitCopper:SetPoint("RIGHT", row, "RIGHT", MONEY_COPPER_COLUMN_OFFSET, -9)
        row.UnitPrice:ClearAllPoints()
        row.UnitPrice:SetPoint("RIGHT", row, "RIGHT", MONEY_SILVER_COLUMN_OFFSET, -9)
        row.UnitGold:ClearAllPoints()
        row.UnitGold:SetPoint("RIGHT", row, "RIGHT", MONEY_GOLD_COLUMN_OFFSET, -9)
        row.Name:Show()
        -- Match Blizzard's native list: wrap long item names to a second
        -- line instead of truncating with an ellipsis.
        row.Name:SetWordWrap(true)
        row.Name:SetMaxLines(2)
        row.UnitLabel:Show()
        row.UnitPrice:Show()
        row.UnitCopper:Show()
        row.BidQuantity:Hide()
        row.BidPrice:Hide()
        row.BidCopper:Hide()
        row.BidGold:Hide()
        row.BidOnlyPriceLabel:Hide()
        row.BuyoutLabel:Hide()
        row.BuyoutPrice:Hide()
        row.BuyoutCopper:Hide()
        row.BuyoutGold:Hide()
        row.Available:Show()
        row.Poster:Show()
        row.BidOnly:Hide()
        row.UnitLabel:SetText("Buyout")
        row.UnitGold:SetText(unitGoldText)
        row.UnitGold:SetShown(unitGoldText ~= "")
        row.UnitPrice:SetText(unitSilverText)
        row.UnitCopper:SetText(unitCopperText)
        PositionPriceLabel(row.UnitLabel,
          (unitGoldText ~= "" and row.UnitGold) or
            (unitSilverText ~= "" and row.UnitPrice) or row.UnitCopper)
        row.Available:SetFontObject("GameFontHighlightSmall")
        row.Available:SetText(result.availablePretty or "")
        row.Poster:SetText(result.otherSellers or "?")
      else
        row.Name:Hide()
        row.UnitLabel:Hide()
        row.UnitPrice:Hide()
        row.UnitCopper:Hide()
        row.UnitGold:Hide()
        row.BidQuantity:Hide()
        row.BidPrice:Hide()
        row.BidCopper:Hide()
        row.BidGold:Hide()
        row.BuyoutLabel:Hide()
        row.BuyoutPrice:Hide()
        row.BuyoutCopper:Hide()
        row.BuyoutGold:Hide()
        row.BidOnlyPriceLabel:Hide()
        row.Available:Hide()
        row.Poster:Hide()
        row.BidOnly:Show()
        row.BidOnly:SetText("Bid only available")
      end
      row:SetActiveVisual(row.isHovered or result.isSelected == true)
    end
  end

  self.ResultsStatus:SetShown(count == 0)
  if count == 0 then
    self.ResultsStatus:SetText(self.resultsSearching and "Searching" or
      (GetSelectedItemInfo() and "No auctions found" or "Select an item to view current auctions"))
  end

  if self.ResultsRangeText then
    local offset = FauxScrollFrame_GetOffset(self.ResultsScroll)
    if count > 0 and not self.resultsHistoryShown then
      local first = offset + 1
      local last = math.min(count, offset + RESULT_ROW_COUNT)
      self.ResultsRangeText:SetText(("Items %d - %d (%d total)"):format(first, last, count))
      self.ResultsRangeText:Show()
    else
      self.ResultsRangeText:Hide()
    end
  end

  if self.ResultsLoadMoreButton then
    local showLoadMore = (not self.resultsHistoryShown)
      and count > 0
      and provider ~= nil
      and not provider:GetRequestAllResults()
      and not provider:HasAllQueriedResults()
    self.ResultsLoadMoreButton:SetShown(showLoadMore)
  end
  UpdateCancelButton(self)
end

local function ToStackSizeEntry(entry)
  return entry.info[Auctionator.Constants.AuctionItemInfo.Quantity]
end

local function ToOwnerName(entry)
  return tostring(entry.info[Auctionator.Constants.AuctionItemInfo.Owner])
end

local function ToCurrentBidUnitPriceEntry(entry)
  local bidAmount = entry.info[Auctionator.Constants.AuctionItemInfo.BidAmount]
  local minBid = entry.info[Auctionator.Constants.AuctionItemInfo.MinBid]
  local stackSize = math.max(1,
    entry.info[Auctionator.Constants.AuctionItemInfo.Quantity] or 1)
  return math.ceil(((bidAmount or 0) > 0 and bidAmount or minBid or 0) / stackSize)
end

local function ToBuyoutUnitPriceEntry(entry)
  local unitPrice = Auctionator.Utilities.ToUnitPrice(entry)
  if unitPrice == 0 then
    return math.huge
  end
  return unitPrice
end

local function IsPlayerOwnedAuction(entry)
  local owner = entry.info[Auctionator.Constants.AuctionItemInfo.Owner]
  local playerName = GetUnitName("player")
  if owner == playerName then
    return true
  end
  if type(owner) ~= "string" or type(playerName) ~= "string" then
    return false
  end
  local shortOwner = Ambiguate and Ambiguate(owner, "short") or
    owner:match("^[^-]+")
  local shortPlayer = Ambiguate and Ambiguate(playerName, "short") or
    playerName:match("^[^-]+")
  return shortOwner == shortPlayer
end

local function IsPlayerOwnerName(owner)
  local playerName = GetUnitName("player")
  if owner == playerName then
    return true
  end
  if type(owner) ~= "string" or type(playerName) ~= "string" then
    return false
  end
  local shortOwner = Ambiguate and Ambiguate(owner, "short") or
    owner:match("^[^-]+")
  local shortPlayer = Ambiguate and Ambiguate(playerName, "short") or
    playerName:match("^[^-]+")
  return shortOwner == shortPlayer
end

local function GetAuctionSignature(info, itemLink)
  local cleanLink = itemLink and Auctionator.Search.GetCleanItemLink(itemLink) or ""
  return table.concat({
    cleanLink,
    info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0,
    info[Auctionator.Constants.AuctionItemInfo.Quantity] or 0,
    info[Auctionator.Constants.AuctionItemInfo.BidAmount] or 0,
    info[Auctionator.Constants.AuctionItemInfo.MinBid] or 0,
  }, "\031")
end

local function IsProviderSearchMatch(provider, itemLink, info)
  if not itemLink then
    return false
  end
  if provider.exactSearchName then
    local itemName = (info and info[1]) or
      (itemLink and Auctionator.Utilities.GetNameFromLink(itemLink))
    return itemName == provider.exactSearchName
  end
  if provider.exactSearchKey then
    return Auctionator.Search.GetCleanItemLink(itemLink) == provider.exactSearchKey
  end
  return Auctionator.Search.GetCleanItemLink(itemLink) == provider.searchKey
end

-- Overrides the shared provider's PopulateAuctions for this instance only
-- (assigned per-instance below, never mutating the shared mixin) so bid-only
-- auctions stay as individual rows instead of collapsing into one line;
-- Bid Mode needs each auction's own current bid, bidder, and time left.
local function PopulateBidAndBuyoutAuctions(self)
  self:Reset()
  self.populateGeneration = (self.populateGeneration or 0) + 1

  for index = #self.allAuctions, 1, -1 do
    if self.allAuctions[index].forceOwned then
      table.remove(self.allAuctions, index)
    end
  end
  local representedOwned = {}
  for _, auction in ipairs(self.allAuctions) do
    if IsPlayerOwnedAuction(auction) then
      local signature = GetAuctionSignature(auction.info, auction.itemLink)
      representedOwned[signature] = (representedOwned[signature] or 0) + 1
    end
  end

  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local itemLink = GetAuctionItemLink("owner", index)
    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus]
    local buyout = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
    local includeOwned = self.resultsMode == "bid" or buyout > 0
    if includeOwned and saleStatus ~= 1 and IsProviderSearchMatch(self, itemLink, info) then
      local signature = GetAuctionSignature(info, itemLink)
      if (representedOwned[signature] or 0) > 0 then
        representedOwned[signature] = representedOwned[signature] - 1
      else
        table.insert(self.allAuctions, {
          info = info,
          itemLink = itemLink,
          timeLeft = math.max(0,
            (GetAuctionItemTimeLeft("owner", index) or 1) - 1),
          page = 0,
          query = self.query,
          forceOwned = true,
        })
      end
    end
  end

  table.sort(self.allAuctions, function(a, b)
    local unitA = self.resultsMode == "bid" and
      ToCurrentBidUnitPriceEntry(a) or ToBuyoutUnitPriceEntry(a)
    local unitB = self.resultsMode == "bid" and
      ToCurrentBidUnitPriceEntry(b) or ToBuyoutUnitPriceEntry(b)
    if unitA == unitB then
      local stackA = ToStackSizeEntry(a)
      local stackB = ToStackSizeEntry(b)
      if stackA == stackB then
        return ToOwnerName(a) < ToOwnerName(b)
      else
        return stackA > stackB
      end
    else
      return unitA < unitB
    end
  end)

  local results = {}
  for _, auction in ipairs(self.allAuctions) do
    local bidAmount = auction.info[Auctionator.Constants.AuctionItemInfo.BidAmount]
    local minBid = auction.info[Auctionator.Constants.AuctionItemInfo.MinBid]
    local currentBidUnitPrice = ToCurrentBidUnitPriceEntry(auction)
    local newEntry = {
      itemLink = auction.itemLink,
      unitPrice = Auctionator.Utilities.ToUnitPrice(auction),
      stackPrice = auction.info[Auctionator.Constants.AuctionItemInfo.Buyout],
      stackSize = auction.info[Auctionator.Constants.AuctionItemInfo.Quantity],
      numStacks = 1,
      isOwned = auction.forceOwned or IsPlayerOwnedAuction(auction),
      otherSellers = ToOwnerName(auction),
      bidAmount = bidAmount,
      minBid = minBid,
      currentBid = currentBidUnitPrice,
      highBidder = auction.info[Auctionator.Constants.AuctionItemInfo.Bidder],
      isSelected = false,
      notReady = true,
      query = auction.query,
      page = auction.page,
      timeLeft = auction.timeLeft,
      timeLeftPretty = Auctionator.Utilities.FormatTimeLeftBand(auction.timeLeft),
    }
    if newEntry.unitPrice == 0 then
      newEntry.unitPrice = nil
    end

    if newEntry.isOwned then
      newEntry.otherSellers = GREEN_FONT_COLOR:WrapTextInColorCode(AUCTIONATOR_L_YOU)
      newEntry.isOwnedText = AUCTIONATOR_L_UNDERCUT_YES
    else
      newEntry.isOwnedText = ""
    end
    Auctionator.Utilities.SetStacksText(newEntry)

    local prevResult = results[#results] or {}
    if prevResult.unitPrice == newEntry.unitPrice and
       prevResult.stackSize == newEntry.stackSize and
       prevResult.itemLink == newEntry.itemLink and
       prevResult.otherSellers == newEntry.otherSellers and
       prevResult.bidAmount == newEntry.bidAmount then
      prevResult.numStacks = prevResult.numStacks + 1
      Auctionator.Utilities.SetStacksText(prevResult)
    else
      prevResult.nextEntry = newEntry
      table.insert(results, newEntry)
    end
    results[#results].page = math.min(results[#results].page, auction.page)
  end

  self.currentResults = results
  -- RefreshResults now asks the AH to pre-sort "list" pages by "bid" for
  -- Bid Mode (instead of the default buyout unit price), so later pages
  -- mostly land after what is already on screen. That keeps this local
  -- re-sort (by true current-bid unit price) from significantly reshuffling
  -- already-displayed rows, so it is safe to publish every page as it
  -- arrives instead of waiting for the full scan to finish.
  self:AppendEntries(results, self.gotAllResults)
end

local function CreateHeader(self, text, key, width, index)
  local button = CreateFrame("Button", "LogisticianBuyoutHeader" .. index,
    self.ResultsPanel, "AuctionSortButtonTemplate")
  button:SetHeight(20)
  button:SetWidth(width)
  if button.SetText then
    button:SetText(text)
  end
  button.sortKey = key

  -- The template bakes in its own always-visible arrow decoration on every
  -- header; it never reflects actual sort state, so strip it and draw our
  -- own arrow next to the label that we can show only for the active sort.
  -- It may be a texture or a fontstring (a texture escape/glyph rendered as
  -- text), nested in a child frame, and can use an atlas instead of a plain
  -- file path, so every case is checked and children are scanned too.
  local function StripArrowTextures(frame)
    for _, region in ipairs({ frame:GetRegions() }) do
      local objType = region.GetObjectType and region:GetObjectType()
      local regionName = region.GetName and region:GetName()
      local matchesName = type(regionName) == "string" and regionName:lower():find("arrow")
      if objType == "Texture" then
        local texPath = region.GetTexture and region:GetTexture()
        local atlas = region.GetAtlas and region:GetAtlas()
        if matchesName
            or (type(texPath) == "string" and texPath:lower():find("arrow"))
            or (type(atlas) == "string" and atlas:lower():find("arrow")) then
          region:Hide()
          region:SetTexture(nil)
        end
      elseif objType == "FontString" then
        local fontText = region.GetText and region:GetText()
        if matchesName or (type(fontText) == "string" and fontText:lower():find("arrow")) then
          region:Hide()
          region:SetText("")
        end
      end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
      local childName = child.GetName and child:GetName()
      if type(childName) == "string" and childName:lower():find("arrow") then
        child:Hide()
      end
      StripArrowTextures(child)
    end
  end
  StripArrowTextures(button)

  button.Arrow = button:CreateTexture(nil, "OVERLAY")
  button.Arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
  -- This client stores UI-SortArrow on a narrow canvas; a near-square size
  -- stretches it vertically, so use the same compensated ratio as elsewhere.
  button.Arrow:SetSize(20, 10)
  local label = button.GetFontString and button:GetFontString()
  if label then
    button.Arrow:SetPoint("LEFT", label, "RIGHT", 1, 0)
  else
    button.Arrow:SetPoint("LEFT", button, "LEFT", 8, 0)
  end
  button.Arrow:Hide()

  -- Use the live field (mode relabeling mutates this) instead of the
  -- creation-time key, so the arrow keeps matching the active sort column.
  button:SetScript("OnClick", function() SetResultSort(self, button.sortKey) end)
  return button
end

local BUYOUT_HEADER_LABELS = {
  { text = "Rarity", key = "name", width = 235 },
  { text = "Available", key = "stackSize", width = 95 },
  { text = "Poster", key = "otherSellers", width = 90 },
  { text = "Unit Price", key = "unitPrice", width = 150 },
}
local BID_HEADER_LABELS = {
  { text = "Rarity", key = "name", width = 235 },
  { text = "Time Left", key = "timeLeft", width = 95 },
  { text = "High Bidder", key = "highBidder", width = 90 },
  { text = "Current Bid", key = "currentBid", width = 150 },
}

local function UpdateResultsHeadersForMode(self)
  if not self.ResultsHeaders then return end
  local labels = self.mode == "bid" and BID_HEADER_LABELS or BUYOUT_HEADER_LABELS
  for index, header in ipairs(self.ResultsHeaders) do
    local info = labels[index]
    if info then
      header:SetText(info.text)
      header.sortKey = info.key
      if info.width then
        header:SetWidth(info.width)
      end
    end
  end

end

local function CreateResultsPanel(self)
  if self.ResultsPanel then return end
  local panel = CreateFrame("Frame", nil, AuctionFrameAuctions)
  panel:SetPoint("TOPLEFT", AuctionFrame, "TOPLEFT", 210, -50)
  panel:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -10, 43)
  panel:SetFrameLevel(AuctionFrame:GetFrameLevel() + 30)
  panel:EnableMouse(true)
  if panel.SetClipsChildren then
    panel:SetClipsChildren(true)
  end
  self.ResultsPanel = panel

  local headers = {
    CreateHeader(self, "Rarity", "name", RESULTS_COLUMN_X, 1),
    CreateHeader(self, "Available", "stackSize", RESULTS_POSTER_X - RESULTS_COLUMN_X, 2),
    CreateHeader(self, "Poster", "otherSellers", RESULTS_PRICE_X - RESULTS_POSTER_X, 3),
    CreateHeader(self, "Unit Price", "unitPrice", 150, 4),
  }
  headers[1]:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -3)
  for index = 2, #headers do
    headers[index]:SetPoint("LEFT", headers[index - 1], "RIGHT", 0, 0)
  end
  headers[#headers]:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
  self.ResultsHeaders = headers
  UpdateResultsHeadersForMode(self)

  self.ResultsScroll = CreateFrame("ScrollFrame", "LogisticianBuyoutResultsScroll",
    panel, "FauxScrollFrameTemplate")
  self.ResultsScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -23)
  self.ResultsScroll:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -26, -23)
  self.ResultsScroll:SetHeight(RESULT_ROW_COUNT * RESULT_ROW_HEIGHT)
  local scrollBar = _G.LogisticianBuyoutResultsScrollScrollBar or
    self.ResultsScroll.ScrollBar
  if not scrollBar then
    for _, child in ipairs({ self.ResultsScroll:GetChildren() }) do
      if child:GetObjectType() == "Slider" then
        scrollBar = child
        break
      end
    end
  end
  if scrollBar then
    -- Match the native/Selling-list scrollbar housing. The character-scrollbar
    -- atlas supplies the continuous metal trim and textured track; the Faux
    -- scrollbar above it continues to provide the working arrows and thumb.
    local scrollHousing = CreateFrame("Frame", nil, panel)
    scrollHousing:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -27)
    -- The panel bottom is the native viewport edge immediately above the
    -- Auction/Close button strip; do not leave the former 18px gap here.
    scrollHousing:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 0)
    scrollHousing:SetWidth(24)
    scrollHousing:SetFrameLevel(panel:GetFrameLevel() + 5)

    local housingTexture = "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar"
    local top = scrollHousing:CreateTexture(nil, "BACKGROUND")
    top:SetTexture(housingTexture)
    top:SetTexCoord(2 / 64, 29 / 64, 0 / 256, 32 / 256)
    top:SetPoint("TOP", scrollHousing, "TOP", 0, 0)
    top:SetSize(24, 27)

    local bottom = scrollHousing:CreateTexture(nil, "BACKGROUND")
    bottom:SetTexture(housingTexture)
    bottom:SetTexCoord(35 / 64, 62 / 64, 228 / 256, 255 / 256)
    bottom:SetPoint("BOTTOM", scrollHousing, "BOTTOM", 0, 0)
    bottom:SetSize(24, 27)

    local middle = scrollHousing:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture(housingTexture)
    middle:SetTexCoord(2 / 64, 29 / 64, 28 / 256, 228 / 256)
    middle:SetPoint("TOP", top, "BOTTOM", 0, 0)
    middle:SetPoint("BOTTOM", bottom, "TOP", 0, 0)
    middle:SetWidth(24)
    self.ResultsScrollBorder = scrollHousing

    -- FauxScrollFrameTemplate removes its arrow artwork when there is no
    -- scroll range. Persistent native-textured buttons make the empty state
    -- match Selling and still operate the Faux scrollbar when results exist.
    local scrollBarName = scrollBar:GetName()
    local nativeUp = scrollBar.ScrollUpButton or
      (scrollBarName and _G[scrollBarName .. "ScrollUpButton"])
    local nativeDown = scrollBar.ScrollDownButton or
      (scrollBarName and _G[scrollBarName .. "ScrollDownButton"])
    if nativeUp then nativeUp:Hide() end
    if nativeDown then nativeDown:Hide() end
    self.ResultsNativeScrollUpButton = nativeUp
    self.ResultsNativeScrollDownButton = nativeDown

    local function MakeArrow(name, topSide)
      local button = CreateFrame("Button", name, panel)
      -- Blizzard's scrollbar arrow textures are authored for a 32px button;
      -- using their native size makes the visible artwork fill the metal cap.
      button:SetSize(29, 29)
      button:SetFrameLevel(panel:GetFrameLevel() + 25)
      button:SetPoint(topSide and "TOP" or "BOTTOM", scrollHousing,
        topSide and "TOP" or "BOTTOM", 1, topSide and 4 or -2)
      local stem = topSide and "UI-ScrollBar-ScrollUpButton" or
        "UI-ScrollBar-ScrollDownButton"
      button:SetNormalTexture("Interface\\Buttons\\" .. stem .. "-Up")
      button:SetPushedTexture("Interface\\Buttons\\" .. stem .. "-Down")
      button:SetHighlightTexture("Interface\\Buttons\\" .. stem .. "-Highlight")
      -- TBC's disabled scrollbar texture is not consistently available. Use
      -- the guaranteed normal asset and tint it so empty lists still show a
      -- clearly disabled arrow instead of a blank cap.
      button:SetDisabledTexture("Interface\\Buttons\\" .. stem .. "-Up")
      local disabled = button:GetDisabledTexture()
      if disabled then
        disabled:SetDesaturated(true)
        disabled:SetVertexColor(0.55, 0.55, 0.55)
      end
      button:SetScript("OnClick", function()
        local value = scrollBar:GetValue() or 0
        scrollBar:SetValue(value + (topSide and -RESULT_ROW_HEIGHT or RESULT_ROW_HEIGHT))
      end)
      return button
    end
    self.ResultsScrollUpButton = MakeArrow(nil, true)
    self.ResultsScrollDownButton = MakeArrow(nil, false)

    -- The Faux slider is only the thumb track. Inset it between the two arrow
    -- buttons so the thumb can never enter or overlap either arrow cap.
    scrollBar:ClearAllPoints()
    -- The Slider template has its own internal thumb padding. Extend its
    -- bounds four pixels farther at each end to remove the visible end gaps.
    scrollBar:SetPoint("TOP", scrollHousing, "TOP", 1, -16)
    scrollBar:SetPoint("BOTTOM", scrollHousing, "BOTTOM", 1, 20)
    scrollBar:SetWidth(16)
  end
  self.ResultsScrollBar = scrollBar
  self.ResultsScroll:SetScript("OnVerticalScroll", function(frame, offset)
    FauxScrollFrame_OnVerticalScroll(frame, offset, RESULT_ROW_HEIGHT, function()
      RenderResults(self)
    end)
  end)

  self.ResultsRows = {}
  for index = 1, RESULT_ROW_COUNT do
    local row = CreateFrame("Button", nil, panel)
    row:SetPoint("TOPLEFT", self.ResultsScroll, "TOPLEFT", 8,
      -1 - (index - 1) * RESULT_ROW_HEIGHT)
    row:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
    row:SetHeight(RESULT_ROW_HEIGHT - 1)
    -- Rounded-corner row body to match the native Browse list language.
    row.Body = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.Body:SetPoint("TOPLEFT", row, "TOPLEFT", 44, -1)
    row.Body:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 1)
    row.Body:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 10,
      insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    row.Body:SetBackdropColor(0.02, 0.02, 0.02, 0.22)
    row.Body:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.90)
    -- Use Blizzard's native horizontally fading selection texture. The TBC
    -- Anniversary client does not expose Texture:SetGradientAlpha().
    row.Highlight = row.Body:CreateTexture(nil, "ARTWORK")
    row.Highlight:SetPoint("TOPLEFT", row.Body, "TOPLEFT", 3, -1)
    row.Highlight:SetPoint("BOTTOMRIGHT", row.Body, "BOTTOMRIGHT", -3, 1)
    row.Highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.Highlight:SetBlendMode("ADD")
    -- Preserve the texture's native Blizzard yellow-gold. Multiplying it by
    -- an amber tint makes the result look brown in the classic client.
    row.Highlight:SetVertexColor(1.00, 1.00, 1.00, 0.76)
    row.Highlight:Hide()

    -- Rounded icon surround like native row item buttons.
    row.IconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.IconFrame:SetPoint("LEFT", 4, 0)
    row.IconFrame:SetSize(38, 38)
    row.IconFrame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 8,
      insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    row.IconFrame:SetBackdropColor(0, 0, 0, 1)
    row.IconFrame:SetBackdropBorderColor(0.52, 0.52, 0.52, 1)
    row.Icon = CreateFrame("Button", "LogisticianBuyoutResultItem" .. index,
      row.IconFrame, "ItemButtonTemplate")
    row.Icon:SetPoint("CENTER")
    row.Icon:SetSize(32, 32)
    row.Icon:EnableMouse(false)
    row.OwnerLabel = row.Icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall", 7)
    row.OwnerLabel:SetPoint("BOTTOM", row.IconFrame, "TOP", 0, -21)
    row.OwnerLabel:SetWidth(52)
    row.OwnerLabel:SetJustifyH("CENTER")
    row.OwnerLabel:SetText(AUCTIONATOR_L_YOU or "You")
    row.OwnerLabel:SetTextColor(0.20, 1.00, 0.20, 1)
    local ownerFont, ownerSize = row.OwnerLabel:GetFont()
    if ownerFont then
      row.OwnerLabel:SetFont(ownerFont, ownerSize + 2, "THICKOUTLINE")
    end
    row.OwnerLabel:SetShadowOffset(1, -1)
    row.OwnerLabel:Hide()
    row.Name = row.Body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.Name:SetPoint("LEFT", row.IconFrame, "RIGHT", 7, 0)
    -- Name starts at IconFrame's right edge (42) + 7 = 49; keep its right
    -- edge clear of the Available column (RESULTS_COLUMN_X) with a small
    -- gap so long/wrapped names never crowd or overlap into it.
    row.Name:SetWidth(RESULTS_COLUMN_X - 49 - 6)
    row.Name:SetWordWrap(false)
    row.Name:SetMaxLines(1)
    row.Name:SetJustifyH("LEFT")
    row.Name:SetTextColor(1, 1, 1, 1)
    row.NameQuantity = row.Body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.NameQuantity:SetJustifyH("LEFT")
    row.NameQuantity:SetTextColor(1, 0.82, 0, 1)
    local quantityFont, quantitySize = row.NameQuantity:GetFont()
    if quantityFont then
      row.NameQuantity:SetFont(quantityFont, quantitySize + 1, "THICKOUTLINE")
    end
    row.NameQuantity:Hide()
    local function Cell(x, width, y)
      local value = row.Body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      value:SetPoint("LEFT", row, "LEFT", x, y or 0)
      value:SetWidth(width)
      value:SetJustifyH("LEFT")
      value:SetTextColor(1, 1, 1, 1)
      return value
    end
    row.Available = Cell(255, 95)
    row.Available:SetJustifyH("CENTER")
    row.Poster = Cell(350, 90)
    row.Poster:SetFontObject("GameFontHighlightSmall")
    row.Poster:SetJustifyH("CENTER")
    row.UnitLabel = Cell(440, 44, -9)
    row.UnitLabel:SetFontObject("GameFontNormalSmall")
    row.UnitLabel:SetTextColor(1, 0.82, 0)
    row.UnitLabel:SetJustifyH("RIGHT")
    row.UnitLabel:Hide()
    row.UnitPrice = Cell(440, MONEY_SILVER_COLUMN_WIDTH, -9)
    row.UnitPrice:SetFontObject("NumberFontNormalRightYellow")
    row.UnitPrice:SetTextColor(1, 0.82, 0)
    row.UnitPrice:SetJustifyH("RIGHT")
    row.UnitPrice:SetWordWrap(false)
    row.UnitGold = Cell(440, MONEY_GOLD_COLUMN_WIDTH, -9)
    row.UnitGold:SetFontObject("NumberFontNormalRightYellow")
    row.UnitGold:SetTextColor(1, 0.82, 0)
    row.UnitGold:SetJustifyH("RIGHT")
    row.UnitGold:SetWordWrap(false)
    row.UnitGold:Hide()
    row.UnitCopper = Cell(536, MONEY_COPPER_COLUMN_WIDTH, -9)
    row.UnitCopper:SetFontObject("NumberFontNormalRightYellow")
    row.UnitCopper:SetTextColor(1, 0.82, 0)
    row.UnitCopper:SetJustifyH("RIGHT")
    row.UnitCopper:SetWordWrap(false)
    row.UnitCopper:Hide()
    row.BidQuantity = Cell(440, 44, 9)
    row.BidQuantity:SetFontObject("GameFontNormalSmall")
    row.BidQuantity:SetTextColor(1, 0.82, 0)
    row.BidQuantity:SetJustifyH("RIGHT")
    row.BidQuantity:Hide()
    row.BidPrice = Cell(440, MONEY_SILVER_COLUMN_WIDTH, 9)
    row.BidPrice:SetFontObject("NumberFontNormalRight")
    row.BidPrice:SetJustifyH("RIGHT")
    row.BidPrice:SetWordWrap(false)
    row.BidPrice:Hide()
    row.BidGold = Cell(440, MONEY_GOLD_COLUMN_WIDTH, 9)
    row.BidGold:SetFontObject("NumberFontNormalRight")
    row.BidGold:SetJustifyH("RIGHT")
    row.BidGold:SetWordWrap(false)
    row.BidGold:Hide()
    row.BidCopper = Cell(536, MONEY_COPPER_COLUMN_WIDTH, 9)
    row.BidCopper:SetFontObject("NumberFontNormalRight")
    row.BidCopper:SetJustifyH("RIGHT")
    row.BidCopper:SetWordWrap(false)
    row.BidCopper:Hide()
    row.BuyoutLabel = Cell(440, 44, -9)
    row.BuyoutLabel:SetFontObject("GameFontNormalSmall")
    row.BuyoutLabel:SetTextColor(1, 0.82, 0)
    row.BuyoutLabel:SetJustifyH("RIGHT")
    row.BuyoutLabel:Hide()
    row.BuyoutPrice = Cell(440, MONEY_SILVER_COLUMN_WIDTH, -9)
    row.BuyoutPrice:SetFontObject("NumberFontNormalRightYellow")
    row.BuyoutPrice:SetTextColor(1, 0.82, 0)
    row.BuyoutPrice:SetJustifyH("RIGHT")
    row.BuyoutPrice:SetWordWrap(false)
    row.BuyoutPrice:Hide()
    row.BuyoutGold = Cell(440, MONEY_GOLD_COLUMN_WIDTH, -9)
    row.BuyoutGold:SetFontObject("NumberFontNormalRightYellow")
    row.BuyoutGold:SetTextColor(1, 0.82, 0)
    row.BuyoutGold:SetJustifyH("RIGHT")
    row.BuyoutGold:SetWordWrap(false)
    row.BuyoutGold:Hide()
    row.BuyoutCopper = Cell(536, MONEY_COPPER_COLUMN_WIDTH, -9)
    row.BuyoutCopper:SetFontObject("NumberFontNormalRightYellow")
    row.BuyoutCopper:SetTextColor(1, 0.82, 0)
    row.BuyoutCopper:SetJustifyH("RIGHT")
    row.BuyoutCopper:SetWordWrap(false)
    row.BuyoutCopper:Hide()
    row.BidOnly = row.Body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    -- Center in the complete rounded body rather than in the Available cell.
    -- The body already begins to the right of the item icon, so this also
    -- provides the visual rightward correction requested for bid-only rows.
    row.BidOnly:SetPoint("CENTER", row.Body, "CENTER", 0, 0)
    row.BidOnly:SetJustifyH("CENTER")
    row.BidOnly:Hide()
    row.BidOnlyPriceLabel = row.Body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.BidOnlyPriceLabel:SetPoint("TOPRIGHT", row, "TOPLEFT", 612, -24)
    row.BidOnlyPriceLabel:SetWidth(130)
    row.BidOnlyPriceLabel:SetJustifyH("CENTER")
    row.BidOnly:SetJustifyH("CENTER")
    row.BidOnlyPriceLabel:SetFontObject("SystemFont_Shadow_Med1")
    row.BidOnlyPriceLabel:SetText("Bid Only")
    row.BidOnlyPriceLabel:SetTextColor(0.25, 0.65, 1, 1)
    local bidOnlyFont, bidOnlySize = row.BidOnlyPriceLabel:GetFont()
    if bidOnlyFont then
      row.BidOnlyPriceLabel:SetFont(bidOnlyFont, math.max(1, bidOnlySize - 2), "THICKOUTLINE")
    end
    row.BidOnlyPriceLabel:Hide()
    function row:SetActiveVisual(active)
      self.Highlight:SetShown(active == true)
      if active then
        -- The Browse highlight is a fading fill; its rounded frame does not
        -- gain heavy gold lines on the top/bottom or vertical gold edges.
        self.Body:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.95)
        self.IconFrame:SetBackdropBorderColor(1.00, 0.82, 0.00, 1)
      else
        self.Body:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.90)
        self.IconFrame:SetBackdropBorderColor(0.52, 0.52, 0.52, 1)
      end
    end
    row:SetScript("OnClick", function(button)
      if not button.result or self.cancelPending then return end
      if self.mode == "buyout" then
        if not button.result.unitPrice then return end
        SetCustomSelectedResult(self, button.resultIndex)
        MoneyInputFrame_SetCopper(StartPrice, button.result.unitPrice)
        MoneyInputFrame_SetCopper(BuyoutPrice, button.result.stackPrice)
        self.previousUnitPrice = button.result.unitPrice
        self.previousStackPrice = button.result.stackPrice
      else
        SetCustomSelectedResult(self, button.result.isOwned and button.resultIndex or nil)
      end
      RenderResults(self)
    end)
    row:SetScript("OnEnter", function(button)
      button.isHovered = true
      button:SetActiveVisual(true)
      if button.result and button.result.itemLink then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(button.result.itemLink)
        GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave", function(button)
      button.isHovered = false
      button:SetActiveVisual(button.result and button.result.isSelected == true)
      GameTooltip:Hide()
    end)
    self.ResultsRows[index] = row
  end

  self.ResultsStatus = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.ResultsStatus:SetPoint("TOP", panel, "TOP", 5, -62)

  self.ResultsRangeText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.ResultsRangeText:SetPoint("BOTTOM", panel, "BOTTOM", -2, 0)
  self.ResultsRangeText:SetFontObject("GameFontNormalSmall")
  self.ResultsRangeText:SetText("")
  self.ResultsRangeText:Hide()

  -- Reuse Auctionator's Selling history implementation (realm history and
  -- posting history providers) rather than maintaining a second history UI.
  self.ResultsHistoryFrame = CreateFrame(
    "Frame", nil, panel, "AuctionatorBuyHistoryPricesFrameTemplate"
  )
  -- The history template already applies its own inset/list offsets. Anchoring
  -- this wrapper with additional offsets causes the table and backdrop to drift.
  self.ResultsHistoryFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, 6)
  self.ResultsHistoryFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, -6)
  self.ResultsHistoryFrame:Hide()

  -- ResultsListing builds and caches its table layout during Init().  At addon
  -- startup this panel has not necessarily completed its anchor layout yet;
  -- initializing here can therefore collapse every history column into the
  -- first visible column.  Initialize on first use, when the Auction frame and
  -- this viewport have their final dimensions.
  local function EnsureHistoryInitialized()
    if self.resultsHistoryInitialized then return end

    local width = math.max(1, self.ResultsHistoryFrame:GetWidth())
    local height = math.max(1, self.ResultsHistoryFrame:GetHeight())
    if width <= 1 or height <= 1 then
      width = math.max(1, panel:GetWidth())
      height = math.max(1, panel:GetHeight())
      self.ResultsHistoryFrame:SetSize(width, height)
    end
    self.ResultsHistoryFrame:Init()
    self.ResultsHistoryFrame.RealmHistoryResultsListing:SetScrollBarOffsetX(0)
    self.ResultsHistoryFrame.PostingHistoryResultsListing:SetScrollBarOffsetX(0)
    if self.ResultsHistoryFrame.RealmHistoryButton then
      self.ResultsHistoryFrame.RealmHistoryButton:Hide()
    end
    if self.ResultsHistoryFrame.PostingHistoryButton then
      self.ResultsHistoryFrame.PostingHistoryButton:Hide()
    end
    self.resultsHistoryInitialized = true
  end

  local function SetHistoryShown(shown)
    if shown then EnsureHistoryInitialized() end
    self.resultsHistoryShown = shown == true
    if panel.SetClipsChildren then
      -- Current-prices mode should stay clipped to its viewport, but history
      -- needs to extend into the reserved bottom strip for visual alignment.
      panel:SetClipsChildren(not shown)
    end
    for _, header in ipairs(self.ResultsHeaders) do header:SetShown(not shown) end
    for _, row in ipairs(self.ResultsRows) do
      row:SetShown(not shown and row.result ~= nil)
    end
    self.ResultsScroll:SetShown(not shown)
    if self.ResultsScrollBorder then
      self.ResultsScrollBorder:SetShown(not shown)
    end
    if self.ResultsScrollUpButton then
      self.ResultsScrollUpButton:SetShown(not shown)
    end
    if self.ResultsScrollDownButton then
      self.ResultsScrollDownButton:SetShown(not shown)
    end
    if shown and self.ResultsRangeText then
      self.ResultsRangeText:Hide()
    end
    if shown and self.ResultsLoadMoreButton then
      self.ResultsLoadMoreButton:Hide()
    end
    self.ResultsStatus:SetShown(not shown and self.ResultsProvider:GetCount() == 0)
    self.ResultsHistoryFrame:SetShown(shown)
    if self.ResultsHistoryFrame.RealmHistoryButton then
      self.ResultsHistoryFrame.RealmHistoryButton:SetShown(false)
    end
    if self.ResultsHistoryFrame.PostingHistoryButton then
      self.ResultsHistoryFrame.PostingHistoryButton:SetShown(false)
    end
    self.ResultsHistoryButton:SetText(shown and "Current Prices" or "History")
    if not shown then
      RenderResults(self)
    end
  end
  self.SetResultsHistoryShown = SetHistoryShown

  self.ResultsHistoryButton = CreateFrame(
    "Button", nil, AuctionFrameAuctions, "UIPanelButtonTemplate"
  )
  self.ResultsHistoryButton:SetSize(112, 22)
  self.ResultsHistoryButton:SetPoint(
    "BOTTOMLEFT", AuctionFrameAuctions, "BOTTOMLEFT", 216, 14
  )
  self.ResultsHistoryButton:SetText("History")
  self.ResultsHistoryButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 60)
  self.ResultsHistoryButton:SetScript("OnClick", function()
    local item = GetSelectedItemInfo()
    if not item or not item.itemLink then return end
    if not self.resultsHistoryShown then
      EnsureHistoryInitialized()
      self.ResultsHistoryFrame.RealmHistoryDataProvider:SetItemLink(item.itemLink)
      self.ResultsHistoryFrame.PostingHistoryDataProvider:SetItemLink(item.itemLink)
      self.ResultsHistoryFrame:SelectRealmHistory()
    end
    SetHistoryShown(not self.resultsHistoryShown)
  end)

  self.ResultsRefreshButton = CreateFrame(
    "Button", nil, AuctionFrameAuctions, "UIPanelButtonTemplate"
  )
  self.ResultsRefreshButton:SetSize(112, 22)
  if AuctionsCancelAuctionButton then
    self.ResultsRefreshButton:SetPoint(
      "RIGHT", AuctionsCancelAuctionButton, "LEFT", -5, 0
    )
  else
    self.ResultsRefreshButton:SetPoint(
      "BOTTOMRIGHT", AuctionFrameAuctions, "BOTTOMRIGHT", -250, 12
    )
  end
  self.ResultsRefreshButton:SetText("Refresh")
  self.ResultsRefreshButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 60)
  self.ResultsRefreshButton:SetScript("OnClick", function()
    SetHistoryShown(false)
    -- Refresh should feel like a clean re-search, not "keep whatever column
    -- I last clicked" - drop back to the mode's default order/arrow first.
    ResetResultSort(self)
    ApplyDefaultResultSort(self)
    RefreshResults(self, self.resultsItemLink)
  end)

  self.ResultsCancelButton = CreateFrame(
    "Button", nil, AuctionFrameAuctions, "UIPanelButtonTemplate"
  )
  self.ResultsCancelButton:SetAllPoints(AuctionsCancelAuctionButton)
  self.ResultsCancelButton:SetText("Cancel Auction")
  self.ResultsCancelButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 60)
  self.ResultsCancelButton:SetScript("OnClick", function()
    local result = GetSelectedResult(self)
    if self.cancelPending or not (self.mode == "bid" or self.mode == "buyout") or not result or
        not result.isOwned or not Auctionator.AH.IsNotThrottled() then
      return
    end
    local cancelCost = math.floor(((result.bidAmount or 0) * AUCTION_CANCEL_COST) / 100)
    if cancelCost > 0 then
      local dialog = StaticPopup_Show(CANCEL_CONFIRM_POPUP)
      if dialog then
        dialog.data = { owner = self, result = result }
        MoneyFrame_Update(dialog.moneyFrame, cancelCost)
      end
    else
      StartCancellation(self, result)
    end
  end)
  self.ResultsCancelButton:Hide()

  self.ResultsLoadMoreButton = CreateFrame(
    "Button", nil, AuctionFrameAuctions, "UIPanelButtonTemplate"
  )
  self.ResultsLoadMoreButton:SetSize(160, 22)
  self.ResultsLoadMoreButton:SetPoint(
    "RIGHT", self.ResultsRefreshButton, "LEFT", -6, 0
  )
  self.ResultsLoadMoreButton:SetText("Load More Items")
  self.ResultsLoadMoreButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 60)
  self.ResultsLoadMoreButton:SetScript("OnClick", function()
    SetHistoryShown(false)
    self.ResultsProvider:SetRequestAllResults(true)
    self.ResultsProvider:RefreshQuery()
  end)

  self.ResultsHistoryButton:Disable()
  self.ResultsRefreshButton:Disable()
  self.ResultsLoadMoreButton:Hide()

  local provider = CreateFrame("Frame", nil, panel)
  Mixin(provider, AuctionatorBuyAuctionsDataProviderMixin)
  provider:OnLoad()
  -- Per-instance override only; the shared mixin (and the native Buying
  -- tab's own provider instance) are left untouched.
  provider.PopulateAuctions = PopulateBidAndBuyoutAuctions
  provider:SetScript("OnUpdate", provider.OnUpdate)
  provider:SetAutoSelectResults(false)
  provider:SetIgnoreItemSuffix(Auctionator.Config.Get(
    Auctionator.Config.Options.SELLING_IGNORE_ITEM_SUFFIX
  ))
  provider:SetOnUpdateCallback(function()
    -- Reapply the player's chosen column sort to freshly (re)populated
    -- data (e.g. after hitting Refresh or as more pages stream in) instead
    -- of letting it silently fall back to the default order. Guarded by a
    -- generation counter bumped once per PopulateAuctions call so this
    -- does not re-trigger itself every time Sort()'s own SetDirty() causes
    -- another update pass.
    if self.resultSortKey and provider.sortedGeneration ~= provider.populateGeneration then
      provider.sortedGeneration = provider.populateGeneration
      provider:Sort(self.resultSortKey, self.resultSortAscending and
        Auctionator.Constants.SORT.ASCENDING or Auctionator.Constants.SORT.DESCENDING)
    end
    RenderResults(self)
  end)
  provider:SetOnSearchStartedCallback(function()
    self.resultsSearching = true
    if self.resultViewRestore then
      self.resultViewRestore.searchStarted = true
      self.resultViewRestore.ready = false
    end
    self.searchDotsElapsed = 0
    self.searchDotsCount = 0
    RenderResults(self)
  end)
  provider:SetOnSearchEndedCallback(function()
    self.resultsSearching = false
    local restore = self.resultViewRestore
    if (restore and restore.searchStarted) or self.mode == "bid" then
      C_Timer.After(0, function()
        if self.resultsSearching then
          return
        end
        if restore and self.resultViewRestore == restore then
          restore.ready = true
        end
        FocusOwnedBidResult(self)
        RenderResults(self)
      end)
    end
    RenderResults(self)
  end)
  provider:SetOnPreserveScrollCallback(function() end)
  provider:SetOnResetScrollCallback(function()
    FauxScrollFrame_SetOffset(self.ResultsScroll, 0)
  end)
  self.ResultsProvider = provider
  panel:HookScript("OnShow", function()
    self.ResultsHistoryButton:Show()
    self.ResultsRefreshButton:Show()
    SetPageStatusSuppressed(true)
    UpdateCancelButton(self)
  end)
  panel:HookScript("OnHide", function()
    self.ResultsHistoryButton:Hide()
    self.ResultsRefreshButton:Hide()
    self.ResultsRangeText:Hide()
    self.ResultsLoadMoreButton:Hide()
    self.ResultsCancelButton:Hide()
    SetHistoryShown(false)
    SetPageStatusSuppressed(false)
  end)
  panel:SetScript("OnUpdate", function(_, elapsed)
    -- Bid Mode now holds the custom list blank while a large search is
    -- still loading (see PopulateBidAndBuyoutAuctions). Blizzard keeps
    -- creating/repainting native AuctionsButton* rows underneath in the
    -- background during that same window, and those rows are only ever
    -- re-hidden reactively (on specific events); with our rows blank there
    -- was nothing left covering a leaked native row, so its price text
    -- would appear to float in place, unaffected by our own scrolling.
    -- Re-hide on a steady tick instead of relying solely on those events.
    self.nativeHideElapsed = (self.nativeHideElapsed or 0) + elapsed
    if self.nativeHideElapsed >= 0.2 then
      self.nativeHideElapsed = 0
      SetNativeResultsHidden(self, true)
    end
    if not self.resultsSearching or self.resultsHistoryShown then
      return
    end
    if not self.ResultsStatus:IsShown() then
      return
    end
    self.searchDotsElapsed = (self.searchDotsElapsed or 0) + elapsed
    if self.searchDotsElapsed < 0.45 then
      return
    end
    self.searchDotsElapsed = 0
    self.searchDotsCount = ((self.searchDotsCount or 0) + 1) % 4
    self.ResultsStatus:SetText("Searching" .. string.rep(".", self.searchDotsCount))
  end)
  self.ResultsHistoryButton:Hide()
  self.ResultsRefreshButton:Hide()
  self.ResultsLoadMoreButton:Hide()
  panel:Hide()
end

RefreshResults = function(self, forcedItemLink, forcedDisplayName)
  CreateResultsPanel(self)
  self.resultsQueryGeneration = (self.resultsQueryGeneration or 0) + 1
  local queryGeneration = self.resultsQueryGeneration
  self.ResultsProvider:EndAnyQuery()
  local item = GetSelectedItemInfo()
  local itemLink = forcedItemLink or (item and item.itemLink)
  local displayName = forcedDisplayName or (item and item.name)
  local restoreRequestAllResults = self.resultViewRestore and
    self.resultViewRestore.requestAllResults
  if not itemLink then
    self.resultsItemLink = nil
    self.ResultsProvider:EndAnyQuery()
    self.ResultsProvider:SetQuery(nil, function() end)
    self.resultsSearching = false
    RenderResults(self)
    return
  end
  self.resultsItemLink = itemLink
  if self.resultsHistoryShown and self.ResultsHistoryFrame then
    self.ResultsHistoryFrame.RealmHistoryDataProvider:SetItemLink(itemLink)
    self.ResultsHistoryFrame.PostingHistoryDataProvider:SetItemLink(itemLink)
    self.ResultsHistoryFrame:SelectRealmHistory()
  end
  self.pricesSeededForSearch = false
  -- The new query's results only replace the provider's data once its first
  -- page actually arrives (async) - until then, GetCount()/GetEntryAt(1)
  -- still reflect the PREVIOUS item's stale results. Any render in that gap
  -- (e.g. the panel's own OnUpdate, or even this function's own immediate
  -- call below) could seed StartPrice/BuyoutPrice from the wrong item's
  -- price and never get corrected once pricesSeededForSearch latches true.
  -- `:Reset()` alone is NOT enough here: GetCount()/GetEntryAt() actually
  -- read `cachedResults`, which Reset() only refreshes from the (now
  -- cleared) `results` table lazily on the provider's NEXT OnUpdate tick -
  -- one frame too late for the RenderResults call right below. Clear
  -- `cachedResults` directly too so nothing can ever read stale prior-item
  -- data before the genuinely new results land.
  self.ResultsProvider.allAuctions = {}
  self.ResultsProvider.currentResults = {}
  self.ResultsProvider:Reset()
  self.ResultsProvider.cachedResults = {}
  RenderResults(self)
  self.ResultsProvider.resultsMode = self.mode
  self.ResultsProvider:SetQuery(itemLink, function()
    if self.resultsQueryGeneration ~= queryGeneration then
      return
    end
    self.ResultsProvider:SetRequestAllResults(
      self.mode == "bid" or restoreRequestAllResults or Auctionator.Config.Get(
        Auctionator.Config.Options.SELLING_ALWAYS_LOAD_MORE)
    )
    -- Ask the AH to pre-sort pages the same way we always sort locally, so
    -- later pages mostly land after what is already on screen instead of
    -- reshuffling it: Bid Mode by current bid (Scan.lua has no per-unit bid
    -- column - see PopulateBidAndBuyoutAuctions for the true per-unit sort
    -- applied to what is actually displayed), Buyout Mode by buyout unit
    -- price. Set explicitly for both instead of leaning on Scan.lua's
    -- "unitprice" fallback for buyout.
    if self.ResultsProvider.query then
      self.ResultsProvider.query.sortKey = self.mode == "bid" and "bid" or "unitprice"
    end
    if self.mode == "bid" then
      GetOwnerAuctionItems(0)
    end
    self.ResultsProvider:RefreshQuery()
  end, displayName)
end

local function SetResultsPanelShown(self, shown, skipRefresh)
  CreateResultsPanel(self)
  self.ResultsPanel:SetShown(shown)
  SetNativeResultsHidden(self, shown)
  if shown and not skipRefresh then
    RefreshResults(self)
  else
    self.ResultsProvider:EndAnyQuery()
  end
end

-- Bid Mode's custom search panel stays shown at all times (mirroring Buyout
-- Mode), so an emptied staging slot falls back to the last-searched item
-- instead of exposing the native listing; only the staged item's changes
-- need reacting to here.
local function UpdateBidModeResults(self)
  if self.mode ~= "bid" then return end
  local item = GetSelectedItemInfo()
  local itemLink = item and item.itemLink
  if itemLink ~= self.lastBidItemLink then
    self.lastBidItemLink = itemLink
    RefreshResults(self, itemLink)
  end
end

local function GetBuyoutValues(self)
  local item = GetSelectedItemInfo()
  local stackSize = self.Stacks.StackSize:GetNumber()
  local numStacks = self.Stacks.NumStacks:GetNumber()
  local unitPrice = MoneyInputFrame_GetCopper(StartPrice)
  local stackPrice = MoneyInputFrame_GetCopper(BuyoutPrice)
  return item, unitPrice, stackPrice, stackSize, numStacks
end

local function UpdateStackLimits(self, resetValues)
  local item = GetSelectedItemInfo()
  if not item then
    self.Stacks:SetMaxStackSize(0)
    self.Stacks:SetMaxNumStacks(0)
    if resetValues then
      self.Stacks.StackSize:SetNumber(0)
      self.Stacks.NumStacks:SetNumber(0)
    end
    return
  end

  local maxStack = math.max(1, math.min(item.maxStack, item.totalCount))
  if resetValues then
    local initialStack = math.max(1, math.min(item.count, maxStack))
    self.Stacks.StackSize:SetNumber(initialStack)
    self.Stacks.NumStacks:SetNumber(math.max(1, math.floor(item.totalCount / initialStack)))
  end

  local stackSize = math.max(1, math.min(self.Stacks.StackSize:GetNumber(), maxStack))
  self.Stacks:SetMaxStackSize(maxStack)
  self.Stacks:SetMaxNumStacks(math.max(1, math.floor(item.totalCount / stackSize)))
end

-- Staging a new item must not auto-fill Stacks; the player has to specify
-- stack size/count explicitly (Post/Create Auction pulses the row otherwise).
local function ClearStacksForNewItem(self)
  self.previousStackSize = nil
  self.Stacks.StackSize:SetNumber(0)
  self.Stacks.NumStacks:SetNumber(0)
  UpdateStackLimits(self, false)
end

local function UpdateBuyoutPanel(self)
  if self.mode ~= "buyout" then
    return
  end

  local item, unitPrice, stackPrice, stackSize, numStacks = GetBuyoutValues(self)

  if stackSize ~= self.previousStackSize then
    self.previousStackSize = stackSize
    stackPrice = unitPrice * stackSize
    MoneyInputFrame_SetCopper(BuyoutPrice, stackPrice)
    self.previousStackPrice = stackPrice
    UpdateStackLimits(self, false)
  elseif unitPrice ~= self.previousUnitPrice then
    self.previousUnitPrice = unitPrice
    stackPrice = unitPrice * stackSize
    MoneyInputFrame_SetCopper(BuyoutPrice, stackPrice)
    self.previousStackPrice = stackPrice
  elseif stackPrice ~= self.previousStackPrice then
    self.previousStackPrice = stackPrice
    if stackSize > 0 then
      unitPrice = math.ceil(stackPrice / stackSize)
      MoneyInputFrame_SetCopper(StartPrice, unitPrice)
      self.previousUnitPrice = unitPrice
    end
  end

  item, unitPrice, stackPrice, stackSize, numStacks = GetBuyoutValues(self)
  -- Stacks are left unspecified after staging (no auto-populate); gate button
  -- enablement on item/price only so PostBuyout can pulse the Stacks row instead.
  local priceValid = item ~= nil and stackPrice > 0 and Auctionator.AH.IsNotThrottled()
  local stacksValid = item ~= nil and stackSize > 0 and numStacks > 0 and
    stackSize * numStacks <= item.totalCount
  local valid = priceValid and stacksValid

  local totalPrice = valid and stackPrice * numStacks or 0
  local deposit = 0
  if valid then
    local buyoutPrice = math.min(stackPrice, MAXIMUM_BID_PRICE)
    deposit = GetAuctionDeposit(
      AuctionFrameAuctions.duration,
      buyoutPrice,
      buyoutPrice,
      stackSize,
      numStacks
    )
  end

  MoneyFrame_Update("AuctionsDepositMoneyFrame", deposit)
  SetStackedMoneyDisplay(self.TotalPrice, totalPrice)
  AuctionsCreateAuctionButton:SetEnabled(priceValid)
end

local function UpdateBidPanel(self)
  if self.mode ~= "bid" then
    return
  end

  local item = GetSelectedItemInfo()
  local unitBid = MoneyInputFrame_GetCopper(StartPrice)
  local unitBuyout = MoneyInputFrame_GetCopper(BuyoutPrice)
  local stackSize = self.Stacks.StackSize:GetNumber()
  local numStacks = self.Stacks.NumStacks:GetNumber()

  UpdateStackLimits(self, false)

  -- Stacks are left unspecified after staging (no auto-populate); gate button
  -- enablement on item/price only so PostBid can pulse the Stacks row instead.
  local priceValid = item ~= nil and unitBid > 0 and Auctionator.AH.IsNotThrottled()
  local stacksValid = item ~= nil and stackSize > 0 and numStacks > 0 and
    stackSize * numStacks <= item.totalCount
  local valid = priceValid and stacksValid
  local totalUnitPrice = unitBuyout > 0 and unitBuyout or unitBid
  local totalPrice = valid and totalUnitPrice * stackSize * numStacks or 0
  local deposit = 0
  if valid then
    local stackBid = math.min(unitBid * stackSize, MAXIMUM_BID_PRICE)
    local stackBuyout = unitBuyout > 0 and math.min(unitBuyout * stackSize, MAXIMUM_BID_PRICE) or 0
    deposit = GetAuctionDeposit(
      AuctionFrameAuctions.duration,
      stackBid,
      stackBuyout,
      stackSize,
      numStacks
    )
  end

  MoneyFrame_Update("AuctionsDepositMoneyFrame", deposit)
  if self.BidTotalPrice then
    SetStackedMoneyDisplay(self.BidTotalPrice, totalPrice)
  end
  AuctionsCreateAuctionButton:SetEnabled(priceValid)
end

local function PulseInputFeedback(frame)
  frame = frame or StartPrice
  if not frame or not frame.CreateAnimationGroup then
    return
  end

  if not frame.LogisticianHistoryPulse then
    local pulse = frame:CreateAnimationGroup()
    local fadeOut = pulse:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.35)
    fadeOut:SetDuration(0.12)
    fadeOut:SetOrder(1)

    local fadeIn = pulse:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.35)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.12)
    fadeIn:SetOrder(2)

    local fadeOutAgain = pulse:CreateAnimation("Alpha")
    fadeOutAgain:SetFromAlpha(1)
    fadeOutAgain:SetToAlpha(0.35)
    fadeOutAgain:SetDuration(0.12)
    fadeOutAgain:SetOrder(3)

    local fadeInAgain = pulse:CreateAnimation("Alpha")
    fadeInAgain:SetFromAlpha(0.35)
    fadeInAgain:SetToAlpha(1)
    fadeInAgain:SetDuration(0.12)
    fadeInAgain:SetOrder(4)

    pulse:SetScript("OnFinished", function()
      frame:SetAlpha(1)
    end)
    pulse:SetScript("OnStop", function()
      frame:SetAlpha(1)
    end)
    frame.LogisticianHistoryPulse = pulse
  end

  frame.LogisticianHistoryPulse:Stop()
  frame:SetAlpha(1)
  frame.LogisticianHistoryPulse:Play()
end


local function ApplyHistoryUnitPrice(self, unitPrice)
  if self.mode ~= "bid" and self.mode ~= "buyout" then
    return
  end
  if not self.resultsHistoryShown or not GetSelectedItemInfo() then
    return
  end
  if not unitPrice or unitPrice <= 0 then
    return
  end

  unitPrice = GetAmountWithUndercut(unitPrice)

  if self.mode == "buyout" then
    MoneyInputFrame_SetCopper(StartPrice, unitPrice)
    self.previousUnitPrice = unitPrice
    local stackSize = math.max(1, self.Stacks.StackSize:GetNumber())
    local stackPrice = math.min(unitPrice * stackSize, MAXIMUM_BID_PRICE)
    MoneyInputFrame_SetCopper(BuyoutPrice, stackPrice)
    self.previousStackPrice = stackPrice
    UpdateBuyoutPanel(self)
    PulseInputFeedback(StartPrice)
  else
    MoneyInputFrame_SetCopper(BuyoutPrice, unitPrice)
    AuctionsFrameAuctions_ValidateAuction()
    PulseInputFeedback(BuyoutPrice)
  end
end

local function MarkPendingPostedSearch(self, item)
  item = item or GetSelectedItemInfo()
  local itemLink = (item and item.itemLink) or self.resultsItemLink
  if itemLink then
    self.pendingPostedItemLink = itemLink
  end
  if item then
    self.pendingPostedItemID = item.itemID
    self.pendingPostedItemName = item.name
  end
  if itemLink or item then
    self.preservePostedSearch = true
  end
end

local function ResolvePendingPostedItemLink(self)
  if self.pendingPostedItemLink then
    return self.pendingPostedItemLink
  end
  if not self.pendingPostedItemID and not self.pendingPostedItemName then
    return nil
  end

  if self.pendingPostedItemID then
    local itemLink = select(2, GetItemInfo(self.pendingPostedItemID))
    if itemLink then
      self.pendingPostedItemLink = itemLink
      return itemLink
    end
  end

  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus]
    local itemID = info[Auctionator.Constants.AuctionItemInfo.ItemID]
    local name = info[1]
    if saleStatus ~= 1 and
        ((self.pendingPostedItemID and itemID == self.pendingPostedItemID) or
        (self.pendingPostedItemName and name == self.pendingPostedItemName)) then
      local itemLink = GetAuctionItemLink("owner", index)
      if itemLink then
        self.pendingPostedItemLink = itemLink
        return itemLink
      end
    end
  end
end

local function IsPendingPostedAuctionVisible(self, itemLink)
  local wantedLink = itemLink and Auctionator.Search.GetCleanItemLink(itemLink)
  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus]
    local ownerItemLink = GetAuctionItemLink("owner", index)
    local cleanLink = ownerItemLink and Auctionator.Search.GetCleanItemLink(ownerItemLink)
    local itemID = info[Auctionator.Constants.AuctionItemInfo.ItemID]
    local name = info[1]
    if saleStatus ~= 1 and
        ((wantedLink and cleanLink == wantedLink) or
        (self.pendingPostedItemID and itemID == self.pendingPostedItemID) or
        (self.pendingPostedItemName and name == self.pendingPostedItemName)) then
      return true
    end
  end
  return false
end

local function ClearPendingPostedSearch(self)
  self.pendingPostedItemLink = nil
  self.pendingPostedItemID = nil
  self.pendingPostedItemName = nil
  self.pendingPostedRefreshAttempts = nil
end

local function RenderPendingPostedSearch(self, postedItemLink)
  CreateResultsPanel(self)
  self.resultsItemLink = postedItemLink
  self.pricesSeededForSearch = false
  self.resultsSearching = false
  self.ResultsProvider.resultsMode = self.mode
  self.ResultsProvider:SetQuery(postedItemLink, function()
    self.ResultsProvider:SetRequestAllResults(self.mode == "bid")
    GetOwnerAuctionItems(0)
    self.ResultsProvider.allAuctions = {}
    self.ResultsProvider.gotAllResults = true
    self.ResultsProvider:PopulateAuctions()
    RenderResults(self)
  end, self.pendingPostedItemName)
end

local function RefreshPostedSearchWithMarket(self, postedItemLink, displayName)
  if self.RefreshResults then
    self.RefreshResults(self, postedItemLink, displayName)
  elseif RefreshResults then
    RefreshResults(self, postedItemLink, displayName)
  end
end

local function TryRefreshPendingPostedSearch(self)
  if not self.ResultsPanel or not self.ResultsPanel:IsShown() or
      not (self.pendingPostedItemLink or self.pendingPostedItemID or
      self.pendingPostedItemName) then
    return false
  end

  local postedItemLink = ResolvePendingPostedItemLink(self)
  if not postedItemLink then
    self.pendingPostedRefreshAttempts = (self.pendingPostedRefreshAttempts or 0) + 1
    if self.pendingPostedRefreshAttempts <= 20 then
      GetOwnerAuctionItems(0)
      C_Timer.After(0.5, function()
        TryRefreshPendingPostedSearch(self)
      end)
    end
    return false
  end

  if self.SetResultsHistoryShown then
    self.SetResultsHistoryShown(false)
  end
  if not IsPendingPostedAuctionVisible(self, postedItemLink) then
    self.pendingPostedRefreshAttempts = (self.pendingPostedRefreshAttempts or 0) + 1
    if self.pendingPostedRefreshAttempts <= 20 then
      GetOwnerAuctionItems(0)
      C_Timer.After(0.5, function()
        TryRefreshPendingPostedSearch(self)
      end)
      return false
    end
  end

  RenderPendingPostedSearch(self, postedItemLink)
  local postedItemName = self.pendingPostedItemName
  C_Timer.After(0.25, function()
    RefreshPostedSearchWithMarket(self, postedItemLink, postedItemName)
  end)
  ClearPendingPostedSearch(self)
  return true
end

local function PostBuyout(self)
  local item, _, stackPrice, stackSize, numStacks = GetBuyoutValues(self)
  if not item or stackPrice <= 0 or not Auctionator.AH.IsNotThrottled() then
    return
  end
  if stackSize <= 0 or numStacks <= 0 or stackSize * numStacks > item.totalCount then
    PulseInputFeedback(self.Stacks)
    return
  end

  MarkPendingPostedSearch(self, item)

  DropCursorMoney()
  local buyoutPrice = math.min(stackPrice, MAXIMUM_BID_PRICE)
  if StaticPopupDialogs["AUCTION_HOUSE_POST_WARNING"] then
    Auctionator.AH.PostAuction(buyoutPrice, buyoutPrice,
      AuctionFrameAuctions.duration, stackSize, numStacks, true)
  else
    Auctionator.AH.PostAuction(buyoutPrice, buyoutPrice,
      AuctionFrameAuctions.duration, stackSize, numStacks)
  end

end

local function PostBid(self)
  local item = GetSelectedItemInfo()
  local unitBid = MoneyInputFrame_GetCopper(StartPrice)
  local unitBuyout = MoneyInputFrame_GetCopper(BuyoutPrice)
  local stackSize = self.Stacks.StackSize:GetNumber()
  local numStacks = self.Stacks.NumStacks:GetNumber()
  if not item or unitBid <= 0 or not Auctionator.AH.IsNotThrottled() then
    return
  end
  if stackSize <= 0 or numStacks <= 0 or stackSize * numStacks > item.totalCount then
    PulseInputFeedback(self.Stacks)
    return
  end

  MarkPendingPostedSearch(self, item)
  DropCursorMoney()
  local startingBid = math.min(unitBid * stackSize, MAXIMUM_BID_PRICE)
  local buyoutPrice = unitBuyout > 0 and math.min(unitBuyout * stackSize, MAXIMUM_BID_PRICE) or 0
  if StaticPopupDialogs["AUCTION_HOUSE_POST_WARNING"] then
    Auctionator.AH.PostAuction(startingBid, buyoutPrice,
      AuctionFrameAuctions.duration, stackSize, numStacks, true)
  else
    Auctionator.AH.PostAuction(startingBid, buyoutPrice,
      AuctionFrameAuctions.duration, stackSize, numStacks)
  end
end

local function SetPostingControlShown(self, frame, shown)
  if not frame then
    return
  end
  self.postingControlMouseState = self.postingControlMouseState or {}
  self.postingControlShownState = self.postingControlShownState or {}
  if not shown and frame.IsShown and self.postingControlShownState[frame] == nil then
    self.postingControlShownState[frame] = frame:IsShown()
  end
  if not shown and frame.IsMouseEnabled and self.postingControlMouseState[frame] == nil then
    self.postingControlMouseState[frame] = frame:IsMouseEnabled()
  end
  if frame.EnableMouse then
    if shown then
      if self.postingControlMouseState[frame] ~= nil then
        frame:EnableMouse(self.postingControlMouseState[frame])
      end
    else
      frame:EnableMouse(false)
    end
  end
  local shouldShow = shown and self.postingControlShownState[frame] ~= false
  if frame.SetShown then
    frame:SetShown(shouldShow)
  elseif shouldShow and frame.Show then
    frame:Show()
  elseif not shouldShow and frame.Hide then
    frame:Hide()
  end
end

local function SetPostingControlTreeShown(self, frame, shown)
  SetPostingControlShown(self, frame, shown)
  if frame and frame.GetRegions then
    for _, region in ipairs({ frame:GetRegions() }) do
      SetPostingControlShown(self, region, shown)
    end
  end
  if frame and frame.GetChildren then
    for _, child in ipairs({ frame:GetChildren() }) do
      SetPostingControlTreeShown(self, child, shown)
    end
  end
end

local function SetPostingControlsShown(self, shown)
  SetPostingControlShown(self, _G.AuctionsItemText, shown)
  SetPostingControlTreeShown(self, AuctionsItemButton, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonIconTexture, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonIcon, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonIconBorder, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonNormalTexture, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonNameFrame, shown)
  SetPostingControlShown(self, _G.AuctionsItemName, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonCount, shown)
  SetPostingControlShown(self, _G.AuctionsItemButtonStock, shown)
  SetPostingControlShown(self, StartPrice, shown)
  SetPostingControlShown(self, self.StartPriceText, shown)
  SetPostingControlShown(self, AuctionsBuyoutText, shown)
  SetPostingControlShown(self, BuyoutPrice, shown)
  SetPostingControlShown(self, AuctionsDurationText, shown)
  SetPostingControlShown(self, AuctionsShortAuctionButton, shown)
  SetPostingControlShown(self, AuctionsMediumAuctionButton, shown)
  SetPostingControlShown(self, AuctionsLongAuctionButton, shown)
  SetPostingControlShown(self, AuctionsDepositText, shown)
  SetPostingControlShown(self, _G.AuctionsDepositMoneyFrame, shown)
  SetPostingControlShown(self, AuctionsCreateAuctionButton, shown)
  SetPostingControlShown(self, AuctionsBuyoutErrorText, shown and self.original.buyoutErrorShown)
end

local function SetListingsSlotCoverShown(self, shown)
  if self.ListingsSlotCover then
    self.ListingsSlotCover:SetShown(shown)
  end
end
local function SetListingsUndercutButtonShown(self, shown)
  if self.ListingsUndercutButton then
    self.ListingsUndercutButton:SetShown(shown)
  end
end

local function ClearStagedAuctionItem()
  if GetAuctionSellItemInfo() then
    ClickAuctionSellItemButton()
    ClearCursor()
  end
end

local function CaptureStagedAuctionItem()
  local item = GetSelectedItemInfo()
  if not item then
    return nil
  end

  local itemInfo = item.itemLink and AuctionatorBagCacheFrame and
    AuctionatorBagCacheFrame:GetByLinkInstant(item.itemLink, true)
  return {
    itemLink = item.itemLink,
    itemID = item.itemID,
    location = itemInfo and itemInfo.locations and itemInfo.locations[1],
  }
end

local function RestoreStagedAuctionItem(self)
  local stagedItem = self.stagedPostingItem
  if not stagedItem then
    return
  end

  local location = stagedItem.location
  if (not location or not C_Item.DoesItemExist(location)) and stagedItem.itemLink and
      AuctionatorBagCacheFrame then
    local itemInfo = AuctionatorBagCacheFrame:GetByLinkInstant(stagedItem.itemLink, true)
    location = itemInfo and itemInfo.locations and itemInfo.locations[1]
  end
  if not location or not C_Item.DoesItemExist(location) then
    self.stagedPostingItem = nil
    return
  end

  ClearCursor()
  if location:IsBagAndSlot() then
    local bag, slot = location:GetBagAndSlot()
    if C_Container and C_Container.PickupContainerItem then
      C_Container.PickupContainerItem(bag, slot)
    else
      PickupContainerItem(bag, slot)
    end
  else
    PickupInventoryItem(location:GetEquipmentSlot())
  end
  if CursorHasItem and CursorHasItem() then
    ClickAuctionSellItemButton()
  end
  ClearCursor()
  self.stagedPostingItem = nil
end

local function ClearCountRegion(region)
  if type(region) == "table" and region.SetText then
    region:SetText("")
    if region.Hide then
      region:Hide()
    end
  end
end

local function ClearEmptyAuctionItemButtonCount()
  if GetAuctionSellItemInfo() then
    return
  end
  if AuctionsItemButton then
    SetItemButtonCount(AuctionsItemButton, 0)
    ClearCountRegion(AuctionsItemButton.Count)
    ClearCountRegion(AuctionsItemButton.count)
  end
  if _G.AuctionsItemButtonCount then
    _G.AuctionsItemButtonCount:SetText("")
    _G.AuctionsItemButtonCount:Hide()
  end
end

local function HideAuctionItemButtonCount()
  if AuctionsItemButton then
    SetItemButtonCount(AuctionsItemButton, 0)
    ClearCountRegion(AuctionsItemButton.Count)
    ClearCountRegion(AuctionsItemButton.count)
  end
  if _G.AuctionsItemButtonCount then
    _G.AuctionsItemButtonCount:SetText("")
    _G.AuctionsItemButtonCount:Hide()
  end
end

local function GetPendingIncomeAmount()
  local total = 0
  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus]
    if saleStatus == 1 then
      local bidAmount = info[Auctionator.Constants.AuctionItemInfo.BidAmount] or 0
      local minBid = info[Auctionator.Constants.AuctionItemInfo.MinBid] or 0
      total = total + math.max(bidAmount, minBid)
    end
  end
  return total
end

local function UpdateListingsPendingIncome(self)
  if not self.ListingsPendingIncomeLabel or not self.ListingsPendingIncomeValue then
    return
  end

  local shown = self.mode == "listings" or self.listingsDetailsShown == true
  self.ListingsPendingIncomeLabel:SetShown(shown)
  self.ListingsPendingIncomeValue:SetShown(shown)
  if shown then
    self.ListingsPendingIncomeValue:SetText(GetMoneyString(GetPendingIncomeAmount(), true))
  end
end

local function MatchesListingsSearch(self, ownerIndex)
  local query = self.ListingsSearchBox and
    NormalizeWhitespace(self.ListingsSearchBox:GetText()):lower() or ""
  if query == "" then
    return true
  end

  local info = { GetAuctionItemInfo("owner", ownerIndex) }
  local name = NormalizeWhitespace(StripColorCodes(info[1])):lower()
  for token in query:gmatch("%S+") do
    if not string.find(name, token, 1, true) then
      return false
    end
  end
  return true
end

local function CacheListingsRowPoints(self)
  if self.listingsRowPoints then
    return
  end

  self.listingsRowPoints = {}
  local rowIndex = 1
  while _G["AuctionsButton" .. rowIndex] do
    self.listingsRowPoints[rowIndex] = SavePoints(_G["AuctionsButton" .. rowIndex])
    rowIndex = rowIndex + 1
  end
end

local function RestoreListingsRowPoints(self)
  if not self.listingsRowPoints then
    return
  end

  for rowIndex, points in ipairs(self.listingsRowPoints) do
    local row = _G["AuctionsButton" .. rowIndex]
    if row then
      RestorePoints(row, points)
    end
  end
end

local function IsListingsAuctionScannable(info)
  -- SaleStatus alone was not reliably catching every sold auction - user
  -- screenshots showed rows Blizzard itself labels "- Sold" still getting a
  -- red X/green check. Per warcraft.wiki.gg, `count` (Quantity) is
  -- documented as "zero if item is 'sold' in the owner auctions" - almost
  -- certainly the signal Blizzard's own "- Sold" label actually reads, and
  -- apparently more reliably/promptly updated than SaleStatus for a batch of
  -- identical (item, price) listings selling off one at a time. Check both.
  local buyout = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
  local bidAmount = info[Auctionator.Constants.AuctionItemInfo.BidAmount] or 0
  -- A bid lower than the buyout doesn't stop the buyout from still being
  -- undercut by a competitor, so only a bid that has actually MET the
  -- buyout (effectively already sold) should exclude it - not any bid.
  return info[Auctionator.Constants.AuctionItemInfo.SaleStatus] ~= 1 and
    (info[Auctionator.Constants.AuctionItemInfo.Quantity] or 0) > 0 and
    buyout > 0 and
    bidAmount ~= buyout
end

local function GetListingsUndercutKey(itemLink, unitPrice)
  return Auctionator.Search.GetCleanItemLink(itemLink) .. "\031" .. tostring(unitPrice)
end

-- AuctionsButtonN's own :GetID() is only the row's position WITHIN the
-- current scroll page (e.g. always 1-9), not the absolute owner-list index -
-- ShowListingResults already knew to add the scroll offset, but every other
-- place reading row:GetID() for owner-index purposes did not. That silently
-- computed undercut status/search matches against whatever auction happens
-- to sit at that same relative position on the FIRST page, once scrolled to
-- any later page - explaining stale/wrong icons and "page 2" search misses.
local function GetListingsScrollOffset()
  return GetEffectiveAuctionsScrollFrameOffset and GetEffectiveAuctionsScrollFrameOffset() or
    FauxScrollFrame_GetOffset(AuctionsScrollFrame)
end

local function GetListingsRowOwnerIndex(row)
  return row:GetID() + GetListingsScrollOffset()
end

local function GetListingsRowUndercutKey(ownerIndex)
  local info = { GetAuctionItemInfo("owner", ownerIndex) }
  local itemLink = GetAuctionItemLink("owner", ownerIndex)
  if not itemLink or not IsListingsAuctionScannable(info) then
    return nil
  end
  return GetListingsUndercutKey(itemLink, Auctionator.Utilities.ToUnitPrice({ info = info }))
end

local function EnsureListingsRowStatus(row)
  local itemButton = row:GetName() and _G[row:GetName() .. "Item"] or nil
  if not row.LogisticianUndercutStatus then
    row.LogisticianUndercutStatus = (itemButton or row):CreateTexture(nil, "OVERLAY")
    row.LogisticianUndercutStatus:SetSize(22, 22)
  end
  row.LogisticianUndercutStatus:ClearAllPoints()
  if itemButton then
    if row.LogisticianUndercutStatus:GetParent() ~= itemButton then
      row.LogisticianUndercutStatus:SetParent(itemButton)
    end
    row.LogisticianUndercutStatus:SetDrawLayer("OVERLAY", 7)
    row.LogisticianUndercutStatus:SetPoint("CENTER", itemButton, "CENTER", 0, 0)
  else
    row.LogisticianUndercutStatus:SetPoint("LEFT", row, "LEFT", 8, 0)
  end
  return row.LogisticianUndercutStatus
end

local function ApplyListingsUndercutStatus(self)
  if self.mode ~= "listings" then
    return
  end

  local rowIndex = 1
  while _G["AuctionsButton" .. rowIndex] do
    local row = _G["AuctionsButton" .. rowIndex]
    local statusText = EnsureListingsRowStatus(row)
    local ownerIndex = GetListingsRowOwnerIndex(row)
    local key = row:IsShown() and GetListingsRowUndercutKey(ownerIndex) or nil
    local status = key and self.listingsUndercutStatuses and
      self.listingsUndercutStatuses[key]
    if status == "checking" then
      statusText:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
      statusText:SetAlpha(self.listingsUndercutBlinkAlpha or 1)
      statusText:Show()
    elseif status == "unknown" then
      statusText:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
      statusText:SetAlpha(1)
      statusText:Show()
    elseif status == "undercut" then
      statusText:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
      statusText:SetAlpha(1)
      statusText:Show()
    elseif status == "ok" then
      statusText:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
      statusText:SetAlpha(1)
      statusText:Show()
    else
      statusText:SetAlpha(1)
      statusText:Hide()
    end
    rowIndex = rowIndex + 1
  end
end

local function MarkListingsCheckingUnknown(self)
  if not self.listingsUndercutStatuses then
    return
  end

  for key, status in pairs(self.listingsUndercutStatuses) do
    if status == "checking" then
      self.listingsUndercutStatuses[key] = "unknown"
    end
  end
end

local function HideListingsUndercutStatus(self)
  local rowIndex = 1
  while _G["AuctionsButton" .. rowIndex] do
    local statusText = _G["AuctionsButton" .. rowIndex].LogisticianUndercutStatus
    if statusText then
      statusText:Hide()
    end
    rowIndex = rowIndex + 1
  end
end

local function ClearListingsUndercutStatusCache(self)
  self.listingsUndercutStatuses = nil
  self.listingsUndercutFound = 0
  self.listingsUndercutIndex = 0
  self.listingsUndercutQueue = nil
  self.listingsUndercutCurrent = nil
  HideListingsUndercutStatus(self)
end

local function ApplyListingsSearchFilter(self)
  if self.mode ~= "listings" or not self.ListingsSearchBox then
    return
  end

  CacheListingsRowPoints(self)
  RestoreListingsRowPoints(self)

  local query = NormalizeWhitespace(self.ListingsSearchBox:GetText())
  if query == "" then
    ApplyListingsUndercutStatus(self)
    return
  end

  local compactRowIndex = 1
  local rowIndex = 1
  while _G["AuctionsButton" .. rowIndex] do
    local row = _G["AuctionsButton" .. rowIndex]
    if row:IsShown() then
      if MatchesListingsSearch(self, GetListingsRowOwnerIndex(row)) then
        RestorePoints(row, self.listingsRowPoints[compactRowIndex])
        compactRowIndex = compactRowIndex + 1
      else
        row:Hide()
      end
    end
    rowIndex = rowIndex + 1
  end
  ApplyListingsUndercutStatus(self)
end

-- SearchBoxTemplate's built-in clear ("x") button isn't exposed under a
-- single consistent key across client versions, so look it up once by
-- child name (same technique as StripArrowTextures above) and cache it.
local function GetListingsSearchClearButton(self)
  if self.ListingsSearchClearButton ~= nil then
    return self.ListingsSearchClearButton or nil
  end
  local box = self.ListingsSearchBox
  local clearButton = box and (box.ClearButton or box.clearButton)
  if not clearButton and box then
    local boxName = box.GetName and box:GetName()
    clearButton = boxName and _G[boxName .. "ClearButton"]
  end
  if not clearButton and box then
    for _, child in ipairs({ box:GetChildren() }) do
      local childName = child.GetName and child:GetName()
      if type(childName) == "string" and childName:lower():find("clearbutton") then
        clearButton = child
        break
      end
    end
  end
  self.ListingsSearchClearButton = clearButton or false
  return clearButton
end

local function SetListingsSearchLocked(self, locked)
  if not self.ListingsSearchBox then
    return
  end

  if locked then
    self.ListingsSearchBox:ClearFocus()
    if self.ListingsSearchBox.Disable then
      self.ListingsSearchBox:Disable()
    end
    self.ListingsSearchBox:EnableMouse(false)
    self.ListingsSearchBox:SetAlpha(0.45)
  else
    if self.ListingsSearchBox.Enable then
      self.ListingsSearchBox:Enable()
    end
    self.ListingsSearchBox:EnableMouse(true)
    self.ListingsSearchBox:SetAlpha(1)
  end

  local clearButton = GetListingsSearchClearButton(self)
  if clearButton then
    if locked then
      if clearButton.Disable then clearButton:Disable() end
      clearButton:EnableMouse(false)
      clearButton:SetAlpha(0.45)
    else
      if clearButton.Enable then clearButton:Enable() end
      clearButton:EnableMouse(true)
      clearButton:SetAlpha(1)
    end
  end
end

local function SetListingsScanBlockerShown(self, shown)
  if self.ListingsScanBlocker then
    self.ListingsScanBlocker:SetShown(shown)
    self.ListingsScanBlocker:EnableMouse(shown)
  end
  if shown then
    self.listingsUndercutDotsElapsed = 0
    self.listingsUndercutDots = 1
    self.listingsUndercutBlinkAlpha = 1
    self.listingsUndercutCheckingText = "Checking."
  end
end

local function SetListingsUndercutButtonBusy(self, busy, text)
  if not self.ListingsUndercutButton then
    return
  end

  SetListingsSearchLocked(self, busy or self.listingsDetailsShown == true)
  SetListingsScanBlockerShown(self, busy)
  SetPageStatusSuppressed(busy)
  if busy then
    self.ListingsUndercutButton:SetText("Cancel")
    self.ListingsUndercutButton:SetEnabled(true)
  else
    self.ListingsUndercutButton:SetText(text or "Check Undercut")
    self.ListingsUndercutButton:SetEnabled(Auctionator.AH.IsNotThrottled())
  end
end

local function FinishListingsUndercutScan(self, text)
  self.listingsUndercutScanning = false
  self.listingsUndercutQueue = nil
  self.listingsUndercutCurrent = nil
  SetListingsUndercutButtonBusy(self, false, text or "Check Undercut")
  ApplyListingsUndercutStatus(self)
end

local function CancelListingsUndercutScan(self)
  if not self.listingsUndercutScanning then
    return
  end

  self.listingsUndercutScanning = false
  self.listingsUndercutQueue = nil
  self.listingsUndercutCurrent = nil
  MarkListingsCheckingUnknown(self)
  Auctionator.AH.AbortQuery()
  SetListingsUndercutButtonBusy(self, false, "Check Undercut")
  ApplyListingsUndercutStatus(self)
end

local function BuildListingsUndercutScanQueue(self)
  local byItem = {}
  local queue = {}
  local ownerCount = GetNumAuctionItems("owner")
  for index = 1, ownerCount do
    local info = { GetAuctionItemInfo("owner", index) }
    local itemLink = GetAuctionItemLink("owner", index)
    local scannable = itemLink and IsListingsAuctionScannable(info)
    local matchesSearch = itemLink and MatchesListingsSearch(self, index)
    if itemLink and scannable and matchesSearch then
      local cleanLink = Auctionator.Search.GetCleanItemLink(itemLink)
      local itemName = Auctionator.Utilities.GetNameFromLink(itemLink)
      local scanItem = byItem[cleanLink]
      if not scanItem and itemName then
        scanItem = {
          cleanLink = cleanLink,
          itemLink = itemLink,
          searchString = itemName,
          unitPrices = {},
          itemID = C_Item.GetItemInfoInstant(itemLink),
        }
        byItem[cleanLink] = scanItem
        table.insert(queue, scanItem)
      end
      if scanItem then
        local unitPrice = Auctionator.Utilities.ToUnitPrice({ info = info })
        scanItem.unitPrices[unitPrice] = true
        self.listingsUndercutStatuses[GetListingsUndercutKey(itemLink, unitPrice)] = "checking"
      end
    end
  end
  table.sort(queue, function(left, right)
    return NormalizeWhitespace(left.searchString):lower() <
      NormalizeWhitespace(right.searchString):lower()
  end)
  return queue
end

local function QueryListingsUndercutItem(self)
  self.listingsUndercutIndex = (self.listingsUndercutIndex or 0) + 1
  local scanItem = self.listingsUndercutQueue and
    self.listingsUndercutQueue[self.listingsUndercutIndex]
  if not scanItem then
    FinishListingsUndercutScan(self, "Check Undercut")
    return
  end

  self.listingsUndercutCurrent = scanItem
  SetListingsUndercutButtonBusy(self, true,
    ("Checking %d/%d"):format(self.listingsUndercutIndex, #self.listingsUndercutQueue))

  Auctionator.AH.QueryAndFocusPage({
    searchString = scanItem.searchString,
    isExact = true,
  }, 0)
end

local function ProcessListingsUndercutScanResults(self, results)
  local scanItem = self.listingsUndercutCurrent
  if not scanItem then
    return
  end

  local minMarketUnitPrice = nil
  for _, result in ipairs(results or {}) do
    local resultCleanLink = result.itemLink and
      Auctionator.Search.GetCleanItemLink(result.itemLink) or nil
    local info = result.info
    local buyout = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
    local owner = info[Auctionator.Constants.AuctionItemInfo.Owner]
    if resultCleanLink == scanItem.cleanLink and buyout > 0 and
        not IsPlayerOwnerName(owner) then
      local marketUnitPrice = Auctionator.Utilities.ToUnitPrice(result)
      if not minMarketUnitPrice or marketUnitPrice < minMarketUnitPrice then
        minMarketUnitPrice = marketUnitPrice
      end
    end
  end

  -- Cache the cheapest competitor price so unit-price variants that show up
  -- later (e.g. owner list still streaming in from the server) can be
  -- classified immediately by AugmentListingsUndercutScanQueue without
  -- re-querying this same item name.
  scanItem.marketChecked = true
  scanItem.minMarketUnitPrice = minMarketUnitPrice

  for ownedUnitPrice in pairs(scanItem.unitPrices) do
    local key = GetListingsUndercutKey(scanItem.itemLink, ownedUnitPrice)
    if minMarketUnitPrice and minMarketUnitPrice < ownedUnitPrice then
      self.listingsUndercutStatuses[key] = "undercut"
      self.listingsUndercutFound = (self.listingsUndercutFound or 0) + 1
    else
      self.listingsUndercutStatuses[key] = "ok"
    end
  end

  ApplyListingsUndercutStatus(self)
  QueryListingsUndercutItem(self)
end

-- The owner auction list can still be streaming in from the server when
-- "Check Undercut" is clicked (or its data can briefly change mid-scan), so
-- entries missing from the initial BuildListingsUndercutScanQueue snapshot
-- would otherwise never get a status/icon at all. Re-scan the owner list
-- while a scan is running and fold in anything not seen yet.
local function AugmentListingsUndercutScanQueue(self)
  if not self.listingsUndercutScanning or not self.listingsUndercutQueue then
    return
  end

  local byItem = {}
  for _, scanItem in ipairs(self.listingsUndercutQueue) do
    byItem[scanItem.cleanLink] = scanItem
  end

  local added = false
  for index = 1, GetNumAuctionItems("owner") do
    local info = { GetAuctionItemInfo("owner", index) }
    local itemLink = GetAuctionItemLink("owner", index)
    if itemLink and IsListingsAuctionScannable(info) and MatchesListingsSearch(self, index) then
      local cleanLink = Auctionator.Search.GetCleanItemLink(itemLink)
      local itemName = Auctionator.Utilities.GetNameFromLink(itemLink)
      local scanItem = byItem[cleanLink]
      if not scanItem and itemName then
        scanItem = {
          cleanLink = cleanLink,
          itemLink = itemLink,
          searchString = itemName,
          unitPrices = {},
          itemID = C_Item.GetItemInfoInstant(itemLink),
        }
        byItem[cleanLink] = scanItem
        table.insert(self.listingsUndercutQueue, scanItem)
      end
      if scanItem then
        local unitPrice = Auctionator.Utilities.ToUnitPrice({ info = info })
        if not scanItem.unitPrices[unitPrice] then
          scanItem.unitPrices[unitPrice] = true
          local key = GetListingsUndercutKey(itemLink, unitPrice)
          if scanItem.marketChecked then
            if scanItem.minMarketUnitPrice and scanItem.minMarketUnitPrice < unitPrice then
              self.listingsUndercutStatuses[key] = "undercut"
              self.listingsUndercutFound = (self.listingsUndercutFound or 0) + 1
            else
              self.listingsUndercutStatuses[key] = "ok"
            end
          else
            self.listingsUndercutStatuses[key] = "checking"
          end
          added = true
        end
      end
    end
  end

  if added then
    ApplyListingsUndercutStatus(self)
  end
end

local function BeginListingsUndercutQueryLoop(self)
  self.listingsUndercutStatuses = {}
  self.listingsUndercutFound = 0
  self.listingsUndercutIndex = 0
  self.listingsUndercutQueue = BuildListingsUndercutScanQueue(self)
  if #self.listingsUndercutQueue == 0 then
    FinishListingsUndercutScan(self, "No Items")
    return
  end

  ApplyListingsUndercutStatus(self)
  QueryListingsUndercutItem(self)
end

-- GetOwnerAuctionItems(0) can take a couple of frames (or a full server
-- round trip) before GetNumAuctionItems("owner")/GetAuctionItemInfo reflect
-- every owned auction, especially right after posting a batch of items.
-- Building the scan queue too early silently drops whatever hadn't loaded
-- yet, permanently leaving those rows unmarked. Poll until the owner count
-- is unchanged across two checks (or a retry limit is hit) before scanning.
local function WaitForStableOwnerList(self, attempt, lastCount)
  if not self.listingsUndercutScanning then
    return
  end

  attempt = attempt or 0
  local currentCount = GetNumAuctionItems("owner")
  if attempt >= 8 or (lastCount ~= nil and currentCount == lastCount) then
    BeginListingsUndercutQueryLoop(self)
    return
  end

  C_Timer.After(0.3, function()
    WaitForStableOwnerList(self, attempt + 1, currentCount)
  end)
end

local function StartListingsUndercutScan(self)
  if self.mode ~= "listings" or self.listingsUndercutScanning then
    return
  end

  Auctionator.AH.AbortQuery()
  self.listingsUndercutScanning = true
  SetListingsUndercutButtonBusy(self, true)
  -- Force a fresh owner-list fetch so any auctions still streaming in from
  -- the server (or just posted) are present before the scan queue is built;
  -- WaitForStableOwnerList only proceeds once the count settles.
  GetOwnerAuctionItems(0)
  WaitForStableOwnerList(self)
end

local function SetMode(self, mode)
  if self.mode ~= mode then
    ResetResultSort(self)
  end
  local enteringListings = mode == "listings" and self.mode ~= "listings"
  local leavingListings = self.mode == "listings" and mode ~= "listings"
  local enteringListingDetails = self.mode == "listings" and
    self.listingsDetailsShown == true
  local leavingListingDetails = self.listingsDetailsShown == true and
    self.mode ~= "listings" and mode ~= "listings"
  if enteringListings then
    self.stagedPostingItem = CaptureStagedAuctionItem()
    ClearStagedAuctionItem()
  end
  if mode == "listings" then
    self.listingsDetailsShown = false
    self.detailsItemLink = nil
    self.detailsBuyout = nil
    self.detailsQuantity = nil
    self.detailsBidAmount = nil
    self.detailsMinBid = nil
    self.detailsHighBidder = nil
  end
  self.mode = mode
  local buyout = mode == "buyout"
  local listings = mode == "listings"
  local listingsPanel = listings or self.listingsDetailsShown == true
  local restoreStagedItem = (leavingListings and not enteringListingDetails) or
    leavingListingDetails
  if restoreStagedItem then
    self.listingsDetailsShown = false
    listingsPanel = listings
  end
  -- Searching would refresh/compact the native owned-auction rows behind
  -- the detail view and desync it from whichever row is being inspected.
  SetListingsSearchLocked(self,
    self.listingsDetailsShown == true or self.listingsUndercutScanning == true)

  -- Blizzard's Cancel Auction button targets the native owned-auctions
  -- selection, which our Buyout Mode overlay replaces entirely; hide it
  -- there and leave it to work natively in Bid Mode and My Listings.
  if AuctionsCancelAuctionButton then
    AuctionsCancelAuctionButton:SetShown(not buyout)
  end

  RestorePoints(AuctionsTabText, self.original.tabTextPoints)
  if buyout then
    NudgePoints(AuctionsTabText, 8, -2)
  else
    NudgePoints(AuctionsTabText, 0, -2)
  end
  if self.ModeButton and self.original.modeButtonPoints then
    RestorePoints(self.ModeButton, self.original.modeButtonPoints)
    -- Keep the mode icon fixed while mode labels get per-mode vertical nudges.
    NudgePoints(self.ModeButton, 0, 2)
  end
  AuctionsTabText:SetText(buyout and not listingsPanel and "Buyout Mode" or
    listingsPanel and "My Listings" or "Bid Mode")
  if self.ModeIcon then
    self.ModeIcon:Show()
    if listingsPanel then
      self.ModeIcon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
      self.ModeIcon:SetTexCoord(0, 1, 0, 1)
      self.ModeIcon:ClearAllPoints()
      self.ModeIcon:SetPoint("LEFT", self.ModeButton, "LEFT", 46, -1)
    else
      self.ModeIcon:SetTexture(buyout and
        "Interface\\MoneyFrame\\UI-GoldIcon" or
        "Interface\\MoneyFrame\\UI-CopperIcon")
      self.ModeIcon:SetTexCoord(0, 1, 0, 1)
      self.ModeIcon:ClearAllPoints()
      self.ModeIcon:SetPoint("LEFT", self.ModeButton, "LEFT", buyout and 39 or 46, -1)
    end
  end
  if self.ModeToggleSwapIcon then
    self.ModeToggleSwapIcon:SetTexture(listings and
      "Interface\\Buttons\\UI-GuildButton-MOTD-Up" or
      "Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    self.ModeToggleSwapIcon:SetVertexColor(1, 1, 1)
    self.ModeToggleSwapIcon:SetSize(18, 18)
    self.ModeToggleSwapIcon:ClearAllPoints()
    self.ModeToggleSwapIcon:SetPoint("CENTER", self.ModeToggleButton, "CENTER", 0, 0)
  end

  self.StartPriceText:SetText(buyout and "Unit Price" or "Starting Unit Price")
  AuctionsBuyoutText:SetText(buyout and "Stack Price" or self.original.buyoutText)
  AuctionsCreateAuctionButton:SetText(buyout and "Post" or self.original.postText)
  self.Stacks:SetShown(not listingsPanel)
  self.TotalLabel:SetShown(buyout and not listingsPanel)
  SetStackedMoneyVisible(self.TotalPrice, buyout and not listingsPanel)
  if self.BidTotalLabel then
    self.BidTotalLabel:SetShown(mode == "bid" and not listingsPanel)
  end
  if self.BidTotalPrice then
    SetStackedMoneyVisible(self.BidTotalPrice, mode == "bid" and not listingsPanel)
  end
  if not listings then
    HideAuctionItemButtonCount()
  end
  SetPostingControlsShown(self, not listingsPanel)
  if restoreStagedItem then
    RestoreStagedAuctionItem(self)
  end
  SetListingsSlotCoverShown(self, listingsPanel)
  UpdateListingsPendingIncome(self)
  SetListingsUndercutButtonShown(self, listingsPanel)
  if listings then
    SetListingsUndercutButtonBusy(self, false, "Check Undercut")
  else
    CancelListingsUndercutScan(self)
    HideListingsUndercutStatus(self)
  end
  AuctionsBuyoutErrorText:SetShown(not buyout and not listings and self.original.buyoutErrorShown)

  if buyout then
    RestorePoints(StartPrice, self.original.startPricePoints)
    NudgePoints(StartPrice, 0, 10)
    SetPoint(AuctionsBuyoutText, "TOPLEFT", StartPrice, "BOTTOMLEFT", -1, -11)
    SetPoint(BuyoutPrice, "TOPLEFT", AuctionsBuyoutText, "BOTTOMLEFT", 2, -2)
    SetPoint(AuctionsDurationText, "TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 28, -287)
    SetPoint(AuctionsShortAuctionButton, "TOPLEFT", AuctionsDurationText, "BOTTOMLEFT", 3, -2)
    SetPoint(AuctionsMediumAuctionButton, "TOPLEFT", AuctionsShortAuctionButton, "BOTTOMLEFT", 0, 2)
    SetPoint(AuctionsLongAuctionButton, "TOPLEFT", AuctionsMediumAuctionButton, "BOTTOMLEFT", 0, 2)
    SetPoint(AuctionsDepositText, "BOTTOMLEFT", AuctionFrameAuctions, "BOTTOMLEFT", 30, 71)

    self.previousUnitPrice = MoneyInputFrame_GetCopper(StartPrice)
    self.previousStackSize = nil
    self.previousStackPrice = nil
    UpdateStackLimits(self, true)
    self.Stacks:ClearAllPoints()
    self.Stacks:SetPoint("TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 38, -287)
    self.TotalLabel:ClearAllPoints()
    self.TotalLabel:SetPoint("TOPLEFT", AuctionsDurationText, "TOPLEFT", 115, 0)
    self.TotalPrice:ClearAllPoints()
    self.TotalPrice:SetPoint("TOPLEFT", self.TotalLabel, "BOTTOMLEFT", -47, -5)
    self.TotalPrice:SetWidth(95)
    self.TotalPrice:SetJustifyH("RIGHT")
    self.TotalPrice:SetSpacing(3)
    UpdateBuyoutPanel(self)
    UpdateResultsHeadersForMode(self)
    ApplyDefaultResultSort(self)
    SetResultsPanelShown(self, true, self.listingsDetailsShown)
    RenderResults(self)
  else
    UpdateResultsHeadersForMode(self)
    ApplyDefaultResultSort(self)
    if listings then
      -- Ignore any staged item; always show Blizzard's native owned-auctions
      -- listing instead of a search/results overlay.
      SetResultsPanelShown(self, false)
    else
      -- Bid Mode's search panel stays shown at all times, just like Buyout
      -- Mode, falling back to its own empty state when nothing is staged.
      local item = GetSelectedItemInfo()
      self.lastBidItemLink = item and item.itemLink or nil
      RestorePoints(StartPrice, self.original.startPricePoints)
      NudgePoints(StartPrice, 0, 10)
      MoneyInputFrame_SetCopper(BuyoutPrice, 0)
      if BuyoutPrice.gold then BuyoutPrice.gold:SetText("") end
      if BuyoutPrice.silver then BuyoutPrice.silver:SetText("") end
      if BuyoutPrice.copper then BuyoutPrice.copper:SetText("") end
      self.Stacks:ClearAllPoints()
      self.Stacks:SetPoint("TOPLEFT", StartPrice, "BOTTOMLEFT", -1, -6)
      UpdateStackLimits(self, true)
      UpdateBidPanel(self)
      SetResultsPanelShown(self, true, self.listingsDetailsShown)
    end
    RenderResults(self)
    -- Restore the money frame first. In buyout mode it is anchored to its
    -- label, while Blizzard's native label is anchored back to the frame.
    -- Reversing that order would briefly create a circular dependency.
    RestorePoints(BuyoutPrice, self.original.buyoutPricePoints)
    RestorePoints(AuctionsBuyoutText, self.original.buyoutTextPoints)
    if listings then
      RestorePoints(StartPrice, self.original.startPricePoints)
    end
    RestorePoints(AuctionsDurationText, self.original.durationTextPoints)
    RestorePoints(AuctionsShortAuctionButton, self.original.shortDurationPoints)
    RestorePoints(AuctionsMediumAuctionButton, self.original.mediumDurationPoints)
    RestorePoints(AuctionsLongAuctionButton, self.original.longDurationPoints)
    RestorePoints(AuctionsDepositText, self.original.depositTextPoints)
    if not listings then
      SetPoint(AuctionsBuyoutText, "TOPLEFT", StartPrice, "BOTTOMLEFT", -1, -11)
      SetPoint(BuyoutPrice, "TOPLEFT", AuctionsBuyoutText, "BOTTOMLEFT", 2, -2)
      RestorePoints(AuctionsBuyoutErrorText, self.original.buyoutErrorTextPoints)
      NudgePoints(AuctionsBuyoutErrorText, 0, -47)
      self.Stacks:ClearAllPoints()
      self.Stacks:SetPoint("TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 38, -287)
      SetPoint(AuctionsDurationText, "TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 28, -287)
      SetPoint(AuctionsShortAuctionButton, "TOPLEFT", AuctionsDurationText, "BOTTOMLEFT", 3, -2)
      SetPoint(AuctionsMediumAuctionButton, "TOPLEFT", AuctionsShortAuctionButton, "BOTTOMLEFT", 0, 2)
      SetPoint(AuctionsLongAuctionButton, "TOPLEFT", AuctionsMediumAuctionButton, "BOTTOMLEFT", 0, 2)
      self.BidTotalLabel:ClearAllPoints()
      self.BidTotalLabel:SetPoint("TOPLEFT", AuctionsDurationText, "TOPLEFT", 115, 0)
      self.BidTotalPrice:ClearAllPoints()
      self.BidTotalPrice:SetPoint("TOPLEFT", self.BidTotalLabel, "BOTTOMLEFT", -47, -5)
      self.BidTotalPrice:SetWidth(95)
      self.BidTotalPrice:SetJustifyH("RIGHT")
      self.BidTotalPrice:SetSpacing(3)
    else
      RestorePoints(AuctionsBuyoutErrorText, self.original.buyoutErrorTextPoints)
    end
    NudgePoints(AuctionsDepositText, 5, 2)
    if not listings then
      UpdateBidPanel(self)
    else
      AuctionsFrameAuctions_ValidateAuction()
    end
  end
end

local function Initialize()
  if initialized or not AuctionFrameAuctions or not AuctionsTabText or
      not StartPrice or not BuyoutPrice or not AuctionsBuyoutText or
      not AuctionsDurationText or not AuctionsDepositText or
      not AuctionsCreateAuctionButton then
    return
  end

  local startPriceText = FindFrameFontString(StartPrice)
  if not startPriceText then
    return
  end
  initialized = true

  StaticPopupDialogs[CANCEL_CONFIRM_POPUP] = {
    text = AUCTIONATOR_L_BID_EXISTING_ON_OWNED_AUCTION,
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(dialog)
      if dialog.data then
        StartCancellation(dialog.data.owner, dialog.data.result)
      end
    end,
    hasMoneyFrame = 1,
    showAlert = 1,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1,
  }

  controller:SetParent(AuctionFrameAuctions)
  controller.mode = "buyout"
  controller.lastBuyoutMode = "buyout"
  controller.RefreshResults = RefreshResults
  controller.StartPriceText = startPriceText
  controller.original = {
    priceText = startPriceText:GetText(),
    buyoutText = AuctionsBuyoutText:GetText(),
    postText = AuctionsCreateAuctionButton:GetText(),
    buyoutErrorShown = AuctionsBuyoutErrorText:IsShown(),
    tabTextPoints = SavePoints(AuctionsTabText),
    buyoutTextPoints = SavePoints(AuctionsBuyoutText),
    buyoutErrorTextPoints = SavePoints(AuctionsBuyoutErrorText),
    startPricePoints = SavePoints(StartPrice),
    buyoutPricePoints = SavePoints(BuyoutPrice),
    durationTextPoints = SavePoints(AuctionsDurationText),
    shortDurationPoints = SavePoints(AuctionsShortAuctionButton),
    mediumDurationPoints = SavePoints(AuctionsMediumAuctionButton),
    longDurationPoints = SavePoints(AuctionsLongAuctionButton),
    depositTextPoints = SavePoints(AuctionsDepositText),
    createOnClick = AuctionsCreateAuctionButton:GetScript("OnClick"),
  }

  -- Right-clicking the staged item icon should remove it from posting in
  -- both modes; the native slot otherwise only reacts to left-click.
  if AuctionsItemButton then
    local originalItemButtonOnClick = AuctionsItemButton:GetScript("OnClick")
    local originalItemButtonOnEnter = AuctionsItemButton:GetScript("OnEnter")
    local originalItemButtonOnLeave = AuctionsItemButton:GetScript("OnLeave")
    AuctionsItemButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    AuctionsItemButton:SetScript("OnClick", function(button, mouseButton, ...)
      if mouseButton == "RightButton" then
        ClearStagedAuctionItem()
      elseif originalItemButtonOnClick then
        originalItemButtonOnClick(button, mouseButton, ...)
      end
    end)
    AuctionsItemButton:HookScript("OnShow", function()
      if controller.mode == "listings" then
        SetPostingControlsShown(controller, false)
      end
    end)
    AuctionsItemButton:HookScript("OnShow", function()
      if controller.mode == "bid" or controller.mode == "buyout" then
        HideAuctionItemButtonCount()
      end
    end)
    AuctionsItemButton:SetScript("OnEnter", function(button, ...)
      if originalItemButtonOnEnter then
        originalItemButtonOnEnter(button, ...)
      end
      local item = GetSelectedItemInfo()
      if item and item.itemLink and GameTooltip then
        if not GameTooltip:IsShown() then
          GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
          GameTooltip:SetHyperlink(item.itemLink)
          GameTooltip:Show()
        end
        if Auctionator and Auctionator.Tooltip and
            Auctionator.Tooltip.ShowTipWithPricing then
          Auctionator.Tooltip.ShowTipWithPricing(GameTooltip, item.itemLink,
            item.count and item.count > 0 and item.count or 1)
        end
      end
    end)
    AuctionsItemButton:SetScript("OnLeave", function(button, ...)
      if originalItemButtonOnLeave then
        originalItemButtonOnLeave(button, ...)
      else
        GameTooltip:Hide()
      end
    end)
  end

  controller.ModeButton = CreateFrame("Button", nil, AuctionFrameAuctions)
  controller.ModeButton:SetPoint("CENTER", AuctionsTabText, "CENTER", 0, 0)
  controller.ModeButton:SetSize(180, 28)
  local function UpdateModeSwitchTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetScale(0.9)
    GameTooltip:ClearLines()
    if controller.mode == "listings" then
      GameTooltip:AddLine("Return to Posting", 0.2, 1, 0.2)
    else
      GameTooltip:AddLine("Switch to My Listings", 0.2, 1, 0.2)
    end
    GameTooltip:Show()
  end
  -- Above the results panel's level (+30) so its icons can't be drawn over
  -- by that panel's opaque background where the two frames' bounds overlap.
  controller.ModeButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 45)
  controller.ModeButton:SetScript("OnClick", function()
    SetMode(controller, controller.mode == "bid" and "buyout" or "bid")
  end)
  controller.ModeButton:SetScript("OnEnter", nil)
  controller.ModeButton:SetScript("OnLeave", nil)
  controller.original.modeButtonPoints = SavePoints(controller.ModeButton)

  -- Small icon on the left showing the current mode, and a static loop icon
  -- on the right hinting that the button toggles between modes. Anchored to
  -- the button's own edges (not the text) so they stay put as the label
  -- text length changes between modes.
  controller.ModeIcon = controller.ModeButton:CreateTexture(nil, "OVERLAY")
  controller.ModeIcon:SetSize(16, 16)
  controller.ModeIcon:SetPoint("LEFT", controller.ModeButton, "LEFT", 46, -1)

  -- Compact icon button for entering and leaving My Listings.
  controller.ModeToggleButton = CreateFrame(
    "Button", "LogisticianModeToggleButton", AuctionFrameAuctions, "UIPanelButtonTemplate"
  )
  controller.ModeToggleButton:SetSize(38, 24)
  -- Anchored to AuctionsTabText's ORIGINAL point tuple (not the live label),
  -- since Buyout Mode nudges the label itself; this keeps the button fixed
  -- regardless of mode.
  local tabAnchorPoint, tabAnchorRelativeTo, tabAnchorRelativePoint, tabAnchorX, tabAnchorY =
    unpack(controller.original.tabTextPoints[1])
  controller.ModeToggleButton:SetPoint(
    tabAnchorPoint, tabAnchorRelativeTo, tabAnchorRelativePoint,
    tabAnchorX + 60, tabAnchorY - 22
  )
  controller.ModeToggleButton:SetText("")
  controller.ModeToggleSwapIcon = controller.ModeToggleButton:CreateTexture(nil, "OVERLAY")
  controller.ModeToggleSwapIcon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
  controller.ModeToggleSwapIcon:SetSize(18, 18)
  controller.ModeToggleSwapIcon:SetPoint("CENTER", controller.ModeToggleButton, "CENTER", 0, 0)
  controller.ModeToggleSwapIcon:SetTexCoord(0, 1, 0, 1)
  controller.ModeToggleButton:SetScript("OnEnter", function()
    UpdateModeSwitchTooltip(controller.ModeToggleButton)
  end)
  controller.ModeToggleButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    GameTooltip:SetScale(1)
  end)
  controller.ModeToggleButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 45)
  -- The banner (ModeButton) still toggles Bid/Buyout; this button now
  -- toggles My Listings on and off, remembering the mode to return to.
  controller.ModeToggleButton:SetScript("OnClick", function()
    if controller.mode == "listings" then
      SetMode(controller, controller.lastBuyoutMode or "bid")
    else
      controller.lastBuyoutMode = controller.mode
      SetMode(controller, "listings")
    end
    if GameTooltip:IsOwned(controller.ModeToggleButton) then
      UpdateModeSwitchTooltip(controller.ModeToggleButton)
    end
  end)

  controller.ListingsSlotCover = CreateFrame(
    "Frame", nil, AuctionFrameAuctions, "BackdropTemplate"
  )
  controller.ListingsSlotCover:SetPoint("TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 24, -77)
  controller.ListingsSlotCover:SetSize(180, 77)
  controller.ListingsSlotCover:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 35)
  controller.ListingsSlotCover:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  controller.ListingsSlotCover:SetBackdropColor(0.70, 0.70, 0.70, 1)
  controller.ListingsSlotCover:SetBackdropBorderColor(0.32, 0.32, 0.32, 0.95)
  controller.ListingsSlotCover:EnableMouse(false)
  controller.ListingsSlotCover:Hide()

  controller.ListingsSearchTitle = controller.ListingsSlotCover:CreateFontString(
    nil, "ARTWORK", "GameFontHighlightSmall"
  )
  controller.ListingsSearchTitle:SetText("Search")
  controller.ListingsSearchTitle:SetTextColor(1, 1, 1, 1)

  controller.ListingsSearchBox = CreateFrame(
    "EditBox", "LogisticianListingsSearchBox", controller.ListingsSlotCover, "SearchBoxTemplate"
  )
  controller.ListingsSearchBox:SetSize(156, 22)
  controller.ListingsSearchBox:SetPoint("CENTER", controller.ListingsSlotCover, "CENTER", 0, -3)
  controller.ListingsSearchTitle:SetPoint(
    "BOTTOMLEFT", controller.ListingsSearchBox, "TOPLEFT", 2, 2
  )
  controller.ListingsSearchBox:SetAutoFocus(false)
  local instructions = controller.ListingsSearchBox.Instructions or
    _G["LogisticianListingsSearchBoxInstructions"]
  if instructions and instructions.SetText then
    instructions:SetText("")
  end
  if controller.ListingsSearchBox.SetHistoryLines then
    controller.ListingsSearchBox:SetHistoryLines(1)
  end
  if controller.ListingsSearchBox.SetMaxBytes then
    controller.ListingsSearchBox:SetMaxBytes(64)
  end
  controller.ListingsSearchBox:HookScript("OnTextChanged", function()
    if controller.mode == "listings" then
      if controller.listingsUndercutScanning then
        CancelListingsUndercutScan(controller)
      end
      if AuctionFrameAuctions_Update then
        AuctionFrameAuctions_Update()
      end
      ApplyListingsSearchFilter(controller)
    end
  end)

  controller.ListingsScanBlocker = CreateFrame("Frame", nil, AuctionFrameAuctions)
  controller.ListingsScanBlocker:SetPoint("TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 306, -104)
  controller.ListingsScanBlocker:SetPoint("BOTTOMRIGHT", AuctionFrameAuctions, "BOTTOMRIGHT", -48, 78)
  controller.ListingsScanBlocker:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 80)
  controller.ListingsScanBlocker:EnableMouse(true)
  controller.ListingsScanBlocker:Hide()

  local function GetListingResultMode(ownerIndex)
    local info = { GetAuctionItemInfo("owner", ownerIndex) }
    local startingBid = info[Auctionator.Constants.AuctionItemInfo.MinBid] or 0
    local buyoutPrice = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
    return buyoutPrice > 0 and startingBid == buyoutPrice and "buyout" or "bid"
  end

  local function ShowListingResults(row, mouseButton)
    if mouseButton ~= "LeftButton" or controller.mode ~= "listings" then
      return
    end
    local ownerIndex = GetListingsRowOwnerIndex(row)
    local itemLink = GetAuctionItemLink("owner", ownerIndex)
    if not itemLink then
      return
    end
    local ownerInfo = { GetAuctionItemInfo("owner", ownerIndex) }
    controller.detailsItemLink = itemLink
    controller.detailsBuyout = ownerInfo[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
    controller.detailsQuantity = ownerInfo[Auctionator.Constants.AuctionItemInfo.Quantity] or 0
    controller.detailsBidAmount = ownerInfo[Auctionator.Constants.AuctionItemInfo.BidAmount] or 0
    controller.detailsMinBid = ownerInfo[Auctionator.Constants.AuctionItemInfo.MinBid] or 0
    controller.detailsHighBidder = ownerInfo[Auctionator.Constants.AuctionItemInfo.Bidder]
    controller.listingsDetailsShown = true
    SetMode(controller, GetListingResultMode(ownerIndex))
    RefreshResults(controller, itemLink)
  end

  local function DetectListingsDoubleClick(row, mouseButton)
    if mouseButton ~= "LeftButton" or controller.mode ~= "listings" then
      return
    end
    local now = GetTime()
    if row.logisticianLastClick and now - row.logisticianLastClick <= 0.35 then
      row.logisticianLastClick = nil
      ShowListingResults(row, mouseButton)
    else
      row.logisticianLastClick = now
    end
  end

  local function SetupListingsRow(row)
    if not row then
      return
    end
    local itemButton = _G[(row:GetName() or "") .. "Item"]
    if itemButton and not itemButton.logisticianDoubleClickHooked then
      itemButton:HookScript("OnDoubleClick", function(_, mouseButton)
        ShowListingResults(row, mouseButton)
      end)
      itemButton.logisticianDoubleClickHooked = true
    end
    if not row.logisticianDoubleClickHooked then
      row:HookScript("OnDoubleClick", function(_, mouseButton)
        ShowListingResults(row, mouseButton)
      end)
      row:HookScript("OnMouseUp", function(_, mouseButton)
        DetectListingsDoubleClick(row, mouseButton)
      end)
      row.logisticianDoubleClickHooked = true
    end
    if itemButton and not itemButton.logisticianClickHooked then
      itemButton:HookScript("OnMouseUp", function(_, mouseButton)
        DetectListingsDoubleClick(row, mouseButton)
      end)
      itemButton.logisticianClickHooked = true
    end

    local function DisableChildMouse(frame)
      for _, child in ipairs({ frame:GetChildren() }) do
        if child ~= itemButton and child.EnableMouse then
          child:EnableMouse(false)
        end
        DisableChildMouse(child)
      end
    end
    DisableChildMouse(row)
  end

  local function SetupVisibleListingsRows()
    local rowIndex = 1
    while _G["AuctionsButton" .. rowIndex] do
      SetupListingsRow(_G["AuctionsButton" .. rowIndex])
      rowIndex = rowIndex + 1
    end
  end

  SetupVisibleListingsRows()

  if AuctionFrameAuctions_Update then
    hooksecurefunc("AuctionFrameAuctions_Update", function()
      SetupVisibleListingsRows()
      ApplyListingsSearchFilter(controller)
      if controller.ResultsPanel and controller.ResultsPanel:IsShown() then
        SetNativeResultsHidden(controller, true)
      end
    end)
  end

  controller.Stacks = CreateFrame(
    "Frame", nil, AuctionFrameAuctions, "AuctionatorStackOfInputTemplate"
  )
  controller.Stacks:ClearAllPoints()
  controller.Stacks:SetPoint("TOPLEFT", AuctionFrameAuctions, "TOPLEFT", 40, -355)
  controller.Stacks:SetSize(260, 40)
  controller.Stacks:SetScale(0.82)
  controller.Stacks:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 50)
  if controller.Stacks.MaxNumStacks then
    controller.Stacks.MaxNumStacks:Hide()
    controller.Stacks.MaxNumStacks:EnableMouse(false)
  end
  if controller.Stacks.MaxStackSize then
    controller.Stacks.MaxStackSize:Hide()
    controller.Stacks.MaxStackSize:EnableMouse(false)
  end
  controller.Stacks:Hide()

  controller.TotalLabel = AuctionFrameAuctions:CreateFontString(
    nil, "ARTWORK", "GameFontNormal"
  )
  controller.TotalLabel:SetText("Total Price")
  controller.TotalLabel:SetPoint("TOPLEFT", controller.Stacks, "BOTTOMLEFT", -5, -3)
  controller.TotalLabel:Hide()

  controller.TotalPrice = AuctionFrameAuctions:CreateFontString(
    nil, "ARTWORK", "GameFontHighlight"
  )
  controller.TotalPrice:SetPoint("LEFT", controller.TotalLabel, "RIGHT", 5, 0)
  SetStackedMoneyDisplay(controller.TotalPrice, 0)
  controller.TotalPrice:Hide()

  controller.BidTotalLabel = AuctionFrameAuctions:CreateFontString(
    nil, "ARTWORK", "GameFontNormal"
  )
  controller.BidTotalLabel:SetText("Total Price")
  controller.BidTotalLabel:Hide()

  controller.BidTotalPrice = AuctionFrameAuctions:CreateFontString(
    nil, "ARTWORK", "GameFontHighlight"
  )
  SetStackedMoneyDisplay(controller.BidTotalPrice, 0)
  controller.BidTotalPrice:Hide()

  controller.ListingsPendingIncomeLabel = AuctionFrameAuctions:CreateFontString(
    nil, "ARTWORK", "GameFontNormal"
  )
  controller.ListingsPendingIncomeLabel:SetText("Incoming:")
  controller.ListingsPendingIncomeLabel:SetPoint(
    "BOTTOMLEFT", AuctionFrameAuctions, "BOTTOMLEFT", 29, 70
  )
  controller.ListingsPendingIncomeLabel:Hide()

  controller.ListingsPendingIncomeValue = AuctionFrameAuctions:CreateFontString(
    nil, "ARTWORK", "GameFontHighlight"
  )
  controller.ListingsPendingIncomeValue:SetPoint(
    "LEFT", controller.ListingsPendingIncomeLabel, "RIGHT", 5, 0
  )
  controller.ListingsPendingIncomeValue:Hide()
  controller.ListingsUndercutButton = CreateFrame(
    "Button", nil, AuctionFrameAuctions, "UIPanelButtonTemplate"
  )
  controller.ListingsUndercutButton:SetAllPoints(AuctionsCreateAuctionButton)
  controller.ListingsUndercutButton:SetText("Check Undercut")
  controller.ListingsUndercutButton:SetFrameLevel(AuctionFrameAuctions:GetFrameLevel() + 45)
  controller.ListingsUndercutButton:SetScript("OnClick", function()
    if controller.listingsUndercutScanning then
      CancelListingsUndercutScan(controller)
    else
      if controller.listingsDetailsShown then
        SetMode(controller, "listings")
      end
      StartListingsUndercutScan(controller)
    end
  end)
  controller.ListingsUndercutButton:Hide()

  AuctionsCreateAuctionButton:SetScript("OnClick", function(button, ...)
    if controller.mode == "buyout" then
      PostBuyout(controller)
    elseif controller.mode == "bid" then
      PostBid(controller)
    elseif controller.original.createOnClick then
      MarkPendingPostedSearch(controller)
      controller.original.createOnClick(button, ...)
    end
  end)

  AuctionFrameAuctions:HookScript("OnShow", function()
    SetMode(controller, controller.mode or "buyout")
  end)
  AuctionFrameAuctions:HookScript("OnHide", function()
    if controller.listingsUndercutScanning then
      CancelListingsUndercutScan(controller)
    end
    if controller.ResultsPanel then
      controller.ResultsPanel:Hide()
      SetNativeResultsHidden(controller, false)
      controller.ResultsProvider:EndAnyQuery()
    end
  end)

  controller.ReceiveEvent = function(self, eventName, ...)
    if eventName == Auctionator.Buying.Events.HistoricalPrice then
      ApplyHistoryUnitPrice(self, ...)
    elseif eventName == Auctionator.AH.Events.ScanResultsUpdate and
        self.listingsUndercutScanning then
      ProcessListingsUndercutScanResults(self, ...)
    elseif eventName == Auctionator.AH.Events.ScanAborted and
        self.listingsUndercutScanning then
      MarkListingsCheckingUnknown(self)
      FinishListingsUndercutScan(self, "Check Undercut")
    elseif eventName == Auctionator.AH.Events.Ready and self.mode == "listings" and
        not self.listingsUndercutScanning then
      SetListingsUndercutButtonBusy(self, false, self.ListingsUndercutButton:GetText())
    end
  end
  Auctionator.EventBus:Register(controller, {
    Auctionator.Buying.Events.HistoricalPrice,
    Auctionator.AH.Events.ScanResultsUpdate,
    Auctionator.AH.Events.ScanAborted,
    Auctionator.AH.Events.Ready,
  })

  controller:RegisterEvent("NEW_AUCTION_UPDATE")
  controller:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
  controller:RegisterEvent("AUCTION_HOUSE_CLOSED")
  controller:RegisterEvent("CHAT_MSG_SYSTEM")
  controller:RegisterEvent("UI_ERROR_MESSAGE")
  controller:SetScript("OnEvent", function(_, eventName, ...)
    if eventName == "NEW_AUCTION_UPDATE" then
      local selectedItem = GetSelectedItemInfo()
      if selectedItem and controller.listingsDetailsShown then
        controller.stagedPostingItem = nil
        controller.listingsDetailsShown = false
        -- Leftover from whichever listing's detail view was open before
        -- staging - must be cleared or RenderResults' bidder-name fallback
        -- (matched against these) can misapply to the newly staged item.
        controller.detailsItemLink = nil
        controller.detailsBuyout = nil
        controller.detailsQuantity = nil
        controller.detailsBidAmount = nil
        controller.detailsMinBid = nil
        controller.detailsHighBidder = nil
        -- Detail view already runs in "buyout"/"bid" mode (whichever matched
        -- that listing), so SetMode here often sees no actual mode change
        -- and skips re-querying - RenderResults would then just redraw the
        -- OLD listing's still-cached search results (and seed StartPrice
        -- from them) instead of searching for the newly staged item. Force
        -- a fresh search explicitly instead of relying on SetMode's
        -- mode-change detection.
        SetMode(controller, "buyout")
        RefreshResults(controller)
        return
      end
      if controller.mode == "listings" then
        if selectedItem then
          if controller.listingsUndercutScanning then
            CancelListingsUndercutScan(controller)
          end
          controller.lastAuctionSlotItemKey = selectedItem.itemLink or
            tostring(selectedItem.itemID)
          PlayAuctionSlotItemCue(selectedItem)
          SetMode(controller, "buyout")
          return
        end
        SetPostingControlsShown(controller, false)
        SetListingsSlotCoverShown(controller, true)
        return
      end
      local selectedKey = selectedItem and
        (selectedItem.itemLink or tostring(selectedItem.itemID)) or nil
      if not selectedItem then
        ClearEmptyAuctionItemButtonCount()
      end
      if selectedKey ~= controller.lastAuctionSlotItemKey then
        if selectedItem then
          PlayAuctionSlotItemCue(selectedItem)
        end
        controller.lastAuctionSlotItemKey = selectedKey
      end

      if controller.mode == "buyout" then
        HideAuctionItemButtonCount()
        ClearStacksForNewItem(controller)
        if not controller.pendingPostedItemLink then
          if selectedItem then
            controller.preservePostedSearch = false
            RefreshResults(controller)
          elseif not controller.preservePostedSearch then
            RefreshResults(controller)
          end
        elseif not selectedItem then
          controller.preservePostedSearch = true
        end
      else
        if controller.mode == "bid" then
          ClearStacksForNewItem(controller)
        end
        UpdateBidModeResults(controller)
      end
    elseif eventName == "AUCTION_OWNED_LIST_UPDATE" then
      if controller.cancelPending then
        local remaining = CountMatchingOwnedAuctions(controller.cancelPending.result)
        if remaining < controller.cancelPending.beforeCount then
          controller.cancelPending.ownerCountDecreased = true
        else
          GetOwnerAuctionItems(0)
        end
        TryFinishCancellation(controller)
      elseif controller.ResultsPanel and controller.ResultsPanel:IsShown() and
          (controller.pendingPostedItemLink or controller.pendingPostedItemID or
          controller.pendingPostedItemName) then
        TryRefreshPendingPostedSearch(controller)
      elseif controller.mode == "listings" then
        ApplyListingsSearchFilter(controller)
        UpdateListingsPendingIncome(controller)
        AugmentListingsUndercutScanQueue(controller)
      elseif controller.mode == "bid" and controller.ResultsPanel and
          controller.ResultsPanel:IsShown() and
          controller.ResultsProvider.searchKey then
        controller.ResultsProvider:PopulateAuctions()
        RenderResults(controller)
      end
    elseif eventName == "AUCTION_HOUSE_CLOSED" then
      if controller.listingsUndercutScanning then
        controller.listingsUndercutScanning = false
        Auctionator.AH.AbortQuery()
      end
      ClearListingsUndercutStatusCache(controller)
      SetListingsUndercutButtonBusy(controller, false, "Check Undercut")
    elseif eventName == "CHAT_MSG_SYSTEM" then
      local message = ...
      if message == ERR_AUCTION_REMOVED then
        PlayAuctionCancelCue()
        if controller.cancelPending then
          controller.cancelPending.removalConfirmed = true
          GetOwnerAuctionItems(0)
          TryFinishCancellation(controller)
        end
      end
    elseif eventName == "UI_ERROR_MESSAGE" and controller.cancelPending then
      FinishCancelWaiting(controller)
    end
  end)
  controller:SetScript("OnUpdate", function(_, elapsed)
    if AuctionFrameAuctions:IsShown() then
      UpdateBuyoutPanel(controller)
      UpdateBidPanel(controller)
      UpdateBidModeResults(controller)
      UpdateItemNameQualityColor()
      UpdateCancelButton(controller)
      if controller.mode == "bid" or controller.mode == "buyout" then
        HideAuctionItemButtonCount()
      end
      if controller.listingsUndercutScanning then
        controller.listingsUndercutDotsElapsed =
          (controller.listingsUndercutDotsElapsed or 0) + (elapsed or 0)
        if controller.listingsUndercutDotsElapsed >= 0.35 then
          controller.listingsUndercutDotsElapsed = 0
          controller.listingsUndercutDots = ((controller.listingsUndercutDots or 0) % 3) + 1
          controller.listingsUndercutCheckingText =
            "Checking" .. string.rep(".", controller.listingsUndercutDots)
          controller.listingsUndercutBlinkAlpha =
            controller.listingsUndercutBlinkAlpha == 1 and 0.25 or 1
          ApplyListingsUndercutStatus(controller)
        end
      end
    end
  end)

  SetMode(controller, "buyout")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, addonName)
  if addonName == "Blizzard_AuctionUI" then
    C_Timer.After(0, Initialize)
  end
end)

local function IsAuctionUILoaded()
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded("Blizzard_AuctionUI")
  elseif type(IsAddOnLoaded) == "function" then
    return IsAddOnLoaded("Blizzard_AuctionUI")
  end
  return false
end

if IsAuctionUILoaded() then
  C_Timer.After(0, Initialize)
end
