--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Total RP 3, by Telkostrasz (Kirin Tor - Eu/Fr)
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

TRP3_UI_UTILS = {
	Tooltip = {},
}

local globals = TRP3_GLOBALS;
local loc = TRP3_L;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Background
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local tiledBackgrounds = {
	"Interface\\DialogFrame\\UI-DialogBox-Background",
	"Interface\\BankFrame\\Bank-Background",
	"Interface\\FrameGeneral\\UI-Background-Marble",
	"Interface\\FrameGeneral\\UI-Background-Rock",
	"Interface\\GuildBankFrame\\GuildVaultBG",
	"Interface\\HELPFRAME\\DarkSandstone-Tile",
	"Interface\\HELPFRAME\\Tileable-Parchment",
	"Interface\\QuestionFrame\\question-background",
	"Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg",
	"Interface\\Destiny\\EndscreenBG",
	"Interface\\Stationery\\AuctionStationery1",
	"Interface\\Stationery\\Stationery_ill1",
	"Interface\\Stationery\\Stationery_OG1",
	"Interface\\Stationery\\Stationery_TB1",
	"Interface\\Stationery\\Stationery_UC1",
	"Interface\\Stationery\\StationeryTest1",
	"Interface\\WorldMap\\UI-WorldMap-Middle1",
	"Interface\\WorldMap\\UI-WorldMap-Middle2",
	"Interface\\ACHIEVEMENTFRAME\\UI-Achievement-StatsBackground",	
};

function TRP3_getTiledBackground(index)
	return tiledBackgrounds[index] or tiledBackgrounds[1];
end

function TRP3_getTiledBkgListForListbox()
	local tab = {};
	for index, _ in pairs(tiledBackgrounds) do
		tinsert(tab, {loc("UI_BKG"):format(tostring(index)), index});
	end
	return tab;
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Misc
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_ShowIfMouseOver(frame, frameOver)
	assert(frame and frameOver, "Frames can't be nil");
	if MouseIsOver(frameOver) then
		frame:Show();
	else
		frame:Hide();
	end
end

function TRP3_CreateRefreshOnFrame(frame, time, callback)
	assert(frame and time and callback, "Argument must be not nil");
	frame.refreshTimer = 1000;
	frame:SetScript("OnUpdate", function(arg, elapsed)
		frame.refreshTimer = frame.refreshTimer + elapsed;
		if (frame.refreshTimer > time) then
			frame.refreshTimer = 0;
			callback(frame);
		end
	end);
	
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Drop down
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local DROPDOWN_FRAME = "TRP3_UIDD";

local function openDropDown(anchoredFrame, values, callback, space, addCancel)
	local frame = _G[DROPDOWN_FRAME];
	if not frame then
		frame = CreateFrame("Frame", DROPDOWN_FRAME, UIParent,"UIDropDownMenuTemplate");
	end
	UIDropDownMenu_Initialize(frame,
		function(uiFrame,level,menuList)
			for index, tab in pairs(values) do
				local text = tab[1];
				local value = tab[2];
				local info = UIDropDownMenu_CreateInfo();
				info.notCheckable = "true";
				info.text = text;
				if value then
					info.func = function()
						if callback then
							callback(value, anchoredFrame);
						end
						anchoredFrame:GetParent().selectedValue = value;
					end;
					info.isTitle = false;
				else
					info.func = function() end;
					info.isTitle = true;
				end
				UIDropDownMenu_AddButton(info);
			end
			if addCancel then
				local info = UIDropDownMenu_CreateInfo();
				info.notCheckable = "true";
				info.text = CANCEL;
				UIDropDownMenu_AddButton(info,level);
			end
		end, 
		"MENU"
	);
	frame:SetParent(anchoredFrame);
	ToggleDropDownMenu(1, nil, frame, anchoredFrame:GetName(), -((space or -10)), 0);
	PlaySound("igMainMenuOptionCheckBoxOn");
end

--- Display a dropdown menu on the anchoredFrame
function TRP3_DisplayDropDown(anchoredFrame, values, callback, space, addCancel)
	openDropDown(anchoredFrame, values, callback, space, addCancel);
end

--- Setup a drop down menu for a clickable (Button ...)
function TRP3_SetupDropDownMenu(hasClickFrame, values, callback, space, addCancel, rightClick)
	hasClickFrame:SetScript("OnClick", function(self, button)
		if (rightClick and button ~= "RightButton") or (not rightClick and button ~= "LeftButton") then return; end
		TRP3_DisplayDropDown(hasClickFrame, values, callback, space, addCancel);
	end);
end

function TRP3_InitDropDown(dropDown)
	assert(dropDown, "Dropdown is nil");
	assert(_G[dropDown:GetName().."Button"], "Dropdown does not have a button child");
	_G[dropDown:GetName().."Button"]:SetScript("OnEnter", function(self) TRP3_RefreshTooltipForFrame(self) end);
	
	_G[dropDown:GetName().."Button"]:SetScript("OnLeave", function() TRP3_MainTooltip:Hide() end);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- ListBox tools
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function listBoxSetSelected(self, index)
	assert(self and self.values, "Badly initialized listbox");
	assert(self.values[index], "Array index out of bound");
	_G[self:GetName().."Text"]:SetText(self.values[index][1]);
	self.selectedValue = self.values[index][2];
	if self.callback then
		self.callback(self.values[index][2], self);
	end
end

local function listBoxSetSelectedValue(self, value)
	assert(self and self.values, "Badly initialized listbox");
	for index, tab in pairs(self.values) do
		local val = tab[2];
		if val == value then
			listBoxSetSelected(self, index);
			break;
		end
	end
end

local function listBoxGetValue(self)
	return self.selectedValue;
end

-- Setup a ListBox. When the player choose a value, it triggers the function passing the value of the selected element
function TRP3_ListBox_Setup(listBox, values, callback, defaultText, boxWidth, addCancel)
	assert(listBox and values, "Invalid arguments");
	assert(_G[listBox:GetName().."Button"], "Invalid arguments: listbox doesn't have a button");
	boxWidth = boxWidth or 115;
	listBox.values = values;
	listBox.callback = callback;
	local listCallback = function(value)
		for index, tab in pairs(values) do
			local text = tab[1];
			local val = tab[2];
			if val == value then
				_G[listBox:GetName().."Text"]:SetText(text);
			end
		end
		if callback then
			callback(value, listBox);
		end
	end;
	
	TRP3_SetupDropDownMenu(_G[listBox:GetName().."Button"], values, listCallback, boxWidth, addCancel, false);
	
	listBox.SetSelectedIndex = listBoxSetSelected;
	listBox.GetSelectedValue = listBoxGetValue;
	listBox.SetSelectedValue = listBoxSetSelectedValue;
	
	if defaultText then
		_G[listBox:GetName().."Text"]:SetText(defaultText);
	end
	_G[listBox:GetName().."Middle"]:SetWidth(boxWidth);
	_G[listBox:GetName().."Text"]:SetWidth(boxWidth-20);
end

function TRP3_LabelledListBox_Setup(label, listBox, values, callback, defaultText, boxWidth, addCancel, labelWidth)
	TRP3_ListBox_Setup(listBox, values, callback, defaultText, boxWidth, addCancel);
	_G[listBox:GetParent():GetName().."Label"]:SetText(label or "");
	_G[listBox:GetParent():GetName().."Label"]:SetWidth(labelWidth or 100);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- List tools
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

-- Handle the mouse wheel for the frame in order to slide the slider
function TRP3_HandleMouseWheel(frame,slider)
	frame:SetScript("OnMouseWheel",function(self,delta) 
		local mini,maxi = slider:GetMinMaxValues();
		if delta == 1 and slider:GetValue() > mini then
			slider:SetValue(slider:GetValue()-1);
		elseif delta == -1 and slider:GetValue() < maxi then
			slider:SetValue(slider:GetValue()+1);
		end
	end);
	frame:EnableMouseWheel(1);
end

local function listShowPage(infoTab, pageNum)
	assert(infoTab.uiTab, "Error : no uiTab in infoTab.");

	-- Hide all widgets
	for k=1,infoTab.maxPerPage do
		infoTab.widgetTab[k]:Hide();
	end
	
	-- Show list
	for widgetIndex=1, infoTab.maxPerPage do
		local dataIndex = pageNum*infoTab.maxPerPage + widgetIndex;
		if dataIndex <= #infoTab.uiTab then
			infoTab.widgetTab[widgetIndex]:Show();
			infoTab.decorate(infoTab.widgetTab[widgetIndex], infoTab.uiTab[dataIndex]);
		else
			break;
		end
	end
end

-- Init a list.
-- Arguments :
-- 		infoTab, a structure containing :
-- 			- A widgetTab (the list of all widget used in a full page)
-- 			- A decorate function, which will receive 3 arguments : a widget and an ID. Decorate will be called on every couple "widget from widgetTab" and "id from dataTab".
--		dataTab, all the possible values
--		slider, the slider :3
function TRP3_InitList(infoTab, dataTab, slider)
	assert(infoTab and dataTab and slider, "Error : no argument can be nil.");
	assert(infoTab.widgetTab, "Error : no widget tab in infoTab.");
	assert(infoTab.decorate, "Error : no decorate function in infoTab.");
	
	local count = 0;
	local maxPerPage = #infoTab.widgetTab;
	infoTab.maxPerPage = maxPerPage;
	
	if not infoTab.uiTab then
		infoTab.uiTab = {};
	end

	slider:Hide();
	wipe(infoTab.uiTab);
	
	for key,_ in pairs(dataTab) do
		tinsert(infoTab.uiTab, key);
	end
	count = #infoTab.uiTab;
	
	table.sort(infoTab.uiTab);
	
	slider:SetScript("OnValueChanged", nil);
	if count > maxPerPage then
		slider:Show();
		local total = floor((count-1)/maxPerPage);
		slider:SetMinMaxValues(0, total);
	else
		slider:SetValue(0);
	end
	slider:SetScript("OnValueChanged",function(self)
		if self:IsVisible() then
			listShowPage(infoTab, math.floor(self:GetValue()));
		end
	end);
	listShowPage(infoTab, slider:GetValue());
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Tooltip tools
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function getTooltipSize()
	return 10; --TODO: Use config
end

local function tooltipSimpleOnEnter(self)
	TRP3_RefreshTooltipForFrame(self);
end

local function tooltipSimpleOnLeave(self)
	TRP3_MainTooltip:Hide();
end

function TRP3_SetTooltipOnMain(frame, title, text)
	TRP3_SetTooltipForFrame(frame, TRP3_MainFrame, "RIGHT", 0, -500, title, text);
end

-- Setup the frame tooltip (position and text)
-- The tooltip can be shown by using TRP3_RefreshTooltipForFrame(Frame)
function TRP3_SetTooltipForFrame(Frame, GenFrame, GenFrameAnch, GenFrameX, GenFrameY, titleText, bodyText, rightText)
	assert(Frame and GenFrame, "Frame and GenFrame cannot be nil.");
	if Frame and GenFrame then
		Frame.GenFrame = GenFrame;
		Frame.GenFrameX = GenFrameX;
		Frame.GenFrameY = GenFrameY;
		Frame.titleText = titleText;
		Frame.bodyText = bodyText;
		Frame.rightText = rightText;
		if GenFrameAnch then
			Frame.GenFrameAnch = "ANCHOR_"..GenFrameAnch;
		else
			Frame.GenFrameAnch = "ANCHOR_TOPRIGHT";
		end
	end
end
TRP3_UI_UTILS.setTooltipForFrame = TRP3_SetTooltipForFrame;

-- Setup the frame tooltip (position and text)
-- The tooltip can be shown by using TRP3_RefreshTooltipForFrame(Frame)
function TRP3_SetTooltipForSameFrame(Frame, GenFrameAnch, GenFrameX, GenFrameY, titleText, bodyText, rightText)
	TRP3_SetTooltipForFrame(Frame, Frame, GenFrameAnch, GenFrameX, GenFrameY, titleText, bodyText, rightText);
end
TRP3_UI_UTILS.setTooltipForSameFrame = TRP3_SetTooltipForSameFrame;

-- Setup the frame tooltip and add the Enter and Leave scripts
function TRP3_SetTooltipAll(Frame, GenFrameAnch, GenFrameX, GenFrameY, titleText, bodyText, rightText)
	Frame:SetScript("OnEnter", tooltipSimpleOnEnter);
	Frame:SetScript("OnLeave", tooltipSimpleOnLeave);
	TRP3_SetTooltipForFrame(Frame, Frame, GenFrameAnch, GenFrameX, GenFrameY, titleText, bodyText, rightText);
end

-- Show the tooltip for this Frame (the frame must have been set up with TRP3_SetTooltipForFrame).
-- If already shown, the tooltip text will be refreshed.
function TRP3_RefreshTooltipForFrame(Frame)
	if Frame.titleText and Frame.GenFrame and Frame.GenFrameX and Frame.GenFrameY and Frame.GenFrameAnch then
		TRP3_MainTooltip:Hide();
		TRP3_MainTooltip:SetOwner(Frame.GenFrame, Frame.GenFrameAnch,Frame.GenFrameX,Frame.GenFrameY);
		if not Frame.rightText then
			TRP3_MainTooltip:AddLine(Frame.titleText, 1, 1, 1,true);
		else
			TRP3_MainTooltip:AddDoubleLine(Frame.titleText, Frame.rightText);
			TRP3_MainTooltipTextRight1:SetFont("Fonts\\FRIZQT__.TTF", getTooltipSize()+4);
			TRP3_MainTooltipTextRight1:SetNonSpaceWrap(true);
			TRP3_MainTooltipTextRight1:SetTextColor(1,1,1);
		end
		TRP3_MainTooltipTextLeft1:SetFont("Fonts\\FRIZQT__.TTF", getTooltipSize()+4);
		TRP3_MainTooltipTextLeft1:SetNonSpaceWrap(true);
		TRP3_MainTooltipTextLeft1:SetTextColor(1,1,1);
		if Frame.bodyText then
			TRP3_MainTooltip:AddLine(Frame.bodyText,1,0.6666,0,true);
			TRP3_MainTooltipTextLeft2:SetFont("Fonts\\FRIZQT__.TTF", getTooltipSize());
			TRP3_MainTooltipTextLeft2:SetNonSpaceWrap(true);
			TRP3_MainTooltipTextLeft2:SetTextColor(1,0.75,0);
		end
		TRP3_MainTooltip:Show();
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Tooltip tools
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local unitTexture = {
	Human = {
		"Achievement_Character_Human_Male",
		"Achievement_Character_Human_Female",
	},
	Gnome = {
		"Achievement_Character_Gnome_Male",
		"Achievement_Character_Gnome_Female",
	},
	Scourge = {
		"Achievement_Character_Undead_Male",
		"Achievement_Character_Undead_Female",
	},
	NightElf = {
		"Achievement_Character_Nightelf_Male",
		"Achievement_Character_Nightelf_Female",
	},
	Dwarf = {
		"Achievement_Character_Dwarf_Male",
		"Achievement_Character_Dwarf_Female",
	},
	Draenei = {
		"Achievement_Character_Draenei_Male",
		"Achievement_Character_Draenei_Female",
	},
	Orc = {
		"Achievement_Character_Orc_Male",
		"Achievement_Character_Orc_Female",
	},
	BloodElf = {
		"Achievement_Character_Bloodelf_Male",
		"Achievement_Character_Bloodelf_Female",
	},
	Troll = {
		"Achievement_Character_Troll_Male",
		"Achievement_Character_Troll_Female",
	},
	Tauren = {
		"Achievement_Character_Tauren_Male",
		"Achievement_Character_Tauren_Female",
	},
	Worgen = {
		"Ability_Racial_TwoForms",
		"Ability_Racial_Viciousness",
	},
	Goblin = {
		"Ability_Racial_RocketJump",
		"Ability_Racial_RocketJump",
	},
	Pandaren = {
      "Achievement_Guild_ClassyPanda",
      "Achievement_Character_Pandaren_Female",
    },
};

local classTexture = {
	ROGUE = "Ability_Rogue_DualWeild",
	WARLOCK = "Ability_Warlock_Eradication",
	PALADIN = "Spell_Paladin_Clarityofpurpose",
	MONK = "Monk_Ability_Transcendence",
	MAGE = "spell_Mage_NetherTempest",
	HUNTER = "Ability_Hunter_MasterMarksman",
	WARRIOR = "Ability_Warrior_OffensiveStance",
	DEATHKNIGHT = "Spell_Deathknight_FrostPresence",
	DRUID = "Spell_druid_tirelesspursuit",
	SHAMAN = "Ability_Shaman_WindwalkTotem",
	PRIEST = "Priest_icon_Chakra",
}

function TRP3_GetUnitTexture(race, gender)
	if unitTexture[race] and unitTexture[race][gender - 1] then
		return unitTexture[race][gender - 1];
	end
	return globals.icons.default;
end

function TRP3_GetClassTexture(class)
	return classTexture[class] or globals.icons.default;
end
