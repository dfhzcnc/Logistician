LogisticianBagUseMixin = {}
function LogisticianBagUseMixin:OnLoad()
  self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")

  Logistician.EventBus:RegisterSource(self, "LogisticianBagUseMixin")
  self.View.rowWidth = math.ceil(5 * 42 / Logistician.Config.Get(Logistician.Config.Options.SELLING_ICON_SIZE))
  self.awaitingCompletion = true

  Logistician.EventBus:Register(self, {
    Logistician.Selling.Events.BagItemRequest,
    Logistician.Selling.Events.BagItemClicked,
  })
end

function LogisticianBagUseMixin:OnShow()
  Logistician.Groups.CallbackRegistry:RegisterCallback("BagUse.BagItemClicked", self.BagItemClicked, self)
  Logistician.Groups.CallbackRegistry:RegisterCallback("BagUse.AddToDefaultGroup", self.AddToDefaultGroup, self)

  Logistician.Groups.CallbackRegistry:RegisterCallback("ViewComplete", function(_, listsCached)
    self.awaitingCompletion = false
    if self.pendingKey then
      self:ReturnItem(self.pendingKey)
      self.pendingKey = nil
    end
  end, self)
  Logistician.Groups.CallbackRegistry:TriggerEvent("BagCacheOn")
end

function LogisticianBagUseMixin:OnHide()
  self.View:SetSelected(nil)
  Logistician.Groups.CallbackRegistry:UnregisterCallback("BagUse.BagItemClicked", self)
  Logistician.Groups.CallbackRegistry:UnregisterCallback("BagUse.AddToDefaultGroup", self)
  Logistician.Groups.CallbackRegistry:UnregisterCallback("BagUse.RemoveFromDefaultGroup", self)
  Logistician.Groups.CallbackRegistry:UnregisterCallback("ViewComplete", self)
  Logistician.Groups.CallbackRegistry:TriggerEvent("BagCacheOff")
  self.awaitingCompletion = true
end

function LogisticianBagUseMixin:ReturnItem(key)
  local button = (self.View.itemMap[key.keyName] and self.View.itemMap[key.keyName][key.sortKey])
  if not button then
    Logistician.EventBus:Fire(self, Logistician.Selling.Events.ClearBagItem)
  else
    button:Click()
  end
end

function LogisticianBagUseMixin:ReceiveEvent(eventName, info, ...)
  if eventName == Logistician.Selling.Events.BagItemRequest then
    if self.awaitingCompletion then
      self.pendingKey = info
    else
      self:ReturnItem(info)
    end
  elseif eventName == Logistician.Selling.Events.BagItemClicked then
    if self:IsVisible() then
      self.View:SetSelected(info.key)
      self.View:ScrollToSelected()
    end
  elseif eventName == Logistician.Selling.Events.BagItemClear then
    self.View:SetSelected(nil)
  end
end

function LogisticianBagUseMixin:BagItemClicked(button, mouseButton)
  if mouseButton == "LeftButton" then
    local postingInfo = Logistician.Groups.Utilities.ToPostingItem(button.itemInfo)
    postingInfo.nextItem = button.nextItem
    postingInfo.prevItem = button.prevItem
    postingInfo.key = button.key
    postingInfo.sortKey = button.itemInfo.sortKey
    Logistician.EventBus:Fire(self, Logistician.Selling.Events.BagItemClicked, postingInfo)
  elseif mouseButton == "RightButton" then
    local defaultName = Logistician.Groups.GetGroupNameByIndex(1)
    local isInDefaultGroup = self.View.itemMap[defaultName][button.itemInfo.sortKey] ~= nil
    local options = {}
    local defaultPrintName = _G["LOGISTICIAN_L_" .. defaultName] or defaultName
    MenuUtil.CreateContextMenu(self, function(_, rootDescription)
      if isInDefaultGroup then
        rootDescription:CreateButton(LOGISTICIAN_L_REMOVE_FROM_X:format(defaultPrintName), function() self:RemoveFromDefaultGroup(button) end)
      else
        rootDescription:CreateButton(LOGISTICIAN_L_ADD_TO_X:format(defaultPrintName), function() self:AddToDefaultGroup(button) end)
      end
      if not button.itemInfo.isCustom then
        if not self.View.hiddenItems[button.itemInfo.sortKey] then
          rootDescription:CreateButton(LOGISTICIAN_L_HIDE, function() self:HideItem(button) end)
        else
          rootDescription:CreateButton(LOGISTICIAN_L_UNHIDE, function() self:UnhideItem(button) end)
        end
        if next(self.View.hiddenItems) == nil then
          rootDescription:CreateTitle(GRAY_FONT_COLOR:WrapTextInColorCode(LOGISTICIAN_L_UNHIDE_ALL))
        else
          rootDescription:CreateButton(LOGISTICIAN_L_UNHIDE_ALL, function() self:UnhideAll() end)
        end
      end
    end)
  end
end

function LogisticianBagUseMixin:AddToDefaultGroup(button)
  local defaultName = Logistician.Groups.GetGroupNameByIndex(1)
  local defaultList = Logistician.Groups.GetGroupList(defaultName)
  if self.View.itemMap[defaultName][button.itemInfo.sortKey] == nil then
    table.insert(defaultList, button.itemInfo.itemLink)
    Logistician.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
  end
end

function LogisticianBagUseMixin:RemoveFromDefaultGroup(button)
  local defaultName = Logistician.Groups.GetGroupNameByIndex(1)
  local defaultList = Logistician.Groups.GetGroupList(defaultName)
  local info = self.View.itemMap[defaultName][button.itemInfo.sortKey].itemInfo
  for index, itemLink in ipairs(defaultList) do
    local sortKey = LogisticianBagCacheFrame:GetByLinkInstant(itemLink, info.auctionable).sortKey
    if sortKey == info.sortKey then
      table.remove(defaultList, index)
      Logistician.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
      break
    end
  end
end

function LogisticianBagUseMixin:HideItem(button)
  if not self.View.hiddenItems[button.itemInfo.sortKey] then
    local itemLink = button.itemInfo.itemLink
    Logistician.Groups.HideItemLink(itemLink)
    Logistician.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
  end
end

function LogisticianBagUseMixin:UnhideItem(button)
  local hiddenLink = self.View.hiddenItems[button.itemInfo.sortKey]
  if hiddenLink then
    Logistician.Groups.UnhideItemLink(hiddenLink)
    Logistician.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
  end
end

function LogisticianBagUseMixin:UnhideAll()
  Logistician.Dialogs.ShowConfirm(LOGISTICIAN_L_CONFIRM_UNHIDE_ALL, ACCEPT, CANCEL, function()
    Logistician.Groups.UnhideAll()
    Logistician.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
  end)
end
