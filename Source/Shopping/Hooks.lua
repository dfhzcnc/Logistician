-- Reads the reagent list off a recipe's native tooltip. Blizzard renders "Reagents:" for
-- any recipe hyperlink client-side (enchant formulas, and item-type recipes like Plans/
-- Patterns/Formulas/Schematics), known or not - the same trick AtlasLoot's crafting browser
-- uses to show reagents without its own bill-of-materials database. Works generically for
-- whatever link the user shift-clicked, not just enchants.
local function GetRecipeReagents(link)
  if AuctionatorRecipeScanTooltip == nil then
    CreateFrame("GameTooltip", "AuctionatorRecipeScanTooltip", nil, "GameTooltipTemplate")
  end
  local tooltip = AuctionatorRecipeScanTooltip
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  local ok = pcall(tooltip.SetHyperlink, tooltip, link)
  if not ok then
    tooltip:Hide()
    return {}
  end

  local reagents = {}
  local foundReagentsLabel = false
  for lineIndex = 1, tooltip:NumLines() do
    local fontString = _G["AuctionatorRecipeScanTooltipTextLeft" .. lineIndex]
    local rawText = fontString and fontString:GetText()
    -- Strip color codes and literal "|n" newline escapes (both can appear embedded within
    -- a single logical tooltip line, e.g. "Reagents:|nStrange Dust (4), ...").
    local text = rawText and rawText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
    if text then
      -- The label and the reagent list can be on the SAME tooltip line (wrapping is only
      -- visual), so check for "Reagents:" as a prefix rather than requiring its own line.
      local sameLineReagents = text:match("^Reagents:%s*(.+)$")
      if sameLineReagents then
        text = sameLineReagents
        foundReagentsLabel = true
      end

      if foundReagentsLabel then
        for reagentName, count in text:gmatch("([^,]-)%s*%((%d+)%)") do
          table.insert(reagents, {
            name = reagentName:gsub("^%s+", ""):gsub("%s+$", ""),
            count = tonumber(count),
          })
        end
        if #reagents > 0 then
          break
        end
      elseif text == "Reagents:" then
        foundReagentsLabel = true
      end
    end
  end
  tooltip:Hide()

  return reagents
end

-- Auto-creates a new Shopping List populated with a recipe's reagents (with quantities).
-- Only triggered by alt+click (see the SetItemRef/HandleModifiedItemClick overrides below) -
-- separate from SearchItem's plain-name search, which stays on the regular shift+click.
-- Works as long as the AH is open at all (any tab), switching to Shopping automatically.
local function TryCreateShoppingListFromRecipe(text)
  if text == nil or AuctionatorShoppingFrame == nil then
    return false
  end

  local isAHOpen = (AuctionHouseFrame and AuctionHouseFrame:IsShown())
    or (AuctionFrame and AuctionFrame:IsShown())
  if not isAHOpen then
    return false
  end

  local reagents = GetRecipeReagents(text)
  if #reagents == 0 then
    return false
  end

  if AuctionatorTabs_Shopping and not AuctionatorShoppingFrame:IsVisible() then
    AuctionatorTabs_Shopping:Click()
  end

  local recipeName = text:match("%[(.-)%]") or "Recipe"
  local listName = Auctionator.Shopping.ListManager:GetUnusedName(recipeName)
  Auctionator.Shopping.ListManager:Create(listName)
  local list = Auctionator.Shopping.ListManager:GetByName(listName)

  for _, reagent in ipairs(reagents) do
    list:InsertItem(Auctionator.Search.ReconstituteAdvancedSearch({
      searchString = reagent.name,
      isExact = true,
      quantity = reagent.count,
    }))
  end

  AuctionatorShoppingFrame.ContainerTabs:SetView(Auctionator.Constants.ShoppingListViews.Lists)
  AuctionatorShoppingFrame.ListsContainer:ExpandList(list)

  Auctionator.Utilities.Message(
    ("Created shopping list \"%s\" with %d reagents."):format(listName, #reagents)
  )

  return true
end

local function SearchItem(text)
  if text == nil or AuctionatorShoppingFrame == nil or not AuctionatorShoppingFrame:IsVisible() then
    return false
  end

  C_Timer.After(0, function()
    StackSplitFrame:Hide()
  end)

  -- Borrowed from Blizzard InsertLink to avoid inserting textures with
  -- DF reagent links
  local name;
  if ( strfind(text, "battlepet:") ) then
    local petName = strmatch(text, "%[(.+)%]");
    name = petName;
  elseif ( strfind(text, "item:", 1, true) ) then
    name = C_Item.GetItemInfo(text);
  elseif ( strfind(text, "enchant:", 1, true) ) then
    name = Auctionator.Utilities.GetNameFromLink(text)
  end

  if name == nil then
    name = text
  end

  -- A modified bag click is equivalent to typing in the main Name field. Do
  -- not wrap the name as an exact/advanced search expression.
  local searchTerm = name
  AuctionatorShoppingFrame:DoSearch({searchTerm}, {})
  AuctionatorShoppingFrame.SearchOptions:SetPlainSearchText(searchTerm)
  Auctionator.Shopping.Recents.Save(searchTerm)

  return true
end

-- Shared by integrated UI modules which have an item link but do not pass
-- through Blizzard's normal modified-item-click path.
Auctionator.Shopping.SearchItem = SearchItem

local function Callback(text)
  -- Prevent searching when the user is attempting to link the item in chat
  if GetCurrentKeyBoardFocus() == nil or GetCurrentKeyBoardFocus():GetName() == nil then
    SearchItem(text)
  end
end

-- We would replace InsertLink so that the return value is used, but
-- that causes a taint error when attempting to buy vendor items with the stack
-- selection dialog (to replicate, when InsertLink is manually
-- replaced, hold down "c" while pressing [Enter] with the stack dialog open)
if ChatFrameUtil and ChatFrameUtil.InsertLink then
  hooksecurefunc(ChatFrameUtil, "InsertLink", Callback)
else
  hooksecurefunc(_G, "ChatEdit_InsertLink", Callback)
end

-- Alt+click (a different modifier from the shift+click-to-chat one that triggers the plain
-- search above) creates a reagent shopping list instead, for both existing chat/tooltip
-- links (SetItemRef) and bag/equipped item clicks (HandleModifiedItemClick).
local originalSetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
  -- SetItemRef's own "link" argument is the bare "type:id" data with no [Name] brackets
  -- (SetHyperlink/GetNameFromLink need those), so use "text" (the full clicked string) instead.
  if IsAltKeyDown() and TryCreateShoppingListFromRecipe(text) then
    return
  end
  originalSetItemRef(link, text, button, chatFrame)
end

local originalHandleModifiedItemClick = HandleModifiedItemClick
HandleModifiedItemClick = function(link, ...)
  if IsAltKeyDown() and TryCreateShoppingListFromRecipe(link) then
    return
  end
  return originalHandleModifiedItemClick(link, ...)
end
