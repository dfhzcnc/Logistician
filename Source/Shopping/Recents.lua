Logistician.Shopping.Recents = {}

function Logistician.Shopping.Recents.Save(searchText)
  local prevIndex = tIndexOf(LOGISTICIAN_RECENT_SEARCHES, searchText)
  if prevIndex ~= nil then
    table.remove(LOGISTICIAN_RECENT_SEARCHES, prevIndex)
  end

  table.insert(LOGISTICIAN_RECENT_SEARCHES, 1, searchText)

  while #LOGISTICIAN_RECENT_SEARCHES > Logistician.Constants.RecentsListLimit do
    table.remove(LOGISTICIAN_RECENT_SEARCHES)
  end

  Logistician.EventBus
    :RegisterSource(Logistician.Shopping.Recents.Save, "save recents entry")
    :Fire(Logistician.Shopping.Recents.Save, Logistician.Shopping.Events.RecentSearchesUpdate)
    :UnregisterSource(Logistician.Shopping.Recents.Save)
end

function Logistician.Shopping.Recents.DeleteEntry(searchTerm)
  local index = tIndexOf(LOGISTICIAN_RECENT_SEARCHES, searchTerm)

  if index ~= nil then
    table.remove(LOGISTICIAN_RECENT_SEARCHES, index)
    Logistician.EventBus
      :RegisterSource(Logistician.Shopping.Recents.DeleteEntry, "delete recents entry")
      :Fire(Logistician.Shopping.Recents.DeleteEntry, Logistician.Shopping.Events.RecentSearchesUpdate)
      :UnregisterSource(Logistician.Shopping.Recents.DeleteEntry)
  end
end

function Logistician.Shopping.Recents.GetAll()
  return LOGISTICIAN_RECENT_SEARCHES
end
