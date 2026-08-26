local MAX_DEBUG_ENTRIES = 200
local STALE_DEBUG_SECONDS = 24 * 60 * 60

local uiRefreshHandlers = {}

-- Session-only (not persisted), separate from the master DEBUG setting: lets
-- the debug viewer's own Recording/Stopped button pause/resume capture
-- without affecting the Enable/Disable Debug button (Settings, AH shortcut).
-- Starts stopped - the master switch only shows/hides the AH shortcut, it
-- never starts capture on its own; the user must press Start in the viewer.
local isPaused = true

function Auctionator.Debug.IsOn()
  return Auctionator.Config.Get(Auctionator.Config.Options.DEBUG)
end

function Auctionator.Debug.Toggle()
  local isEnabled = not Auctionator.Config.Get(Auctionator.Config.Options.DEBUG)
  Auctionator.Config.Set(Auctionator.Config.Options.DEBUG, isEnabled)
  if not isEnabled then
    -- Disabling always stops capture (and the viewer closes itself via its
    -- own registered refresh handler); enabling never auto-starts capture.
    isPaused = true
  end
  Auctionator.Debug.RefreshUI()
end

function Auctionator.Debug.IsPaused()
  return isPaused
end

function Auctionator.Debug.TogglePaused()
  isPaused = not isPaused
  Auctionator.Debug.RefreshUI()
end

-- Lets independent UI elements (Settings module button, AH panel shortcut
-- button) stay in sync whenever debug capture is toggled from any entry
-- point (Settings panel, slash command, etc.) without holding direct
-- references to each other.
function Auctionator.Debug.RegisterUIRefreshHandler(handler)
  table.insert(uiRefreshHandlers, handler)
end

function Auctionator.Debug.RefreshUI()
  for _, handler in ipairs(uiRefreshHandlers) do
    handler()
  end
end

local function FormatValue(value)
  if type(value) == "string" then
    return value
  end
  return tostring(value)
end

function Auctionator.Debug.PruneStale()
  if not Auctionator.SavedState then
    return
  end

  local lastUpdated = Auctionator.SavedState.DebugLogLastUpdated
  if lastUpdated and time() - lastUpdated >= STALE_DEBUG_SECONDS then
    Auctionator.SavedState.DebugLog = {}
    Auctionator.SavedState.DebugLogLastUpdated = nil
  end
end

function Auctionator.Debug.Capture(message, ...)
  if not Auctionator.Debug.IsOn() or Auctionator.Debug.IsPaused() or not Auctionator.SavedState then
    return
  end

  Auctionator.SavedState.DebugLog = Auctionator.SavedState.DebugLog or {}
  local values = { FormatValue(message) }
  for index = 1, select("#", ...) do
    values[#values + 1] = FormatValue(select(index, ...))
  end

  table.insert(Auctionator.SavedState.DebugLog,
    date("%H:%M:%S") .. " " .. table.concat(values, " "))
  Auctionator.SavedState.DebugLogLastUpdated = time()
  while #Auctionator.SavedState.DebugLog > MAX_DEBUG_ENTRIES do
    table.remove(Auctionator.SavedState.DebugLog, 1)
  end
end

function Auctionator.Debug.Message(message, ...)
  if Auctionator.Debug.IsOn() and not Auctionator.Debug.IsPaused() then
    Auctionator.Debug.Capture(message, ...)
    print(GREEN_FONT_COLOR:WrapTextInColorCode(message), ...)
  end
end

function Auctionator.Debug.Dump()
  Auctionator.Debug.PruneStale()
  local entries = Auctionator.SavedState and Auctionator.SavedState.DebugLog or {}
  Auctionator.Utilities.Message("Captured debug entries: " .. #entries)
  for index = 1, #entries do
    Auctionator.Utilities.Message(entries[index])
  end
end

function Auctionator.Debug.Clear()
  if Auctionator.SavedState then
    Auctionator.SavedState.DebugLog = {}
    Auctionator.SavedState.DebugLogLastUpdated = nil
  end
  Auctionator.Utilities.Message("Captured debug entries cleared")
end
