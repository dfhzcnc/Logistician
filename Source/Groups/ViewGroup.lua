LogisticianGroupsViewGroupMixin = {}

function LogisticianGroupsViewGroupMixin:Reset()
  self.col = 0
  self.row = 0
  self.collapsed = false
  self.buttons = {}
  self.iconSize = Logistician.Config.Get(Logistician.Config.Options.SELLING_ICON_SIZE)
  -- Use first fixed parent's size to determine how many icons per row
  self.rowWidth = math.floor(self:GetParent():GetParent():GetWidth() / self.iconSize)
  self.GroupTitle:SetPoint("TOPLEFT", self.insetLeft, 0)
end

function LogisticianGroupsViewGroupMixin:AddButton(button)
  table.insert(self.buttons, button)
  local yOffset = -self.groupTitleHeight - (self.row * self.iconSize)
  button:SetPoint("TOPLEFT", self, self.insetLeft + self.col * self.iconSize, yOffset)
  button.yOffset = yOffset
  button:SetShown(not self.collapsed)
  self.col = self.col + 1

  if self.col == self.rowWidth then
    self.col = 0
    self.row = self.row + 1
  end
end

function LogisticianGroupsViewGroupMixin:AnyButtons()
  return self.col ~= 0 or self.row ~= 0
end

function LogisticianGroupsViewGroupMixin:ToggleOpen(doNotNotify)
  if not self.collapsable then
    return
  end

  self.collapsed = not self.collapsed

  for _, button in ipairs(self.buttons) do
    button:SetShown(not self.collapsed)
  end

  if not doNotNotify then
    -- Need to update heights
    Logistician.Groups.CallbackRegistry:TriggerEvent("ViewGroupToggled")
  end
end

function LogisticianGroupsViewGroupMixin:UpdateHeight()
  local newHeight
  if self.collapsed then
    newHeight = self.groupTitleHeight
  else
    if self.col == 0 then
      newHeight = self.row * self.iconSize + self.groupTitleHeight
    else
      newHeight = (self.row + 1) * self.iconSize + self.groupTitleHeight
    end
  end
  self:SetHeight(newHeight + self.paddingBottom)
end

function LogisticianGroupsViewGroupMixin:SetName(name, isCustom)
  if self.GroupTitle then
    self.GroupTitle:SetText(_G["LOGISTICIAN_L_" .. name] or name)
  end
  self.name = name
  self.isCustom = isCustom
end
