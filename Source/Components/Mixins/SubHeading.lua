LogisticianConfigurationSubHeadingMixin = {}

function LogisticianConfigurationSubHeadingMixin:InitializeSubHeading()
  Logistician.Debug.Message("LogisticianConfigurationSubHeadingMixin:InitializeSubHeading()")

  if self.subHeadingText ~= nil then
    self.HeadingText:SetText(self.subHeadingText)
  end
end

function LogisticianConfigurationSubHeadingMixin:SetText(newHeading)
  self.subHeadingText = newHeading
  self:OnLoad()
end
