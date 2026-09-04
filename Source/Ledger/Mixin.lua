-- Persistent record of completed auction sales, shown in the "Ledger" tab.
-- A separate global (not nested under Auctionator.Ledger) so it survives Auctionator.Ledger
-- itself being reassigned to a new object by Auctionator.Variables.InitializeLedger().
Auctionator.LedgerEvents = {
  EntryAdded = "ledger_entry_added",
}

Auctionator.LedgerMixin = {}

local MAX_LEDGER_ENTRIES = 500

function Auctionator.LedgerMixin:Init(db)
  self.db = db
  Auctionator.EventBus:RegisterSource(self, "AuctionatorLedgerMixin")
end

-- entry = { itemLink, quantity, unitPrice, saleType ("buyout"/"bid"), marketPrice (may be nil),
--           time (optional - overrides the default "recorded right now" timestamp, used when
--           the real sale time was already learned earlier from the CHAT_MSG_SYSTEM sold notice) }
function Auctionator.LedgerMixin:AddSale(entry)
  local itemName = entry.itemLink and entry.itemLink:match("%[(.-)%]") or ""
  -- C_Item.GetItemInfoInstant returns itemID, itemType, itemSubType, itemEquipLoc, icon,
  -- classID, subClassID on this client - icon is the 5th value, NOT the 6th (that's classID,
  -- which was being fed into SetTexture as a bogus fileID, rendering as a solid green square).
  local iconTexture = entry.itemLink and select(5, C_Item.GetItemInfoInstant(entry.itemLink)) or nil
  -- Item links always embed their quality color as a |cAARRGGBB prefix regardless of whether
  -- the item's info is cached yet, so read the color straight from the link instead of relying
  -- on an item-info API call that could still be pending.
  local qualityR, qualityG, qualityB = 1, 1, 1
  if entry.itemLink then
    local rr, gg, bb = entry.itemLink:match("|c%x%x(%x%x)(%x%x)(%x%x)")
    if rr then
      qualityR, qualityG, qualityB = tonumber(rr, 16) / 255, tonumber(gg, 16) / 255, tonumber(bb, 16) / 255
    end
  end

  table.insert(self.db, 1, {
    time = entry.time or time(),
    itemLink = entry.itemLink,
    itemName = itemName,
    iconTexture = iconTexture,
    qualityR = qualityR,
    qualityG = qualityG,
    qualityB = qualityB,
    quantity = entry.quantity,
    unitPrice = entry.unitPrice,
    saleType = entry.saleType,
    marketPrice = entry.marketPrice,
  })

  while #self.db > MAX_LEDGER_ENTRIES do
    table.remove(self.db)
  end

  Auctionator.EventBus:Fire(self, Auctionator.LedgerEvents.EntryAdded)
end

function Auctionator.LedgerMixin:GetEntries()
  return self.db
end

-- Persisted scan state for the owner-auction poll/diff in Source_LegacyAH/Ledger/Main.lua -
-- without this surviving a reload, a sold auction still lingering (uncollected) in the owner
-- list would look "new" again on the very first post-reload scan and get recorded twice, the
-- same way Posting History persists its own state instead of starting blank every reload.
function Auctionator.LedgerMixin:GetScanState()
  self.db.__scanState = self.db.__scanState or { previousSoldCounts = {}, knownActiveQuantity = {} }
  return self.db.__scanState
end

-- Keeps only the newest `count` entries (entries are stored newest-first), discarding the rest.
-- Used for one-off cleanup of bad data recorded before a bugfix.
function Auctionator.LedgerMixin:TrimTo(count)
  while #self.db > count do
    table.remove(self.db)
  end

  Auctionator.EventBus:Fire(self, Auctionator.LedgerEvents.EntryAdded)
end

function Auctionator.LedgerMixin:Clear()
  self:TrimTo(0)
end
