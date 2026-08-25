AuctionatorItemKeyCellTemplateMixin = CreateFromMixins(AuctionatorCellMixin, AuctionatorRetailImportTableBuilderCellMixin)

local function HideComparisonTooltips()
  if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
  if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
end

local function PositionTooltipAtCursor()
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale + 10)
end

local function UpdateEquipmentComparison(self)
  PositionTooltipAtCursor()

  local shiftDown = IsShiftKeyDown()
  if self.comparisonShiftDown == shiftDown then return end
  self.comparisonShiftDown = shiftDown

  if shiftDown and GameTooltip_ShowCompareItem then
    GameTooltip_ShowCompareItem(GameTooltip)
  else
    HideComparisonTooltips()
  end
end

local function HideDressUpPreview(self)
  if self.controlPreviewActive then
    if DressUpFrame then DressUpFrame:Hide() end
    self.controlPreviewActive = nil
  end
end

local function UpdateDressUpPreview(self)
  local controlDown = IsControlKeyDown()
  if self.previewControlDown == controlDown then return end
  self.previewControlDown = controlDown

  if controlDown and self.rowData.itemLink then
    local wasAlreadyShown = DressUpFrame and DressUpFrame:IsShown()
    if DressUpItemLink then
      DressUpItemLink(self.rowData.itemLink)
      self.controlPreviewActive = not wasAlreadyShown
    elseif DressUpLink then
      DressUpLink(self.rowData.itemLink)
      self.controlPreviewActive = not wasAlreadyShown
    end
  else
    HideDressUpPreview(self)
  end
end

local function UpdateModifierPreviews(self)
  UpdateEquipmentComparison(self)
  UpdateDressUpPreview(self)
end

function AuctionatorItemKeyCellTemplateMixin:Init()
  self.Text:SetJustifyH("LEFT")
end

function AuctionatorItemKeyCellTemplateMixin:Populate(rowData, index)
  AuctionatorCellMixin.Populate(self, rowData, index)

  self.Text:SetText(rowData.itemName or "")

  if rowData.iconTexture ~= nil then
    self.Icon:SetTexture(rowData.iconTexture)
    self.Icon:Show()
  end

  self.Icon:SetAlpha(rowData.noneAvailable and 0.5 or 1.0)
end

function AuctionatorItemKeyCellTemplateMixin:OnEnter()
  if self.rowData.itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    PositionTooltipAtCursor()
    GameTooltip:SetHyperlink(self.rowData.itemLink)
    GameTooltip:Show()
    self.comparisonShiftDown = nil
    self.previewControlDown = nil
    UpdateModifierPreviews(self)
    self:SetScript("OnUpdate", UpdateModifierPreviews)
  end
  AuctionatorCellMixin.OnEnter(self)
end

function AuctionatorItemKeyCellTemplateMixin:OnClick(button, ...)
  if button == "LeftButton" and IsControlKeyDown() and self.rowData.itemLink then
    if DressUpItemLink then
      DressUpItemLink(self.rowData.itemLink)
    elseif DressUpLink then
      DressUpLink(self.rowData.itemLink)
    end
    return
  end

  AuctionatorCellMixin.OnClick(self, button, ...)
end

function AuctionatorItemKeyCellTemplateMixin:OnLeave()
  self:SetScript("OnUpdate", nil)
  self.comparisonShiftDown = nil
  self.previewControlDown = nil
  HideDressUpPreview(self)
  if self.rowData.itemLink then
    GameTooltip:Hide()
    HideComparisonTooltips()
  end
  AuctionatorCellMixin.OnLeave(self)
end
