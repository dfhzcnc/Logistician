LogisticianKeyBindingConfigMixin = CreateFromMixins(LogisticianConfigTooltipMixin)

function LogisticianKeyBindingConfigMixin:OnLoad()
  self.isListening = false
  self.Description:SetText(self.labelText)
  self.shortcut = ""
end

function LogisticianKeyBindingConfigMixin:SetShortcut(shortcut)
  self.shortcut = shortcut
  if self.shortcut == "" then
    self.Button:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(NOT_BOUND))
  else
    self.Button:SetText(GetBindingText(self.shortcut))
  end
end

function LogisticianKeyBindingConfigMixin:GetShortcut(shortcut)
  return self.shortcut
end

function LogisticianKeyBindingConfigMixin:OnHide()
  self:StopListening()
end

function LogisticianKeyBindingConfigMixin:StartListening()
  self.isListening = true
  self:SetScript("OnMouseWheel", self.OnMouseWheel)
  self:SetScript("OnKeyDown", self.OnKeyDown)
  self.Button:SetScript("OnMouseWheel", function(button, ...)
    self:OnMouseWheel(...)
  end)
  self.Button.selectedHighlight:Show()
end
function LogisticianKeyBindingConfigMixin:StopListening()
  self.isListening = false
  self:SetScript("OnMouseWheel", nil)
  self:SetScript("OnKeyDown", nil)
  self.Button:SetScript("OnMouseWheel", nil)
  self.Button.selectedHighlight:Hide()
end

function LogisticianKeyBindingConfigMixin:OnClick(button)
  if button == "LeftButton" or button == "RightButton" then
    if self.isListening then
      self:StopListening()
    else
      self:StartListening()
    end
  else
    self:OnKeyDown(button)
  end
end

function LogisticianKeyBindingConfigMixin:OnEnter()
  LogisticianConfigTooltipMixin.OnEnter(self)
  self.Button:LockHighlight()
end
function LogisticianKeyBindingConfigMixin:OnLeave()
  LogisticianConfigTooltipMixin.OnLeave(self)
  self.Button:UnlockHighlight()
end

function LogisticianKeyBindingConfigMixin:OnMouseWheel(delta)
  if delta > 0 then
    self:OnKeyDown("MOUSEWHEELUP")
  else
    self:OnKeyDown("MOUSEWHEELDOWN")
  end
end

function LogisticianKeyBindingConfigMixin:OnKeyDown(keyOrButton)
  if GetBindingFromClick(keyOrButton) == "SCREENSHOT" then
    self:SetPropagateKeyboardInput(true)
    return
  elseif keyOrButton == "ESCAPE" then
    self:SetShortcut("")
    self:StopListening()
    return
  end

  local keyPressed = GetConvertedKeyOrButton(keyOrButton)
  self:SetPropagateKeyboardInput(false)
  if not IsKeyPressIgnoredForBinding(keyPressed) then
    if CreateKeyChordStringUsingMetaKeyState then
      keyPressed = CreateKeyChordStringUsingMetaKeyState(keyPressed)
    else --if Logistician.Constants.IsClassic
      keyPressed = CreateKeyChordString(keyPressed)
    end
    self:SetShortcut(keyPressed)
    self:StopListening()
  end
end
