local owner = {}
local function SelectOwnItem(self)
  ClearCursor()

  local itemLocation = ItemLocation:CreateFromBagAndSlot(self:GetParent():GetID(), self:GetID())

  if not C_Item.DoesItemExist(itemLocation) then
    return
  end

  local itemLink = C_Item.GetItemLink(itemLocation)

  LogisticianTabs_Selling:Click()
  Logistician.EventBus:RegisterSource(owner, "SellingTabBagHooks")
  Logistician.Groups.CallbackRegistry:RegisterCallback("BagCacheUpdated", function(_, cache)
    Logistician.Groups.CallbackRegistry:UnregisterCallback("BagCacheUpdated", owner)
    Logistician.Groups.CallbackRegistry:TriggerEvent("BagCacheOff")
    cache:CacheLinkInfo(itemLink, function()
      local info = Logistician.Groups.Utilities.ToPostingItem(LogisticianBagCacheFrame:GetByLinkInstant(itemLink, true))
      if info.location then
        info.location = itemLocation
        Logistician.EventBus:Fire(owner, Logistician.Selling.Events.BagItemClicked, info)
      else
        Logistician.Selling.ShowCannotSellReason(itemLocation)
      end
    end)
  end, owner)
  Logistician.Groups.CallbackRegistry:TriggerEvent("BagCacheOn")
end

local function AHShown()
  return AuctionFrame and AuctionFrame:IsShown() and LogisticianTabs_Selling
end

hooksecurefunc(_G, "ContainerFrameItemButton_OnEnter", function(self)
  if AHShown() and
      Logistician.Config.Get(Logistician.Config.Options.SELLING_BAG_SELECT_SHORTCUT) == Logistician.Config.Shortcuts.RIGHT_CLICK then
    SetAuctionsTabShowing(true)
  end
end)

hooksecurefunc(_G, "ContainerFrameItemButton_OnClick", function(self, button)
  if AHShown() and
      Logistician.Utilities.IsShortcutActive(Logistician.Config.Get(Logistician.Config.Options.SELLING_BAG_SELECT_SHORTCUT), button) then
    SelectOwnItem(self)
  end
end)

hooksecurefunc(_G, "ContainerFrameItemButton_OnModifiedClick", function(self, button)
  if AHShown() and
      Logistician.Utilities.IsShortcutActive(Logistician.Config.Get(Logistician.Config.Options.SELLING_BAG_SELECT_SHORTCUT), button) then
    SelectOwnItem(self)
  end
end)
