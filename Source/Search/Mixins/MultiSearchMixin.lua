LogisticianMultiSearchMixin = {}

function LogisticianMultiSearchMixin:InitSearch(completionCallback, incrementCallback)
  Logistician.Debug.Message("LogisticianMultiSearchMixin:InitSearch()")

  self.complete = true
  self.onSearchComplete = completionCallback or function()
    Logistician.Debug.Message("Search completed.")
  end
  self.onNextSearch = incrementCallback or function()
    Logistician.Debug.Message("Next search.")
  end
end

function LogisticianMultiSearchMixin:OnEvent(event, ...)
  self:OnSearchEventReceived(event, ...)
end

function LogisticianMultiSearchMixin:Search(terms, config)
  Logistician.Debug.Message("LogisticianMultiSearchMixin:Search()", terms)

  self.complete = false
  self.partialResults = {}
  self.fullResults = {}
  self.anyResultsForThisTerm = false

  self:RegisterProviderEvents()

  self:SetTerms(terms, config)
  self:NextSearch()
end

function LogisticianMultiSearchMixin:AbortSearch()
  self:UnregisterProviderEvents()
  local isComplete = self.complete
  self.complete = true
  if not isComplete then
    self.onSearchComplete(self.fullResults)
  end
end

function LogisticianMultiSearchMixin:AddResults(results)
  Logistician.Debug.Message("LogisticianSearchProviderMixin:AddResults()")

  if #results > 0 then
    self.anyResultsForThisTerm = true
  end

  for index = 1, #results do
    table.insert(self.partialResults, results[index])
    table.insert(self.fullResults, results[index])
  end

  if self:HasCompleteTermResults() then
    self:NextSearch()
  end
end

function LogisticianMultiSearchMixin:NoResultsForTermCheck()
  if self.config and self.config.suppressMissingTerms then
    return
  end
  if not Logistician.Config.Get(Logistician.Config.Options.SHOPPING_LIST_MISSING_TERMS) then
    return
  end

  if self:GetCurrentSearchParameter() and not self.anyResultsForThisTerm then
    local emptyResult = self:GetCurrentEmptyResult()
    table.insert(self.partialResults, emptyResult)
    table.insert(self.fullResults, emptyResult)
  end
end

function LogisticianMultiSearchMixin:NextSearch()
  if self:HasMoreTerms() then
    self:NoResultsForTermCheck()
    self.anyResultsForThisTerm = false

    self.onNextSearch(
      self:GetCurrentSearchIndex(),
      self:GetSearchTermCount(),
      self.partialResults
    )
    self.partialResults = {}
    self:GetSearchProvider()(self:GetNextSearchParameter())
  else
    Logistician.Debug.Message("LogisticianMultiSearchMixin:NextSearch Complete")

    self:NoResultsForTermCheck()

    self:UnregisterProviderEvents()

    self.complete = true
    self.onSearchComplete(self.fullResults)
  end
end
