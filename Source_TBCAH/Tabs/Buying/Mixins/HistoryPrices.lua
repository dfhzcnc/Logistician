LogisticianBuyHistoryPricesFrameMixin = {}
function LogisticianBuyHistoryPricesFrameMixin:Init()
  self.RealmHistoryResultsListing:Init(self.RealmHistoryDataProvider)
  self.PostingHistoryResultsListing:Init(self.PostingHistoryDataProvider)
end

function LogisticianBuyHistoryPricesFrameMixin:Reset()
  self.RealmHistoryDataProvider:Reset()
  self.PostingHistoryDataProvider:Reset()

  self:SelectRealmHistory()
end

function LogisticianBuyHistoryPricesFrameMixin:SelectRealmHistory()
  self.RealmHistoryResultsListing:Show()
  self.PostingHistoryResultsListing:Hide()

  self.RealmHistoryButton:Disable()
  self.PostingHistoryButton:Enable()
end

function LogisticianBuyHistoryPricesFrameMixin:SelectPostingHistory()
  self.RealmHistoryResultsListing:Hide()
  self.PostingHistoryResultsListing:Show()

  self.RealmHistoryButton:Enable()
  self.PostingHistoryButton:Disable()
end
