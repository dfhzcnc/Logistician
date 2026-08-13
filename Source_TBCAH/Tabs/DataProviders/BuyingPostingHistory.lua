LogisticianBuyingPostingHistoryProviderMixin = CreateFromMixins(LogisticianPostingHistoryProviderMixin)

function LogisticianBuyingPostingHistoryProviderMixin:OnLoad()
  LogisticianPostingHistoryProviderMixin.OnLoad(self)
end

function LogisticianBuyingPostingHistoryProviderMixin:SetItemLink(itemLink)
  Logistician.Utilities.DBKeyFromLink(itemLink, function(dbKeys)
    self:SetItem(dbKeys[1])
  end)
end

function LogisticianBuyingPostingHistoryProviderMixin:GetColumnHideStates()
  return Logistician.Config.Get(Logistician.Config.Options.COLUMNS_POSTING_HISTORY)
end

function LogisticianBuyingPostingHistoryProviderMixin:GetRowTemplate()
  return "LogisticianBuyingPostingHistoryRowTemplate"
end
