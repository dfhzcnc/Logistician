function Logistician.API.v1.RegisterForDBUpdate(callerID, callback)
  Logistician.API.InternalVerifyID(callerID)

  if type(callback) ~= "function" then
    Logistician.API.ComposeError(
      callerID,
      "Usage Logistician.API.v1.RegisterForDBUpdate(string, function)"
    )
  end

  Logistician.EventBus:Register({
    ReceiveEvent = function()
      callback()
    end
  }, {
    Logistician.Search.Events.PricesProcessed,
    Logistician.FullScan.Events.ScanComplete,
  })
end
