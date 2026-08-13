LogisticianEnchantInfoFrameMixin = {}

function LogisticianEnchantInfoFrameMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED",
  })

  self.originalFirstLine = CraftDescription or CraftReagentLabel
  self.originalDescriptionPoint = {self.originalFirstLine:GetPoint(1)}

  hooksecurefunc(_G, "CraftFrame_SetSelection", function(ecipeID)
    self:ShowIfRelevant()
    if self:IsVisible() then
      self:UpdateTotal()
    end
  end)
  Logistician.API.v1.RegisterForDBUpdate(LOGISTICIAN_L_REAGENT_SEARCH, function()
    if self:IsVisible() then
      self:UpdateTotal()
    end
  end)
  self:ShowIfRelevant()
  if self:IsVisible() then
    self:UpdateTotal()
  end
end

function LogisticianEnchantInfoFrameMixin:ShowIfRelevant()
  self:SetShown(Logistician.Config.Get(Logistician.Config.Options.CRAFTING_INFO_SHOW) and GetCraftSelectionIndex() ~= 0)
  if self:IsVisible() then
    self.SearchButton:SetShown(AuctionFrame ~= nil and AuctionFrame:IsShown())

    self:SetPoint(unpack(self.originalDescriptionPoint))
    self.originalFirstLine:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
  else
    self.originalFirstLine:SetPoint(unpack(self.originalDescriptionPoint))
  end
end

function LogisticianEnchantInfoFrameMixin:UpdateTotal()
  self.Total:SetText(Logistician.EnchantInfo.GetInfoText())
end

function LogisticianEnchantInfoFrameMixin:SearchButtonClicked()
  if AuctionFrame and AuctionFrame:IsShown() then
    Logistician.EnchantInfo.DoCraftReagentsSearch()
  end
end

function LogisticianEnchantInfoFrameMixin:OnEvent(...)
  if self:IsVisible() then
    self:UpdateTotal()
  end
end
