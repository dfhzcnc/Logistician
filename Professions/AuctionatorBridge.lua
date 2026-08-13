-- Wider Professions+ <-> Auctionator compatibility bridge
-- WPP 0.1.20
--
-- Keep Auctionator integration centralized here. Future WPP features should
-- prefer this bridge instead of reaching into Auctionator internals directly.
-- The bridge intentionally uses Auctionator.API.v1, which Auctionator exposes
-- as its supported external API.

local Bridge = {}
_G.WiderProfessionsAuctionatorBridge = Bridge

Bridge.CALLER_ID = "Logistician"

local function API()
    if type(Auctionator) ~= "table"
        or type(Auctionator.API) ~= "table"
        or type(Auctionator.API.v1) ~= "table" then
        return nil
    end
    return Auctionator.API.v1
end

local function Metadata(name, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, field)
    elseif GetAddOnMetadata then
        return GetAddOnMetadata(name, field)
    end
    return nil
end

function Bridge:IsAvailable()
    return API() ~= nil
end

function Bridge:GetVersion()
    return Metadata("!Logistician", "Version")
end

function Bridge:Has(functionName)
    local api = API()
    return api and type(api[functionName]) == "function" or false
end

function Bridge:Call(functionName, ...)
    local api = API()
    local fn = api and api[functionName]

    if type(fn) ~= "function" then
        return false, nil, "Auctionator API function unavailable: " .. tostring(functionName)
    end

    local ok, result = pcall(fn, self.CALLER_ID, ...)
    if not ok then
        return false, nil, result
    end

    return true, result, nil
end

function Bridge:GetAuctionPriceByItemID(itemID)
    if type(itemID) ~= "number" then return nil end
    local ok, value = self:Call("GetAuctionPriceByItemID", itemID)
    if ok and type(value) == "number" and value > 0 then
        return value
    end
    return nil
end

function Bridge:GetAuctionPriceByItemLink(itemLink)
    if type(itemLink) ~= "string" then return nil end
    local ok, value = self:Call("GetAuctionPriceByItemLink", itemLink)
    if ok and type(value) == "number" and value > 0 then
        return value
    end
    return nil
end


function Bridge:GetAuctionAverageByItemID(itemID, days)
    if type(itemID) ~= "number" then return nil end
    local ok, value = self:Call("GetAuctionAverageByItemID", itemID, days)
    if ok and type(value) == "number" and value > 0 then
        return value
    end
    return nil
end

function Bridge:GetAuctionAverageByItemLink(itemLink, days)
    if type(itemLink) ~= "string" then return nil end
    local ok, value = self:Call("GetAuctionAverageByItemLink", itemLink, days)
    if ok and type(value) == "number" and value > 0 then
        return value
    end
    return nil
end


function Bridge:GetSaleLikelihoodByItemID(itemID, days)
    if type(itemID) ~= "number" then return nil end

    local api = API()
    local fn = api and api.GetSaleLikelihoodByItemID
    if type(fn) ~= "function" then return nil end

    local ok, score, label, confidence, details =
        pcall(fn, self.CALLER_ID, itemID, days)

    if not ok then return nil end
    return score, label, confidence, details
end

function Bridge:GetSaleLikelihoodByItemLink(itemLink, days)
    if type(itemLink) ~= "string" then return nil end

    local api = API()
    local fn = api and api.GetSaleLikelihoodByItemLink
    if type(fn) ~= "function" then return nil end

    local ok, score, label, confidence, details =
        pcall(fn, self.CALLER_ID, itemLink, days)

    if not ok then return nil end
    return score, label, confidence, details
end


function Bridge:GetSaleExposureHistoryByItemID(itemID)
    if type(itemID) ~= "number" then return {} end

    local api = API()
    local fn = api and api.GetSaleExposureHistoryByItemID
    if type(fn) ~= "function" then return {} end

    local ok, observations =
        pcall(fn, self.CALLER_ID, itemID)

    if not ok or type(observations) ~= "table" then
        return {}
    end

    return observations
end

function Bridge:GetAuctionAgeByItemID(itemID)
    if type(itemID) ~= "number" then return nil end
    local ok, value = self:Call("GetAuctionAgeByItemID", itemID)
    return ok and value or nil
end

function Bridge:IsAuctionDataExactByItemID(itemID)
    if type(itemID) ~= "number" then return nil end
    local ok, value = self:Call("IsAuctionDataExactByItemID", itemID)
    return ok and value or nil
end

function Bridge:GetVendorPriceByItemID(itemID)
    if type(itemID) ~= "number" then return nil end
    local ok, value = self:Call("GetVendorPriceByItemID", itemID)
    return ok and value or nil
end

function Bridge:GetDisenchantPriceByItemID(itemID)
    if type(itemID) ~= "number" then return nil end
    local ok, value = self:Call("GetDisenchantPriceByItemID", itemID)
    return ok and value or nil
end

local function RowName(row)
    if type(row) ~= "table" then return nil end
    if type(row.name) == "string" and row.name ~= "" then
        return row.name
    end
    if type(row.itemID) == "number" then
        return GetItemInfo(row.itemID)
    end
    return nil
end

local function RowQuantity(row)
    return math.max(
        1,
        math.floor(
            tonumber(
                row.quantity
                    or row.count
                    or row.qty
                    or 1
            ) or 1
        )
    )
end

function Bridge:BuildAdvancedSearchTerms(rows)
    local terms = {}

    for _, row in ipairs(rows or {}) do
        local name = RowName(row)
        if name then
            table.insert(terms, {
                searchString = name,
                categoryKey = "",
                isExact = true,
                quantity = RowQuantity(row),
            })
        end
    end

    return terms
end

function Bridge:BuildShoppingListStrings(rows)
    if not self:Has("ConvertToSearchString") then
        return nil, "Auctionator ConvertToSearchString API unavailable"
    end

    local strings = {}

    for _, term in ipairs(self:BuildAdvancedSearchTerms(rows)) do
        local ok, value, err = self:Call("ConvertToSearchString", term)
        if not ok then
            return nil, err
        end
        table.insert(strings, value)
    end

    return strings
end

-- Create/replace a persistent Auctionator shopping list.
-- This does NOT require the auction house to be open.
function Bridge:CreateShoppingList(name, rows)
    if type(name) ~= "string" or name == "" then
        return false, "Shopping list name is required"
    end

    local searchStrings, err = self:BuildShoppingListStrings(rows)
    if not searchStrings then
        return false, err
    end

    local ok, _, callErr = self:Call(
        "CreateShoppingList",
        name,
        searchStrings
    )

    if not ok then
        return false, callErr
    end

    return true
end

function Bridge:GetShoppingListItems(name)
    local ok, value, err = self:Call("GetShoppingListItems", name)
    if not ok then return nil, err end
    return value
end

-- Launch an Auctionator Shopping search for these rows.
-- Auctionator requires the auction house to be open for MultiSearchAdvanced.
function Bridge:SearchRows(rows)
    if not self:Has("MultiSearchAdvanced") then
        return false, "Auctionator MultiSearchAdvanced API unavailable"
    end

    local terms = self:BuildAdvancedSearchTerms(rows)
    local ok, _, err = self:Call("MultiSearchAdvanced", terms)

    if not ok then
        return false, err
    end

    return true
end

function Bridge:GetCapabilities()
    return {
        available = self:IsAvailable(),
        version = self:GetVersion(),
        auctionPrice = self:Has("GetAuctionPriceByItemID"),
        auctionAverage = self:Has("GetAuctionAverageByItemID"),
        saleLikelihood = self:Has("GetSaleLikelihoodByItemID"),
        saleExposureHistory = self:Has("GetSaleExposureHistoryByItemID"),
        auctionAge = self:Has("GetAuctionAgeByItemID"),
        exactPrice = self:Has("IsAuctionDataExactByItemID"),
        vendorPrice = self:Has("GetVendorPriceByItemID"),
        disenchantPrice = self:Has("GetDisenchantPriceByItemID"),
        shoppingLists =
            self:Has("CreateShoppingList")
            and self:Has("GetShoppingListItems")
            and self:Has("ConvertToSearchString"),
        multiSearch = self:Has("MultiSearchAdvanced"),
    }
end
