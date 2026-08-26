AuctionatorConfigTabMixin = {}

function AuctionatorConfigTabMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigTabMixin:OnLoad()")

  -- Logistician has one author and a donation section. Community engagement
  -- and translator sections are intentionally omitted until they are used.
  self.ContributorsHeading:Hide()
  self.Contributors:Hide()
  self.ContributeHeading:Show()
  self.ContributeLink:Show()
  self.EngageHeading:Hide()
  self.DiscordLink:Hide()
  self.BugReportLink:Hide()
  self.TranslatorsHeading:Hide()

  for _, key in ipairs({
    "deDE", "ptBR", "zhCN", "zhTW", "esES", "esMX", "frFR",
    "itIT", "koKR", "ruRU", "tkTK", "roRO",
  }) do
    if self[key] then
      self[key]:Hide()
    end
  end

  -- Debug shortcut only appears while debug capture is enabled; stays in
  -- sync with the Settings panel's Enable/Disable Debug button. Anchored up
  -- by AuctionFrame's own close button (top-right of the whole AH window),
  -- not the Logistician tab's own option buttons - Anchors can reference any
  -- named frame regardless of parent/child relationship. Reparented to
  -- AuctionFrame directly (it's created as a child of this tab's own
  -- content frame in XML) so it stays visible across ALL AH tabs, not just
  -- Logistician - the tab content frame gets hidden on tab switches, but
  -- AuctionFrame itself never does. Anchored by CENTER (not an edge) so
  -- resizing the button in XML never shifts its visual position - offsets
  -- below are the CENTER-equivalent of the old edge-anchored position at
  -- the button's original 28x28 size, nudged 12px further right per request.
  local debugButton = self.DebugButton
  debugButton:SetParent(AuctionFrame or self)
  debugButton:ClearAllPoints()
  local closeButton = AuctionFrame and (AuctionFrame.CloseButton or _G["AuctionFrameCloseButton"])
  if closeButton then
    debugButton:SetPoint("CENTER", closeButton, "LEFT", -8, 0)
  elseif AuctionFrame then
    debugButton:SetPoint("CENTER", AuctionFrame, "TOPRIGHT", -42, -22)
  else
    debugButton:SetPoint("CENTER", self.OptionsButton, "TOPLEFT", -5, -14)
  end
  Auctionator.Debug.RegisterUIRefreshHandler(function()
    debugButton:SetShown(Auctionator.Debug.IsOn())
  end)
  debugButton:SetShown(Auctionator.Debug.IsOn())
end

function AuctionatorConfigTabMixin:OpenOptions()
  Settings.OpenToCategory(Auctionator.State.OptionsCategory:GetID())
end

function AuctionatorConfigTabMixin:OpenDebugViewer()
  Auctionator.Debug.ShowViewer()
end
