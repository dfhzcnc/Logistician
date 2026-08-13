local tabPadding = 0
local tabAbsoluteSize = nil
local minTabWidth = 36

LogisticianTabContainerMixin = {}

local function InitializeFromDetails(details)
  local frame = CreateFrame(
    "BUTTON",
    "AuctionFrameTab" .. (AuctionFrame.numTabs + 1),
    AuctionFrame,
    "LogisticianTabButtonTemplate"
  )
  local frameName = "LogisticianTabs_" .. details.name
  _G[frameName] = frame

  frame:SetText(details.textLabel)

  frame:Initialize(details.name, details.tabTemplate, details.tabHeader, {details.tabFrameName})
  PanelTemplates_TabResize(frame, tabPadding, tabAbsoluteSize, minTabWidth)

  return frame
end

function LogisticianTabContainerMixin:OnLoad()
  Logistician.Debug.Message("LogisticianTabContainerMixin:OnLoad()")

  -- Tabs are sorted to avoid inconsistent ordering based on the addon loading
  -- order
  table.sort(
    Logistician.Tabs.State.knownTabs,
    function(left, right)
      return left.tabOrder < right.tabOrder
    end
  )

  self.Tabs = {}

  for _, details in ipairs(Logistician.Tabs.State.knownTabs) do
    table.insert(self.Tabs, InitializeFromDetails(details))
  end

  self:HookTabs()
end

function LogisticianTabContainerMixin:OnShow()
end

function LogisticianTabContainerMixin:OnHide()
  for _, logisticianTab in pairs(self.Tabs) do
    logisticianTab:DeselectTab()
  end
end

function LogisticianTabContainerMixin:IsLogisticianFrame(tab)
  for _, frame in pairs(self.Tabs) do
    if frame == tab then
      return true
    end
  end

  return false
end

function LogisticianTabContainerMixin:HookTabs()
  hooksecurefunc(_G, "AuctionFrameTab_OnClick", function(tabButton, ...)
    for _, tab in ipairs(self.Tabs) do
      tab:DeselectTab()
    end

    local isLogisticianFrame = self:IsLogisticianFrame(tabButton)
    if isLogisticianFrame then
      tabButton:Selected()
    end
  end)
end
