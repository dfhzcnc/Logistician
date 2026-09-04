local tabPadding = 0
local tabAbsoluteSize = nil
local minTabWidth = 36

AuctionatorTabContainerMixin = {}

local function InitializeFromDetails(details)
  local frame = CreateFrame(
    "BUTTON",
    "AuctionFrameTab" .. (AuctionFrame.numTabs + 1),
    AuctionFrame,
    "AuctionatorTabButtonTemplate"
  )
  local frameName = "AuctionatorTabs_" .. details.name
  _G[frameName] = frame

  frame:SetText(details.textLabel)

  frame:Initialize(details.name, details.tabTemplate, details.tabHeader, {details.tabFrameName})
  PanelTemplates_TabResize(frame, tabPadding, tabAbsoluteSize, minTabWidth)

  -- Some tabs are only meant to be reached via another entry point (e.g. a button elsewhere)
  -- rather than shown in the tab bar - their content frame still gets created normally above,
  -- :Click() still works programmatically on a hidden button, it just isn't visible/clickable
  -- by the player directly.
  if details.hiddenTab then
    frame:Hide()
  end

  return frame
end

function AuctionatorTabContainerMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorTabContainerMixin:OnLoad()")

  -- Tabs are sorted to avoid inconsistent ordering based on the addon loading
  -- order
  table.sort(
    Auctionator.Tabs.State.knownTabs,
    function(left, right)
      return left.tabOrder < right.tabOrder
    end
  )

  self.Tabs = {}

  for _, details in ipairs(Auctionator.Tabs.State.knownTabs) do
    table.insert(self.Tabs, InitializeFromDetails(details))
  end

  self:HookTabs()
end

function AuctionatorTabContainerMixin:OnShow()
end

function AuctionatorTabContainerMixin:OnHide()
  for _, auctionatorTab in pairs(self.Tabs) do
    auctionatorTab:DeselectTab()
  end
end

function AuctionatorTabContainerMixin:IsAuctionatorFrame(tab)
  for _, frame in pairs(self.Tabs) do
    if frame == tab then
      return true
    end
  end

  return false
end

function AuctionatorTabContainerMixin:HookTabs()
  hooksecurefunc(_G, "AuctionFrameTab_OnClick", function(tabButton, ...)
    for _, tab in ipairs(self.Tabs) do
      tab:DeselectTab()
    end

    local isAuctionatorFrame = self:IsAuctionatorFrame(tabButton)
    if isAuctionatorFrame then
      tabButton:Selected()
    end
  end)
end
