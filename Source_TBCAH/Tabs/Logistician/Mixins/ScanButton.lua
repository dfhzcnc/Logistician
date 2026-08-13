LogisticianScanButtonMixin = {}

function LogisticianScanButtonMixin:OnClick()
  Logistician.State.FullScanFrameRef:InitiateScan()
end
