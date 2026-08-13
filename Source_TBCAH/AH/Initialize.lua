function Logistician.AH.Initialize()
  if Logistician.AH.Internals ~= nil then
    return
  end
  Logistician.AH.Internals = {}

  Logistician.AH.Internals.throttling = CreateFrame(
    "FRAME",
    "LogisticianAHThrottlingFrame",
    AuctionFrame,
    "LogisticianAHThrottlingFrameTemplate"
  )

  Logistician.AH.Internals.scan = CreateFrame(
    "FRAME",
    "LogisticianAHScanFrame",
    AuctionFrame,
    "LogisticianAHScanFrameTemplate"
  )

  Logistician.AH.Queue = CreateAndInitFromMixin(Logistician.AH.QueueMixin)
end
