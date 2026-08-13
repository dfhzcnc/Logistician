LogisticianGroupsViewItemMixin = {}

function LogisticianGroupsViewItemMixin:SetClickEvent(eventName)
  self.clickEventName = eventName
end

function LogisticianGroupsViewItemMixin:SetItemInfo(info)
  self.itemInfo = info

  if info ~= nil then

    self.Icon:SetTexture(info.iconTexture)
    self.Icon:Show()

    if info.selected then
      self.Icon:SetAlpha(0.8)
    else
      self.Icon:SetAlpha(1)
    end
    local selectedColor = {r=0.977, g=0.592, b=0.086}

    self.IconSelectedHighlight:SetVertexColor(selectedColor.r, selectedColor.g, selectedColor.b)
    self.IconSelectedHighlight:SetShown(info.selected)

    self.IconBorder:SetVertexColor(
      ITEM_QUALITY_COLORS[self.itemInfo.quality].r,
      ITEM_QUALITY_COLORS[self.itemInfo.quality].g,
      ITEM_QUALITY_COLORS[self.itemInfo.quality].b,
      1
    )
    self.IconBorder:SetShown(not info.selected)

    self.Text:SetText(info.itemCount)

    self:ApplyQualityIcon(info.itemLink)

  else
    self.IconBorder:Hide()
    self.Icon:Hide()
    self.Text:SetText("")
    self:SetAlpha(1)

    self:HideQualityIcon()
  end

  self.initializationTime = GetTime()
end

function LogisticianGroupsViewItemMixin:OnEnter()
  if GetTime() - self.initializationTime > 0 then
    self:UpdateTooltip()
  end
end

function LogisticianGroupsViewItemMixin:UpdateTooltip()
  if self.itemInfo ~= nil then
    if IsModifiedClick("DRESSUP") then
      ShowInspectCursor();
    else
      ResetCursor()
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if Logistician.Utilities.IsPetLink(self.itemInfo.itemLink) then
      BattlePetToolTip_ShowLink(self.itemInfo.itemLink)
    else
      GameTooltip:SetHyperlink(self.itemInfo.itemLink)
      GameTooltip:Show()
    end
  end
end

function LogisticianGroupsViewItemMixin:OnLeave()
  ResetCursor()
  if BattlePetTooltip then
    BattlePetTooltip:Hide()
  end
  GameTooltip:Hide()
end

function LogisticianGroupsViewItemMixin:OnClick(button)
  if self.itemInfo ~= nil then
    if IsModifiedClick("DRESSUP") then
      (DressUpLink or DressUpItemLink)(self.itemInfo.itemLink)

    elseif IsModifiedClick("CHATLINK") then
      Logistician.Utilities.InsertLink(self.itemInfo.itemLink)

    else
      Logistician.Groups.CallbackRegistry:TriggerEvent(self.clickEventName, self, button)
    end
  end
end

function LogisticianGroupsViewItemMixin:ApplyQualityIcon(itemLink)
  self:HideQualityIcon()
end

function LogisticianGroupsViewItemMixin:HideQualityIcon()
  if self.ProfessionQualityOverlay then
    self.ProfessionQualityOverlay:Hide()
  end
end
