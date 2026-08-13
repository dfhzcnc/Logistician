StaticPopupDialogs[Logistician.Constants.DialogNames.SellingConfirmPost] = {
  text = "",
  button1 = ACCEPT,
  button2 = CANCEL,
  OnShow = function(self)
    Logistician.EventBus:RegisterSource(self, "Selling Confirm Post Low Price Dialog")
  end,
  OnHide = function(self)
    Logistician.EventBus:UnregisterSource(self)
  end,
  OnAccept = function(self)
    Logistician.EventBus:Fire(self, Logistician.Selling.Events.ConfirmPost)
  end,
  timeout = 0,
  exclusive = 1,
  whileDead = 1,
  hideOnEscape = 1
}

StaticPopupDialogs[Logistician.Constants.DialogNames.SellingConfirmPostSkip] = {
  text = "",
  button1 = ACCEPT,
  button2 = LOGISTICIAN_L_SKIP,
  button3 = CANCEL,
  selectCallbackByIndex = true,
  OnShow = function(self)
    Logistician.EventBus:RegisterSource(self, "Selling Confirm Post Low Price Dialog")
  end,
  OnHide = function(self)
    Logistician.EventBus:UnregisterSource(self)
  end,
  OnButton1 = function(self)
    Logistician.EventBus:Fire(self, Logistician.Selling.Events.ConfirmPost)
  end,
  OnButton2 = function(self)
    Logistician.EventBus:Fire(self, Logistician.Selling.Events.SkipItem)
  end,
  OnButton3 = function(self) end,
  timeout = 0,
  exclusive = 1,
  whileDead = 1,
  hideOnEscape = 1
}
