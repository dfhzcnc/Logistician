AuctionatorLedgerFrameMixin = {}

function AuctionatorLedgerFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorLedgerFrameMixin:OnLoad()")

  self.ResultsListing:SetScrollBarOffsetX(0)
  self.ResultsListing:Init(self.DataProvider)

  self.DataProvider:SetOnTotalChangedCallback(function(totalGold)
    self.TotalValue:SetText(GetMoneyString(totalGold, true))
  end)

  self.FilterBox:SetAutoFocus(false)
  if self.FilterBox.Instructions then
    self.FilterBox.Instructions:SetText(AUCTIONATOR_L_SEARCH)
  end
  self.FilterBox:HookScript("OnTextChanged", function()
    self.DataProvider:SetFilterText(self.FilterBox:GetText())
  end)
end
