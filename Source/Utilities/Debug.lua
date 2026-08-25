local MAX_DEBUG_ENTRIES = 200
local STALE_DEBUG_SECONDS = 24 * 60 * 60

function Auctionator.Debug.IsOn()
  return Auctionator.Config.Get(Auctionator.Config.Options.DEBUG)
end

function Auctionator.Debug.Toggle()
  Auctionator.Config.Set(Auctionator.Config.Options.DEBUG,
    not Auctionator.Config.Get(Auctionator.Config.Options.DEBUG))
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
  if not Auctionator.Debug.IsOn() or not Auctionator.SavedState then
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
  if Auctionator.Debug.IsOn() then
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
