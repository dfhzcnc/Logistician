function Logistician.Shopping.Tab.CreateOptionButton(button, xOffset, width, height)
  local option = CreateFrame("Button", nil, button)
  local size = 16
  option:SetPoint("RIGHT", button, "RIGHT", xOffset - 3, 0)
  option:SetSize(size, size)
  option.Icon = option:CreateTexture(nil, "ARTWORK")
  option.Icon:SetSize(12, 12)
  option.Icon:SetPoint("CENTER")
  option.Icon:SetBlendMode("BLEND")
  option:SetScript("OnEnter", function()
    option.Icon:SetAlpha(0.5)
    if option.TooltipText then
      GameTooltip:SetOwner(option, "ANCHOR_RIGHT")
      GameTooltip:SetText(option.TooltipText, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  option:SetScript("OnLeave", function()
    option.Icon:SetAlpha(1)
    if option.TooltipText then
      GameTooltip:Hide()
    end
  end)
  option:SetScript("OnHide", function()
    option.Icon:SetAlpha(1)
  end)
  return option
end

function Logistician.Shopping.Tab.SetOptionIcon(option, action)
  option.Icon:SetTexCoord(0, 1, 0, 1)
  option.Icon:SetVertexColor(1, 1, 1, 1)
  if action == "delete" then
    option.Icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
  elseif action == "edit" then
    option.Icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
  elseif action == "copy" then
    option.Icon:SetTexture("Interface\\Buttons\\UI-GuildButton-MOTD-Up")
  elseif action == "search" then
    option.Icon:SetTexture(nil)
    option.Icon:SetAtlas("common-search-magnifyingglass")
  end
end

function Logistician.Shopping.Tab.SetupContainerRow(button, buttonHeight, buttonSpacing)
  local fontString = button:CreateFontString(nil, nil, "GameFontHighlightSmall")
  fontString:SetJustifyH("LEFT")
  fontString:SetPoint("RIGHT", button, "RIGHT", -buttonSpacing, 0)
  fontString:SetWordWrap(false)
  button.Text = fontString
  button.Bg = button:CreateTexture()
  button.Bg:SetAtlas("auctionhouse-rowstripe-1")
  button.Bg:SetBlendMode("ADD")
  button.Bg:SetAllPoints()
  button.Highlight = button:CreateTexture()
  button.Highlight:SetAtlas("auctionhouse-ui-row-highlight")
  button.Highlight:SetBlendMode("ADD")
  button.Highlight:SetAllPoints()
  button.Highlight:Hide()
  button.Selected = button:CreateTexture()
  button.Selected:SetAtlas("auctionhouse-ui-row-select")
  button.Selected:SetBlendMode("ADD")
  button.Selected:SetAllPoints()
  button.Selected:Hide()
end
