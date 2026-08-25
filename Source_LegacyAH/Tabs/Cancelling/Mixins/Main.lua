AuctionatorCancellingFrameMixin = {}

function AuctionatorCancellingFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorCancellingFrameMixin:OnLoad()")

  self.ResultsListing:SetScrollBarOffsetX(0)
  self.ResultsListing:Init(self.DataProvider)

  Auctionator.EventBus:Register(self, {
    Auctionator.Cancelling.Events.RequestCancel,
    Auctionator.Cancelling.Events.ShowDetail,
    Auctionator.Cancelling.Events.TotalUpdated,
    Auctionator.Buying.Events.ViewSetup,
  })

  self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")

  self.SearchFilter:HookScript("OnTextChanged", function()
    self.DataProvider:NoQueryRefresh()
  end)

  self:SetScript("OnUpdate", self.OnUpdate)
end

local function SetOverviewShown(self, shown)
  self.SearchFilter:SetShown(shown)
  self.ResultsListing:SetShown(shown)
  self.HistoricalPriceInset:SetShown(shown)
  self.UndercutScanContainer:SetShown(shown)
  self.Total:SetShown(shown)
end

local OWNED_LIST_ROW_HEIGHT = 28
local OWNED_LIST_MAX_ROWS = 24

function AuctionatorCancellingFrameMixin:CreateOwnedListPanel()
  if self.DetailOwnedList then
    return
  end

  local panel = CreateFrame("Frame", nil, self, "AuctionatorInsetTemplate")
  self.DetailOwnedList = panel
  panel:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -102)
  panel:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 0)
  panel:SetWidth(300)
  panel:Hide()

  panel.Title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
  panel.Title:SetText("Current Listings")
  panel.Title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)

  panel.Scroll = CreateFrame("ScrollFrame", nil, panel, "FauxScrollFrameTemplate")
  panel.Scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -38)
  panel.Scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 8)
  panel.Scroll:SetScript("OnVerticalScroll", function(scroll, offset)
    FauxScrollFrame_OnVerticalScroll(scroll, offset, OWNED_LIST_ROW_HEIGHT, function()
      self:RefreshOwnedListPanel()
    end)
  end)

  panel.Rows = {}
  for index = 1, OWNED_LIST_MAX_ROWS do
    local row = CreateFrame("Button", nil, panel)
    panel.Rows[index] = row
    row:SetHeight(OWNED_LIST_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -38 - (index - 1) * OWNED_LIST_ROW_HEIGHT)
    row:SetPoint("RIGHT", panel, "RIGHT", -30, 0)

    row.Stripe = row:CreateTexture(nil, "BACKGROUND")
    row.Stripe:SetAtlas("auctionhouse-rowstripe-1")
    row.Stripe:SetAllPoints()

    row.Highlight = row:CreateTexture(nil, "ARTWORK")
    row.Highlight:SetAtlas("auctionhouse-ui-row-highlight")
    row.Highlight:SetBlendMode("ADD")
    row.Highlight:SetAllPoints()
    row.Highlight:Hide()

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(22, 22)
    row.Icon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 7, 0)
    row.Name:SetPoint("RIGHT", row, "RIGHT", -96, 0)
    row.Name:SetJustifyH("LEFT")

    row.Quantity = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.Quantity:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    row.Quantity:SetJustifyH("RIGHT")

    row.Status = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.Status:SetWidth(38)
    row.Status:SetPoint("RIGHT", row, "RIGHT", -49, 0)
    row.Status:SetJustifyH("CENTER")

    row:SetScript("OnClick", function(button)
      if button.auctionData and not button.auctionData.isSold then
        self:ShowDetail(button.auctionData)
      end
    end)
    row:SetScript("OnEnter", function(button)
      if button.auctionData and button.auctionData.itemLink then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(button.auctionData.itemLink)
        if button.auctionData.isSold then
          GameTooltip:AddLine("Sold", 0.65, 0.65, 0.65)
        elseif button.auctionData.undercutStatus == true then
          GameTooltip:AddLine("Undercut", 1, 0.2, 0.1)
        elseif button.auctionData.undercutStatus == false then
          GameTooltip:AddLine("Not undercut", 0.2, 1, 0.2)
        else
          GameTooltip:AddLine("Undercut status unknown", 0.65, 0.65, 0.65)
        end
        GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  panel:SetScript("OnSizeChanged", function()
    self:RefreshOwnedListPanel()
  end)
end

function AuctionatorCancellingFrameMixin:GetOwnedListItems()
  local byItem = {}
  local knownStatuses = {}
  for _, result in ipairs(self.DataProvider.results or {}) do
    local cleanLink = Auctionator.Search.GetCleanItemLink(result.itemLink)
    if result.undercut == AUCTIONATOR_L_UNDERCUT_YES then
      knownStatuses[cleanLink] = true
    elseif result.undercut == AUCTIONATOR_L_UNDERCUT_NO and knownStatuses[cleanLink] == nil then
      knownStatuses[cleanLink] = false
    end
  end
  for cleanLink, status in pairs(self.detailUndercutStatuses or {}) do
    knownStatuses[cleanLink] = status
  end
  for _, auction in ipairs(Auctionator.AH.DumpAuctions("owner")) do
    local itemLink = auction.itemLink
    if itemLink then
      local info = auction.info
      local cleanLink = Auctionator.Search.GetCleanItemLink(itemLink)
      local isSold = info[Auctionator.Constants.AuctionItemInfo.SaleStatus] == 1
      local entry = byItem[cleanLink]
      if entry then
        entry.numStacks = entry.numStacks + 1
        entry.isSold = entry.isSold and isSold
      else
        entry = {
          itemLink = itemLink,
          numStacks = 1,
          stackSize = info[Auctionator.Constants.AuctionItemInfo.Quantity],
          stackPrice = info[Auctionator.Constants.AuctionItemInfo.Buyout],
          bidAmount = info[Auctionator.Constants.AuctionItemInfo.BidAmount],
          undercutStatus = knownStatuses[cleanLink],
          isSold = isSold,
        }
        byItem[cleanLink] = entry
      end
    end
  end

  local items = {}
  for _, entry in pairs(byItem) do
    table.insert(items, entry)
  end
  table.sort(items, function(left, right)
    return Auctionator.Utilities.GetNameFromLink(left.itemLink):lower()
      < Auctionator.Utilities.GetNameFromLink(right.itemLink):lower()
  end)
  return items
end

function AuctionatorCancellingFrameMixin:RefreshOwnedListPanel()
  local panel = self.DetailOwnedList
  if not panel or not panel:IsShown() then
    return
  end

  local items = self:GetOwnedListItems()
  local visibleRows = math.max(1, math.min(OWNED_LIST_MAX_ROWS,
    math.floor((panel:GetHeight() - 46) / OWNED_LIST_ROW_HEIGHT)))
  FauxScrollFrame_Update(panel.Scroll, #items, visibleRows, OWNED_LIST_ROW_HEIGHT)
  local offset = FauxScrollFrame_GetOffset(panel.Scroll)
  local selectedLink = self.detailAuctionData and
    Auctionator.Search.GetCleanItemLink(self.detailAuctionData.itemLink)

  for index, row in ipairs(panel.Rows) do
    local entry = index <= visibleRows and items[offset + index] or nil
    row.auctionData = entry
    row:SetShown(entry ~= nil)
    if entry then
      row:SetEnabled(not entry.isSold)
      row:SetAlpha(entry.isSold and 0.45 or 1)
      row.Icon:SetTexture(select(10, GetItemInfo(entry.itemLink)))
      row.Name:SetText(entry.itemLink)
      row.Quantity:SetText("x" .. entry.numStacks)
      if entry.isSold then
        row.Status:SetText("Sold")
        row.Status:SetTextColor(0.65, 0.65, 0.65)
      elseif entry.undercutStatus == true then
        row.Status:SetText("!")
        row.Status:SetTextColor(1, 0.2, 0.1)
      elseif entry.undercutStatus == false then
        row.Status:SetText("OK")
        row.Status:SetTextColor(0.2, 1, 0.2)
      else
        row.Status:SetText("?")
        row.Status:SetTextColor(0.65, 0.65, 0.65)
      end
      row.Highlight:SetShown(
        selectedLink == Auctionator.Search.GetCleanItemLink(entry.itemLink)
      )
    end
  end
end

function AuctionatorCancellingFrameMixin:UpdateDetailUndercutStatus()
  local prices = self.DetailView and self.DetailView.CurrentPrices
  local provider = prices and prices.SearchDataProvider
  if not self.detailAuctionData or not provider or not provider:HasAllQueriedResults() then
    return
  end

  local cleanLink = Auctionator.Search.GetCleanItemLink(self.detailAuctionData.itemLink)
  local playerName = GetUnitName("player")
  local itemsAhead = 0
  local foundOwnedAuction = false
  local isUndercut = false
  local allowedAhead = Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_ITEMS_AHEAD) or 0
  local ownedPositions = {}

  -- allAuctions is sorted by unit price when the detail scan is populated.
  for _, auction in ipairs(provider.allAuctions or {}) do
    local info = auction.info
    local quantity = info[Auctionator.Constants.AuctionItemInfo.Quantity] or 0
    local buyout = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
    local owner = tostring(info[Auctionator.Constants.AuctionItemInfo.Owner])
    if buyout > 0 then
      if owner == playerName then
        foundOwnedAuction = true
        local unitPrice = Auctionator.Utilities.ToUnitPrice(auction)
        if ownedPositions[unitPrice] == nil then
          ownedPositions[unitPrice] = itemsAhead
        end
      end
      itemsAhead = itemsAhead + quantity
    end
  end

  for _, position in pairs(ownedPositions) do
    if position > allowedAhead then
      isUndercut = true
      break
    end
  end

  if foundOwnedAuction then
    self.detailUndercutStatuses = self.detailUndercutStatuses or {}
    self.detailUndercutStatuses[cleanLink] = isUndercut
    self:RefreshOwnedListPanel()
  end
end

function AuctionatorCancellingFrameMixin:CreateDetailView()
  if self.DetailView then
    return
  end

  local detail = CreateFrame("Frame", nil, self, "AuctionatorBuyFrameTemplate")
  self.DetailView = detail
  detail:SetPoint("TOPLEFT", self, "TOPLEFT", 314, -102)
  detail:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 0)
  detail:Init()
  detail:Hide()
  detail.HistoryButton:Hide()
  detail.HistoryPrices:Hide()

  local prices = detail.CurrentPrices
  prices.SearchDataProvider:SetAutoSelectResults(false)
  prices.SearchResultsListing:UseLoadingDots()
  prices.BuyButton:Hide()
  prices.CancelButton:SetText("Cancel")

  prices.CancelButton:ClearAllPoints()
  prices.CancelButton:SetWidth(130)
  prices.CancelButton:SetPoint("BOTTOMRIGHT", prices, "BOTTOMRIGHT", -8, -22)
  prices.RefreshButton:ClearAllPoints()
  prices.RefreshButton:SetWidth(130)
  prices.RefreshButton:SetPoint("BOTTOMRIGHT", prices.CancelButton, "BOTTOMLEFT", 0, 0)
  prices.CancelButton:SetScript("OnClick", function()
    self:CancelOneSelected()
  end)

  local baseUpdateButtons = prices.UpdateButtons
  prices.UpdateButtons = function(frame)
    baseUpdateButtons(frame)
    local selected = frame.selectedAuctionData
    frame.CancelButton:SetEnabled(selected ~= nil
      and selected.isOwned
      and selected.numStacks > 0
      and selected.bidAmount == 0
      and Auctionator.AH.IsNotThrottled())
  end

  self.DetailBackButton = CreateFrame("Button", nil, self, "UIPanelDynamicResizeButtonTemplate")
  self.DetailBackButton:SetText(BACK)
  self.DetailBackButton:SetSize(100, 24)
  self.DetailBackButton:SetPoint("TOPLEFT", self, "TOPLEFT", 63, -59)
  self.DetailBackButton:SetScript("OnClick", function()
    self:HideDetail()
  end)
  self.DetailBackButton:Hide()

  self.DetailIcon = self:CreateTexture(nil, "ARTWORK")
  self.DetailIcon:SetSize(40, 40)
  self.DetailIcon:SetPoint("TOPLEFT", self, "TOPLEFT", 340, -51)
  self.DetailIcon:Hide()

  self.DetailName = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
  self.DetailName:SetPoint("LEFT", self.DetailIcon, "RIGHT", 10, 0)
  self.DetailName:SetPoint("RIGHT", self, "RIGHT", -20, 0)
  self.DetailName:SetJustifyH("LEFT")
  self.DetailName:Hide()

  self:CreateOwnedListPanel()
end

function AuctionatorCancellingFrameMixin:ShowDetail(auctionData)
  self:CreateDetailView()
  self.detailAuctionData = auctionData

  if self.SearchFilter:GetText() ~= "" then
    self.SearchFilter:SetText("")
  end
  SetOverviewShown(self, false)
  self.DetailOwnedList:Show()
  self:RefreshOwnedListPanel()
  self.DetailBackButton:Show()
  self.DetailIcon:SetTexture(select(10, GetItemInfo(auctionData.itemLink)))
  self.DetailIcon:Show()
  self.DetailName:SetText(auctionData.itemLink or Auctionator.Utilities.GetNameFromLink(auctionData.itemLink))
  self.DetailName:Show()
  self.DetailView:Show()
  self.DetailView:Reset()

  local prices = self.DetailView.CurrentPrices
  prices.SearchDataProvider:SetAutoSelectResults(false)
  prices.SearchDataProvider:SetIgnoreItemSuffix(false)
  prices.SearchDataProvider:SetQuery(auctionData.itemLink, function()
    prices.SearchDataProvider:SetRequestAllResults(true)
    prices.SearchDataProvider:RefreshQuery()
  end)
  prices.RefreshButton:Enable()
  prices:UpdateButtons()
end

function AuctionatorCancellingFrameMixin:HideDetail()
  self.detailAuctionData = nil
  if self.DetailView then
    self.DetailView:Reset()
    self.DetailView:Hide()
    self.DetailBackButton:Hide()
    self.DetailIcon:Hide()
    self.DetailName:Hide()
    self.DetailOwnedList:Hide()
  end
  SetOverviewShown(self, true)
  self.DataProvider:NoQueryRefresh()
end

function AuctionatorCancellingFrameMixin:CancelOneSelected()
  local prices = self.DetailView and self.DetailView.CurrentPrices
  local selected = prices and prices.selectedAuctionData
  if selected and selected.isOwned and selected.numStacks > 0
      and selected.bidAmount == 0 and Auctionator.AH.IsNotThrottled() then
    prices:CancelFocussed()
  end
end

function AuctionatorCancellingFrameMixin:OnShow()
  if self.DetailView then
    self:HideDetail()
  end
end

function AuctionatorCancellingFrameMixin:OnHide()
  if self.DetailView then
    self.DetailView.CurrentPrices.SearchDataProvider:EndAnyQuery()
  end
end

function AuctionatorCancellingFrameMixin:OnEvent(eventName)
  if eventName == "AUCTION_OWNED_LIST_UPDATE" then
    self.DataProvider:NoQueryRefresh()
    self:RefreshOwnedListPanel()
    if self.DetailView and self.DetailView:IsShown() then
      self.DetailView.CurrentPrices.SearchDataProvider:PurgeAndReplaceOwnedAuctions(
        Auctionator.AH.DumpAuctions("owner")
      )
      self.DetailView.CurrentPrices:UpdateButtons()
    end
  end
end

function AuctionatorCancellingFrameMixin:OnUpdate()
  GetOwnerAuctionItems(0)
end

local ConfirmBidPricePopup = "AuctionatorConfirmBidPricePopupDialog"

StaticPopupDialogs[ConfirmBidPricePopup] = {
  text = AUCTIONATOR_L_BID_EXISTING_ON_OWNED_AUCTION,
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function(self)
    Auctionator.AH.CancelAuction(self.data)
    Auctionator.EventBus:RegisterSource(self, "CancellingFramePopupDialog")
      :Fire(self, Auctionator.Cancelling.Events.CancelConfirmed, self.data)
      :UnregisterSource(self)
  end,
  hasMoneyFrame = 1,
  showAlert = 1,
  timeout = 0,
  exclusive = 1,
  hideOnEscape = 1
}

function AuctionatorCancellingFrameMixin:IsAuctionShown(auctionInfo)
  local searchString = self.SearchFilter:GetText()
  if searchString ~= "" then
    local exact = searchString:match("^\"(.*)\"$")
    local name = string.lower(Auctionator.Utilities.GetNameFromLink(auctionInfo.itemLink))
    if exact then
      return name == exact
    else
      return string.find(name, string.lower(searchString), 1, true)
    end
  else
    return true
  end
end

function AuctionatorCancellingFrameMixin:ReceiveEvent(eventName, ...)
  if eventName == Auctionator.Buying.Events.ViewSetup then
    if self.DetailView and self.DetailView:IsShown() then
      self:UpdateDetailUndercutStatus()
    end

  elseif eventName == Auctionator.Cancelling.Events.ShowDetail then
    self:ShowDetail(...)

  elseif eventName == Auctionator.Cancelling.Events.RequestCancel then
    local auctionData = ...
    Auctionator.Debug.Message("Executing cancel request", auctionData)

    -- Prevent cancelling auctions which someone has bid on
    local cancelCost = math.floor((auctionData.bidAmount * AUCTION_CANCEL_COST) / 100)
    if cancelCost > 0 then
      local dialog = StaticPopup_Show(ConfirmBidPricePopup)
      if dialog then
        dialog.data = auctionData
        MoneyFrame_Update(dialog.moneyFrame, cancelCost);
      end
    else
      Auctionator.AH.CancelAuction(auctionData)
      Auctionator.EventBus:RegisterSource(self, "CancellingFrame")
        :Fire(self, Auctionator.Cancelling.Events.CancelConfirmed, auctionData)
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)

  elseif eventName == Auctionator.Cancelling.Events.TotalUpdated then
    local totalOnSale, totalPending = ...

    local text = AUCTIONATOR_L_TOTAL_ON_SALE:format(
        GetMoneyString(totalOnSale, true)
      )
    if totalPending > 0 then
      text = text .. " " ..
      AUCTIONATOR_L_TOTAL_PENDING:format(
        GetMoneyString(totalPending, true)
      )
    end

    self.Total:SetText(text)
  end
end
