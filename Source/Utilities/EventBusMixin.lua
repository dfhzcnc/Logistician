LogisticianEventBusMixin = {}

function LogisticianEventBusMixin:Init()
  self.registeredListeners = {}
  self.sources = {}
  self.queue = {}
end

function LogisticianEventBusMixin:Register(listener, eventNames)
  if listener.ReceiveEvent == nil then
    error("Attempted to register an invalid listener! ReceiveEvent method must be defined.")
    return self
  end

  for _, eventName in ipairs(eventNames) do
    if self.registeredListeners[eventName] == nil then
      self.registeredListeners[eventName] = {}
    end

    table.insert(self.registeredListeners[eventName], listener)
    Logistician.Debug.Message("LogisticianEventBusMixin:Register", eventName)
  end

  return self
end

-- Assumes events have been registered exactly once
function LogisticianEventBusMixin:Unregister(listener, eventNames)
  for _, eventName in ipairs(eventNames) do
    local index = tIndexOf(self.registeredListeners[eventName], listener)
    if index ~= nil then
      table.remove(self.registeredListeners[eventName], index, listener)
    end
    Logistician.Debug.Message("LogisticianEventBusMixin:Unregister", eventName)
  end

  return self
end

function LogisticianEventBusMixin:IsSourceRegistered(source)
  return self.sources[source] ~= nil
end

function LogisticianEventBusMixin:RegisterSource(source, name)
  self.sources[source] = name

  return self
end

function LogisticianEventBusMixin:UnregisterSource(source)
  self.sources[source] = nil

  return self
end

function LogisticianEventBusMixin:Fire(source, eventName, ...)
  if self.sources[source] == nil then
    error("All sources must be registered (" .. eventName .. ")")
  end

  Logistician.Debug.Message(
    "LogisticianEventBus:Fire()",
    self.sources[source],
    eventName,
    ...
  )

  if self.registeredListeners[eventName] ~= nil then
    Logistician.Debug.Message("ReceiveEvent", #self.registeredListeners[eventName], eventName)

    local allListeners = Logistician.Utilities.Slice(
      self.registeredListeners[eventName],
      1,
      #self.registeredListeners[eventName]
    )
    for index, listener in ipairs(allListeners) do
      listener:ReceiveEvent(eventName, ...)
    end
  end

  return self
end

Logistician.EventBus = CreateAndInitFromMixin(LogisticianEventBusMixin)
