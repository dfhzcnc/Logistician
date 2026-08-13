-- Tex coords for Interface\MoneyFrame\UI-MoneyIcons
local TextureType = {
	File = 1,
	Atlas = 2,
};

LogisticianTBCImportMoneyDenominationDisplayType = {
	Copper = { TextureType.File, [[Interface\MoneyFrame\UI-MoneyIcons]], 0.5, 0.75, 0, 1, },
	Silver = { TextureType.File, [[Interface\MoneyFrame\UI-MoneyIcons]], 0.25, 0.5, 0, 1, },
	Gold = { TextureType.File, [[Interface\MoneyFrame\UI-MoneyIcons]], 0, 0.25, 0, 1, },
	AuctionHouseCopper = { TextureType.Atlas, "auctionhouse-icon-coin-copper" },
	AuctionHouseSilver = { TextureType.Atlas, "auctionhouse-icon-coin-silver" },
	AuctionHouseGold = { TextureType.Atlas, "auctionhouse-icon-coin-gold" },
};

LOGISTICIAN_IMPORT_DENOMINATION_SYMBOLS_BY_DISPLAY_TYPE = {
	[LogisticianTBCImportMoneyDenominationDisplayType.Copper] = COPPER_AMOUNT_SYMBOL,
	[LogisticianTBCImportMoneyDenominationDisplayType.Silver] = SILVER_AMOUNT_SYMBOL,
	[LogisticianTBCImportMoneyDenominationDisplayType.Gold] = GOLD_AMOUNT_SYMBOL,
	[LogisticianTBCImportMoneyDenominationDisplayType.AuctionHouseCopper] = COPPER_AMOUNT_SYMBOL,
	[LogisticianTBCImportMoneyDenominationDisplayType.AuctionHouseSilver] = SILVER_AMOUNT_SYMBOL,
	[LogisticianTBCImportMoneyDenominationDisplayType.AuctionHouseGold] = GOLD_AMOUNT_SYMBOL,
};

LogisticianTBCImportMoneyDenominationDisplayMixin = {};

function LogisticianTBCImportMoneyDenominationDisplayMixin:OnLoad()
	self.amount = 0;
	
	if self.displayType == nil then
		error("A money denomination display needs a type. Add a KeyValue entry, displayType = LogisticianTBCImportMoneyDenominationDisplayType.[Copper|Silver|Gold|AuctionHouseCopper|AuctionHouseSilver|AuctionHouseGold].");
		return;
	end

	self:UpdateDisplayType();
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetDisplayType(displayType)
	self.displayType = displayType;
	self:UpdateDisplayType();
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:UpdateDisplayType()
	local textureType, fileOrAtlas, l, r, b, t = unpack(self.displayType);

	if textureType == TextureType.Atlas then
		self.Icon:SetAtlas(fileOrAtlas);
		self.Icon:SetSize(12,14);
	else
		self.Icon:SetTexture(fileOrAtlas);
		self.Icon:SetSize(13,13);
	end

	self.Icon:SetTexCoord(l or 0, r or 1, b or 0, t or 1);
	self:UpdateWidth();
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetFontObject(fontObject)
	self.Text:SetFontObject(fontObject);
	self:UpdateWidth();
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:GetFontObject()
	return self.Text:GetFontObject();
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetFontAndIconDisabled(disabled)
	self:SetFontObject(disabled and NumberFontNormalGray or NumberFontNormal);
	self.Icon:SetAlpha(disabled and 0.5 or 1);
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetFormatter(formatter)
	self.formatter = formatter;
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetForcedHidden(forcedHidden)
	self.forcedHidden = forcedHidden;
	self:SetShown(self:ShouldBeShown());
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:IsForcedHidden()
	return self.forcedHidden;
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetShowsZeroAmount(showsZeroAmount)
	self.showsZeroAmount = showsZeroAmount;
	self:SetShown(self:ShouldBeShown());
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:ShowsZeroAmount()
	return self.showsZeroAmount;
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:ShouldBeShown()
	return not self:IsForcedHidden() and self.amount ~= nil and (self.amount > 0 or self:ShowsZeroAmount());
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:SetAmount(amount)
	self.amount = amount;

	local shouldBeShown = self:ShouldBeShown();
	self:SetShown(shouldBeShown);
	if not shouldBeShown then
		return;
	end

	local amountText = amount;
	if self.formatter then
		amountText = self.formatter(amount);
	end

	local colorblindMode = ENABLE_COLORBLIND_MODE == "1";
	if colorblindMode then
		amountText = amountText..LOGISTICIAN_IMPORT_DENOMINATION_SYMBOLS_BY_DISPLAY_TYPE[self.displayType];
	end

	self.Text:SetText(amountText);
	self.Icon:SetShown(not colorblindMode);

	self:UpdateWidth();
end

function LogisticianTBCImportMoneyDenominationDisplayMixin:UpdateWidth()
	local iconWidth = self.Icon:IsShown() and self.Icon:GetWidth() or 0;
	local iconSpacing = 2;
	self.Text:SetPoint("RIGHT", -(iconWidth + iconSpacing), 0);
	self:SetWidth(self.Text:GetStringWidth() + iconWidth + iconSpacing);
end


LogisticianTBCImportMoneyDisplayFrameMixin = {};

local DENOMINATION_DISPLAY_WIDTH = 36; -- Space for two characters and an anchor offset.

function LogisticianTBCImportMoneyDisplayFrameMixin:OnLoad()
	self.CopperDisplay:SetShowsZeroAmount(true);
	self.SilverDisplay:SetShowsZeroAmount(true);
	self.GoldDisplay:SetFormatter(BreakUpLargeNumbers);

	if self.hideCopper then
		self.CopperDisplay:SetForcedHidden(true);
	end

	if self.useAuctionHouseIcons then
		self.CopperDisplay:SetDisplayType(LogisticianTBCImportMoneyDenominationDisplayType.AuctionHouseCopper);
		self.SilverDisplay:SetDisplayType(LogisticianTBCImportMoneyDenominationDisplayType.AuctionHouseSilver);
		self.GoldDisplay:SetDisplayType(LogisticianTBCImportMoneyDenominationDisplayType.AuctionHouseGold);
	end

	self:UpdateAnchoring();
end

function LogisticianTBCImportMoneyDisplayFrameMixin:SetFontAndIconDisabled(disabled)
	self.CopperDisplay:SetFontAndIconDisabled(disabled);
	self.SilverDisplay:SetFontAndIconDisabled(disabled);
	self.GoldDisplay:SetFontAndIconDisabled(disabled);

	if self.resizeToFit then
		self:UpdateWidth();
	end
end

function LogisticianTBCImportMoneyDisplayFrameMixin:SetFontObject(fontObject)
	self.CopperDisplay:SetFontObject(fontObject);
	self.SilverDisplay:SetFontObject(fontObject);
	self.GoldDisplay:SetFontObject(fontObject);

	if self.resizeToFit then
		self:UpdateWidth();
	end
end

function LogisticianTBCImportMoneyDisplayFrameMixin:GetFontObject()
	return self.CopperDisplay:GetFontObject();
end

function LogisticianTBCImportMoneyDisplayFrameMixin:UpdateAnchoring()
	self.CopperDisplay:ClearAllPoints();
	self.SilverDisplay:ClearAllPoints();
	self.GoldDisplay:ClearAllPoints();

	if self.leftAlign then
		self.GoldDisplay:SetPoint("LEFT");

		if self.GoldDisplay:ShouldBeShown() then
			self.SilverDisplay:SetPoint("RIGHT", self.GoldDisplay, "RIGHT", DENOMINATION_DISPLAY_WIDTH, 0);
		else
			self.SilverDisplay:SetPoint("LEFT", self.GoldDisplay, "LEFT");
		end
		
		if self.SilverDisplay:ShouldBeShown() then
			self.CopperDisplay:SetPoint("RIGHT", self.SilverDisplay, "RIGHT", DENOMINATION_DISPLAY_WIDTH, 0);
		else
			self.CopperDisplay:SetPoint("LEFT", self.SilverDisplay, "LEFT");
		end
	else
		self.CopperDisplay:SetPoint("RIGHT");

		if self.CopperDisplay:ShouldBeShown() then
			self.SilverDisplay:SetPoint("RIGHT", -DENOMINATION_DISPLAY_WIDTH, 0);
		else
			self.SilverDisplay:SetPoint("RIGHT", self.CopperDisplay, "RIGHT");
		end
		
		if self.SilverDisplay:ShouldBeShown() then
			self.GoldDisplay:SetPoint("RIGHT", self.SilverDisplay, "RIGHT", -DENOMINATION_DISPLAY_WIDTH, 0);
		else
			self.GoldDisplay:SetPoint("RIGHT", self.SilverDisplay, "RIGHT");
		end
	end
end

function LogisticianTBCImportMoneyDisplayFrameMixin:SetAmount(rawCopper)
	self.rawCopper = rawCopper;
	
	local gold = floor(rawCopper / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((rawCopper - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(rawCopper, COPPER_PER_SILVER);
	self.GoldDisplay:SetAmount(gold);
	self.SilverDisplay:SetAmount(silver);
	self.CopperDisplay:SetAmount(copper);

	if self.resizeToFit then
		self:UpdateWidth();
	else
		self:UpdateAnchoring();
	end
end

function LogisticianTBCImportMoneyDisplayFrameMixin:UpdateWidth()
	local width = 0;
	local goldDisplayed = self.GoldDisplay:IsShown()
	if goldDisplayed then
		width = width + self.GoldDisplay:GetWidth();
	end

	local silverDisplayed = self.SilverDisplay:IsShown();
	if silverDisplayed then
		if goldDisplayed then
			width = width + DENOMINATION_DISPLAY_WIDTH;
		else
			width = width + self.SilverDisplay:GetWidth();
		end
	end

	if self.CopperDisplay:IsShown() then
		if goldDisplayed or silverDisplayed then
			width = width + DENOMINATION_DISPLAY_WIDTH;
		else
			width = width + self.CopperDisplay:GetWidth();
		end
	end

	self:SetWidth(width);
end

function LogisticianTBCImportMoneyDisplayFrameMixin:GetAmount()
	return self.rawCopper;
end

function LogisticianTBCImportMoneyDisplayFrameMixin:SetResizeToFit(resizeToFit)
	self.resizeToFit = resizeToFit;
end
