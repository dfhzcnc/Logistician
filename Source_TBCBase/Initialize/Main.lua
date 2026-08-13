local LOGISTICIAN_EVENTS = {
  "CRAFT_SHOW",
}

LogisticianInitializeTBCMixin = {}

function LogisticianInitializeTBCMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, LOGISTICIAN_EVENTS)
end

function LogisticianInitializeTBCMixin:OnEvent(event, ...)
  if event == "CRAFT_SHOW" then
    Logistician.EnchantInfo.Initialize()
    self:CraftShown()
  end
end

function LogisticianInitializeTBCMixin:CraftShown()
  Logistician.Debug.Message("LogisticianInitializeTBCMixin::CraftShown()")

  if self.initializedCraftHooks then
    return
  end

  local reagentHook = function(self)
    if IsModifiedClick("CHATLINK") and LogisticianShoppingFrame ~= nil and LogisticianShoppingFrame:IsVisible() then
      local name = GetCraftReagentInfo(GetCraftSelectionIndex(), self:GetID())

      if name == nil then
        return
      end

      local searchTerm = "\"" .. name .. "\""
      LogisticianShoppingFrame:DoSearch({searchTerm}, {})
      LogisticianShoppingFrame.SearchOptions:SetSearchTerm(searchTerm)
      Logistician.Shopping.Recents.Save(searchTerm)
    end
  end
  CraftReagent1:HookScript("OnClick", reagentHook)
  CraftReagent2:HookScript("OnClick", reagentHook)
  CraftReagent3:HookScript("OnClick", reagentHook)
  CraftReagent4:HookScript("OnClick", reagentHook)

  self.initializedCraftHooks = true
end
