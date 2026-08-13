LogisticianSearchProviderMixin = {}

-- Derive
function LogisticianSearchProviderMixin:OnSearchEventReceived(eventName, ...)
end

-- Derive
function LogisticianSearchProviderMixin:CreateSearchTerm(term)
end

-- Derive
function LogisticianSearchProviderMixin:GetSearchProvider()
end

-- Derive
function LogisticianSearchProviderMixin:RegisterProviderEvents()
end

-- Derive
function LogisticianSearchProviderMixin:UnregisterProviderEvents()
end

-- Derive
function LogisticianSearchProviderMixin:HasCompleteTermResults()
end

-- Derive
function LogisticianSearchProviderMixin:GetCurrentEmptyResult()
end

function LogisticianSearchProviderMixin:RegisterEvents(events)
  Logistician.Debug.Message("LogisticianSearchProviderMixin:RegisterEvents()", events)

  FrameUtil.RegisterFrameForEvents(self, events)
end

function LogisticianSearchProviderMixin:UnregisterEvents(events)
  Logistician.Debug.Message("LogisticianSearchProviderMixin:UnregisterEvents()", events)

  FrameUtil.UnregisterFrameForEvents(self, events)
end

function LogisticianSearchProviderMixin:SetTerms(terms, config)
  Logistician.Debug.Message("LogisticianSearchProviderMixin:SetTerms()", terms, config)

  self.terms = terms
  self.config = config or {}
  self.index = 1
end

function LogisticianSearchProviderMixin:GetCurrentSearchIndex()
  return self.index
end

function LogisticianSearchProviderMixin:GetSearchTermCount()
  return #self.terms
end

function LogisticianSearchProviderMixin:HasMoreTerms()
  Logistician.Debug.Message("LogisticianSearchProviderMixin:HasMoreTerms()")

  return
    self.terms ~= nil and
    #self.terms > 0 and
    self.index ~= nil and
    self.index <= #self.terms
end

function LogisticianSearchProviderMixin:GetNextSearchParameter()
  Logistician.Debug.Message("LogisticianSearchProviderMixin:GetNextSearchParameter()")

  if self:HasMoreTerms() then
    self.index = self.index + 1

    return self:CreateSearchTerm(self.terms[self.index - 1], self.config)
  else
    error("You requested a term that does not exist: " .. (self.index == nil and "nil" or self.index))
  end
end

function LogisticianSearchProviderMixin:GetCurrentSearchParameter()
  return self.terms[self.index - 1]
end
