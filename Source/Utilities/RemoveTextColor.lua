function Logistician.Utilities.RemoveTextColor(text)
  return gsub(gsub(text, "|c........", ""), "|r", "")
end
