function Logistician.Config.InternalInitializeFrames(templateNames)
  for _, name in ipairs(templateNames) do
    CreateFrame(
      "FRAME",
      "LogisticianConfig" .. name .. "Frame",
      SettingsPanel,
      "LogisticianConfig" .. name .. "FrameTemplate")
  end
end
