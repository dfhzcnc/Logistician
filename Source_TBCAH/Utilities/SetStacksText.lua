function Logistician.Utilities.SetStacksText(entry)
  if entry.numStacks == 1 then
    entry.availablePretty = LOGISTICIAN_L_X_STACK_OF_X:format(entry.numStacks, entry.stackSize)
  else
    entry.availablePretty = LOGISTICIAN_L_X_STACKS_OF_X:format(entry.numStacks, entry.stackSize)
  end
end
