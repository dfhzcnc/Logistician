LogisticianConfigurationHeadingMixin = {}

function LogisticianConfigurationHeadingMixin:OnLoad()
  if self.headingText ~= nil then
    self.HeadingText:SetText(self.headingText)
  end
end