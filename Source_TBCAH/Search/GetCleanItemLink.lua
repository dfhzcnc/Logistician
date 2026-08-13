function Logistician.Search.GetCleanItemLink(itemLink)
  if not itemLink then
    return ""
  end

  local _, pre, hyperlink, post = ExtractHyperlinkString(itemLink)

  local parts = { strsplit(":", hyperlink) }

  for index = 3, 7 do
    parts[index] = ""
  end

  local wantedBits = Logistician.Utilities.Slice(parts, 1, 8)

  return Logistician.Utilities.StringJoin(wantedBits, ":")
end
