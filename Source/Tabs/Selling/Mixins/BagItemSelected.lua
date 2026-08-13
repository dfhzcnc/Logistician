LogisticianBagItemSelectedMixin = CreateFromMixins(LogisticianGroupsViewItemMixin)

function LogisticianBagItemSelectedMixin:SetItemInfo(info, ...)
  LogisticianGroupsViewItemMixin.SetItemInfo(self, info, ...)
  self.IconSelectedHighlight:Hide()
  self.IconBorder:SetShown(info ~= nil)
  self.Icon:SetAlpha(1)

  self.clickEventName = "BagUse.BagItemClicked"
end

local seenBag, seenSlot

function LogisticianBagItemSelectedMixin:OnClick(button)
  local wasCursorItem = C_Cursor.GetCursorItem()
  self:ProcessCursor(function(check)
    if not check then
      if button == "LeftButton" and not wasCursorItem and self.itemInfo ~= nil and not IsModifiedClick("DRESSUP") and not IsModifiedClick("CHATLINK") then
        self:SearchInShoppingTab()
      else
        LogisticianGroupsViewItemMixin.OnClick(self, button)
      end
    end
  end)
end

function LogisticianBagItemSelectedMixin:SearchInShoppingTab()
  Logistician.API.v1.MultiSearchExact(LOGISTICIAN_L_SELLING_TAB, { self.itemInfo.itemName })
end

function LogisticianBagItemSelectedMixin:OnReceiveDrag()
  self:ProcessCursor(function() end)
end

function LogisticianBagItemSelectedMixin:ProcessCursor(callback)
  local location = C_Cursor.GetCursorItem()
  ClearCursor()

  if not location then
    Logistician.Debug.Message("nothing on cursor")
    callback(false)
    return
  end

  -- Case when picking up a key from your keyring in classic, WoW doesn't always
  -- give a valid item location for the cursor, causing an error unless we
  -- either:
  --  1. Ignore it
  --  2. Replace the location with one that is valid based on a hook on bag
  --  clicks.
  -- We use 2.
  if not location:HasAnyLocation() then
    Logistician.Debug.Message("LogisticianBagItemSelected", "recovering")
    location = ItemLocation:CreateFromBagAndSlot(seenBag, seenSlot)
  end

  if not C_Item.DoesItemExist(location) then
    Logistician.Debug.Message("LogisticianBagItemSelected", "not exists")
    callback(false)
    return
  end

  local itemLink = C_Item.GetItemLink(location)

  Logistician.EventBus:RegisterSource(self, "BagItemSelected")
  Logistician.Groups.CallbackRegistry:RegisterCallback("BagCacheUpdated", function(_, cache)
    Logistician.Groups.CallbackRegistry:UnregisterCallback("BagCacheUpdated", self)
    Logistician.Groups.CallbackRegistry:TriggerEvent("BagCacheOff")
    cache:CacheLinkInfo(itemLink, function()
      local info = Logistician.Groups.Utilities.ToPostingItem(LogisticianBagCacheFrame:GetByLinkInstant(itemLink, true))
      if info.location then
        callback(true)
        info.location = location
        Logistician.EventBus:Fire(self, Logistician.Selling.Events.BagItemClicked, info)
      else
        Logistician.Selling.ShowCannotSellReason(location)
        callback(false)
      end
    end)
  end, self)
  Logistician.Groups.CallbackRegistry:TriggerEvent("BagCacheOn")
end

local function HookForPickup(bag, slot)
  seenBag = bag
  seenSlot = slot
end

-- For classic record clicks on bag items so that we can make keyring items
-- being picked up and placed in the Selling tab work.
if C_Container and C_Container.PickupContainerItem then
  hooksecurefunc(C_Container, "PickupContainerItem", HookForPickup)
end
