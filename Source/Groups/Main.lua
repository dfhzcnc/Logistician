Logistician.Groups.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Logistician.Groups.CallbackRegistry:OnLoad()
Logistician.Groups.CallbackRegistry:GenerateCallbackEvents(Logistician.Groups.Constants.Events)

function Logistician.Groups.Initialize()
  if LOGISTICIAN_SELLING_GROUPS == nil then
    LOGISTICIAN_SELLING_GROUPS = {
      Version = 1,
      CustomGroups = {},
      HiddenItems = {},
    }

    Logistician.Groups.AddGroup("FAVOURITES")
    local list = Logistician.Groups.GetGroupList("FAVOURITES")

    for _, data in pairs(Logistician.Config.Get(Logistician.Config.Options.SELLING_FAVOURITE_KEYS)) do
      table.insert(list, data.itemLink)
    end
  end
  if LOGISTICIAN_SELLING_GROUPS.CustomSections then
    LOGISTICIAN_SELLING_GROUPS.CustomGroups = LOGISTICIAN_SELLING_GROUPS.CustomSections
    LOGISTICIAN_SELLING_GROUPS.CustomSections = nil
  end

  local group1 = LOGISTICIAN_SELLING_GROUPS.CustomGroups[1]
  if group1.name ~= "FAVOURITES_GROUP" and group1.name ~= "FAVOURITES" then
    for index, group in ipairs(LOGISTICIAN_SELLING_GROUPS.CustomGroups) do
      if group.name == "FAVOURITES_GROUP" or group.name == "FAVOURITES" then
        LOGISTICIAN_SELLING_GROUPS.CustomGroups[index] = group1
        LOGISTICIAN_SELLING_GROUPS.CustomGroups[1] = group
        group1 = group
      end
    end
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
