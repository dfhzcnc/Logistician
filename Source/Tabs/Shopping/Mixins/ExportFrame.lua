LogisticianListExportFrameMixin = {}

function LogisticianListExportFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianListExportFrameMixin:OnLoad()")

  -- Setup scrolling region
  local view = CreateScrollBoxLinearView()
  view:SetPadding(5, 5, 0, 0, 0)
  view:SetPanExtent(50)
  ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, view);

  self.ScrollBox.ListListingFrame.OnCleaned = function()
    self.ScrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately);
  end

  self.copyTextDialog = CreateFrame("Frame", nil, self:GetParent(), "LogisticianExportTextFrame")
  self.copyTextDialog:SetPoint("CENTER")

  if self:GetParent().dialogs then
    table.insert(self:GetParent().dialogs, self.copyTextDialog)
  end

  -- self.ExportOption:SetOnChange(function(selectedValue)
  --   if selectedValue == Logistician.Constants.EXPORT_TYPES.WHISPER then
  --     self.Recipient:Show()
  --     self.Recipient:SetFocus()
  --   else
  --     self.Recipient:Hide()
  --   end
  -- end)
  -- self.ExportOption:SetSelectedValue(Logistician.Constants.EXPORT_TYPES.STRING)

  self.checkBoxPool = CreateFramePool("Frame", self.ScrollBox.ListListingFrame, "LogisticianConfigurationCheckbox")
end

function LogisticianListExportFrameMixin:OnShow()
  Logistician.Debug.Message("LogisticianListExportFrameMixin:OnShow()")

  Logistician.EventBus:Register(self, { Logistician.Shopping.Events.ListMetaChange })

  self:RefreshLists()

  Logistician.EventBus
    :RegisterSource(self, "lists export dialog 1")
    :Fire(self, Logistician.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function LogisticianListExportFrameMixin:OnHide()
  self:Hide()

  Logistician.EventBus:Unregister(self, { Logistician.Shopping.Events.ListMetaChange })

  Logistician.EventBus
    :RegisterSource(self, "lists export dialog 1")
    :Fire(self, Logistician.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function LogisticianListExportFrameMixin:ReceiveEvent(eventName, listName)
  if eventName == Logistician.Shopping.Events.ListMetaChange then
    if self:IsShown() then
      self:RefreshLists()
    end
  end
end

function LogisticianListExportFrameMixin:RefreshLists()
  Logistician.Debug.Message("LogisticianListExportFrameMixin:RefreshLists()")
  self.checkBoxPool:ReleaseAll()

  for index = 1, Logistician.Shopping.ListManager:GetCount() do
    local list = Logistician.Shopping.ListManager:GetByIndex(index)
    local checkBox = self.checkBoxPool:Acquire()
    checkBox:SetText(list:GetName())
    checkBox:SetHeight(25)
    checkBox:SetPoint("TOPRIGHT", self.ScrollBox.ListListingFrame, "TOPRIGHT", 0, -(checkBox:GetHeight()) * (index - 1))
    checkBox:SetPoint("TOPLEFT", self.ScrollBox.ListListingFrame, "TOPLEFT", 0, -(checkBox:GetHeight()) * (index - 1))
    checkBox:Show()
  end

  self.ScrollBox.ListListingFrame:MarkDirty()
end

function LogisticianListExportFrameMixin:OnCloseDialogClicked()
  self:Hide()
end

function LogisticianListExportFrameMixin:OnSelectAllClicked()
  for checkbox in self.checkBoxPool:EnumerateActive() do
    checkbox:SetChecked(true)
  end
end

function LogisticianListExportFrameMixin:OnUnselectAllClicked()
  for checkbox in self.checkBoxPool:EnumerateActive() do
    checkbox:SetChecked(false)
  end
end

function LogisticianListExportFrameMixin:OnExportClicked()
  local exportString = ""

  for checkbox in self.checkBoxPool:EnumerateActive() do
    if checkbox:GetChecked() then
      exportString = exportString .. Logistician.Shopping.Lists.GetBatchExportString(checkbox:GetText()) .. "\n"
    end
  end

  -- if self.ExportOption:GetValue() == 0 then
    self:Hide()
    self.copyTextDialog:SetExportString(exportString)
    self.copyTextDialog:Show()
  -- else
    -- Addon messages can not exceed 254 characters, so do lists one by one?
    -- for checkbox in self.checkBoxPool:EnumerateActive() do
    --   if checkbox:IsVisible() and checkbox:GetChecked() then
    --     C_ChatInfo.SendAddonMessage( "Logistician", Logistician.Shopping.Lists.GetBatchExportString(checkbox:GetText()), "WHISPER", self.Recipient:GetText())
    --   end
    -- end
    -- C_ChatInfo.SendAddonMessage( "Logistician", exportString, "WHISPER", self.Recipient:GetText())
  -- end

end
