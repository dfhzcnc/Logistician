-- Group items by database key for use with Auctiontator.Database:ProcessScan
function Logistician.Search.GroupResultsForDB(results)
  Logistician.Debug.Message("Logistician.Search.GroupResults", #results)

  local waiting = #results
  local doneComplete = false
  local groups = {}

  local function OnComplete()
    doneComplete = true
    Logistician.Database:ProcessScan(groups, function()
      Logistician.EventBus
        :RegisterSource(Logistician.Search.GroupResultsForDB, "Classic GroupResultsForDB")
        :Fire(Logistician.Search.GroupResultsForDB, Logistician.Search.Events.PricesProcessed)
        :UnregisterSource(Logistician.Search.GroupResultsForDB)
    end)
  end

  for _, entry in ipairs(results) do
    if entry.info[3] ~= 0 and entry.info[10] ~= 0 then
      Logistician.Utilities.DBKeyFromLink(entry.itemLink, function(keys)
        local unitPrice = math.ceil(entry.info[10] / entry.info[3])
        waiting = waiting - 1
        for _, key in ipairs(keys) do
          if groups[key] == nil then
            groups[key] = {}
          end
          table.insert(groups[key], {
            price = unitPrice,
            available = entry.info[3],
            timeLeft = entry.timeLeft,
            owner = entry.info[Logistician.Constants.AuctionItemInfo.Owner],
          })
        end
        if waiting == 0 then
          OnComplete()
        end
      end)
    else
      waiting = waiting - 1
    end
  end

  if waiting == 0 and not doneComplete then
    OnComplete()
  end
end
