LogisticianShoppingTabClassicLoadAllButtonMixin = {}

function LogisticianShoppingTabClassicLoadAllButtonMixin:OnLoad()
  Logistician.EventBus:Register(self, {
    Logistician.Shopping.Tab.Events.SearchStart,
    Logistician.Shopping.Tab.Events.SearchEnd,
  })
end

function LogisticianShoppingTabClassicLoadAllButtonMixin:ReceiveEvent(eventName, eventData)
  if eventName == Logistician.Shopping.Tab.Events.SearchStart then
    self.lastTerms = eventData
    self:Hide()
  elseif eventName == Logistician.Shopping.Tab.Events.SearchEnd then
    if eventData and #eventData > 0 then
      local anyIncomplete = false
      for _, entry in ipairs(eventData) do
        if not entry.complete then
          anyIncomplete = true
          break
        end
      end
      self:SetShown(anyIncomplete)
    end
   end
end

function LogisticianShoppingTabClassicLoadAllButtonMixin:OnClick()
  if self.lastTerms ~= nil then
    self:GetParent():DoSearch(self.lastTerms, { searchAllPages = true })
  end
end
