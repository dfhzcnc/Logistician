LogisticianEscapeToCloseMixin = {}

function LogisticianEscapeToCloseMixin:OnKeyDown(key)
  self:SetPropagateKeyboardInput(key ~= "ESCAPE")
end

function LogisticianEscapeToCloseMixin:OnKeyUp(key)
  Logistician.Debug.Message("LogisticianEscapeToCloseMixin:OnKeyUp()", key)

  if key == "ESCAPE" then
    self:Hide()
  end
end
