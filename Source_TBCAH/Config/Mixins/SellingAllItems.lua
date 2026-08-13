LogisticianConfigSellingAllItemsFrameMixin = CreateFromMixins(LogisticianPanelConfigMixin)

function LogisticianConfigSellingAllItemsFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianConfigSellingAllItemsFrameMixin:OnLoad()")

  self.name = LOGISTICIAN_L_CONFIG_SELLING_ALL_ITEMS_CATEGORY
  self.parent = "Logistician"
  self.beenShown = false

  self:SetupPanel()

  self.SalesPreference:SetOnChange(function(selectedValue)
    self:OnSalesPreferenceChange(selectedValue)
  end)
end

function LogisticianConfigSellingAllItemsFrameMixin:ShowSettings()
  self.beenShown = true
  self.currentUndercutPreference = Logistician.Config.Get(Logistician.Config.Options.AUCTION_SALES_PREFERENCE)

  self.DurationGroup:SetSelectedValue(Logistician.Config.Get(Logistician.Config.Options.AUCTION_DURATION))
  self.SaveLastDurationAsDefault:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT))
  self.SalesPreference:SetSelectedValue(self.currentUndercutPreference)

  self:OnSalesPreferenceChange(self.currentUndercutPreference)

  self.UndercutPercentage:SetNumber(Logistician.Config.Get(Logistician.Config.Options.UNDERCUT_PERCENTAGE))
  self.UndercutValue:SetAmount(Logistician.Config.Get(Logistician.Config.Options.UNDERCUT_STATIC_VALUE))

  self.GearPriceMultiplier:SetNumber(Logistician.Config.Get(Logistician.Config.Options.GEAR_PRICE_MULTIPLIER))

  self.StartingPricePercentage:SetNumber(Logistician.Config.Get(Logistician.Config.Options.STARTING_PRICE_PERCENTAGE))

  local defaultStacks = Logistician.Config.Get(Logistician.Config.Options.DEFAULT_SELLING_STACKS)
  self.DefaultStacks.StackSize:SetNumber(defaultStacks.stackSize)
  self.DefaultStacks.NumStacks:SetNumber(defaultStacks.numStacks)
  self.DefaultStacks.StackSize:Show()
  self.DefaultStacks.NumStacks:Show()
  self.DefaultStacks:SetMaxStackSize(0)
  self.DefaultStacks:SetMaxNumStacks(0)

  self.ResetStackSizeMemory:SetEnabled(next(Logistician.Config.Get(Logistician.Config.Options.STACK_SIZE_MEMORY)) ~= nil)

  self.IgnoreItemSuffix:SetChecked(Logistician.Config.Get(Logistician.Config.Options.SELLING_IGNORE_ITEM_SUFFIX))
end

function LogisticianConfigSellingAllItemsFrameMixin:OnSalesPreferenceChange(selectedValue)
  self.currentUndercutPreference = selectedValue

  if self.currentUndercutPreference == Logistician.Config.SalesTypes.PERCENTAGE then
    self.UndercutPercentage:Show()
    self.UndercutValue:Hide()
  else
    self.UndercutValue:Show()
    self.UndercutPercentage:Hide()
  end
end

function LogisticianConfigSellingAllItemsFrameMixin:Save()
  if not self.beenShown then
    return
  end

  Logistician.Debug.Message("LogisticianConfigSellingAllItemsFrameMixin:Save()")

  Logistician.Config.Set(Logistician.Config.Options.AUCTION_DURATION, self.DurationGroup:GetValue())
  Logistician.Config.Set(Logistician.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT, self.SaveLastDurationAsDefault:GetChecked())

  Logistician.Config.Set(Logistician.Config.Options.AUCTION_SALES_PREFERENCE, self.SalesPreference:GetValue())
  Logistician.Config.Set(
    Logistician.Config.Options.UNDERCUT_PERCENTAGE,
    Logistician.Utilities.ValidatePercentage(self.UndercutPercentage:GetNumber())
  )
  Logistician.Config.Set(Logistician.Config.Options.UNDERCUT_STATIC_VALUE, self.UndercutValue:GetAmount())

  Logistician.Config.Set(Logistician.Config.Options.GEAR_PRICE_MULTIPLIER, self.GearPriceMultiplier:GetNumber())

  local newPercentage = Logistician.Utilities.ValidatePercentage(self.StartingPricePercentage:GetNumber())
  if newPercentage > 0 then
    Logistician.Config.Set(
      Logistician.Config.Options.STARTING_PRICE_PERCENTAGE,
      newPercentage
    )
  end

  local defaultStacks = {
    stackSize = self.DefaultStacks.StackSize:GetNumber(),
    numStacks = self.DefaultStacks.NumStacks:GetNumber()
  }
  Logistician.Config.Set(Logistician.Config.Options.DEFAULT_SELLING_STACKS, defaultStacks)
  Logistician.Config.Set(Logistician.Config.Options.SELLING_IGNORE_ITEM_SUFFIX, self.IgnoreItemSuffix:GetChecked())
end

function LogisticianConfigSellingAllItemsFrameMixin:ResetStackSizeMemoryClicked()
  Logistician.Config.Set(Logistician.Config.Options.STACK_SIZE_MEMORY, {})
  self.ResetStackSizeMemory:Disable()
end

function LogisticianConfigSellingAllItemsFrameMixin:Cancel()
  Logistician.Debug.Message("LogisticianConfigSellingAllItemsFrameMixin:Cancel()")
end
