LogisticianConfigTabMixin = {}

function LogisticianConfigTabMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigTabMixin:OnLoad()")

  -- Logistician has one author and a donation section. Community engagement
  -- and translator sections are intentionally omitted until they are used.
  self.ContributorsHeading:Hide()
  self.Contributors:Hide()
  self.ContributeHeading:Show()
  self.ContributeLink:Show()
  self.EngageHeading:Hide()
  self.DiscordLink:Hide()
  self.BugReportLink:Hide()
  self.TranslatorsHeading:Hide()

  for _, key in ipairs({
    "deDE", "ptBR", "zhCN", "zhTW", "esES", "esMX", "frFR",
    "itIT", "koKR", "ruRU", "tkTK", "roRO",
  }) do
    if self[key] then
      self[key]:Hide()
    end
  end
end

function LogisticianConfigTabMixin:OpenOptions()
  Settings.OpenToCategory(Logistician.State.OptionsCategory:GetID())
end
