LogisticianSellingTabMixin = {}

function LogisticianSellingTabMixin:OnLoad()
  self:ApplyHiding()

  Logistician.Groups.OnAHOpen()
  local defaultIconSize = Logistician.Config.Defaults[Logistician.Config.Options.SELLING_ICON_SIZE]
  local currentIconSize = Logistician.Config.Get(Logistician.Config.Options.SELLING_ICON_SIZE)
  local defaultIconsPerRow = 6
  self.BagListing:SetWidth(math.ceil(defaultIconsPerRow * defaultIconSize / currentIconSize ) * currentIconSize + self.BagListing.View.ScrollBar:GetWidth() + 4 * 2)

  self.BuyFrame:Init()
  self.BuyFrame.CurrentPrices.SearchResultsListing:SetScrollBarOffsetX(0)
end

function LogisticianSellingTabMixin:ApplyHiding()
  if not Logistician.Config.Get(Logistician.Config.Options.SHOW_SELLING_BAG) then
    self.BagListing:Hide()
    self.BagInset:Hide()
    self.BuyFrame:SetPoint("TOPLEFT", self.BagListing, "TOPLEFT", 10, 10)
    self.BuyFrame.HistoryButton:SetPoint("LEFT", AuctionFrameMoneyFrame, "RIGHT")
  end
end

function LogisticianSellingTabMixin:OnHide()
  self:Hide()
end
