AuctionatorLedgerFrameMixin = {}

function AuctionatorLedgerFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorLedgerFrameMixin:OnLoad()")

  self.ResultsListing:SetScrollBarOffsetX(0)
  self.ResultsListing:Init(self.DataProvider)
end
