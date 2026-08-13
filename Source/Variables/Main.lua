local VERSION_8_3 = 6
local VERSION_SERIALIZED = 7
local VERSION_KEY_SERIALIZED = 8
local POSTING_HISTORY_DB_VERSION = 1
local VENDOR_PRICE_CACHE_DB_VERSION = 1

function Logistician.Variables.Initialize()
  Logistician.Variables.InitializeSavedState()

  Logistician.Config.InitializeData()
  Logistician.Config.InitializeFrames()

  local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  Logistician.State.CurrentVersion = GetAddOnMetadata("!Logistician", "Version")

  Logistician.Variables.InitializeShoppingLists()
  Logistician.Variables.InitializePostingHistory()
  Logistician.Variables.InitializeVendorPriceCache()

  Logistician.Groups.Initialize()
end

function Logistician.Variables.InitializeLate()
  Logistician.Variables.InitializeDatabase()

  Logistician.State.Loaded = true
end

function Logistician.Variables.Commit()
  Logistician.Variables.CommitDatabase()
end

function Logistician.Variables.InitializeSavedState()
  if LOGISTICIAN_SAVEDVARS == nil then
    LOGISTICIAN_SAVEDVARS = {}
  end
  Logistician.SavedState = LOGISTICIAN_SAVEDVARS
end

-- Attempt to import from other connected realms (this may happen if another
-- realm was connected or the databases are not currently shared)
--
-- Assumes rootRealm has no active database
local function ImportFromConnectedRealm(rootRealm)
  local connections = GetAutoCompleteRealms()

  if #connections == 0 then
    return false
  end

  for _, altRealm in ipairs(connections) do

    if LOGISTICIAN_PRICE_DATABASE[altRealm] ~= nil then

      LOGISTICIAN_PRICE_DATABASE[rootRealm] = LOGISTICIAN_PRICE_DATABASE[altRealm]
      -- Remove old database (no longer needed)
      LOGISTICIAN_PRICE_DATABASE[altRealm] = nil
      return true
    end
  end

  return false
end

local function ImportFromNotNormalizedName(target)
  local unwantedName = GetRealmName()

  if LOGISTICIAN_PRICE_DATABASE[unwantedName] ~= nil then

    LOGISTICIAN_PRICE_DATABASE[target] = LOGISTICIAN_PRICE_DATABASE[unwantedName]
    -- Remove old database (no longer needed)
    LOGISTICIAN_PRICE_DATABASE[unwantedName] = nil
    return true
  end

  return false
end

-- Deserialize current realm when not already deserialized in the saved
-- variables and serialize any other realms.
-- We keep the current realm deserialized in the saved variables to speed up
-- /reloads and logging in/out when only using one realm.
function Logistician.Variables.InitializeDatabase()
  Logistician.Debug.Message("Logistician.Database.Initialize()")
  -- Logistician.Utilities.TablePrint(LOGISTICIAN_PRICE_DATABASE, "LOGISTICIAN_PRICE_DATABASE")

  -- First time users need the price database initialized
  if LOGISTICIAN_PRICE_DATABASE == nil then
    LOGISTICIAN_PRICE_DATABASE = {
      ["__dbversion"] = VERSION_8_3
    }
  end

  local LibCBOR = LibStub("LibCBOR-1.0")

  if LOGISTICIAN_PRICE_DATABASE["__dbversion"] == VERSION_8_3 then
    LOGISTICIAN_PRICE_DATABASE["__dbversion"] = VERSION_SERIALIZED
  end
  if LOGISTICIAN_PRICE_DATABASE["__dbversion"] == VERSION_SERIALIZED then
    LOGISTICIAN_PRICE_DATABASE["__dbversion"] = VERSION_KEY_SERIALIZED
  end

  -- If we changed how we record item info we need to reset the DB
  if LOGISTICIAN_PRICE_DATABASE["__dbversion"] ~= VERSION_KEY_SERIALIZED then
    LOGISTICIAN_PRICE_DATABASE = {
      ["__dbversion"] = VERSION_KEY_SERIALIZED
    }
  end

  local realm = Logistician.Variables.GetConnectedRealmRoot()
  Logistician.State.CurrentRealm = realm

  if C_EncodingUtil then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function()
      local raw = LOGISTICIAN_PRICE_DATABASE[realm]
      LOGISTICIAN_PRICE_DATABASE[realm] = C_EncodingUtil.SerializeCBOR(raw)
    end)
  end

  -- Check for current realm and initialize if not present
  if LOGISTICIAN_PRICE_DATABASE[realm] == nil then
    if not ImportFromNotNormalizedName(realm) and not ImportFromConnectedRealm(realm) then
      LOGISTICIAN_PRICE_DATABASE[realm] = {}
    end
  end

  C_Timer.After(0, function()
    -- Serialize and other unserialized realms so their data doesn't contribute to
    -- a constant overflow when the client parses the saved variables.
    for key, data in pairs(LOGISTICIAN_PRICE_DATABASE) do
      -- Convert one realm at a time, no need to hold up a login indefinitely
      if key ~= "__dbversion" and key ~= realm and type(data) == "table" then
        if C_EncodingUtil then
          LOGISTICIAN_PRICE_DATABASE[key] = C_EncodingUtil.SerializeCBOR(data)
        else
          LOGISTICIAN_PRICE_DATABASE[key] = LibCBOR:Serialize(data)
        end
        break
      end
    end
  end)

  -- Only deserialize the current realm and save the deserialization in the
  -- saved variables to speed up reloads or changing character on the same
  -- realm.
  --]]
  -- Deserialize the current realm if it was left serialized by a previous
  -- version of Logistician
  local raw = LOGISTICIAN_PRICE_DATABASE[realm]
  if type(raw) == "string" then
    local success, data
    if C_EncodingUtil then
      success, data = pcall(C_EncodingUtil.DeserializeCBOR, raw)
    else
      success, data = pcall(LibCBOR.Deserialize, LibCBOR, raw)
    end
    if not success then
      LOGISTICIAN_PRICE_DATABASE[realm] = {}
    else
      LOGISTICIAN_PRICE_DATABASE[realm] = data
    end
  end

  -- Fix conversion error from old code
  if type(LOGISTICIAN_PRICE_DATABASE[realm]) ~= "table" then
    LOGISTICIAN_PRICE_DATABASE[realm] = {}
  end

  assert(LOGISTICIAN_PRICE_DATABASE[realm], "Realm data missing somehow")

  for realm, realmData in pairs(LOGISTICIAN_PRICE_DATABASE) do
    if type(realmData) == "table" and realmData.version ~= 2 then
      for key, itemData in pairs(realmData) do
        if type(itemData) == "table" and itemData.pending then
          for _, field in ipairs({"a", "h", "l"}) do
            local new = {}
            -- Make it valid JSON (legacy)
            for day, data in pairs(itemData[field] or {}) do
              new[tostring(day)] = data
            end
            itemData[field] = new
          end
        elseif type(itemData) == "table" and itemData.pending then
          itemData = itemData.old
        end
        -- Reverse per-item CBOR format
        if type(itemData) == "string" then
          if C_EncodingUtil then
            realmData[key] = C_EncodingUtil.DeserializeCBOR(itemData)
          else
            realmData[key] = LibCBOR:Deserialize(itemData)
          end
        end
      end
      realmData.version = 2
    end
  end

  if Logistician.Config.Get(Logistician.Config.Options.NO_PRICE_DATABASE) then
    Logistician.Database = CreateAndInitFromMixin(Logistician.DatabaseMixin, {})
  else
    Logistician.Database = CreateAndInitFromMixin(Logistician.DatabaseMixin, LOGISTICIAN_PRICE_DATABASE[realm])
  end
end

function Logistician.Variables.InitializePostingHistory()
  Logistician.Debug.Message("Logistician.Variables.InitializePostingHistory()")

  if LOGISTICIAN_POSTING_HISTORY == nil  or
     LOGISTICIAN_POSTING_HISTORY["__dbversion"] ~= POSTING_HISTORY_DB_VERSION then
    LOGISTICIAN_POSTING_HISTORY = {
      ["__dbversion"] = POSTING_HISTORY_DB_VERSION
    }
  end

  Logistician.PostingHistory = CreateAndInitFromMixin(Logistician.PostingHistoryMixin, LOGISTICIAN_POSTING_HISTORY)
end

function Logistician.Variables.InitializeShoppingLists()
  Logistician.Shopping.ListManager = CreateAndInitFromMixin(
    LogisticianShoppingListManagerMixin,
    function() return LOGISTICIAN_SHOPPING_LISTS end,
    function(newVal) LOGISTICIAN_SHOPPING_LISTS = newVal end
  )

  LOGISTICIAN_RECENT_SEARCHES = LOGISTICIAN_RECENT_SEARCHES or {}
end

function Logistician.Variables.InitializeVendorPriceCache()
  Logistician.Debug.Message("Logistician.Variables.InitializeVendorPriceCache()")

  if LOGISTICIAN_VENDOR_PRICE_CACHE == nil  or
     LOGISTICIAN_VENDOR_PRICE_CACHE["__dbversion"] ~= VENDOR_PRICE_CACHE_DB_VERSION then
    LOGISTICIAN_VENDOR_PRICE_CACHE = {
      ["__dbversion"] = VENDOR_PRICE_CACHE_DB_VERSION
    }
  end
end
