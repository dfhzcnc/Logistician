local function SelectOwnItem(self)
  ClearCursor()

  local itemLocation = ItemLocation:CreateFromBagAndSlot(self:GetParent():GetID(), self:GetID())

  if not C_Item.DoesItemExist(itemLocation) then
    return
  end

  local itemLink = C_Item.GetItemLink(itemLocation)
  local function Debug(message)
    if Auctionator.Debug and Auctionator.Debug.Message then
      Auctionator.Debug.Message("Logistician stage debug " .. message)
    end
  end

  Debug("start link=" .. tostring(itemLink) .. " auctionsShown=" ..
    tostring(AuctionFrameAuctions and AuctionFrameAuctions:IsShown()))

  if AuctionFrameTab3 then
    Debug("click AuctionFrameTab3")
    AuctionFrameTab3:Click()
  end
  if itemLink and Auctionator.Selling and Auctionator.Selling.ShowCannotSellReason then
    local itemInfo = AuctionatorBagCacheFrame and AuctionatorBagCacheFrame:GetByLinkInstant(itemLink, true)
    if itemInfo then
      local postingInfo = Auctionator.Groups.Utilities.ToPostingItem(itemInfo)
      if not postingInfo.location then
        Auctionator.Selling.ShowCannotSellReason(itemLocation)
        return
      end
    end
  end
  local attempts = 0
  local function StageItem()
    attempts = attempts + 1
    Debug("attempt=" .. attempts .. " auctionsShown=" ..
      tostring(AuctionFrameAuctions and AuctionFrameAuctions:IsShown()) ..
      " cursor=" .. tostring(CursorHasItem and CursorHasItem()))
    if (not AuctionFrameAuctions or not AuctionFrameAuctions:IsShown()) and
        attempts < 10 and C_Timer then
      C_Timer.After(0.05, StageItem)
      return
    end
    ClearCursor()
    if GetAuctionSellItemInfo() then
      ClickAuctionSellItemButton()
      ClearCursor()
    end
    if itemLocation:IsBagAndSlot() then
      if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(itemLocation:GetBagAndSlot())
      else
        PickupContainerItem(itemLocation:GetBagAndSlot())
      end
    else
      PickupInventoryItem(itemLocation:GetEquipmentSlot())
    end
    Debug("after pickup cursor=" .. tostring(CursorHasItem and CursorHasItem()))
    if not CursorHasItem or not CursorHasItem() then
      if itemLocation:IsBagAndSlot() then
        if C_Container and C_Container.PickupContainerItem then
          C_Container.PickupContainerItem(itemLocation:GetBagAndSlot())
        else
          PickupContainerItem(itemLocation:GetBagAndSlot())
        end
      else
        PickupInventoryItem(itemLocation:GetEquipmentSlot())
      end
      Debug("after pickup retry cursor=" .. tostring(CursorHasItem and CursorHasItem()))
    end
    ClickAuctionSellItemButton()
    Debug("after click sellItem=" .. tostring(GetAuctionSellItemInfo()) ..
      " cursor=" .. tostring(CursorHasItem and CursorHasItem()))
    ClearCursor()
    Debug("after clear sellItem=" .. tostring(GetAuctionSellItemInfo()))
  end

  if AuctionFrameAuctions and AuctionFrameAuctions:IsShown() then
    StageItem()
  elseif C_Timer then
    C_Timer.After(0.05, StageItem)
  else
    StageItem()
  end
end

local function AHShown()
  return AuctionFrame and AuctionFrame:IsShown() and AuctionFrameAuctions
end

local function BlizzardAuctionsPageShown()
  return AuctionFrameAuctions and AuctionFrameAuctions:IsShown()
end

hooksecurefunc(_G, "ContainerFrameItemButton_OnEnter", function(self)
  if AHShown() and
      Auctionator.Config.Get(Auctionator.Config.Options.SELLING_BAG_SELECT_SHORTCUT) == Auctionator.Config.Shortcuts.RIGHT_CLICK then
    SetAuctionsTabShowing(true)
  end
end)

hooksecurefunc(_G, "ContainerFrameItemButton_OnClick", function(self, button)
  if AHShown() and not BlizzardAuctionsPageShown() and
      Auctionator.Utilities.IsShortcutActive(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_BAG_SELECT_SHORTCUT), button) then
    SelectOwnItem(self)
  end
end)

hooksecurefunc(_G, "ContainerFrameItemButton_OnModifiedClick", function(self, button)
  if AHShown() and not BlizzardAuctionsPageShown() and
      Auctionator.Utilities.IsShortcutActive(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_BAG_SELECT_SHORTCUT), button) then
    SelectOwnItem(self)
  end
end)
