LogisticianTBCImportTemplatedListElementMixin = {};

function LogisticianTBCImportTemplatedListElementMixin:InitElement(...)
	-- Override in your mixin.
end

function LogisticianTBCImportTemplatedListElementMixin:UpdateDisplay()
	-- Override in your mixin.
	assert("Your templated list element must define a display method");
end

function LogisticianTBCImportTemplatedListElementMixin:OnSelected()
	-- Override in your mixin.
end

function LogisticianTBCImportTemplatedListElementMixin:OnEnter()
	-- Override in your mixin.
end

function LogisticianTBCImportTemplatedListElementMixin:OnLeave()
	-- Override in your mixin.
end

function LogisticianTBCImportTemplatedListElementMixin:Populate(listIndex)
	self.listIndex = listIndex;
	self:UpdateDisplay();
end

function LogisticianTBCImportTemplatedListElementMixin:OnClick()
	self:GetList():SetSelectedListIndex(self.listIndex);
	self:OnSelected();
end

function LogisticianTBCImportTemplatedListElementMixin:IsSelected()
	return self:GetListIndex() == self:GetList():GetSelectedListIndex();
end

function LogisticianTBCImportTemplatedListElementMixin:GetListIndex()
	return self.listIndex;
end

function LogisticianTBCImportTemplatedListElementMixin:GetList()
	return self:GetParent();
end


LogisticianTBCImportTemplatedListMixin = {};

function LogisticianTBCImportTemplatedListMixin:SetElementTemplate(elementTemplate, ...)
	if self.elementTemplate ~= nil then
		assert("You cannot change the element template once it is set, as the necessary frames may have already been created from the old template.");
		return;
	end

	self.elementTemplate = elementTemplate;
	self.elementTemplateInitArgs = SafePack(...);
end

function LogisticianTBCImportTemplatedListMixin:SetGetNumResultsFunction(getNumResultsFunction)
	self.getNumResultsFunction = getNumResultsFunction;
	self:ResetList();
end

function LogisticianTBCImportTemplatedListMixin:SetSelectionCallback(selectionCallback)
	self.selectionCallback = selectionCallback;
end

function LogisticianTBCImportTemplatedListMixin:SetRefreshCallback(refreshCallback)
	self.refreshCallback = refreshCallback;
end

function LogisticianTBCImportTemplatedListMixin:GetSelectedHighlight()
	return self.ArtOverlay.SelectedHighlight;
end

function LogisticianTBCImportTemplatedListMixin:OnShow()
	self:CheckListInitialization();
	self:RefreshListDisplay();
end

function LogisticianTBCImportTemplatedListMixin:IsInitialized()
	return self.isInitialized;
end

function LogisticianTBCImportTemplatedListMixin:CheckListInitialization()
	if self.isInitialized or (self:GetElementTemplate() == nil) or not self:CanInitialize() then
		return;
	end

	self:InitializeList();
	self:InitializeElements();
	
	self.isInitialized = true;
end

function LogisticianTBCImportTemplatedListMixin:GetElementTemplate()
	return self.elementTemplate;
end

function LogisticianTBCImportTemplatedListMixin:GetElementInitializationArgs()
	return SafeUnpack(self.elementTemplateInitArgs);
end

function LogisticianTBCImportTemplatedListMixin:InitializeElements()
	-- We use a local sub-function to capture the variadic parameters and avoid unpacking multiple times.
	local function InitializeAllElementFrames(...)
		for i = 1, self:GetNumElementFrames() do
			self:GetElementFrame(i):InitElement(...);
		end
	end

	InitializeAllElementFrames(self:GetElementInitializationArgs());
end

function LogisticianTBCImportTemplatedListMixin:UpdatedSelectedHighlight()
	local selectedHighlight = self:GetSelectedHighlight();
	selectedHighlight:ClearAllPoints();
	selectedHighlight:Hide();

	local selectedListIndex = self:GetSelectedListIndex();
	if self.isInitialized and selectedListIndex ~= nil then
		local elementOffset = selectedListIndex - self:GetListOffset();
		if elementOffset >= 1 and elementOffset <= self:GetNumElementFrames() then
			local elementFrame = self:GetElementFrame(elementOffset);
			self:AttachHighlightToElementFrame(selectedHighlight, elementFrame);
		end
	end
end

function LogisticianTBCImportTemplatedListMixin:AttachHighlightToElementFrame(selectedHighlight, elementFrame)
	local elementFrame = self:GetElementFrame(elementOffset);
	selectedHighlight:SetPoint("CENTER", elementFrame, "CENTER", 0, 0);
	selectedHighlight:Show();
end

function LogisticianTBCImportTemplatedListMixin:SetSelectedListIndex(listIndex, skipUpdates)
	local sameIndex = selectedListIndex == listIndex;
	self.selectedListIndex = listIndex;

	if not skipUpdates then
		if self.selectionCallback then
			self.selectionCallback(listIndex);
		end
	end

	if sameIndex or skipUpdates then
		return;
	end

	self:RefreshListDisplay();
end

function LogisticianTBCImportTemplatedListMixin:GetSelectedListIndex()
	return self.selectedListIndex;
end

function LogisticianTBCImportTemplatedListMixin:ResetList()
	if self.isInitialized then
		self:ResetDisplay();
	end
end

function LogisticianTBCImportTemplatedListMixin:CanDisplay()
	if self.elementTemplate == nil then
		return false, "Templated list elementTemplate not set. Use LogisticianTBCImportTemplatedListMixin:SetElementTemplate.";
	end

	if self.getNumResultsFunction == nil then
		return false, "Templated list getNumResultsFunction not set. Use LogisticianTBCImportTemplatedListMixin:SetGetNumResultsFunction.";
	end

	if not self.isInitialized then
		return false, "Templated list has not been initialized. This should generally happen in OnShow.";
	end

	return true, nil;
end

function LogisticianTBCImportTemplatedListMixin:RefreshListDisplay()
	if not self:IsVisible() then
		return;
	end

	local canDisplay, displayError = self:CanDisplay();
	if not canDisplay then
		error(displayError);
		return;
	end

	local numResults = self.getNumResultsFunction();
	local lastDisplayedOffset = self:DisplayList(numResults);
	
	self:UpdatedSelectedHighlight();

	if self.refreshCallback ~= nil then
		self.refreshCallback(lastDisplayedOffset);
	end
end

function LogisticianTBCImportTemplatedListMixin:DisplayList(numResults)
	local listOffset = self:GetListOffset();
	local numElementFrames = self:GetNumElementFrames();
	local lastDisplayedOffset = 0;

	for i = 1, numElementFrames do
		local listIndex = listOffset + i;
		local elementFrame = self:GetElementFrame(i);

		if listIndex <= numResults then
			elementFrame:Populate(listIndex);
			elementFrame:Show();
			lastDisplayedOffset = i;
		else
			elementFrame:Hide();
		end
	end
	
	return lastDisplayedOffset;
end

function LogisticianTBCImportTemplatedListMixin:EnumerateElementFrames()
	local numElementFrames = self:GetNumElementFrames();
	local elementFrameIndex = 0;
	local function ElementFrameIterator()
		elementFrameIndex = elementFrameIndex + 1;

		if elementFrameIndex > numElementFrames then
			return nil;
		end

		return self:GetElementFrame(elementFrameIndex);
	end

	return ElementFrameIterator;
end

function LogisticianTBCImportTemplatedListMixin:CanInitialize()
	return true; -- May be implemented by derived mixins.
end

function LogisticianTBCImportTemplatedListMixin:InitializeList()
	-- Implemented by derived mixins.
	error("This must be implemented for a templated list to function.");
end

function LogisticianTBCImportTemplatedListMixin:GetNumElementFrames()
	-- Implemented by derived mixins.
	error("This must be implemented for a templated list to function.");
end

function LogisticianTBCImportTemplatedListMixin:GetElementFrame(frameIndex)
	-- Implemented by derived mixins.
	error("This must be implemented for a templated list to function.");
end

function LogisticianTBCImportTemplatedListMixin:GetListOffset()
	-- Implemented by derived mixins.
	error("This must be implemented for a templated list to function.");
end

function LogisticianTBCImportTemplatedListMixin:ResetDisplay()
	-- Implemented by derived mixins.
end
