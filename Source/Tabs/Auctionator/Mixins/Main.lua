AuctionatorConfigTabMixin = {}

function AuctionatorConfigTabMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigTabMixin:OnLoad()")

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

function AuctionatorConfigTabMixin:OpenOptions()
  Settings.OpenToCategory(Auctionator.State.OptionsCategory:GetID())
end
