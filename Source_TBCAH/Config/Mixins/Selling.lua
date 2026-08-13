LogisticianConfigSellingFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigSellingFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigSellingFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_SELLING_CATEGORY
  self.parent = "Logistician"

  local view = CreateScrollBoxLinearView()
  view:SetPadding(0, 25, 10, 10, 0)
  view:SetPanExtent(50)
  ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, view);
  self.ScrollBox.Content.OnCleaned = function() self.ScrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately) end
  self.ScrollBox.Content:MarkDirty()

  self:SetupPanel()
end

function LogisticianConfigSellingFrameMixin:ShowSettings()
  self.ScrollBox.Content.AuctionChatLog:SetChecked(Logistician.Config.Get(Logistician.Config.Options.AUCTION_CHAT_LOG))
  self.ScrollBox.Content.ShowBidPrice:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SHOW_SELLING_BID_PRICE))
  self.ScrollBox.Content.BagCollapsed:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_BAG_COLLAPSED))
  self.ScrollBox.Content.ConfirmPostLowPrice:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_CONFIRM_LOW_PRICE))
  self.ScrollBox.Content.AlwaysLoadMore:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_ALWAYS_LOAD_MORE))
  self.ScrollBox.Content.GreyPostButton:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_GREY_POST_BUTTON))

  self.ScrollBox.Content.BagShown:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SHOW_SELLING_BAG))
  self.ScrollBox.Content.IconSize:SetNumber(Logistician.Config.Get(Logistician.Config.Options.SELLING_ICON_SIZE))
  self.ScrollBox.Content.AutoSelectNext:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_AUTO_SELECT_NEXT))
  self.ScrollBox.Content.AutoSelectStackRemainder:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_POST_STACK_REMAINDER))
  self.ScrollBox.Content.ReselectItem:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_SHOULD_RESELECT_ITEM))
  self.ScrollBox.Content.MissingFavourites:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_MISSING_FAVOURITES))
  self.ScrollBox.Content.PossessedFavouritesFirst:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_FAVOURITES_SORT_OWNED))

  self.ScrollBox.Content.UnhideAll:SetEnabled(#LOGISTICIAN_SELLING_GROUPS.HiddenItems ~= 0)
end

function LogisticianConfigSellingFrameMixin:Save()
  Logistician.Debug.Message("LogisticianConfigSellingFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.AUCTION_CHAT_LOG, self.ScrollBox.Content.AuctionChatLog:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SHOW_SELLING_BID_PRICE, self.ScrollBox.Content.ShowBidPrice:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_BAG_COLLAPSED, self.ScrollBox.Content.BagCollapsed:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_CONFIRM_LOW_PRICE, self.ScrollBox.Content.ConfirmPostLowPrice:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_ALWAYS_LOAD_MORE, self.ScrollBox.Content.AlwaysLoadMore:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_GREY_POST_BUTTON, self.ScrollBox.Content.GreyPostButton:GetChecked())

  Logistician.Config.Set(Logistician.Config.Options.SHOW_SELLING_BAG, self.ScrollBox.Content.BagShown:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_ICON_SIZE, math.min(50, math.max(10, self.ScrollBox.Content.IconSize:GetNumber())))
  Logistician.Config.Set(Logistician.Config.Options.SELLING_AUTO_SELECT_NEXT, self.ScrollBox.Content.AutoSelectNext:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_POST_STACK_REMAINDER, self.ScrollBox.Content.AutoSelectStackRemainder:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_SHOULD_RESELECT_ITEM, self.ScrollBox.Content.ReselectItem:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_MISSING_FAVOURITES, self.ScrollBox.Content.MissingFavourites:GetChecked())
  Logistician.Config.Set(Logistician.Config.Options.SELLING_FAVOURITES_SORT_OWNED, self.ScrollBox.Content.PossessedFavouritesFirst:GetChecked())
end

function LogisticianConfigSellingFrameMixin:UnhideAllClicked()
  Logistician.Groups.UnhideAll()
  Logistician.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
  self.ScrollBox.Content.UnhideAll:Disable()
end

function LogisticianConfigSellingFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigSellingFrameMixin:Cancel()")
end
