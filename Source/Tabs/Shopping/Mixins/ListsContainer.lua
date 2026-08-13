-- Shows all Auctionator shopping lists and their search terms, and includes
-- buttons to register a callback to (for example) do search, edit and delete
-- commands
AuctionatorShoppingTabListsContainerMixin = {}

RowType = {
  List = "list header",
  SearchTerm = "list entry",
  Empty = "list empty",
}

local listHeaderInset = 10
local listEntryInset = 30
local buttonSpacing = 60
local buttonHeight = 20
local draggingTermAlpha = 0.5

local CATEGORY_ICONS = {
  Weapons = "Interface\\Icons\\INV_Sword_04",
  Armor = "Interface\\Icons\\INV_Chest_Chain",
  Container = "Interface\\Icons\\INV_Misc_Bag_10",
  Consumable = "Interface\\Icons\\INV_Potion_93",
  ["Trade Goods"] = "Interface\\Icons\\INV_Misc_Gear_01",
  Projectile = "Interface\\Icons\\INV_Ammo_Arrow_01",
  Quiver = "Interface\\Icons\\INV_Misc_Quiver_03",
  Recipe = "Interface\\Icons\\INV_Scroll_03",
  Gems = "Interface\\Icons\\INV_Misc_Gem_01",
  Miscellaneous = "Interface\\Icons\\INV_Misc_QuestionMark",
  ["Quest Items"] = "Interface\\Icons\\INV_Misc_Note_01",
}

local function GetSearchTermIcon(searchTerm)
  local split = Auctionator.Search.SplitAdvancedSearch(searchTerm)
  local categoryKey = split.categoryKey or ""
  if categoryKey ~= "" then
    local topLevels = {}
    for category in string.gmatch(categoryKey, "[^|]+") do
      topLevels[(category:match("^[^/]+") or category)] = true
    end
    local count, only = 0, nil
    for category in pairs(topLevels) do count, only = count + 1, category end
    if count == 1 then
      return CATEGORY_ICONS[only] or "Interface\\Icons\\INV_Misc_Spyglass_03"
    end
    return "Interface\\Icons\\INV_Misc_Note_01"
  end

  local plainName = split.searchString and split.searchString:gsub('^"(.*)"$', '%1') or ""
  if plainName == "" then return "Interface\\Icons\\INV_Misc_Spyglass_03" end

  local iconCache = Auctionator.Shopping.ListIconCache or {}
  Auctionator.Shopping.ListIconCache = iconCache
  local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(plainName)
  if texture then iconCache[string.lower(plainName)] = texture end
  return texture or iconCache[string.lower(plainName)] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local CATEGORY_LABELS = {
  Container = "Containers",
  Consumable = "Consumables",
  Miscellaneous = "Miscellaneous",
  Projectile = "Projectiles",
  Quiver = "Quivers",
  Recipe = "Recipes",
  Weapons = "Weapons",
}

local function DisplayRange(label, minimum, maximum)
  if minimum and maximum then
    if minimum == maximum then
      return label .. " " .. minimum
    end
    return label .. " " .. minimum .. "-" .. maximum
  elseif minimum then
    return label .. " " .. minimum .. "+"
  elseif maximum then
    return label .. " up to " .. maximum
  end
end

local function DisplayCategory(categoryKey)
  if not categoryKey or categoryKey == "" then return nil end

  local labels = {}
  for path in string.gmatch(categoryKey, "[^|]+") do
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do table.insert(parts, part) end
    local label
    if parts[1] == "Armor" and #parts >= 3 then
      label = parts[#parts - 1] .. " " .. parts[#parts]
    elseif parts[1] == "Armor" and #parts == 2 then
      label = parts[2] .. " Armor"
    else
      label = CATEGORY_LABELS[parts[#parts]] or parts[#parts]
    end
    table.insert(labels, label)
  end

  if #labels > 2 then return #labels .. " categories" end
  return table.concat(labels, " + ")
end

local function GetSearchTermDisplay(searchTerm)
  local search = Auctionator.Search.SplitAdvancedSearch(searchTerm)
  local primary = search.searchString or ""
  if primary ~= "" and search.isExact then primary = '"' .. primary .. '"' end

  local details = {}
  local function Add(value)
    if value and value ~= "" then table.insert(details, value) end
  end

  Add(DisplayCategory(search.categoryKey))
  Add(DisplayRange("lvl", search.minLevel, search.maxLevel))
  Add(DisplayRange("ilvl", search.minItemLevel, search.maxItemLevel))
  Add(DisplayRange("clvl", search.minCraftedLevel, search.maxCraftedLevel))

  local qualities = {}
  for _, quality in ipairs(search.qualities or {}) do
    if ITEM_QUALITY_COLORS[quality] then
      table.insert(qualities, Auctionator.Utilities.CreateColoredQuality(quality))
    end
  end
  Add(table.concat(qualities, ", "))

  if search.minPrice or search.maxPrice then
    local minimum = search.minPrice and GetMoneyString(search.minPrice, true) or nil
    local maximum = search.maxPrice and GetMoneyString(search.maxPrice, true) or nil
    Add(DisplayRange("price", minimum, maximum))
  end
  if search.quantity then Add("x" .. search.quantity) end

  if primary == "" then
    primary = table.remove(details, 1) or "All items"
  end
  if #details > 0 then
    return primary .. "  |cff888888-|r  " .. table.concat(details, "  |cff888888-|r  ")
  end
  return primary
end

-- Callbacks to add wanted behaviour, e.g. editing a list or searching for a
-- search term
-- When a list is expanded to show its search terms
function AuctionatorShoppingTabListsContainerMixin:SetOnListExpanded(func)
  self.onListExpanded = func
end

-- When a list is collapsed by an explicit button press to hide its search terms
function AuctionatorShoppingTabListsContainerMixin:SetOnListCollapsed(func)
  self.onListCollapsed = func
end

-- When the search button is clicked on a particular list
function AuctionatorShoppingTabListsContainerMixin:SetOnListSearch(func)
  self.onListSearch = func
end

-- When the edit button is clicked on a particular list
function AuctionatorShoppingTabListsContainerMixin:SetOnListEdit(func)
  self.onListEdit = func
end

-- When the delete button is clicked on a particular list
function AuctionatorShoppingTabListsContainerMixin:SetOnListDelete(func)
  self.onListDelete = func
end

-- When the edit button is clicked on a particular search term in a list
function AuctionatorShoppingTabListsContainerMixin:SetOnSearchTermEdit(func)
  self.onSearchTermEdit = func
end

-- When the delete button is clicked on a particular search term in a list
function AuctionatorShoppingTabListsContainerMixin:SetOnSearchTermDelete(func)
  self.onSearchTermDelete = func
end

-- When the search term is just clicked
function AuctionatorShoppingTabListsContainerMixin:SetOnSearchTermClicked(func)
  self.onSearchTermClicked = func
end

-- When a search term is dragged to a different position
function AuctionatorShoppingTabListsContainerMixin:SetOnListItemDrag(func)
  self.onListItemDrag = func
end

function AuctionatorShoppingTabListsContainerMixin:SetOnListDrag(func)
  self.onListDrag = func
end

function AuctionatorShoppingTabListsContainerMixin:SetOnListItemMove(func)
  self.onListItemMove = func
end

function AuctionatorShoppingTabListsContainerMixin:ExpandList(list)
  if self.expandedList then
    self.expandedList = nil
    if self.onListCollapsed then
      self.onListCollapsed()
    end
  end
  self.expandedList = list
  self:Populate()
  self:ScrollToList(list)
  if self.onListExpanded then
    self.onListExpanded()
  end
end

function AuctionatorShoppingTabListsContainerMixin:CollapseList(list)
  self.expandedList = nil
  self:Populate()
  if list ~= nil then
    self:ScrollToList(list)
  end
  if self.onListCollapsed then
    self.onListCollapsed()
  end
end

function AuctionatorShoppingTabListsContainerMixin:TemporarilySelectSearchTerm(index)
  self.ScrollBox:ForEachFrame(function(frame)
    if frame.elementData.type == RowType.SearchTerm then
      frame.Selected:SetShown(frame.elementData.index == index)
    end
  end)
end

function AuctionatorShoppingTabListsContainerMixin:ScrollToList(list)
  local dataIndex = self.ScrollBox:FindElementDataIndexByPredicate(function(elementData)
    return elementData.type == RowType.List and elementData.list:GetName() == list:GetName()
  end)
  local scrollOffset = self.ScrollBox:GetDerivedScrollOffset()
  local dataIndexExtent = (self.ScrollBox:GetExtentUntil(dataIndex) - scrollOffset) / self.ScrollBox:GetVisibleExtent()
  if dataIndexExtent > 0.5 then
    self.ScrollBox:ScrollToElementDataIndex(dataIndex, 0.5)
  else
    self.ScrollBox:ScrollToNearest(dataIndex)
  end
end

function AuctionatorShoppingTabListsContainerMixin:ScrollToListEnd()
  if not self.expandedList then
    return
  end
  local listLength = self.expandedList:GetItemCount()
  local dataIndex = self.ScrollBox:FindElementDataIndexByPredicate(function(elementData)
    return elementData.type == RowType.SearchTerm and elementData.index == listLength
  end)
  self.ScrollBox:ScrollToNearest(dataIndex)
end

function AuctionatorShoppingTabListsContainerMixin:IsListExpanded(list)
  return self.expandedList and self.expandedList:GetName() == list:GetName()
end

function AuctionatorShoppingTabListsContainerMixin:GetExpandedList()
  return self.expandedList
end

function AuctionatorShoppingTabListsContainerMixin:OnLoad()
  self:SetupContent()

  if self:IsVisible() then
    self:Populate()
  end
end

function AuctionatorShoppingTabListsContainerMixin:OnShow()
  self:Populate()

  -- Listen to events to make sure the lists view is up to date
  Auctionator.EventBus:Register(self, {
    Auctionator.Shopping.Events.ListMetaChange,
    Auctionator.Shopping.Events.ListItemChange,
  })
end

function AuctionatorShoppingTabListsContainerMixin:OnHide()
  Auctionator.EventBus:Unregister(self, {
    Auctionator.Shopping.Events.ListMetaChange,
    Auctionator.Shopping.Events.ListItemChange,
  })
end

function AuctionatorShoppingTabListsContainerMixin:OnDragUpdate()
  if not IsMouseButtonDown("LeftButton") then
    local source = self.dragSource
    local target = self.dragTarget
    self.ScrollBox:ForEachFrame(function(frame)
      frame:SetAlpha(1)
      if frame.DropCue then frame.DropCue:Hide() end
    end)
    if source and target then
      if source.type == RowType.List and target.type == RowType.List and self.onListDrag then
        self.onListDrag(source.listIndex, target.listIndex)
      elseif source.type == RowType.SearchTerm then
        if target.type == RowType.SearchTerm and source.list:GetName() == target.list:GetName() and self.onListItemDrag then
          self.onListItemDrag(source.list, source.index, target.index)
        elseif target.type == RowType.List and self.onListItemMove then
          self.onListItemMove(source.list, source.index, target.list)
        end
      end
    end
    self.dragSource = nil
    self.dragTarget = nil
    self.draggingIndex = nil
    self:SetScript("OnUpdate", nil)
  end
end

function AuctionatorShoppingTabListsContainerMixin:ReceiveEvent(eventName, eventData)
  if eventName == Auctionator.Shopping.Events.ListItemChange then
    if self.expandedList and self.expandedList:GetName() == eventData then
      self:Populate()
    end
  elseif eventName == Auctionator.Shopping.Events.ListMetaChange then
    self:Populate()
  end
end

function AuctionatorShoppingTabListsContainerMixin:SetupContent()
  local function OnClick(button, buttonClickedString)
    if buttonClickedString == "RightButton" then
      if self.expandedList then
        self:CollapseList(self.expandedList)
      end
    else
      if button.elementData.type == RowType.List then
        if self:IsListExpanded(button.elementData.list) then
          self:CollapseList(button.elementData.list)
        else
          self:ExpandList(button.elementData.list)
        end
      elseif button.elementData.type == RowType.SearchTerm then
        if self.onSearchTermClicked and self.expandedList then
          self.onSearchTermClicked(self.expandedList, button.elementData.searchTerm, button.elementData.index)
        end
      end
    end
  end

  local function OnEnter(button)
    button.Highlight:Show()
    if button.elementData and button.elementData.type == RowType.SearchTerm then
      GameTooltip:SetOwner(button, "ANCHOR_NONE")
      Auctionator.Shopping.Tab.ComposeSearchTermTooltip(button.elementData.searchTerm)
      GameTooltip:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT")
      GameTooltip:Show()
    end
    if self.dragSource and button.elementData then
      local source, target = self.dragSource, button.elementData
      local valid = (source.type == RowType.List and target.type == RowType.List)
        or (source.type == RowType.SearchTerm and target.type == RowType.List)
        or (source.type == RowType.SearchTerm and target.type == RowType.SearchTerm
          and source.list:GetName() == target.list:GetName())
      if valid then
        self.dragTarget = target
        if button.DropCue then button.DropCue:Show() end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        if source.type == RowType.SearchTerm and target.type == RowType.List then
          GameTooltip:SetText("Move to " .. target.list:GetName(), 0.25, 1, 0.25)
        else
          GameTooltip:SetText("Drop here to reorder", 0.25, 1, 0.25)
        end
        GameTooltip:Show()
      end
    end
  end

  local function OnLeave(button)
    button.Highlight:Hide()
    if button.DropCue then button.DropCue:Hide() end
    if self.dragTarget == button.elementData then self.dragTarget = nil end
    if button.elementData and button.elementData.type == RowType.SearchTerm then
      GameTooltip:Hide()
    end
  end

  local function OnMouseDown(button, buttonClickedString)
    if buttonClickedString == "LeftButton" and button.elementData
      and (button.elementData.type == RowType.SearchTerm or button.elementData.type == RowType.List) then
      self.dragTarget = nil
      self.dragSource = button.elementData
      self.draggingIndex = button.elementData.index
      button:SetAlpha(draggingTermAlpha)
      self:SetScript("OnUpdate", self.OnDragUpdate)
    end
  end

  local function OnListSearchOptionClicked(button)
    button = button:GetParent()
    if self.onListSearch then
      self.onListSearch(button.elementData.list)
    end
  end

  local function OnListEditOptionClicked(button)
    button = button:GetParent()
    if self.onListEdit then
      self.onListEdit(button.elementData.list)
    end
  end

  local function OnListDeleteOptionClicked(button)
    button = button:GetParent()
    self.onListDelete(button.elementData.list)
  end

  local function OnSearchTermDeleteOptionClicked(button)
    button = button:GetParent()
    if self.onSearchTermDelete then
      self.onSearchTermDelete(self.expandedList, button.elementData.searchTerm, button.elementData.index)
    end
  end

  local function OnSearchTermEditOptionClicked(button)
    button = button:GetParent()
    if self.onSearchTermEdit then
      self.onSearchTermEdit(self.expandedList, button.elementData.searchTerm, button.elementData.index)
    end
  end

  local function CreateOptionButton(button, xOffset, xWidth)
    local option = CreateFrame("Button", nil, button)
    option:SetPoint("TOPRIGHT", xOffset, 0)
    option:SetSize(xWidth, buttonHeight)
    option.Icon = option:CreateTexture()
    option.Icon:SetSize(buttonHeight - 5, buttonHeight - 5)
    option.Icon:SetPoint("CENTER")
    option:SetScript("OnEnter", function()
      option.Icon:SetAlpha(0.5)
      if option.TooltipText then
        GameTooltip:SetOwner(option, "ANCHOR_RIGHT")
        GameTooltip:SetText(option.TooltipText, 1, 1, 1)
        GameTooltip:Show()
      end
    end)
    option:SetScript("OnLeave", function()
      option.Icon:SetAlpha(1)
      if option.TooltipText then
        GameTooltip:Hide()
      end
    end)
    option:SetScript("OnHide", function()
      option.Icon:SetAlpha(1)
    end)
    return option
  end

  local function SetupButton(button)
    button.setup = true
    Auctionator.Shopping.Tab.SetupContainerRow(button, buttonHeight, buttonSpacing)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnMouseDown", OnMouseDown)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.DropCue = button:CreateTexture(nil, "OVERLAY")
    button.DropCue:SetAllPoints()
    button.DropCue:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button.DropCue:SetVertexColor(0.15, 1, 0.2, 0.8)
    button.DropCue:SetBlendMode("ADD")
    button.DropCue:Hide()

    button.options1 = Auctionator.Shopping.Tab.CreateOptionButton(button, 0, buttonHeight + 5, buttonHeight)
    button.options2 = Auctionator.Shopping.Tab.CreateOptionButton(button, -buttonHeight - 5, buttonHeight + 5, buttonHeight)
    button.options3 = Auctionator.Shopping.Tab.CreateOptionButton(button, - 2 * buttonHeight - 10, buttonHeight + 5, buttonHeight)
  end

  local function OnButtonAcquire(button, elementData)
    if not button.setup then
      SetupButton(button)
    end

    button:SetSize(self:GetWidth(), buttonHeight)
    button.options1:Hide()
    button.options2:Hide()
    button.options3:Hide()
    button:SetAlpha(1)
    button.DropCue:Hide()

    local text = ""
    local xOffset
    button.elementData = elementData
    if elementData.type == RowType.List then
      xOffset = listHeaderInset
      local color = NORMAL_FONT_COLOR
      if elementData.list:IsTemporary() then
        color = ORANGE_FONT_COLOR
      end
      local icon = ""
      if not self:IsListExpanded(elementData.list) then
        icon = "|TInterface\\AddOns\\!Logistician\\Images\\Plus_Icon:8:8|t"
      else
        icon = "|TInterface\\AddOns\\!Logistician\\Images\\Minus_Icon:8:8|t"
      end
      button.Text:SetText(icon .. "  " .. color:WrapTextInColorCode(elementData.list:GetName()))
      Auctionator.Shopping.Tab.SetOptionIcon(button.options1, "search")
      button.options1:SetScript("OnClick", OnListSearchOptionClicked)
      button.options1.TooltipText = AUCTIONATOR_L_SEARCH_ALL
      button.options1:Show()
      Auctionator.Shopping.Tab.SetOptionIcon(button.options2, "edit")
      button.options2:SetScript("OnClick", OnListEditOptionClicked)
      if elementData.list:IsTemporary() then
        button.options2.TooltipText = AUCTIONATOR_L_MAKE_PERMANENT
      else
        button.options2.TooltipText = AUCTIONATOR_L_RENAME
      end
      button.options2:Show()
      Auctionator.Shopping.Tab.SetOptionIcon(button.options3, "delete")
      button.options3:SetScript("OnClick", OnListDeleteOptionClicked)
      button.options3.TooltipText = AUCTIONATOR_L_DELETE
      button.options3:Show()
    elseif elementData.type == RowType.SearchTerm then
      if elementData.index == self.draggingIndex then
        button:SetAlpha(draggingTermAlpha)
      end
      xOffset = listEntryInset
      local iconPath = GetSearchTermIcon(elementData.searchTerm)
      local displayText = GetSearchTermDisplay(elementData.searchTerm)
      button.Text:SetText("|T" .. iconPath .. ":16:16:0:0|t  " .. displayText)
      Auctionator.Shopping.Tab.SetOptionIcon(button.options1, "delete")
      button.options1:SetScript("OnClick", OnSearchTermDeleteOptionClicked)
      button.options1.TooltipText = AUCTIONATOR_L_DELETE
      button.options1:Show()
      Auctionator.Shopping.Tab.SetOptionIcon(button.options2, "edit")
      button.options2:SetScript("OnClick", OnSearchTermEditOptionClicked)
      button.options2.TooltipText = AUCTIONATOR_L_EDIT_ITEM
      button.options2:Show()
    else
      xOffset = listEntryInset
      button.Text:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(EMPTY))
    end

    button.Text:ClearAllPoints()
    button.Text:SetPoint("LEFT", button, "LEFT", xOffset, 0)
    button.Text:SetPoint("RIGHT", button, "RIGHT", -buttonSpacing, 0)
    button.Highlight:Hide()
    button.Selected:SetShown(elementData.type == RowType.List and self.expandedList and elementData.list:GetName() == self.expandedList:GetName())

    return button
  end

  self.Inset = CreateFrame("Frame", nil, self, "AuctionatorInsetTemplate")
  self.Inset:SetAllPoints()

  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
  self.ScrollBox:SetPoint("TOPLEFT", 0, -2)
  self.ScrollBox:SetPoint("BOTTOMRIGHT", 0, 2)

  self.ScrollBar = CreateFrame("EventFrame", nil, self, "WowTrimScrollBar")
  self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT")
  self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT")

  local view = CreateScrollBoxListLinearView(0, 0, 0, 0)
  view:SetElementExtent(buttonHeight)
  view:SetElementInitializer("Button", OnButtonAcquire)
  view:SetPanExtent(50)

  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
end

function AuctionatorShoppingTabListsContainerMixin:Populate()
  local rows = {}

  for index = 1, Auctionator.Shopping.ListManager:GetCount() do
    local list = Auctionator.Shopping.ListManager:GetByIndex(index)
    table.insert(rows, {
      type = RowType.List,
      list = list,
      listIndex = index,
    })
    if self:IsListExpanded(list) then
      for index, item in ipairs(list:GetAllItems()) do
        table.insert(rows, {
          type = RowType.SearchTerm,
          searchTerm = item,
          index = index,
          list = list,
          text = nil,
        })
      end
      if list:GetItemCount() == 0 then
        table.insert(rows, {
          type = RowType.Empty,
        })
      end
    end
  end
  self.ScrollBox:SetDataProvider(CreateDataProvider(rows), true)
end
