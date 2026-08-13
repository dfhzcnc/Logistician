function Logistician.Selling.ComposeAuctionPostedMessage(auctionInfo)
  local stacksText
  if auctionInfo.numStacks == 1 then
    stacksText = LOGISTICIAN_L_X_STACK_OF_X:format(auctionInfo.numStacks, auctionInfo.stackSize)
  else
    stacksText = LOGISTICIAN_L_X_STACKS_OF_X:format(auctionInfo.numStacks, auctionInfo.stackSize)
  end

  return LOGISTICIAN_L_MULTIPLE_STACKS_AUCTION_INFO:format(
    auctionInfo.itemLink,
    stacksText,
    GetMoneyString(auctionInfo.stackBuyout * auctionInfo.numStacks, true)
  )
end
