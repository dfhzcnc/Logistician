local GroupType = Logistician.Groups.Constants.GroupType

LogisticianGroupsViewMixin = {}
function LogisticianGroupsViewMixin:OnLoad()
  local view = CreateScrollBoxLinearView()
  view:SetPanExtent(50)
  ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, view);

  self.buttonPool = CreateFramePool("Button", self.ScrollBox.ItemListingFrame, self.itemTemplate)
  self.groupPool = CreateFramePool("Frame", self.ScrollBox.ItemListingFrame, self.groupTemplate, function(pool, obj)
    (FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)(pool, obj)
    obj.buttons = {}
  end)
  self.groups = {}

  self.rawItems = {}
  self.hiddenItems = {}

  self.collapsing = {}

  self.originalOpen = true
  self.cachedUpdated = false
end

function LogisticianGroupsViewMixin:OnShow()
  Logistician.Groups.CallbackRegistry:RegisterCallback("BagCacheUpdated", self.Update, self)
  Logistician.Groups.CallbackRegistry:RegisterCallback("ViewGroupToggled", self.UpdateGroupHeights, self)
  Logistician.Groups.CallbackRegistry:RegisterCallback("Customise.EditMade", self.UpdateCustomGroups, self)

  self:UpdateCustomGroups()
  self:UpdateFromExisting()
end

function LogisticianGroupsViewMixin:OnHide()
  Logistician.Groups.CallbackRegistry:UnregisterCallback("BagCacheUpdated", self)
  Logistician.Groups.CallbackRegistry:UnregisterCallback("ViewGroupToggled", self)
  Logistician.Groups.CallbackRegistry:UnregisterCallback("Customise.EditMade", self.UpdateCustomGroups, self)
end

function LogisticianGroupsViewMixin:UpdateCustomGroups()
  self.groupDetails = CopyTable({LOGISTICIAN_SELLING_GROUPS.CustomGroups[1]})
  for _, s in ipairs(Logistician.Groups.Constants.DefaultGroups) do
    table.insert(self.groupDetails, s)
  end

  self:CacheListLinks()
end

function LogisticianGroupsViewMixin:CacheListLinks()
  self.listsCached = false

  local toCache = {}
  for _, s in ipairs(self.groupDetails) do
    if s.type == GroupType.List then
      for _, link in ipairs(s.list) do
        local info = LogisticianBagCacheFrame:GetByLinkInstant(link, true)
        if info == nil then
          table.insert(toCache, link)
        end
      end
    end
  end

  if self.hideHiddenItems then
    for _, link in ipairs(LOGISTICIAN_SELLING_GROUPS.HiddenItems) do
      local info = LogisticianBagCacheFrame:GetByLinkInstant(link, true)
      if info == nil then
        table.insert(toCache, link)
      end
    end
  end

  if #toCache == 0 then
    self.listsCached = true
    self:RefreshHiddenItems()
    self:UpdateFromExisting()
    return
  end

  local waiting = #toCache
  for _, itemLink in ipairs(toCache) do
    LogisticianBagCacheFrame:CacheLinkInfo(itemLink, function()
      waiting = waiting - 1
      if waiting <= 0 then
        self.listsCached = true
        self:RefreshHiddenItems()
        self:UpdateFromExisting()
      end
    end)
  end
end

function LogisticianGroupsViewMixin:RefreshHiddenItems()
  self.hiddenItems = {}
  if self.hideHiddenItems then
    for _, link in ipairs(LOGISTICIAN_SELLING_GROUPS.HiddenItems) do
      local info = LogisticianBagCacheFrame:GetByLinkInstant(link, true)
      self.hiddenItems[info.sortKey] = link
    end
  end
end

function LogisticianGroupsViewMixin:SetSelected(key)
  self.selected = key
  self:UpdateFromExisting()
end

function LogisticianGroupsViewMixin:ScrollToSelected()
  for _, group in ipairs(self.groups) do
    for _, button in ipairs(group.buttons) do
      if button.itemInfo.selected then
        local offset = math.abs(button.yOffset + group.yOffset)
        local scrollOffset = self.ScrollBox:GetDerivedScrollOffset()
        local newOffset = scrollOffset
        if offset + button:GetHeight() > scrollOffset + self.ScrollBox:GetHeight() then
          newOffset = offset + button:GetHeight() - self.ScrollBox:GetHeight()
        elseif offset < scrollOffset then
          newOffset = offset - 40
        end
        self.ScrollBox:ScrollToOffset(newOffset, 0, 0)
      end
    end
  end
end

function LogisticianGroupsViewMixin:ScrollToGroup(index)
  local group = self.groups[index]

  local scrollOffset = self.ScrollBox:GetDerivedScrollOffset()
  local offset = math.abs(group.yOffset)
  local newOffset = scrollOffset
  if offset + group:GetHeight() > scrollOffset + self.ScrollBox:GetHeight() then
    newOffset = offset - 40
  elseif offset < scrollOffset then
    newOffset = offset - 40
  end
  self.ScrollBox:ScrollToOffset(newOffset, 0, 0)
end

function LogisticianGroupsViewMixin:UpdateGroupHeights()
  local offset = 0
  for index, group in ipairs(self.groups) do
    if self.forceShow or (not self.groupDetails[index].hidden and group:AnyButtons()) then
      group:Show()
      group:SetPoint("TOP", 0, -offset)
      group.yOffset = -offset
      group:UpdateHeight()
      offset = offset + group:GetHeight()
    else
      group:Hide()
      for _, b in ipairs(group.buttons) do
        b:Hide()
      end
    end
    self.collapsing[index] = group.collapsed
  end

  self.ScrollBox.ItemListingFrame:SetHeight(offset)
  self.ScrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately);
end

function LogisticianGroupsViewMixin:Update(cache)
  self.cacheUpdated = true
  self.rawItems = cache:GetAllContents()
  table.sort(self.rawItems, function(a, b)
    return a.sortKey < b.sortKey
  end)
  self:UpdateFromExisting()
end

function LogisticianGroupsViewMixin:UpdateFromExisting()
  self.buttonPool:ReleaseAll()
  self.groupPool:ReleaseAll()
  self.groups = {}
  local iconSize = Logistician.Config.Get(Logistician.Config.Options.SELLING_ICON_SIZE)

  -- Used to ensure no key naming clashes between custom groups and raw groups
  local function GetKeyName(groupName, isCustom)
    return (isCustom and groupName) or "k_" .. groupName
  end

  local groups = {}
  for index, groupDetails in ipairs(self.groupDetails) do
    local group = self.groupPool:Acquire()
    group:SetPoint("LEFT", self.groupInsetX, 0)
    group:SetPoint("RIGHT")
    group:Reset()
    local isCustom = index == 1 -- Only the first group is custom FAVOURITES now
    group:SetName(groupDetails.name, isCustom)
    if self.applyVisibility and (self.collapsing[index] or (self.originalOpen and Logistician.Config.Get(Logistician.Config.Options.SELLING_BAG_COLLAPSED))) then
      group:ToggleOpen(true)
    end
    table.insert(groups, group)

    if self.listsCached and groupDetails.type == GroupType.List then
      local infos = {}
      for _, link in ipairs(groupDetails.list) do
        local info = LogisticianBagCacheFrame:GetByLinkInstant(link, true)
        if info ~= nil then
          table.insert(infos, info)
        end
      end
      if self.applyVisibility and Logistician.Config.Get(Logistician.Config.Options.SELLING_FAVOURITES_SORT_OWNED) then
        table.sort(infos, function(a, b)
          if #a.locations > 0 and #b.locations == 0 then
            return true
          elseif #b.locations > 0 and #a.locations == 0 then
            return false
          else
            return a.sortKey < b.sortKey
          end
        end)
      else
        table.sort(infos, function(a, b) return a.sortKey < b.sortKey end)
      end
      if self.applyVisibility and not Logistician.Config.Get(Logistician.Config.Options.SELLING_MISSING_FAVOURITES) then
        infos = tFilter(infos, function(a) return #a.locations > 0 end, true)
      end
      local keyName = GetKeyName(groupDetails.name, isCustom)
      for _, info in ipairs(infos) do
        local button = self.buttonPool:Acquire()
        button:SetClickEvent(self.clickEventName)
        info.selected = self.selected and self.selected.keyName == keyName and info.sortKey == self.selected.sortKey
        info.group = groupDetails.name
        info.isCustom = isCustom
        button:SetSize(iconSize, iconSize)
        button:SetItemInfo(info)
        group:AddButton(button)
      end
    end
  end

  self.groups = groups

  local classIDMap = {}
  for index, s in ipairs(self.groupDetails) do
    if s.type == GroupType.ClassID then
      classIDMap[s.classID] = index
    end
  end

  for _, item in ipairs(self.rawItems) do
    if item.auctionable and not self.hiddenItems[item.sortKey] and (item.quality ~= Enum.ItemQuality.Poor or Logistician.Utilities.IsEquipment(item.classID))  then
      local index = classIDMap[item.classID]
      if index ~= nil then
        local button = self.buttonPool:Acquire()
        button:SetClickEvent(self.clickEventName)
        item.selected = self.selected and self.selected.keyName == GetKeyName(self.groupDetails[index].name, false) and item.sortKey == self.selected.sortKey
        item.isCustom = false
        button:SetItemInfo(item)
        button:SetSize(iconSize, iconSize)
        groups[index]:AddButton(button)
      end
    end
  end

  local prevButton
  local prevGroup
  self.itemMap = {}
  for index, group in ipairs(groups) do
    local groupInfo = self.groupDetails[index]
    local keyName = GetKeyName(groupInfo.name, group.isCustom)
    self.itemMap[keyName] = {}
    for _, button in ipairs(group.buttons) do
      button.prevItem = nil
      button.nextItem = nil
      if not groupInfo.hidden then
        if prevButton then
          button.prevItem = {keyName = prevGroup, sortKey = prevButton.itemInfo.sortKey}
          prevButton.nextItem = {keyName = keyName, sortKey = button.itemInfo.sortKey}
        else
          button.prevItem = nil
        end
        prevGroup = keyName
        prevButton = button
      end
      button.key = {keyName = keyName, sortKey = button.itemInfo.sortKey}
      self.itemMap[keyName][button.itemInfo.sortKey] = button
    end
  end

  self.groups = groups
  self.originalOpen = false
  self:UpdateGroupHeights()
  if self.cacheUpdated and self.listsCached then
    Logistician.Groups.CallbackRegistry:TriggerEvent(self.completeEventName)
  end
end
