LogisticianResetButtonMixin = {}

function LogisticianResetButtonMixin:OnLoad()
  self.clickCallback = function() end
end

function LogisticianResetButtonMixin:OnClick()
  self.clickCallback()
end

function LogisticianResetButtonMixin:SetClickCallback(callback)
  self.clickCallback = callback
end