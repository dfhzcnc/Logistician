AuctionatorFullScanStatusMixin = {}

function AuctionatorFullScanStatusMixin:OnLoad()
  Auctionator.EventBus:Register(self, {
    Auctionator.FullScan.Events.ScanStart,
    Auctionator.FullScan.Events.ScanProgress,
    Auctionator.FullScan.Events.ScanComplete,
    Auctionator.FullScan.Events.ScanFailed,
  })
end

function AuctionatorFullScanStatusMixin:OnShow()
  self.Text:SetText("")
end

local function ProgressPhase(progress)
  if progress < 0.20 then
    return "Query"
  elseif progress < 0.55 then
    return "Read"
  elseif progress < 0.75 then
    return "Depth"
  elseif progress < 0.99 then
    return "Save"
  else
    return "Finish"
  end
end

function AuctionatorFullScanStatusMixin:ReceiveEvent(event, eventData, stats)
  if event == Auctionator.FullScan.Events.ScanStart then
    self.Text:SetText("0% Query")

  elseif event == Auctionator.FullScan.Events.ScanProgress then
    local progress = math.max(0, math.min(1, tonumber(eventData) or 0))
    self.Text:SetText(
      tostring(math.floor(progress * 100)) .. "% " .. ProgressPhase(progress)
    )

  elseif event == Auctionator.FullScan.Events.ScanComplete then
    if stats and stats.quality and stats.quality < 0.999 then
      self.Text:SetText(
        "100% Q" .. tostring(math.floor(stats.quality * 100 + 0.5))
      )
    else
      self.Text:SetText("100% Done")
    end

  else
    self.Text:SetText("")
  end
end
