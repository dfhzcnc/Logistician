function Logistician.Components.ReportEnterPressed()
  Logistician.EventBus
    :RegisterSource(Logistician.Components.ReportEnterPressed, "ReportEnterPressed")
    :Fire(Logistician.Components.ReportEnterPressed, Logistician.Components.Events.EnterPressed)
    :UnregisterSource(Logistician.Components.ReportEnterPressed)
end
