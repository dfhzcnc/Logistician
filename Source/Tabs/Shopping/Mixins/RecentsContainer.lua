LogisticianShoppingTabRecentsContainerMixin = {}

local listHeaderInset = 10
local buttonSpacing = 60
local buttonHeight = 20

function LogisticianShoppingTabRecentsContainerMixin:SetOnSearchRecent(func)
  self.onSearchRecent = func
end

function LogisticianShoppingTabRecentsContainerMixin:SetOnDeleteRecent(func)
  self.onDeleteRecent = func
end

function LogisticianShoppingTabRecentsContainerMixin:SetOnCopyRecent(func)
  self.onCopyRecent = func
end

function LogisticianShoppingTabRecentsContainerMixin:TemporarilySelectSearchTerm(searchTerm)
  self.ScrollBox:ForEachFrame(function(frame)
    frame.Selected:SetShown(frame.elementData == searchTerm)
  end)
end

function LogisticianShoppingTabRecentsContainerMixin:OnLoad()
  self:SetupContent()

  if self:IsVisible() then
    self:Populate()
  end
end

function LogisticianShoppingTabRecentsContainerMixin:OnShow()
  self:Populate()

  Logistician.EventBus:Register(self, {
    Logistician.Shopping.Events.RecentSearchesUpdate
  })
end

function LogisticianShoppingTabRecentsContainerMixin:OnHide()
  Logistician.EventBus:Unregister(self, {
    Logistician.Shopping.Events.RecentSearchesUpdate
  })
end

function LogisticianShoppingTabRecentsContainerMixin:ReceiveEvent(eventName, eventData)
  if eventName == Logistician.Shopping.Events.RecentSearchesUpdate then
    self:Populate()
  end
end

function LogisticianShoppingTabRecentsContainerMixin:SetupContent()
  local function OnClick(button)
    if self.onSearchRecent then
      self.onSearchRecent(button.elementData)
    end
  end

  local function OnEnter(button)
    button.Highlight:Show()
    GameTooltip:SetOwner(button, "ANCHOR_NONE")
    Logistician.Shopping.Tab.ComposeSearchTermTooltip(button.elementData)
    GameTooltip:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT")
    GameTooltip:Show()
  end

  local function OnLeave(button)
    button.Highlight:Hide()
    GameTooltip:Hide()
  end

  local function OnRecentDeleteOptionClicked(button)
    button = button:GetParent()
    if self.onDeleteRecent then
      self.onDeleteRecent(button.elementData)
    end
  end

  local function OnRecentCopyOptionClicked(button)
    button = button:GetParent()
    if self.onCopyRecent then
      self.onCopyRecent(button.elementData)
    end
  end

  local function SetupButton(button)
    button.setup = true
    Logistician.Shopping.Tab.SetupContainerRow(button, buttonHeight, buttonSpacing)
    button.Text:SetPoint("LEFT", listHeaderInset, 0)

    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnClick", OnClick)

    button.options1 = Logistician.Shopping.Tab.CreateOptionButton(button, 0, buttonHeight + 5, buttonHeight)
    button.options2 = Logistician.Shopping.Tab.CreateOptionButton(button, -buttonHeight - 5, buttonHeight + 5, buttonHeight)

    Logistician.Shopping.Tab.SetOptionIcon(button.options1, "delete")
    button.options1:SetScript("OnClick", OnRecentDeleteOptionClicked)
    button.options1.TooltipText = LOGISTICIAN_L_DELETE

    Logistician.Shopping.Tab.SetOptionIcon(button.options2, "copy")
    button.options2:SetScript("OnClick", OnRecentCopyOptionClicked)
    button.options2.TooltipText = LOGISTICIAN_L_COPY_TO_LIST
  end

  self.Inset = CreateFrame("Frame", nil, self, "LogisticianInsetTemplate")
  self.Inset:SetAllPoints()

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  self.ScrollBox:SetPoint("TOPLEFT", 0, -2)
  self.ScrollBox:SetPoint("BOTTOMRIGHT", 0, 2)

  self.ScrollBar = CreateFrame("EventFrame", nil, self, "WowTrimScrollBar")
  self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT")
  self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT")

  local function OnButtonAcquire(button, elementData)
    if not button.setup then
      SetupButton(button)
    end
    button.elementData = elementData
    button.Text:SetText(Logistician.Search.PrettifySearchString(elementData))
    button.Selected:Hide()
  end

  local view = CreateScrollBoxListLinearView(0, 0, 0, 0)
  view:SetElementExtent(buttonHeight)
  view:SetElementInitializer("Button", OnButtonAcquire)
  view:SetPanExtent(50)

  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
end

function LogisticianShoppingTabRecentsContainerMixin:Populate()
  local rows = {}

  for _, recent in ipairs(Logistician.Shopping.Recents.GetAll()) do
    table.insert(rows, recent)
  end
  self.ScrollBox:SetDataProvider(CreateDataProvider(rows), true)
end
