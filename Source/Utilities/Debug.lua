function Logistician.Debug.IsOn()
  return Logistician.Config.Get(Logistician.Config.Options.DEBUG)
end

function Logistician.Debug.Toggle()
  Logistician.Config.Set(Logistician.Config.Options.DEBUG,
    not Logistician.Config.Get(Logistician.Config.Options.DEBUG))
end

function Logistician.Debug.Message(message, ...)
  if Logistician.Debug.IsOn() then
    print(GREEN_FONT_COLOR:WrapTextInColorCode(message), ...)
  end
end
