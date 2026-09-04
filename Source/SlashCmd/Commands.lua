local SLASH_COMMAND_DESCRIPTIONS = {
  {commands = "p, post", message = "Posts the chosen item from the \"Selling\" tab." },
  {commands = "cu, cancelundercut", message = "Cancels the next undercut auction in the \"Cancelling\" tab." },
  {commands = "ra, resetall", message = "Reset database and full scan timer." },
  {commands = "rdb, resetdatabase", message = "Reset Auctionator database."},
  {commands = "rt, resettimer", message = "Reset full scan timer."},
  {commands = "rc, resetconfig", message = "Reset configuration to defaults."},
  {commands = "npd, nopricedb", message = "Disable recording auction prices."},
  {commands = "d, debug", message = "Toggle debug mode; use 'debug dump' or 'debug clear' for captured diagnostics."},
  {commands = "c, config", message = "Show current configuration values."},
  {commands = "c [toggle-name], config [toggle-name]", message = "Toggle the value of the configuration value [toggle-name]."},
  {commands = "v, version", message = "Show current version."},
  {commands = "h, help", message = "Show this help message."},
  {commands = "lt [count], ledgertrim [count]", message = "Keep only the newest [count] Ledger entries, discarding the rest."},
  {commands = "lc, ledgerclear", message = "Delete all Ledger entries."},
  {commands = "ltest [count], ledgertest [count]", message = "Add [count] (default 40) dummy Ledger entries for UI testing."},
}

function Auctionator.SlashCmd.Post()
  Auctionator.EventBus
    :RegisterSource(Auctionator.SlashCmd.Post, "Auctionator.SlashCmd.Post")
    :Fire(Auctionator.SlashCmd.Post, Auctionator.Selling.Events.RequestPost)
    :UnregisterSource(Auctionator.SlashCmd.Post)
end

function Auctionator.SlashCmd.CancelUndercut()
  Auctionator.EventBus
    :RegisterSource(Auctionator.SlashCmd.CancelUndercut, "Auctionator.SlashCmd.CancelUndercut")
    :Fire(Auctionator.SlashCmd.CancelUndercut, Auctionator.Cancelling.Events.RequestCancelUndercut)
    :UnregisterSource(Auctionator.SlashCmd.CancelUndercut)
end

function Auctionator.SlashCmd.ToggleDebug(action)
  if action == "dump" then
    Auctionator.Debug.Dump()
    return
  elseif action == "clear" then
    Auctionator.Debug.Clear()
    return
  end

  Auctionator.Debug.Toggle()
  if Auctionator.Debug.IsOn() then
    Auctionator.Utilities.Message("Debug mode on")
  else
    Auctionator.Utilities.Message("Debug mode off")
  end
end

function Auctionator.SlashCmd.ResetDatabase()
  if Auctionator.Debug.IsOn() then
    -- See Source/Variables/Main.lua for variable usage
    AUCTIONATOR_PRICE_DATABASE = nil
    Auctionator.Utilities.Message("Price database reset")
    Auctionator.Variables.InitializeDatabase()
  else
    Auctionator.Utilities.Message("Requires debug mode.")
  end
end

function Auctionator.SlashCmd.ResetTimer()
  if Auctionator.Debug.IsOn() then
    Auctionator.SavedState.TimeOfLastReplicateScan = nil
    Auctionator.SavedState.TimeOfLastGetAllScan = nil
    Auctionator.Utilities.Message("Scan timer reset.")
  else
    Auctionator.Utilities.Message("Requires debug mode.")
  end
end

function Auctionator.SlashCmd.CleanReset()
  Auctionator.SlashCmd.ResetTimer()
  Auctionator.SlashCmd.ResetDatabase()
end

function Auctionator.SlashCmd.NoPriceDB()
  Auctionator.Config.Set(Auctionator.Config.Options.NO_PRICE_DATABASE, true)

  AUCTIONATOR_PRICE_DATABASE = nil
  Auctionator.Variables.InitializeDatabase()

  Auctionator.Utilities.Message("Disabled recording auction prices in the price database.")
end

function Auctionator.SlashCmd.LedgerTrim(countArg)
  local count = tonumber(countArg)
  if count == nil or count < 0 then
    Auctionator.Utilities.Message("Usage: /logi ledgertrim <count>")
    return
  end

  Auctionator.Ledger:TrimTo(count)
  Auctionator.Utilities.Message("Ledger trimmed to " .. count .. " entries.")
end

function Auctionator.SlashCmd.LedgerClear()
  Auctionator.Ledger:Clear()
  Auctionator.Utilities.Message("Ledger cleared.")
end

function Auctionator.SlashCmd.LedgerTestData(countArg)
  local count = tonumber(countArg) or 40
  -- Fabricated |cAARRGGBB colors so all 6 quality tiers get exercised regardless of the test
  -- items' real quality - this is throwaway test data, not meant to be accurate.
  local qualityColors = { "ff9d9d9d", "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000" }
  local testItemIDs = { 6948, 4306, 2589, 2592, 818 }
  local testQuantities = { 1, 5, 10, 20, 50, 200 }
  local testUnitPrices = { 150, 4999, 12599, 98765, 500000, 987654, 5000000, 222229999 }
  local now = time()

  for i = 1, count do
    local itemID = testItemIDs[((i - 1) % #testItemIDs) + 1]
    local color = qualityColors[((i - 1) % #qualityColors) + 1]
    local quantity = testQuantities[((i - 1) % #testQuantities) + 1]
    local unitPrice = testUnitPrices[((i - 1) % #testUnitPrices) + 1]
    local itemLink = "|c" .. color .. "|Hitem:" .. itemID .. "::::::::1:0:::::|h[Test Item " .. i .. "]|h|r"
    -- Spread sale times over the last 14 days (pseudo-random via a coprime step) so date
    -- formatting/sorting can be tested too, instead of every entry sharing the current instant.
    local saleTime = now - (((i - 1) * 9973) % (14 * 86400))

    Auctionator.Ledger:AddSale({
      itemLink = itemLink,
      quantity = quantity,
      unitPrice = unitPrice,
      saleType = (i % 2 == 0) and "buyout" or "bid",
      marketPrice = unitPrice,
      time = saleTime,
    })
  end

  Auctionator.Utilities.Message("Added " .. count .. " dummy Ledger entries.")
end

function Auctionator.SlashCmd.ResetConfig()
  if Auctionator.Debug.IsOn() then
    Auctionator.Config.Reset()
    Auctionator.Utilities.Message("Config reset.")
  else
    Auctionator.Utilities.Message("Requires debug mode.")
  end
end

local INVALID_OPTION_VALUE = "Wrong config value type %s (required %s)"
function Auctionator.SlashCmd.Config(optionName, value1, ...)
  if optionName == nil then
    Auctionator.Utilities.Message("No config option name supplied")
    for _, name in pairs(Auctionator.Config.Options) do
      Auctionator.Utilities.Message(name .. ": " .. tostring(Auctionator.Config.Get(name)))
    end
    return
  end

  local currentValue = Auctionator.Config.Get(optionName)
  if currentValue == nil then
    Auctionator.Utilities.Message("Unknown config: " .. optionName)
    return
  end

  if value1 == nil then
    Auctionator.Utilities.Message("Config " .. optionName .. ": " .. tostring(currentValue))
    return
  end

  if type(currentValue) == "boolean" then
    if value1 ~= "true" and value1 ~= "false" then
      Auctionator.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    Auctionator.Config.Set(optionName, value1 == "true")
  elseif type(currentValue) == "number" then
    if tonumber(value1) == nil then
      Auctionator.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    Auctionator.Config.Set(optionName, tonumber(value1))
  elseif type(currentValue) == "string" then
    Auctionator.Config.Set(optionName, strjoin(" ", value1, ...))
  else
    Auctionator.Utilities.Message("Unable to edit option type " .. type(currentValue))
    return
  end
  Auctionator.Utilities.Message("Now set " .. optionName .. ": " .. tostring(Auctionator.Config.Get(optionName)))
end

function Auctionator.SlashCmd.Version()
  Auctionator.Utilities.Message(
    BLUE_FONT_COLOR:WrapTextInColorCode("Version: ") .. C_AddOns.GetAddOnMetadata("!Logistician", "Version") ..
    LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(", " .. date() .. ", ") ..
    BLUE_FONT_COLOR:WrapTextInColorCode("WoW: ") .. select(4, GetBuildInfo())
  )
end

function Auctionator.SlashCmd.Help()
  for index = 1, #SLASH_COMMAND_DESCRIPTIONS do
    local description = SLASH_COMMAND_DESCRIPTIONS[index]
    Auctionator.Utilities.Message(description.commands .. ": " .. description.message)
  end
end
