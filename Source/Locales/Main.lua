local currentLocale = {}

local function FixMissingTranslations(incomplete, locale)
  if locale == "enUS" then
    return
  end

  local enUS = LOGISTICIAN_LOCALES["enUS"]()
  for key, val in pairs(enUS) do
    if incomplete[key] == nil then
      incomplete[key] = val
    end
  end
end

local function AddNewLines(full)
  for key, val in pairs(full) do
    full[key] = string.gsub(full[key], "\\n", "\n")
  end
end

if LOGISTICIAN_LOCALES_OVERRIDE ~= nil then
  currentLocale = LOGISTICIAN_LOCALES_OVERRIDE()

  FixMissingTranslations(currentLocale, "OVERRIDE")
elseif LOGISTICIAN_LOCALES[GetLocale()] ~= nil then
  currentLocale = LOGISTICIAN_LOCALES[GetLocale()]()

  FixMissingTranslations(currentLocale, GetLocale())
else
  currentLocale = LOGISTICIAN_LOCALES["enUS"]()
end

AddNewLines(currentLocale)

-- Export constants into the global scope (for XML frames to use)
for key, value in pairs(currentLocale) do
  _G["LOGISTICIAN_L_"..key] = value
end

function Logistician.Locales.Apply(s, ...)
  if currentLocale[s] ~= nil then
    return string.format(currentLocale[s], ...)
  else
    error("Unknown/missing locale string '" .. s .. "'")
  end
end
