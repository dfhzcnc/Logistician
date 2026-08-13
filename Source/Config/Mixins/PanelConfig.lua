AuctionatorPanelConfigMixin = {}

function AuctionatorPanelConfigMixin:SetupPanel()
  self.cancel = function()
    self:Cancel()
  end

  self.okay = function()
    if self.shownSettings then
      self:Save()
    end
  end

  self.shownSettings =  false

  self.OnCommit = self.okay
  self.OnDefault = function() end
  self.OnRefresh = function() end

  if self.parent == nil then
    -- The third argument is the real addon folder/metadata identifier. Without
    -- it Blizzard cannot associate this settings category with !Logistician's
    -- TOC IconTexture and falls back to the generic red addon icon.
    local category = Settings.RegisterCanvasLayoutCategory(self, self.name, "!Logistician")
    Settings.RegisterAddOnCategory(category)
    Auctionator.State.OptionsCategory = category

    -- Keep the integrated addon's settings easy to navigate: auction-house
    -- pages live below Auction, while profession and pet-skill controls use a
    -- separate Professions & Skills branch created by Professions/Options.lua.
    if Settings.RegisterVerticalLayoutSubcategory then
      local auctionCategory = Settings.RegisterVerticalLayoutSubcategory(category, "Auction")
      Settings.RegisterAddOnCategory(auctionCategory)
      Auctionator.State.AuctionOptionsCategory = auctionCategory
    end
  else
    local parentCategory = Auctionator.State.AuctionOptionsCategory or Auctionator.State.OptionsCategory
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, self, self.name)
    Settings.RegisterAddOnCategory(subcategory)
  end
end

function AuctionatorPanelConfigMixin:OnShow()
  self:ShowSettings()
  self.shownSettings = true
end

-- Derive
function AuctionatorPanelConfigMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorPanelConfigMixin:Cancel() Unimplemented")
end

-- Derive
function AuctionatorPanelConfigMixin:Save()
  Auctionator.Debug.Message("AuctionatorPanelConfigMixin:Save() Unimplemented")
end
