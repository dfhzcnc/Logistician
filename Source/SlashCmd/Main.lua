function Logistician.SlashCmd.Initialize()
  SlashCmdList["LOGISTICIAN"] = Logistician.SlashCmd.Handler
  SLASH_LOGISTICIAN1 = "/logistician"
  SLASH_LOGISTICIAN2 = "/logi"
  -- Preserve familiar legacy aliases for existing macros.
  SLASH_LOGISTICIAN3 = "/logistician"
  SLASH_LOGISTICIAN4 = "/atr"
end

--Update SLASH_COMMAND_DESCRIPTIONS in Commands.lua for new commands
local SLASH_COMMANDS = {
  ["p"] = Logistician.SlashCmd.Post,
  ["post"] = Logistician.SlashCmd.Post,
  ["cu"] = Logistician.SlashCmd.CancelUndercut,
  ["cancelundercut"] = Logistician.SlashCmd.CancelUndercut,
  ["ra"] = Logistician.SlashCmd.CleanReset,
  ["resetall"] = Logistician.SlashCmd.CleanReset,
  ["rt"] = Logistician.SlashCmd.ResetTimer,
  ["resettimer"] = Logistician.SlashCmd.ResetTimer,
  ["rdb"] = Logistician.SlashCmd.ResetDatabase,
  ["resetdatabase"] = Logistician.SlashCmd.ResetDatabase,
  ["rc"] = Logistician.SlashCmd.ResetConfig,
  ["resetconfig"] = Logistician.SlashCmd.ResetConfig,
  ["d"] = Logistician.SlashCmd.ToggleDebug,
  ["debug"] = Logistician.SlashCmd.ToggleDebug,
  ["config"] = Logistician.SlashCmd.Config,
  ["c"] = Logistician.SlashCmd.Config,
  ["v"] = Logistician.SlashCmd.Version,
  ["version"] = Logistician.SlashCmd.Version,
  ["nopricedb"] = Logistician.SlashCmd.NoPriceDB,
  ["npd"] = Logistician.SlashCmd.NoPriceDB,
  ["h"] = Logistician.SlashCmd.Help,
  ["help"] = Logistician.SlashCmd.Help,
}

function Logistician.SlashCmd.Handler(input)
  Logistician.Debug.Message( 'Logistician.SlashCmd.Handler', input )

  if #input == 0 then
    Logistician.SlashCmd.Help()
  else
    local command = Logistician.Utilities.SplitCommand(input);
    local handler = SLASH_COMMANDS[command[1]]
    if handler == nil then
      Logistician.Utilities.Message("Unrecognized command '" .. command[1] .. "'")
      Logistician.SlashCmd.Help()
    else
      handler(unpack(Logistician.Utilities.Slice(command, 2, #command-1)))
    end
  end
end
