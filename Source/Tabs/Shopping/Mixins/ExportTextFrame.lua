LogisticianExportTextFrameMixin = {}

function LogisticianExportTextFrameMixin:OnLoad()
  ScrollUtil.RegisterScrollBoxWithScrollBar(self.EditBoxContainer:GetScrollBox(), self.ScrollBar)
  self.EditBoxContainer:GetScrollBox():GetView():SetPanExtent(50)
end

function LogisticianExportTextFrameMixin:SetOpeningEvents(open, close)
  self.openEvent = open
  self.closeEvent = close
end

function LogisticianExportTextFrameMixin:OnShow()
  Logistician.Debug.Message("LogisticianExportTextFrameMixin:OnShow()")

  self.EditBoxContainer:GetEditBox():SetFocus()
  self.EditBoxContainer:GetEditBox():HighlightText()

  if self.openEvent then
    Logistician.EventBus
      :RegisterSource(self, "lists export text dialog 2")
      :Fire(self, self.openEvent)
      :UnregisterSource(self)
  end
end

function LogisticianExportTextFrameMixin:OnHide()
  self:Hide()

  if self.closeEvent then
    Logistician.EventBus
      :RegisterSource(self, "lists export text dialog 2")
      :Fire(self, self.closeEvent)
      :UnregisterSource(self)
  end
end

function LogisticianExportTextFrameMixin:SetExportString(exportString)
  self.EditBoxContainer:GetEditBox():SetText(exportString)
  self.EditBoxContainer:GetEditBox():HighlightText()
end

function LogisticianExportTextFrameMixin:OnCloseClicked()
  self.EditBoxContainer:GetEditBox():SetText("")
  self:Hide()
end
