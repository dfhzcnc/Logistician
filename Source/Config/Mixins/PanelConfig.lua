LogisticianPanelConfigMixin = {}

function LogisticianPanelConfigMixin:SetupPanel()
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
    Logistician.State.OptionsCategory = category

    -- Keep the integrated addon's settings easy to navigate: auction-house
    -- pages live below Auction, while profession and pet-skill controls use a
    -- separate Professions & Skills branch created by Professions/Options.lua.
    if Settings.RegisterVerticalLayoutSubcategory then
      local auctionCategory = Settings.RegisterVerticalLayoutSubcategory(category, "Auction")
      Settings.RegisterAddOnCategory(auctionCategory)
      Logistician.State.AuctionOptionsCategory = auctionCategory
    end
  else
    local parentCategory = Logistician.State.AuctionOptionsCategory or Logistician.State.OptionsCategory
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, self, self.name)
    Settings.RegisterAddOnCategory(subcategory)
  end
end

function LogisticianPanelConfigMixin:OnShow()
  self:ShowSettings()
  self.shownSettings = true
end

-- Derive
function LogisticianPanelConfigMixin:Cancel()
  Logistician.Debug.Message("LogisticianPanelConfigMixin:Cancel() Unimplemented")
end

-- Derive
function LogisticianPanelConfigMixin:Save()
  Logistician.Debug.Message("LogisticianPanelConfigMixin:Save() Unimplemented")
end
