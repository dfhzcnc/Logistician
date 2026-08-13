function Logistician.Utilities.GetNameFromLink(itemLink)
  return string.match(itemLink, "h%[(.*)%]|h")
end
