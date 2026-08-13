local LOGISTICIAN_EVENTS = {
  -- Addon Initialization Events
  "PLAYER_LOGIN",
  "ADDON_LOADED",
  -- Import list events
  -- "CHAT_MSG_ADDON"
}

LogisticianInitializeMixin = {}

function LogisticianInitializeMixin:OnLoad()
  Logistician.Debug.Message("Logistician.Events.CoreFrameLoaded")
  C_ChatInfo.RegisterAddonMessagePrefix("Logistician")

  FrameUtil.RegisterFrameForEvents(self, LOGISTICIAN_EVENTS)
end

function LogisticianInitializeMixin:OnEvent(event, ...)
  -- Logistician.Debug.Message("LogisticianInitializeMixin", event, ...)
  if event == "PLAYER_LOGIN" then
    Logistician.Variables.InitializeLate()
  elseif event == "ADDON_LOADED" and (...) == "!Logistician" then
    Logistician.Variables.Initialize()

    Logistician.SlashCmd.Initialize()
  elseif event == "CHAT_MSG_ADDON" then
    -- For now, just drop the message - we
    -- need to aggregate the messages and provide a pop up
    -- asking people if they want to import
  end
end

function LogisticianInitializeMixin:AddonDataLoaded(event, ...)
  Logistician.Debug.Message("LogisticianInitializeMixin:VariablesLoaded")
end
