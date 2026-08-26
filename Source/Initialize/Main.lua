local AUCTIONATOR_EVENTS = {
  -- Addon Initialization Events
  "PLAYER_LOGIN",
  "ADDON_LOADED",
  -- Import list events
  -- "CHAT_MSG_ADDON"
}

AuctionatorInitializeMixin = {}

function AuctionatorInitializeMixin:OnLoad()
  Auctionator.Debug.Message("Auctionator.Events.CoreFrameLoaded")
  C_ChatInfo.RegisterAddonMessagePrefix("Auctionator")

  FrameUtil.RegisterFrameForEvents(self, AUCTIONATOR_EVENTS)
end

function AuctionatorInitializeMixin:OnEvent(event, ...)
  -- Auctionator.Debug.Message("AuctionatorInitializeMixin", event, ...)
  if event == "PLAYER_LOGIN" then
    Auctionator.Variables.InitializeLate()
  elseif event == "ADDON_LOADED" and (...) == "!Logistician" then
    Auctionator.Variables.Initialize()

    Auctionator.SlashCmd.Initialize()

    -- Debug's Enable/Disable button and AH-tab shortcut are created earlier
    -- (Config/Tabs XML OnLoad, which runs while this addon's own files are
    -- still loading) and read Auctionator.Config.Get() at that point for
    -- their initial display - force a re-sync now that config is guaranteed
    -- fully initialized, in case that first read raced ahead of it.
    Auctionator.Debug.RefreshUI()
  elseif event == "CHAT_MSG_ADDON" then
    -- For now, just drop the message - we
    -- need to aggregate the messages and provide a pop up
    -- asking people if they want to import
  end
end

function AuctionatorInitializeMixin:AddonDataLoaded(event, ...)
  Auctionator.Debug.Message("AuctionatorInitializeMixin:VariablesLoaded")
end
