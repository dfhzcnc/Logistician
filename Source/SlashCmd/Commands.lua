local SLASH_COMMAND_DESCRIPTIONS = {
  {commands = "p, post", message = "Posts the chosen item from the \"Selling\" tab." },
  {commands = "cu, cancelundercut", message = "Cancels the next undercut auction in the \"Cancelling\" tab." },
  {commands = "ra, resetall", message = "Reset database and full scan timer." },
  {commands = "rdb, resetdatabase", message = "Reset Logistician database."},
  {commands = "rt, resettimer", message = "Reset full scan timer."},
  {commands = "rc, resetconfig", message = "Reset configuration to defaults."},
  {commands = "npd, nopricedb", message = "Disable recording auction prices."},
  {commands = "d, debug", message = "Toggle debug mode."},
  {commands = "c, config", message = "Show current configuration values."},
  {commands = "c [toggle-name], config [toggle-name]", message = "Toggle the value of the configuration value [toggle-name]."},
  {commands = "v, version", message = "Show current version."},
  {commands = "h, help", message = "Show this help message."},
}

function Logistician.SlashCmd.Post()
  Logistician.EventBus
    :RegisterSource(Logistician.SlashCmd.Post, "Logistician.SlashCmd.Post")
    :Fire(Logistician.SlashCmd.Post, Logistician.Selling.Events.RequestPost)
    :UnregisterSource(Logistician.SlashCmd.Post)
end

function Logistician.SlashCmd.CancelUndercut()
  Logistician.EventBus
    :RegisterSource(Logistician.SlashCmd.CancelUndercut, "Logistician.SlashCmd.CancelUndercut")
    :Fire(Logistician.SlashCmd.CancelUndercut, Logistician.Cancelling.Events.RequestCancelUndercut)
    :UnregisterSource(Logistician.SlashCmd.CancelUndercut)
end

function Logistician.SlashCmd.ToggleDebug()
  Logistician.Debug.Toggle()
  if Logistician.Debug.IsOn() then
    Logistician.Utilities.Message("Debug mode on")
  else
    Logistician.Utilities.Message("Debug mode off")
  end
end

function Logistician.SlashCmd.ResetDatabase()
  if Logistician.Debug.IsOn() then
    -- See Source/Variables/Main.lua for variable usage
    LOGISTICIAN_PRICE_DATABASE = nil
    Logistician.Utilities.Message("Price database reset")
    Logistician.Variables.InitializeDatabase()
  else
    Logistician.Utilities.Message("Requires debug mode.")
  end
end

function Logistician.SlashCmd.ResetTimer()
  if Logistician.Debug.IsOn() then
    Logistician.SavedState.TimeOfLastReplicateScan = nil
    Logistician.SavedState.TimeOfLastGetAllScan = nil
    Logistician.Utilities.Message("Scan timer reset.")
  else
    Logistician.Utilities.Message("Requires debug mode.")
  end
end

function Logistician.SlashCmd.CleanReset()
  Logistician.SlashCmd.ResetTimer()
  Logistician.SlashCmd.ResetDatabase()
end

function Logistician.SlashCmd.NoPriceDB()
  Logistician.Config.Set(Logistician.Config.Options.NO_PRICE_DATABASE, true)

  LOGISTICIAN_PRICE_DATABASE = nil
  Logistician.Variables.InitializeDatabase()

  Logistician.Utilities.Message("Disabled recording auction prices in the price database.")
end

function Logistician.SlashCmd.ResetConfig()
  if Logistician.Debug.IsOn() then
    Logistician.Config.Reset()
    Logistician.Utilities.Message("Config reset.")
  else
    Logistician.Utilities.Message("Requires debug mode.")
  end
end

local INVALID_OPTION_VALUE = "Wrong config value type %s (required %s)"
function Logistician.SlashCmd.Config(optionName, value1, ...)
  if optionName == nil then
    Logistician.Utilities.Message("No config option name supplied")
    for _, name in pairs(Logistician.Config.Options) do
      Logistician.Utilities.Message(name .. ": " .. tostring(Logistician.Config.Get(name)))
    end
    return
  end

  local currentValue = Logistician.Config.Get(optionName)
  if currentValue == nil then
    Logistician.Utilities.Message("Unknown config: " .. optionName)
    return
  end

  if value1 == nil then
    Logistician.Utilities.Message("Config " .. optionName .. ": " .. tostring(currentValue))
    return
  end

  if type(currentValue) == "boolean" then
    if value1 ~= "true" and value1 ~= "false" then
      Logistician.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    Logistician.Config.Set(optionName, value1 == "true")
  elseif type(currentValue) == "number" then
    if tonumber(value1) == nil then
      Logistician.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    Logistician.Config.Set(optionName, tonumber(value1))
  elseif type(currentValue) == "string" then
    Logistician.Config.Set(optionName, strjoin(" ", value1, ...))
  else
    Logistician.Utilities.Message("Unable to edit option type " .. type(currentValue))
    return
  end
  Logistician.Utilities.Message("Now set " .. optionName .. ": " .. tostring(Logistician.Config.Get(optionName)))
end

function Logistician.SlashCmd.Version()
  Logistician.Utilities.Message(
    BLUE_FONT_COLOR:WrapTextInColorCode("Version: ") .. C_AddOns.GetAddOnMetadata("!Logistician", "Version") ..
    LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(", " .. date() .. ", ") ..
    BLUE_FONT_COLOR:WrapTextInColorCode("WoW: ") .. select(4, GetBuildInfo())
  )
end

function Logistician.SlashCmd.Help()
  for index = 1, #SLASH_COMMAND_DESCRIPTIONS do
    local description = SLASH_COMMAND_DESCRIPTIONS[index]
    Logistician.Utilities.Message(description.commands .. ": " .. description.message)
  end
end
