LogisticianStackOfInputMixin = CreateFromMixins(LogisticianConfigTooltipMixin)

function LogisticianStackOfInputMixin:OnLoad()
  self.maxStackSize = 0
  self.maxNumStacks = 0
end

function LogisticianStackOfInputMixin:SetMaxNumStacks(max)
  self.maxNumStacks = max
end

function LogisticianStackOfInputMixin:GetConfig()
  return {
    numStacks = self.NumStacks:GetNumber(),
    stackSize = self.StackSize:GetNumber(),
  }
end

function LogisticianStackOfInputMixin:SetConfig(config)
  self.NumStacks:SetNumber(config.numStacks)
  self.StackSize:SetNumber(config.stackSize)
end

function LogisticianStackOfInputMixin:SetMaxStackSize(max)
  self.maxStackSize = max
  self.MaxStackSize:SetText(LOGISTICIAN_L_MAX_COLON_X:format(max))
end

function LogisticianStackOfInputMixin:SetMaxNumStacks(max)
  self.maxNumStacks = max
  self.MaxNumStacks:SetText(LOGISTICIAN_L_MAX_COLON_X:format(max))
end

function LogisticianStackOfInputMixin:MaxNumStacksClicked()
  self.NumStacks:SetNumber(self.maxNumStacks)
end

function LogisticianStackOfInputMixin:MaxStackSizeClicked()
  if IsShiftKeyDown() then
    self.StackSize:SetNumber(1)
  else
    self.StackSize:SetNumber(self.maxStackSize)
  end
end
