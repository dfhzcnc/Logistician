LogisticianListImportFrameMixin = {}

function LogisticianListImportFrameMixin:OnLoad()
  Logistician.Debug.Message("LogisticianListImportFrameMixin:OnLoad()")

  ScrollUtil.RegisterScrollBoxWithScrollBar(self.EditBoxContainer:GetScrollBox(), self.ScrollBar)
  self.EditBoxContainer:GetScrollBox():GetView():SetPanExtent(50)
end

function LogisticianListImportFrameMixin:OnShow()
  Logistician.Debug.Message("LogisticianListImportFrameMixin:OnShow()")

  self.EditBoxContainer:GetEditBox():SetFocus()

  Logistician.EventBus
    :RegisterSource(self, "lists import dialog")
    :Fire(self, Logistician.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function LogisticianListImportFrameMixin:OnHide()
  self.EditBoxContainer:GetEditBox():SetText("")
  self:Hide()
  Logistician.EventBus
    :RegisterSource(self, "lists import dialog")
    :Fire(self, Logistician.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function LogisticianListImportFrameMixin:ReceiveEvent(eventName, eventData)
  if eventName == Logistician.Shopping.Events.ListImportFinished then
    Logistician.EventBus:Unregister(self, { Logistician.Shopping.Events.ListImportFinished })
    Logistician.EventBus
      :RegisterSource(self, "lists import dialog")
      :Fire(self, Logistician.Shopping.Tab.Events.ListCreated, Logistician.Shopping.ListManager:GetByName(eventData))
      :UnregisterSource(self)
  end
end

function LogisticianListImportFrameMixin:OnCloseDialogClicked()
  self:Hide()
end

function LogisticianListImportFrameMixin:OnImportClicked()
  -- register finished event early as sometimes it fires immediately
  Logistician.EventBus:Register(self, { Logistician.Shopping.Events.ListImportFinished })

  local importString = self.EditBoxContainer:GetEditBox():GetText()

  local waiting = true
  if string.match(importString, "%^") then
    Logistician.Debug.Message("Import shopping list with 8.3+ format")
    Logistician.Shopping.Lists.BatchImportFromString(importString)
  elseif string.match(importString, "%*") then
    Logistician.Debug.Message("Import shopping list from old format")
    Logistician.Shopping.Lists.OldBatchImportFromString(importString)
  elseif string.match(importString, "%,") then
    Logistician.Debug.Message("Import shopping list from TSM group")
    Logistician.Shopping.Lists.TSMImportFromString(importString)
  else
    waiting = false
  end

  -- Only listen for the import finished event if a valid format was detected
  if not waiting then
    Logistician.EventBus:Unregister(self, { Logistician.Shopping.Events.ListImportFinished })
  end

  self:Hide()
end
