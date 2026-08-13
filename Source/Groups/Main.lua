Logistician.Groups.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Logistician.Groups.CallbackRegistry:OnLoad()
Logistician.Groups.CallbackRegistry:GenerateCallbackEvents(Logistician.Groups.Constants.Events)

function Logistician.Groups.Initialize()
  LOGISTICIAN_SELLING_GROUPS = LOGISTICIAN_SELLING_GROUPS or {}
  LOGISTICIAN_SELLING_GROUPS.Version = LOGISTICIAN_SELLING_GROUPS.Version or 1
  LOGISTICIAN_SELLING_GROUPS.CustomGroups = LOGISTICIAN_SELLING_GROUPS.CustomGroups or {}
  LOGISTICIAN_SELLING_GROUPS.HiddenItems = LOGISTICIAN_SELLING_GROUPS.HiddenItems or {}

  if LOGISTICIAN_SELLING_GROUPS.CustomSections then
    LOGISTICIAN_SELLING_GROUPS.CustomGroups = LOGISTICIAN_SELLING_GROUPS.CustomSections
    LOGISTICIAN_SELLING_GROUPS.CustomSections = nil
  end

  local favouritesIndex = Logistician.Groups.GetGroupIndex("FAVOURITES")
    or Logistician.Groups.GetGroupIndex("FAVOURITES_GROUP")
  if favouritesIndex == nil then
    Logistician.Groups.AddGroup("FAVOURITES")
    local list = Logistician.Groups.GetGroupList("FAVOURITES")

    for _, data in pairs(Logistician.Config.Get(Logistician.Config.Options.SELLING_FAVOURITE_KEYS)) do
      table.insert(list, data.itemLink)
    end
    favouritesIndex = #LOGISTICIAN_SELLING_GROUPS.CustomGroups
  end

  local group1 = LOGISTICIAN_SELLING_GROUPS.CustomGroups[1]
  if favouritesIndex ~= 1 then
    local favourites = LOGISTICIAN_SELLING_GROUPS.CustomGroups[favouritesIndex]
    LOGISTICIAN_SELLING_GROUPS.CustomGroups[favouritesIndex] = group1
    LOGISTICIAN_SELLING_GROUPS.CustomGroups[1] = favourites
    group1 = favourites
  end

  if group1.name == "FAVOURITES_GROUP" then
    LOGISTICIAN_SELLING_GROUPS.CustomGroups[1].name = "FAVOURITES"
  end
end
local function AutoCreateCache()
  if not LogisticianBagCacheFrame then
    CreateFrame("Frame", "LogisticianBagCacheFrame", UIParent, "LogisticianBagCacheTemplate")
  end
end

function Logistician.Groups.OnAHOpen()
  AutoCreateCache()
end
