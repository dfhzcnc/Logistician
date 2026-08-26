AuctionatorConfigFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:OnLoad()")

  -- Only one Settings frame instance ever exists; tracked so other UI (e.g.
  -- the AH panel's debug shortcut button) can open the debug viewer without
  -- needing its own reference to this frame.
  AuctionatorConfigFrameMixin.Instance = self

  -- Classic's Settings list does not consistently resolve a TOC IconTexture
  -- when the visible category name differs from the addon folder (!Logistician).
  -- Embed the texture in the label so the same Pack Kodo badge is always shown.
  self.name = "|TInterface\\AddOns\\!Logistician\\Images\\LogisticianIcon:18:18:0:0|t Logistician"
  self:SetParent(SettingsPanel)

  self:SetupPanel()
  self:CreateModuleDirectory()
end

function AuctionatorConfigFrameMixin:CreateModuleDirectory()
  self.ModuleDirectory = CreateFrame("Frame", nil, self)
  self.ModuleDirectory:SetAllPoints()

  local icon = self.ModuleDirectory:CreateTexture(nil, "ARTWORK")
  icon:SetSize(64, 64)
  icon:SetPoint("TOPLEFT", 32, -24)
  icon:SetTexture("Interface\\AddOns\\!Logistician\\Images\\LogisticianIcon")

  local title = self.ModuleDirectory:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 16, -2)
  title:SetText("Logistician")

  local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  local version = GetAddOnMetadata("!Logistician", "Version") or "Unknown"
  local author = GetAddOnMetadata("!Logistician", "Author") or "Unknown"

  local details = self.ModuleDirectory:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  details:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  details:SetText("by " .. author .. "  |  Version " .. version)

  local heading = self.ModuleDirectory:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  heading:SetPoint("TOPLEFT", 32, -116)
  heading:SetText("Modules")

  local modules = {
    { name = "Auction", page = "general" },
    { name = "Profession", page = "general" },
  }

  for index, module in ipairs(modules) do
    local button = CreateFrame("Button", nil, self.ModuleDirectory, "UIPanelButtonTemplate")
    button:SetSize(220, 32)
    button:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -12 - ((index - 1) * 42))
    button:SetText(module.name)
    button:SetScript("OnClick", function()
      self:ShowGeneralPage()
    end)
  end

  -- Debug is now a direct Enable/Disable toggle (no separate sub-page); the
  -- debug log itself is viewed via the shortcut button on the AH panel's
  -- Logi tab, shown only while debug capture is enabled.
  local debugButton = CreateFrame("Button", nil, self.ModuleDirectory, "UIPanelButtonTemplate")
  debugButton:SetSize(220, 32)
  debugButton:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -12 - (#modules * 42))
  debugButton:SetScript("OnClick", function()
    Auctionator.Debug.Toggle()
  end)

  -- Tried tinting the button's Left/Middle/Right/Normal textures, a plain
  -- inset rectangle in various colors/insets, cloning GetHighlightTexture()/
  -- GetPushedTexture() (both nil on this template), and locking the native
  -- button state via SetButtonState("PUSHED", true) - this specific skin
  -- renders Normal/Highlight/Pushed all identically, so nothing native shows
  -- any visible difference at all. Falling back to a manually-drawn overlay
  -- is therefore the only option that actually renders anything: a small
  -- inset rectangle (proven not to overflow the button's rounded corners)
  -- darkened/tinted to approximate a pressed-in look.
  local activeFill = debugButton:CreateTexture(nil, "ARTWORK")
  activeFill:SetTexture("Interface\\Buttons\\WHITE8x8")
  activeFill:SetPoint("TOPLEFT", 4, -4)
  activeFill:SetPoint("BOTTOMRIGHT", -4, 4)
  activeFill:SetVertexColor(0, 0, 0)
  activeFill:SetAlpha(0.45)
  activeFill:Hide()

  local function RefreshDebugButton()
    local isOn = Auctionator.Debug.IsOn()
    debugButton:SetText(isOn and "Disable Debug" or "Enable Debug")
    activeFill:SetShown(isOn)
  end
  Auctionator.Debug.RegisterUIRefreshHandler(RefreshDebugButton)
  RefreshDebugButton()

  self:CreateGeneralPage()
end

function AuctionatorConfigFrameMixin:CreateGeneralPage()
  self.GeneralPage = CreateFrame("Frame", nil, self)
  self.GeneralPage:SetAllPoints()
  self.GeneralPage:Hide()

  local title = self.GeneralPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 32, -28)
  title:SetText("General")

  local back = CreateFrame("Button", nil, self.GeneralPage, "UIPanelButtonTemplate")
  back:SetSize(120, 28)
  back:SetPoint("BOTTOMLEFT", 32, 28)
  back:SetText("Back")
  back:SetScript("OnClick", function()
    self.GeneralPage:Hide()
    self.ModuleDirectory:Show()
  end)
end

function AuctionatorConfigFrameMixin:ShowGeneralPage()
  self.ModuleDirectory:Hide()
  self.GeneralPage:Show()
end

-- Modeled directly on BugSack's error viewer (Interface/AddOns/BugSack/sack.lua
-- createBugSack/textArea): a bare multi-line EditBox in a ScrollFrame, no
-- manual height/measurement code at all - WoW's EditBox widget auto-sizes
-- itself to its text content, and BugSack relies on exactly that (with only
-- `SetMaxLetters(99999)` as a safety cap) to reliably display arbitrarily
-- long stack traces in this same client. Our own earlier attempts at manually
-- computing/forcing the box height (via a hidden measurement FontString, then
-- via newline counting, then a FontString-per-row pool) were what caused the
-- log to go blank once it got long - removing that custom sizing logic
-- entirely and just trusting the engine's default EditBox behavior is the fix.
-- Color-code each captured line for readability - EditBoxes render the same
-- |cAARRGGBB...|r escape codes FontStrings do, so this is purely cosmetic
-- and needs no changes to how lines are captured/stored.
local function FormatDebugLine(line)
  local timestamp, rest = line:match("^(%d%d:%d%d:%d%d) (.*)$")
  if not timestamp then
    return line
  end

  local color = "|cffe6e6e6" -- default light grey for anything uncategorized
  if rest:lower():find("error") or rest:lower():find("fail") then
    color = "|cffff4040" -- red - problems
  elseif rest:find("[Uu]nregister", 1) then
    color = "|cff808080" -- dim grey - low-signal bookkeeping noise
  elseif rest:find(":Fire%(%)") then
    color = "|cffffd200" -- gold - an event actually firing
  elseif rest:find("ReceiveEvent", 1, true) then
    color = "|cff40c0ff" -- cyan - an event being received
  elseif rest:find("[Rr]egister", 1) then
    color = "|cff40ff60" -- green - setup/registration
  end

  return "|cff909090" .. timestamp .. "|r " .. color .. rest .. "|r"
end

local function GetDebugText()
  Auctionator.Debug.PruneStale()
  local entries = Auctionator.SavedState and Auctionator.SavedState.DebugLog or {}
  if #entries == 0 then
    if Auctionator.Debug.IsOn() then
      return "No captured debug entries."
    end
    return ""
  end

  local formatted = {}
  for index, entry in ipairs(entries) do
    formatted[index] = FormatDebugLine(entry)
  end
  return table.concat(formatted, "\n")
end

function AuctionatorConfigFrameMixin:CreateDebugViewer()
  local viewer = CreateFrame("Frame", "LogisticianDebugViewer", UIParent)
  viewer:SetFrameStrata("DIALOG")
  viewer:SetWidth(540)
  viewer:SetHeight(360)
  viewer:SetPoint("CENTER")
  viewer:SetMovable(true)
  viewer:EnableMouse(true)
  viewer:RegisterForDrag("LeftButton")
  viewer:SetClampedToScreen(true)
  viewer:SetScript("OnDragStart", viewer.StartMoving)
  viewer:SetScript("OnDragStop", viewer.StopMovingOrSizing)
  viewer:Hide()
  -- Deliberately NOT added to UISpecialFrames: that list is hidden as a whole
  -- when Escape closes the Settings panel, which would take this window down
  -- with it. Users need to keep this open while using the AH, closed only via
  -- its own close button.

  -- Same shared Blizzard border/background textures BugSack's window uses.
  local titlebg = viewer:CreateTexture(nil, "BORDER")
  titlebg:SetTexture(251966) -- Interface\PaperDollInfoFrame\UI-GearManager-Title-Background
  titlebg:SetPoint("TOPLEFT", 9, -6)
  titlebg:SetPoint("BOTTOMRIGHT", viewer, "TOPRIGHT", -28, -24)

  local dialogbg = viewer:CreateTexture(nil, "BACKGROUND")
  dialogbg:SetTexture(136548) -- Interface\PaperDollInfoFrame\UI-Character-CharacterTab-L1
  dialogbg:SetPoint("TOPLEFT", 8, -12)
  dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
  dialogbg:SetTexCoord(0.255, 1, 0.29, 1)

  local topleft = viewer:CreateTexture(nil, "BORDER")
  topleft:SetTexture(251963) -- Interface\PaperDollInfoFrame\UI-GearManager-Border
  topleft:SetSize(64, 64)
  topleft:SetPoint("TOPLEFT")
  topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

  local topright = viewer:CreateTexture(nil, "BORDER")
  topright:SetTexture(251963)
  topright:SetSize(64, 64)
  topright:SetPoint("TOPRIGHT")
  topright:SetTexCoord(0.625, 0.75, 0, 1)

  local top = viewer:CreateTexture(nil, "BORDER")
  top:SetTexture(251963)
  top:SetHeight(64)
  top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
  top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
  top:SetTexCoord(0.25, 0.369140625, 0, 1)

  local bottomleft = viewer:CreateTexture(nil, "BORDER")
  bottomleft:SetTexture(251963)
  bottomleft:SetSize(64, 64)
  bottomleft:SetPoint("BOTTOMLEFT")
  bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

  local bottomright = viewer:CreateTexture(nil, "BORDER")
  bottomright:SetTexture(251963)
  bottomright:SetSize(64, 64)
  bottomright:SetPoint("BOTTOMRIGHT")
  bottomright:SetTexCoord(0.875, 1, 0, 1)

  local bottom = viewer:CreateTexture(nil, "BORDER")
  bottom:SetTexture(251963)
  bottom:SetHeight(64)
  bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
  bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
  bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

  local left = viewer:CreateTexture(nil, "BORDER")
  left:SetTexture(251963)
  left:SetWidth(64)
  left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
  left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
  left:SetTexCoord(0.001953125, 0.125, 0, 1)

  local right = viewer:CreateTexture(nil, "BORDER")
  right:SetTexture(251963)
  right:SetWidth(64)
  right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
  right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
  right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

  local close = CreateFrame("Button", nil, viewer, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 1)

  local title = viewer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  title:SetPoint("TOPLEFT", titlebg, 6, -1)
  title:SetJustifyH("LEFT")
  title:SetTextColor(1, 1, 1, 1)
  title:SetText("Logistician Debug")

  local countLabel = viewer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  countLabel:SetPoint("TOPRIGHT", titlebg, -6, -3)
  countLabel:SetJustifyH("RIGHT")
  countLabel:SetTextColor(1, 1, 1, 1)

  local copy = CreateFrame("Button", "LogisticianDebugCopyButton", viewer, "UIPanelButtonTemplate")
  copy:SetPoint("BOTTOMLEFT", viewer, 14, 16)
  copy:SetHeight(40)
  copy:SetWidth(120)
  copy:SetText("Select All")

  local clear = CreateFrame("Button", "LogisticianDebugClearButton", viewer, "UIPanelButtonTemplate")
  clear:SetPoint("BOTTOMRIGHT", viewer, -11, 16)
  clear:SetHeight(40)
  clear:SetWidth(120)
  clear:SetText("Clear")

  local toggle = CreateFrame("Button", "LogisticianDebugToggleButton", viewer, "UIPanelButtonTemplate")
  toggle:SetPoint("LEFT", copy, "RIGHT")
  toggle:SetPoint("RIGHT", clear, "LEFT")
  toggle:SetHeight(40)
  toggle:SetText("")

  -- "Recording"/"Recording."/"Recording.."/"Recording..." looping dots while
  -- capturing (same cadence/style as the "Searching..."/"Checking..." dots
  -- used elsewhere in this addon), static "Stopped" once off. Anchored using
  -- Copy's own native template text position (not a guessed offset) so it
  -- sits at exactly the same vertical baseline as the Copy/Clear button text.
  local toggleLabel = toggle:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  local copyTextPoint, _, copyTextRelativePoint, copyTextX, copyTextY = copy:GetFontString():GetPoint()
  toggleLabel:SetPoint(copyTextPoint, toggle, copyTextRelativePoint, copyTextX, copyTextY)
  toggleLabel:SetTextColor(1, 0.82, 0)

  local recordingDotsElapsed = 0
  local recordingDots = 0
  local function UpdateToggleIcon()
    if Auctionator.Debug.IsOn() and not Auctionator.Debug.IsPaused() then
      recordingDotsElapsed = 0
      recordingDots = 0
      toggleLabel:SetText("Recording")
    else
      toggleLabel:SetText("Stopped")
    end
  end
  toggle:SetScript("OnEnter", function()
    GameTooltip:SetOwner(toggle, "ANCHOR_TOP")
    GameTooltip:SetText(Auctionator.Debug.IsPaused() and
      "Debug capture is stopped - click to resume" or "Debug capture is running - click to stop")
    GameTooltip:Show()
  end)
  toggle:SetScript("OnLeave", function()
    if GameTooltip:IsOwned(toggle) then
      GameTooltip:Hide()
    end
  end)

  -- Anchored to `clear` (the bottom-RIGHT button), not `copy` (bottom-left) -
  -- anchoring to the left button previously clipped the content area down to
  -- just its ~200px width instead of spanning the window.
  local scroll = CreateFrame("ScrollFrame", "LogisticianDebugScroll", viewer, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", viewer, "TOPLEFT", 16, -36)
  scroll:SetPoint("BOTTOMRIGHT", clear, "TOPRIGHT", -24, 8)

  local disabledNotice = viewer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  disabledNotice:SetPoint("CENTER", scroll, "CENTER", 0, 0)
  disabledNotice:SetWidth(390)
  disabledNotice:SetJustifyH("CENTER")
  disabledNotice:SetTextColor(1, 0.82, 0)
  disabledNotice:SetText("Debug capture is stopped. Click Start below and reproduce the issue - this list updates live.")

  local editBox = CreateFrame("EditBox", "LogisticianDebugScrollText", scroll)
  editBox:SetTextColor(0.9, 0.9, 0.9, 1)
  editBox:SetAutoFocus(false)
  editBox:SetMultiLine(true)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetMaxLetters(99999)
  editBox:EnableMouse(true)
  editBox:SetWidth(507)
  editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
  scroll:SetScrollChild(editBox)

  local function RefreshDebugContent()
    local text = GetDebugText()
    local entryCount = Auctionator.SavedState and Auctionator.SavedState.DebugLog
      and #Auctionator.SavedState.DebugLog or 0
    countLabel:SetText(tostring(entryCount))
    disabledNotice:SetShown(entryCount == 0 and (not Auctionator.Debug.IsOn() or Auctionator.Debug.IsPaused()))
    editBox:SetText(text)
    -- BugSack's textArea never repositions the cursor after SetText at all
    -- (it only ever loads text once per manual Prev/Next click). We were
    -- forcing the cursor to the very end on every 1s auto-refresh tick here,
    -- which fights the external ScrollFrame's own scroll offset (the EditBox
    -- tries to auto-scroll its internal view to keep the cursor visible) -
    -- once the log got long enough for those two scroll positions to
    -- diverge, the visible region went fully blank. Leaving the cursor at 0
    -- (matching BugSack) keeps both in sync.
    editBox:SetCursorPosition(0)
    UpdateToggleIcon()
  end

  copy:SetScript("OnClick", function()
    editBox:SetFocus()
    editBox:HighlightText()
  end)
  toggle:SetScript("OnClick", function()
    Auctionator.Debug.TogglePaused()
    RefreshDebugContent()
  end)
  clear:SetScript("OnClick", function()
    Auctionator.Debug.Clear()
    RefreshDebugContent()
  end)

  -- Manual Refresh reliably works; calling SetText() unconditionally every
  -- 1s (even when nothing new arrived) was the one thing that reproduced the
  -- blanking. Auto-refresh now only calls RefreshDebugContent() when the
  -- entry count has actually changed since the last check, so SetText() is
  -- called exactly as often as a real manual Refresh click would be needed -
  -- no redundant/no-op calls - while still updating live without input.
  local autoRefreshElapsed = 0
  local lastSeenEntryCount = nil
  viewer:SetScript("OnUpdate", function(_, elapsed)
    if Auctionator.Debug.IsOn() and not Auctionator.Debug.IsPaused() then
      recordingDotsElapsed = recordingDotsElapsed + elapsed
      if recordingDotsElapsed >= 0.4 then
        recordingDotsElapsed = 0
        recordingDots = (recordingDots + 1) % 4
        toggleLabel:SetText("Recording" .. string.rep(".", recordingDots))
      end
    end

    if editBox:HasFocus() then
      return
    end
    autoRefreshElapsed = autoRefreshElapsed + elapsed
    if autoRefreshElapsed < 1 then
      return
    end
    autoRefreshElapsed = 0
    local entryCount = Auctionator.SavedState and Auctionator.SavedState.DebugLog
      and #Auctionator.SavedState.DebugLog or 0
    if entryCount ~= lastSeenEntryCount then
      lastSeenEntryCount = entryCount
      RefreshDebugContent()
    end
  end)

  viewer.RefreshDebugContent = RefreshDebugContent
  viewer.Toggle = toggle
  self.DebugViewer = viewer

  -- Keeps the "Recording"/"Stopped" label (and disabled notice) in sync
  -- immediately when debug is toggled elsewhere (Settings button, AH-tab
  -- icon, /logi debug), not just from this window's own Start/Stop click.
  -- Disabling the master switch also closes this window entirely - the AH
  -- shortcut used to open it is gone too, so there's no reason to leave it
  -- lingering (capture is already force-stopped by Auctionator.Debug.Toggle).
  Auctionator.Debug.RegisterUIRefreshHandler(function()
    RefreshDebugContent()
    if not Auctionator.Debug.IsOn() then
      viewer:Hide()
    end
  end)
end

function AuctionatorConfigFrameMixin:ShowDebugViewer()
  if not self.DebugViewer then
    self:CreateDebugViewer()
  end
  self.DebugViewer.RefreshDebugContent()
  self.DebugViewer:Show()
  self.DebugViewer:Raise()
end

-- Lets other UI (e.g. the AH panel's Logi tab shortcut button) open the
-- debug viewer without needing a reference to the Settings frame instance.
function Auctionator.Debug.ShowViewer()
  if AuctionatorConfigFrameMixin.Instance then
    AuctionatorConfigFrameMixin.Instance:ShowDebugViewer()
  end
end

function AuctionatorConfigFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:Save()")
end

function AuctionatorConfigFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:Cancel()")
end
