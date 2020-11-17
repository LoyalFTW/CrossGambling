CrossGambling1  = LibStub("AceAddon-3.0"):NewAddon("CrossGambling1")
local CrossGambling1 = LibStub("AceAddon-3.0"):GetAddon("CrossGambling1")
local PlayerName = UnitName("player")
local PlayerClass = select(2, UnitClass("player"))
local CurrentRollValue = 0
local Rolls = {}
local Players = {}
local isCGHost = false
local ChatGrabChannel
local rollCmd = SLASH_RANDOM1:upper()
local GameInProgress = false
local AcceptingRolls = false
local maxRoll
local minRoll
local ReportChannel = ""
local chatmethods = {
	"PARTY",
	"RAID",
	"GUILD",
}
local chatmethod = chatmethods[1];

function CrossGambling1:ConstructMiniMapIcon() 
	self.minimap = { }
	self.minimap.icon_data = LibStub("LibDataBroker-1.1"):NewDataObject("CrossGamblingIcon", {
		type = "data source",
		text = "CrossGambling",
		icon = "Interface\\AddOns\\CrossGambling\\media\\icon",
		OnClick = Minimap_Toggle,

		OnTooltipShow = function(tooltip)
			tooltip:AddLine("CrossGambling!",1,1,1)
			tooltip:Show()
		end,
	})

	self.minimap.icon = LibStub("LibDBIcon-1.0")
	self.minimap.icon:Register("CrossGamblingIcon", self.minimap.icon_data, self.db.global.minimap)
end

local random = random
local gsub = gsub
local type = type
local floor = floor
local format = format
local strmatch = string.match
local tonumber = tonumber
local tostring = tostring
local reverse = string.reverse
local tinsert = tinsert
local tremove = tremove
local tsort = table.sort
local split = strsplit

local DisableButton = function(button)
	button:EnableMouse(false)
	button.Label:SetTextColor(0.3, 0.3, 0.3)
end

local EnableButton = function(button)
	button:EnableMouse(true)
	button.Label:SetTextColor(1, 1, 1)
end
local Comma = function(number)
	if (not number) then
		return
	end
	
	if (type(number) ~= "number") then
		number = tonumber(number)
	end
	
	local Number = format("%.0f", floor(number + 0.5))
   	local Left, Number, Right = strmatch(Number, "^([^%d]*%d)(%d+)(.-)$")
	
	return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
end

local GetRoll = function()
	local Roll = random(1, CurrentRollValue)

	return Roll
end

local CG = "Interface\\AddOns\\CrossGambling\\media\\CG.tga"
local Font = "Fonts\\FRIZQT__.TTF"
local FontColor = {220/255, 220/255, 220/255}

local Backdrop = {
	bgFile = CG,
	edgeFile = CG,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {left = 1, right = 1, top = 1, bottom = 1},
}

local BackdropBorder = {
	edgeFile = CG,
	edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local SetTemplate = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetBackdropColor(0.27, 0.27, 0.27)
end

local SetTemplateDark = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetBackdropColor(0.17, 0.17, 0.17)
end

local SendAddonMessage = SendAddonMessage

local SendEvent = function(event, arg1)
	local Channel
	local IsInRaid = IsInRaid
	local IsInGroup = IsInGroup
	local IsInGuild = IsInGuild
	local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
	local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
	local SendAddonMessage = SendAddonMessage
-- ADD: Conditional variables to each that allow the current chat channel to be shown in the CGHost panel.
	if IsInRaid() then
		Channel = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID" or chatmethod
		ReportChannel = chatmethod
	elseif IsInGroup() then
		Channel = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY" or chatmethod
		ReportChannel = chatmethod
	elseif IsInGuild() then
		Channel = "GUILD"
		ReportChannel = chatmethod
	end
	

	if Channel then
		local Event = event .. ":" .. tostring(arg1)

		C_ChatInfo.SendAddonMessage("CrossGambling", Event, Channel)
    --print("DEBUG | Event: ", event, " // Channel: ", Channel)
	end
end

local GUI = CreateFrame("Frame", "CrossGambling", UIParent, BackdropTemplateMixin and "BackdropTemplate")
GUI:SetSize(227, 141) 
GUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
SetTemplate(GUI)
GUI:SetMovable(true)
GUI:EnableMouse(true)
GUI:SetUserPlaced(true)
GUI:RegisterForDrag("LeftButton")
GUI:SetScript("OnDragStart", GUI.StartMoving)
GUI:SetScript("OnDragStop", GUI.StopMovingOrSizing)

GUI:Hide()

local Top = CreateFrame("Frame", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
Top:SetSize(GUI:GetSize(), 21)
Top:SetPoint("BOTTOM", GUI, "TOP", 0, -20)
SetTemplateDark(Top)

local CGHost = CreateFrame("Frame", "CrossGambleCGHost", GUI, BackdropTemplateMixin and "BackdropTemplate")
CGHost:SetSize(GUI:GetSize(), 1) 
CGHost:SetPoint("BOTTOMLEFT", GUI, "TOPLEFT")
SetTemplate(CGHost)
CGHost:Show()

local CGHost2 = CreateFrame("Frame", "CrossGambleCGHost", GUI, BackdropTemplateMixin and "BackdropTemplate")
CGHost2:SetSize(GUI:GetSize(), 1)
CGHost2:SetPoint("BOTTOMLEFT", GUI, "TOPLEFT")
SetTemplate(CGHost2)
CGHost2:Hide()

local CGHost2Top = CreateFrame("Frame", nil, CGHost2, BackdropTemplateMixin and "BackdropTemplate")
CGHost2Top:SetSize(CGHost2:GetSize(), 21)
CGHost2Top:SetPoint("BOTTOM", GUI, "TOP", 0, -20)
SetTemplateDark(CGHost2Top)

local ButtonOnEnter = function(self)
	self:SetBackdropColor(0.27, 0.27, 0.27)
	SetTemplateDark(GameTooltip)
	GameTooltip:SetOwner(CGHost2Top, "ANCHOR_BOTTOMRIGHT", -2, 21)
end

local ButtonOnLeave = function(self)
      self:SetBackdropColor(0.17, 0.17, 0.17)
	  GameTooltip:Hide() 
end

local CGCHAT = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
CGCHAT:SetSize(108, 20)
CGCHAT:SetPoint("TOPLEFT", Top, "BOTTOMLEFT", 5, -2)
SetTemplateDark(CGCHAT)
CGCHAT:SetScript("OnEnter", ButtonOnEnter)
CGCHAT:HookScript("OnEnter", function(self)
	GameTooltip:SetText(chatmethod)
	GameTooltip:AddLine("Change Chat Method", 1, 1, 1, true)
	GameTooltip:Show()
end)
CGCHAT:SetScript("OnLeave", ButtonOnLeave)
CGCHAT:SetScript("OnMouseUp", function(self)
CrossGambling_OnClickCHAT()
end)

local CrossGambling_CHAT_Button = CGCHAT:CreateFontString(nil, "OVERLAY")
CrossGambling_CHAT_Button:SetPoint("CENTER", CGCHAT, 0, 0)
CrossGambling_CHAT_Button:SetFont(Font, 12)
CrossGambling_CHAT_Button:SetJustifyH("CENTER")
CrossGambling_CHAT_Button:SetTextColor(unpack(FontColor))
CrossGambling_CHAT_Button:SetText(chatmethod)
CrossGambling_CHAT_Button:SetShadowOffset(1.25, -1.25)
CrossGambling_CHAT_Button:SetShadowColor(0, 0, 0)

local Bottom = CreateFrame("Frame", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
Bottom:SetSize(GUI:GetSize(), 21) 
Bottom:SetPoint("TOP", GUI, "BOTTOM", 0, 1)
SetTemplateDark(Bottom)

GUI.BottomLabel = Bottom:CreateFontString(nil, "OVERLAY")
GUI.BottomLabel:SetPoint("LEFT", Bottom, 25, 0)
GUI.BottomLabel:SetFont(Font, 9.9)
GUI.BottomLabel:SetTextColor(unpack(FontColor))
GUI.BottomLabel:SetJustifyH("LEFT")
GUI.BottomLabel:SetShadowOffset(1.25, -1.25)
GUI.BottomLabel:SetShadowColor(0, 0, 0)
GUI.BottomLabel:SetText("CrossGambling - Loyal@Stormrage")

local EditBoxOnEditFocusLost = function(self)
	self:SetAutoFocus(false)
end

local EditBoxOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local EditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (Value == "" or Value == " ") then
		self:SetText(CurrentRollValue)

		return
	end
end


local EditBox = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
EditBox:SetPoint("TOPLEFT", CGCHAT, 0, -23)
EditBox:SetSize(CGHost:GetSize()-9, 21)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

local CrossGambling_EditBox = CreateFrame("EditBox", nil, EditBox)
CrossGambling_EditBox:SetPoint("CENTER", EditBox, 0, 0)
CrossGambling_EditBox:SetPoint("BOTTOMRIGHT", EditBox, -4, 2)
CrossGambling_EditBox:SetFont(Font, 16)
CrossGambling_EditBox:GetText("100")
CrossGambling_EditBox:SetShadowColor(0, 0, 0)
CrossGambling_EditBox:SetShadowOffset(1.25, -1.25)
CrossGambling_EditBox:SetMaxLetters(6)
CrossGambling_EditBox:SetAutoFocus(false)
CrossGambling_EditBox:SetNumeric(true)
CrossGambling_EditBox:EnableKeyboard(true)
CrossGambling_EditBox:EnableMouse(true)
CrossGambling_EditBox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
CrossGambling_EditBox:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
CrossGambling_EditBox:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

local AcceptRolls = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
AcceptRolls:SetSize(108, 20)
AcceptRolls:SetPoint("TOPLEFT", EditBox, "BOTTOMLEFT", 0, -2)
SetTemplateDark(AcceptRolls)
AcceptRolls:SetScript("OnEnter", ButtonOnEnter)
AcceptRolls:SetScript("OnLeave", ButtonOnLeave)
AcceptRolls:SetScript("OnMouseUp", function(self)
	if GameMode_Button_Button:GetText() == "< Game Mode >" then
		SendEvent("SET_ROLL", CrossGambling_EditBox:GetText())
		CrossGambling["lastroll"] = CrossGambling_EditBox:GetText()
		SendEvent("START_GAME")
        CrossGambling["GameMode"] = false
    CrossGambling_EditBox:SetAutoFocus(false)
  	CrossGambling_EditBox:ClearFocus()


	elseif GameMode_Button_Button:GetText() == "< 501 >" or "< BigTwo >" then
    SendEvent("SET_ROLL",CrossGambling["GameMode1"])
	SendEvent("START_GAME")

  else
		print("[|cffaad2a7IG|r] Please enter a wager before starting a new game!")
	end
	
			isCGHost = true
		GameInProgress = true
		AcceptingRolls = true
end)

AcceptRolls.Label = AcceptRolls:CreateFontString(nil, "OVERLAY")
AcceptRolls.Label:SetPoint("CENTER", AcceptRolls, 0, 0)
AcceptRolls.Label:SetFont(Font, 12)
AcceptRolls.Label:SetJustifyH("CENTER")
AcceptRolls.Label:SetText("New Game")
AcceptRolls.Label:SetShadowOffset(1.25, -1.25)
AcceptRolls.Label:SetShadowColor(0, 0, 0)

local EditBox = CreateFrame("Frame", nil, CGHost2Top, BackdropTemplateMixin and "BackdropTemplate")
EditBox:SetSize(108, 20)
EditBox:SetPoint("TOPLEFT", CGHost2Top, "BOTTOMLEFT", 114, -24)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

local GuildCut = CreateFrame("EditBox", nil, EditBox)
GuildCut:SetPoint("CENTER", EditBox, 0, 0)
GuildCut:SetPoint("BOTTOMRIGHT", EditBox, -4, 2)
GuildCut:SetFont(Font, 16)
GuildCut:SetText("10")
GuildCut:SetShadowColor(0, 0, 0)
GuildCut:SetShadowOffset(1.25, -1.25)
GuildCut:SetMaxLetters(2)
GuildCut:SetAutoFocus(false)
GuildCut:SetNumeric(true)
GuildCut:EnableKeyboard(true)
GuildCut:EnableMouse(true)
GuildCut:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
GuildCut:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
GuildCut:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

local ChatFrame = CreateFrame("Frame", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
ChatFrame:SetPoint("TOPLEFT", Top, "TOPRIGHT", 0, 0)
ChatFrame:SetSize(220, 142)
SetTemplate(ChatFrame)
ChatFrame:Hide()

ChatFrame.Chat = CreateFrame("ScrollingMessageFrame", nil, ChatFrame)
ChatFrame.Chat:SetPoint("CENTER", ChatFrame, 2, -10)
ChatFrame.Chat:SetSize(ChatFrame:GetWidth() - 8, ChatFrame:GetHeight() - 30)
ChatFrame.Chat:SetFont(Font, 12)
ChatFrame.Chat:SetShadowColor(0, 0, 0)
ChatFrame.Chat:SetShadowOffset(1.25, -1.25)
ChatFrame.Chat:SetFading(false)
ChatFrame.Chat:SetJustifyH("LEFT")
ChatFrame.Chat:SetMaxLines(50)
ChatFrame.Chat:SetScript("OnMouseWheel", function(self, delta)
	if (delta == 1) then
		self:ScrollUp()
	else
		self:ScrollDown()
	end
end)

-- Editbox
local EditBoxOnMouseDown = function(self)
	self:SetText("")
	self:SetAutoFocus(true)
end

local EditBoxOnEditFocusLost = function(self)
	self:SetAutoFocus(false)
end

local EditBoxOnEscapePressed = function(self)
	self:SetText("")

	self:SetAutoFocus(false)
	self:ClearFocus()

	self:SetText("|cffB0B0B0Chat...|r")
end

local EditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (Value == "" or Value == " ") then
		self:SetText("|cffB0B0B0Chat...|r")

		return
	end

  SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, Value))

	self:SetText("|cffB0B0B0Chat...|r")
end

local EditBox = CreateFrame("Frame", nil, ChatFrame, BackdropTemplateMixin and "BackdropTemplate")
EditBox:SetPoint("TOPLEFT", ChatFrame, "BOTTOMLEFT", 0, 1)
EditBox:SetSize(220, 21)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

EditBox.Box = CreateFrame("EditBox", nil, EditBox)
EditBox.Box:SetPoint("TOPLEFT", EditBox, 5, -1)
EditBox.Box:SetPoint("BOTTOMRIGHT", EditBox, -5, 1)
EditBox.Box:SetFont(Font, 12)
EditBox.Box:SetText("|cffB0B0B0Chat...|r")
EditBox.Box:SetShadowColor(0, 0, 0)
EditBox.Box:SetShadowOffset(1.25, -1.25)
EditBox.Box:SetMaxLetters(255)
EditBox.Box:SetAutoFocus(false)
EditBox.Box:EnableKeyboard(true)
EditBox.Box:EnableMouse(true)
EditBox.Box:SetScript("OnMouseDown", EditBoxOnMouseDown)
EditBox.Box:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
EditBox.Box:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
EditBox.Box:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

-- Chat toggle
local ChatToggle = CreateFrame("Button", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
ChatToggle:SetSize(21, 21)
ChatToggle:SetPoint("BOTTOMRIGHT", Bottom, "BOTTOMRIGHT", 0, 0)
ChatToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(ChatToggle)
ChatToggle:SetScript("OnMouseUp", function(self)
	if self.NeedsReset then
		self.Arrow:SetTextColor(1, 1, 1)
		self.NeedsReset = false
	end

	if ChatFrame:IsShown() then
		ChatFrame:Hide()
		self.Arrow:SetText("►")
	else
		ChatFrame:Show()
		self.Arrow:SetText("◄")
	end
end)
ChatToggle.Arrow = ChatToggle:CreateFontString(nil, "OVERLAY")
ChatToggle.Arrow:SetPoint("CENTER", ChatToggle, "CENTER", 0, 0)
ChatToggle.Arrow:SetFont("Interface\\AddOns\\CrossGambling\\media\\Arial.ttf", 12)
ChatToggle.Arrow:SetTextColor(unpack(FontColor))
ChatToggle.Arrow:SetText("►")
ChatToggle.Arrow:SetShadowOffset(1.25, -1.25)
ChatToggle.Arrow:SetShadowColor(0, 0, 0)


local CGEnter = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
CGEnter:SetSize(108, 20)
CGEnter:SetPoint("TOPRIGHT", CrossGambling_EditBox, "BOTTOMRIGHT", 4, -4)
SetTemplateDark(CGEnter)
CGEnter:SetScript("OnEnter", ButtonOnEnter)
CGEnter:SetScript("OnLeave", ButtonOnLeave)
CGEnter:SetScript("OnMouseUp", function(self)
	 if ChatFrame:IsShown() then
-- Will work on later 
     CrossGambling_OnClickRoll2()
     else
	 CrossGambling_OnClickRoll1()
end 
end)

CGEnter.Label = CGEnter:CreateFontString(nil, "OVERLAY")
CGEnter.Label:SetPoint("CENTER", CGEnter, 0, 0)
CGEnter.Label:SetFont(Font, 12)
CGEnter.Label:SetJustifyH("CENTER")
CGEnter.Label:SetTextColor(unpack(FontColor))
CGEnter.Label:SetText("Join Game")
CGEnter.Label:SetShadowOffset(1.25, -1.25)
CGEnter.Label:SetShadowColor(0, 0, 0)

function CrossGambling_OnClickRoll2()
   if CGEnter.Label:GetText() == "Join Game" then
	local InOrOut = "1"	
    SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, InOrOut))
	SendEvent("ADD_PLAYER", PlayerName)
  --print("DEBUG | EBOnEnPressed | PName: ", PlayerName, " // PClass: ", PlayerClass, " // Value: ", Value)
	CGEnter.Label:SetText("Leave Game")
	elseif CGEnter.Label:GetText() == "Leave Game" then
	SendEvent("REMOVE_PLAYER", PlayerName)
	local InOrOut = "-1"
    SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, InOrOut))
	CGEnter.Label:SetText("Join Game")
   end
end

local RollMe = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
RollMe:SetSize(108, 20)
RollMe:SetPoint("TOPRIGHT", CGEnter, "BOTTOMRIGHT", 0, -2)
SetTemplateDark(RollMe)
RollMe:SetScript("OnEnter", ButtonOnEnter)
RollMe:SetScript("OnLeave", ButtonOnLeave)
RollMe:SetScript("OnMouseUp", function(self)
	 local Roll = GetRoll()
if(ChatFrame:IsShown()) then
SendEvent("PLAYER_ROLL", PlayerName..":"..tostring(Roll))
else 
hash_SlashCmdList[rollCmd](CurrentRollValue)
end
end)

RollMe.Label = RollMe:CreateFontString(nil, "OVERLAY")
RollMe.Label:SetPoint("CENTER", RollMe, 0, 0)
RollMe.Label:SetFont(Font, 12)
RollMe.Label:SetJustifyH("CENTER")
RollMe.Label:SetTextColor(unpack(FontColor))
RollMe.Label:SetText("Roll Me")
RollMe.Label:SetShadowOffset(1.25, -1.25)
RollMe.Label:SetShadowColor(0, 0, 0)

local GameMode_Button = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
GameMode_Button:SetSize(108, 20)
GameMode_Button:SetPoint("TOPRIGHT", Top, "BOTTOMRIGHT", -4, -2)
SetTemplateDark(GameMode_Button)
GameMode_Button:SetScript("OnEnter", ButtonOnEnter)
GameMode_Button:HookScript("OnEnter", function(self)
	GameTooltip:SetText("Game Modes")
    GameTooltip:AddLine("Change Game Mode", 1, 1, 1, true)
    GameTooltip:Show()
end)
GameMode_Button:SetScript("OnLeave", ButtonOnLeave)
GameMode_Button:SetScript("OnMouseUp", function(self)
CrossGambling_GameMode_Button()
end)


GameMode_Button_Button = GameMode_Button:CreateFontString(nil, "OVERLAY")
GameMode_Button_Button:SetPoint("CENTER", GameMode_Button, 0, 0)
GameMode_Button_Button:SetFont(Font, 12)
GameMode_Button_Button:SetJustifyH("CENTER")
GameMode_Button_Button:SetTextColor(unpack(FontColor))
GameMode_Button_Button:SetText("< Game Mode >")
GameMode_Button_Button:SetShadowOffset(1.25, -1.25)
GameMode_Button_Button:SetShadowColor(0, 0, 0)

local LastCall = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
LastCall:SetSize(108, 20)
LastCall:SetPoint("TOPLEFT", AcceptRolls, "BOTTOMLEFT", 0, -2)
SetTemplateDark(LastCall)
LastCall:SetScript("OnEnter", ButtonOnEnter)
LastCall:HookScript("OnEnter", function(self)

end)
LastCall:SetScript("OnLeave", ButtonOnLeave)
LastCall:SetScript("OnMouseUp", function(self)
	SendEvent("LastCall")
end)

LastCall.Label = LastCall:CreateFontString(nil, "OVERLAY")
LastCall.Label:SetPoint("CENTER", LastCall, 0, 0)
LastCall.Label:SetFont(Font, 12)
LastCall.Label:SetJustifyH("CENTER")
LastCall.Label:SetTextColor(unpack(FontColor))
LastCall.Label:SetText("Last Call")
LastCall.Label:SetShadowOffset(1.25, -1.25)
LastCall.Label:SetShadowColor(0, 0, 0)

local RollGame = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
RollGame:SetSize(108, 20)
RollGame:SetPoint("TOPLEFT", LastCall, "BOTTOMLEFT", 0, -2)
SetTemplateDark(RollGame)
RollGame:SetScript("OnEnter", ButtonOnEnter)
RollGame:HookScript("OnEnter", function(self)

end)
RollGame:SetScript("OnLeave", ButtonOnLeave)
RollGame:SetScript("OnMouseUp", function(self)
	SendEvent("CLOSE_GAME")
end)

RollGame.Label = RollGame:CreateFontString(nil, "OVERLAY")
RollGame.Label:SetPoint("CENTER", RollGame, 0, 0)
RollGame.Label:SetFont(Font, 12)
RollGame.Label:SetJustifyH("CENTER")
RollGame.Label:SetTextColor(unpack(FontColor))
RollGame.Label:SetText("Start Rolling")
RollGame.Label:SetShadowOffset(1.25, -1.25)
RollGame.Label:SetShadowColor(0, 0, 0)

DisableButton(RollGame)
DisableButton(LastCall)
DisableButton(RollMe)
EnableButton(CGEnter)

local CGHostToggle = CreateFrame("Button", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
CGHostToggle:SetSize(63, 21)
CGHostToggle:SetPoint("TOPRIGHT", Top, "TOPRIGHT", -30, 0)
SetTemplateDark(CGHostToggle)
CGHostToggle:SetScript("OnMouseUp", function(self)
    if CGHost:IsShown() then
		CGHost:Hide()
		CGHost2:Show()
	end
end)

CGHostToggle.Arrow = CGHostToggle:CreateFontString(nil, "OVERLAY")
CGHostToggle.Arrow:SetPoint("CENTER", CGHostToggle, "CENTER", 0, 0)
CGHostToggle.Arrow:SetTextColor(unpack(FontColor))
CGHostToggle.Arrow:SetFont(Font, 12)
CGHostToggle.Arrow:SetText("Options")
CGHostToggle.Arrow:SetShadowOffset(1.25, -1.25)
CGHostToggle.Arrow:SetShadowColor(0, 0, 0)

local CGHostToggle = CreateFrame("Button", nil, Top, BackdropTemplateMixin and "BackdropTemplate")
CGHostToggle:SetSize(63, 21)
CGHostToggle:SetPoint("TOPLEFT", Top, "TOPLEFT", 30, 0)
CGHostToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(CGHostToggle)
CGHostToggle:SetScript("OnMouseUp", function(self)
    if CGHost2:IsShown() then
		CGHost2:Hide()
		CGHost:Show()
	end
end)

CGHostToggle.Arrow = CGHostToggle:CreateFontString(nil, "OVERLAY")
CGHostToggle.Arrow:SetPoint("CENTER", CGHostToggle, "CENTER", 0, 0)
CGHostToggle.Arrow:SetTextColor(unpack(FontColor))
CGHostToggle.Arrow:SetFont(Font, 12)
CGHostToggle.Arrow:SetText("Main")
CGHostToggle.Arrow:SetShadowOffset(1.25, -1.25)
CGHostToggle.Arrow:SetShadowColor(0, 0, 0)


local Close = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
Close:SetSize(108, 20)
Close:SetPoint("TOPRIGHT", RollMe, "BOTTOMRIGHT", 0, -2)
SetTemplateDark(Close)
Close:SetScript("OnEnter", ButtonOnEnter)
Close:SetScript("OnLeave", ButtonOnLeave)
Close:SetScript("OnMouseUp", function(self)
      GUI:Hide()
end)


Close.Label = Close:CreateFontString(nil, "OVERLAY")
Close.Label:SetPoint("CENTER", Close, 0, 0)
Close.Label:SetFont(Font, 12)
Close.Label:SetJustifyH("CENTER")
Close.Label:SetTextColor(unpack(FontColor))
Close.Label:SetText("Close")
Close.Label:SetShadowOffset(1.25, -1.25)
Close.Label:SetShadowColor(0, 0, 0)

function CrossGambling_OnClickSTATS(full)
	local sortlistname = {};
	local sortlistamount = {};
	local n = 0;
	local i, j, k;

	for i, j in pairs(CrossGambling["stats"]) do
		local name = i;
		if(CrossGambling["joinstats"][strlower(i)] ~= nil) then
			name = CrossGambling["joinstats"][strlower(i)]:gsub("^%l", string.upper);
		end
		for k=0,n do
			if(k == n) then
				sortlistname[n] = name;
				sortlistamount[n] = j;
				n = n + 1;
				break;
			elseif(strlower(name) == strlower(sortlistname[k])) then
				sortlistamount[k] = (sortlistamount[k] or 0) + j;
				break;
			end
		end
	end

	if(n == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("No stats yet!");
		return;
	end

	for i = 0, n-1 do
		for j = i+1, n-1 do
			if(sortlistamount[j] > sortlistamount[i]) then
				sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i];
				sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i];
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("--- CrossGambling Stats ---", chatmethod);

	if full then
	if (CrossGambling["house"] > 0) then
			SendChatMessage(string.format("The house has taken %s total.", (CrossGambling["house"])), chatmethod);
		end
		for k = 0,  #sortlistamount do
			local sortsign = "won";
			if(sortlistamount[k] < 0) then sortsign = "lost"; end
			SendChatMessage(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), chatmethod);
		end

		return
	end



	local x1 = 3-1;
	local x2 = n-3;
	if(x1 >= n) then x1 = n-1; end
	if(x2 <= x1) then x2 = x1+1; end

	for i = 0, x1 do
		sortsign = "won";
		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		SendChatMessage(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), chatmethod);
	end

	if(x1+1 < x2) then
		SendChatMessage("...", chatmethod);
	end

	for i = x2, n-1 do
		sortsign = "won";

		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		SendChatMessage(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), chatmethod);
		
	end
	if (CrossGambling["house"] > 0) then
			SendChatMessage(string.format("The house has taken %s total.", (CrossGambling["house"])), chatmethod);
		end
end


local ResetStats = function()
  if (CrossGambling["stats"] ~= nil) then
    CrossGambling["stats"] = {}
    print("[|cffaad2a7IG|r] Stats have been reset!")
  end
end

local ViewStats = CreateFrame("Button", nil, CGHost2Top, BackdropTemplateMixin and "BackdropTemplate")
ViewStats:SetSize(108, 20)
ViewStats:SetPoint("TOPRIGHT", CGHost2Top, "BOTTOMRIGHT", -5, -2)
ViewStats:SetFrameStrata("MEDIUM")
SetTemplateDark(ViewStats)
ViewStats:SetScript("OnEnter", ButtonOnEnter)
ViewStats:HookScript("OnEnter", function(self)
    GameTooltip:AddLine("Top 3 Winners/Losers", 1, 1, 1, true)
    GameTooltip:Show()

end)
ViewStats:SetScript("OnLeave", ButtonOnLeave)
ViewStats:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickSTATS()
end)

ViewStats.X = ViewStats:CreateFontString(nil, "OVERLAY")
ViewStats.X:SetPoint("CENTER", ViewStats, "CENTER", 1, -1)
ViewStats.X:SetFont(Font, 12)
ViewStats.X:SetTextColor(unpack(FontColor))
ViewStats.X:SetText("Fame/Shame")
ViewStats.X:SetShadowOffset(1.25, -1.25)
ViewStats.X:SetShadowColor(0, 0, 0)

local ViewStats = CreateFrame("Button", nil, CGHost2Top, BackdropTemplateMixin and "BackdropTemplate")
ViewStats:SetSize(108, 20)
ViewStats:SetPoint("TOPLEFT", CGHost2Top, "BOTTOMLEFT", 5, -2)
ViewStats:SetFrameStrata("MEDIUM")
SetTemplateDark(ViewStats)
ViewStats:SetScript("OnEnter", ButtonOnEnter)
ViewStats:SetScript("OnLeave", ButtonOnLeave)
ViewStats:SetScript("OnMouseUp", function(self, full)
	CrossGambling_OnClickSTATS(full)
end)

ViewStats.X = ViewStats:CreateFontString(nil, "OVERLAY")
ViewStats.X:SetPoint("CENTER", ViewStats, "CENTER", 1, -1)
ViewStats.X:SetFont(Font, 12)
ViewStats.X:SetTextColor(unpack(FontColor))
ViewStats.X:SetText("Full Stats")
ViewStats.X:SetShadowOffset(1.25, -1.25)
ViewStats.X:SetShadowColor(0, 0, 0)

local CrossGambling_HouseCut = CreateFrame("Frame", nil, CGHost2, BackdropTemplateMixin and "BackdropTemplate")
CrossGambling_HouseCut:SetSize(108, 20)
CrossGambling_HouseCut:SetPoint("TOPLEFT", ViewStats, "BOTTOMLEFT", 0, -2)
SetTemplateDark(CrossGambling_HouseCut)
CrossGambling_HouseCut:SetScript("OnEnter", ButtonOnEnter)
CrossGambling_HouseCut:HookScript("OnEnter", function(self)
	GameTooltip:SetText("Guild Cut")
    GameTooltip:AddLine("Sets The Guild Cut (90% is Max!)", 1, 1, 1, true)
    GameTooltip:Show()

end)
CrossGambling_HouseCut:SetScript("OnLeave", ButtonOnLeave)
CrossGambling_HouseCut:SetScript("OnMouseUp", function(self)
	CrossGambling_ToggleHouse()
end)

CrossGambling_HouseCut.Label = CrossGambling_HouseCut:CreateFontString(nil, "OVERLAY")
CrossGambling_HouseCut.Label:SetPoint("CENTER", CrossGambling_HouseCut, 0, 0)
CrossGambling_HouseCut.Label:SetFont(Font, 12)
CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)")
CrossGambling_HouseCut.Label:SetJustifyH("CENTER")
CrossGambling_HouseCut.Label:SetTextColor(unpack(FontColor))
CrossGambling_HouseCut.Label:SetShadowOffset(1.25, -1.25)
CrossGambling_HouseCut.Label:SetShadowColor(0, 0, 0)

local CGReset = CreateFrame("Frame", nil, CGHost2, BackdropTemplateMixin and "BackdropTemplate")
CGReset:SetSize(108, 20)
CGReset:SetPoint("TOPRIGHT", CrossGambling_HouseCut, "BOTTOMRIGHT", 0, -55)
SetTemplateDark(CGReset)
CGReset:SetScript("OnEnter", ButtonOnEnter)
CGReset:SetScript("OnLeave", ButtonOnLeave)
CGReset:SetScript("OnMouseUp", function(self)
      SendEvent("RESET_ALL")
	  isCGHost = true
end)

CGReset.Label = CGReset:CreateFontString(nil, "OVERLAY")
CGReset.Label:SetPoint("CENTER", CGReset, 0, 0)
CGReset.Label:SetFont(Font, 12)
CGReset.Label:SetJustifyH("CENTER")
CGReset.Label:SetTextColor(unpack(FontColor))
CGReset.Label:SetText("Reset Stats")
CGReset.Label:SetShadowOffset(1.25, -1.25)
CGReset.Label:SetShadowColor(0, 0, 0)

local Top = CreateFrame("Frame", nil, ChatFrame, BackdropTemplateMixin and "BackdropTemplate")
Top:SetSize(ChatFrame:GetSize(), 21) 
Top:SetPoint("TOP", ChatFrame, "Top", 0, 0)
SetTemplateDark(Top)

GUI.BottomLabel = Top:CreateFontString(nil, "OVERLAY")
GUI.BottomLabel:SetPoint("LEFT", Top, 2, 0)
GUI.BottomLabel:SetFont(Font, 8)
GUI.BottomLabel:SetTextColor(unpack(FontColor))
GUI.BottomLabel:SetJustifyH("LEFT")
GUI.BottomLabel:SetShadowOffset(1.25, -1.25)
GUI.BottomLabel:SetShadowColor(0, 0, 0)
GUI.BottomLabel:SetText("Silent On: Recommended every one has addon.")

local UIConfig
local function ScrollFrame_OnMouseWheel(self, delta)
	local newValue = self:GetVerticalScroll() - (delta * 20);
	
	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end
	
	self:SetVerticalScroll(newValue);
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID());
	
	local scrollChild = UIConfig.ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	UIConfig.ScrollFrame:SetScrollChild(self.content);
	self.content:Show();	
end

local function SetTabs(frame, numTabs, ...)
	frame.numTabs = numTabs;
	
	local contents = {};
	local frameName = frame:GetName();
	
	for i = 1, numTabs do	
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CharacterFrameTabButtonTemplate");
		tab:SetID(i);
		tab:SetText(select(i, ...));
		tab:SetScript("OnClick", Tab_OnClick);
		
		tab.content = CreateFrame("Frame", nil, UIConfig.ScrollFrame);
		tab.content:SetSize(308, 500);
		tab.content:Hide();
		
		-- just for tutorial only:
		table.insert(contents, tab.content);
		
	end
	
	Tab_OnClick(_G[frameName.."Tab1"]);
	
	return unpack(contents);
end

local SlotzContainer = CreateFrame("Frame", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
SlotzContainer:SetPoint("TOPRIGHT", GUI, "TOPLEFT", 0, -20)
SlotzContainer:SetSize(220, 141)
SetTemplate(SlotzContainer)
SlotzContainer:Hide()

local Top = CreateFrame("Frame", nil, SlotzContainer, BackdropTemplateMixin and "BackdropTemplate")
Top:SetSize(SlotzContainer:GetSize(), 21) 
Top:SetPoint("TOP", SlotzContainer, "Top", 0, 21)
Top:SetFrameLevel(15)
SetTemplateDark(Top)

GUI.BottomLabel = Top:CreateFontString(nil, "OVERLAY")
GUI.BottomLabel:SetPoint("CENTER", Top, 2, 0)
GUI.BottomLabel:SetFont(Font, 10)
GUI.BottomLabel:SetTextColor(unpack(FontColor))
GUI.BottomLabel:SetJustifyH("CENTER")
GUI.BottomLabel:SetShadowOffset(1.25, -1.25)
GUI.BottomLabel:SetShadowColor(0, 0, 0)
GUI.BottomLabel:SetText("Roll Tracker")

UIConfig = CreateFrame("Frame", "AuraTrackerConfig", SlotzContainer, "UIPanelDialogTemplate");
UIConfig:SetSize(222, 167);
UIConfig:SetPoint("CENTER", SlotzContainer, "CENTER", -2, 12)
	
UIConfig.ScrollFrame = CreateFrame("ScrollFrame", nil, UIConfig, "UIPanelScrollFrameTemplate");
UIConfig.ScrollFrame:SetPoint("TOPLEFT", AuraTrackerConfigDialogBG, "TOPLEFT", 4, -8);
UIConfig.ScrollFrame:SetPoint("BOTTOMRIGHT", AuraTrackerConfigDialogBG, "BOTTOMRIGHT", -3, 4);
UIConfig.ScrollFrame:SetClipsChildren(true);
UIConfig.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);	
local content1 = SetTabs(UIConfig, 1, "Appearance");
	
local PlayerSlotz = CreateFrame("Frame", nil, content1, BackdropTemplateMixin and "BackdropTemplate")
PlayerSlotz:SetPoint("CENTER", content1, "CENTER", 2, 0)
PlayerSlotz:SetSize(220, 10)
PlayerSlotz:Show()

local PlayerRoll = function(player)
	for i = 1, #Players do
		if (Players[i].Name == player and not Players[i].HasRolled) then
			Players[i].HasRolled = true
			local Roll = GetRoll()

			tinsert(Rolls, {Players[i].Name, Roll})

			Players[i].Total:SetText(Comma(Roll))

			CheckRolls()

		end
	end
end

local SortPlayers = function()
	for i = 1, #Players do
		if (i == 1) then
			Players[i]:SetPoint("TOPLEFT", content1, "TOPLEFT", 0, -3)
		else
			Players[i]:SetPoint("TOP", Players[i-1], "BOTTOM", 0, -2)
		end
	end
end


local ChatAddPlayer = function(chatName)
	local charname, realmname = strsplit("-", chatName)
--local insname = strlower(charname)
	--print("DEBUG | REGISTERED ADD NAME: ", charname)
	SendEvent("ADD_PLAYER", charname)
end

local ChatRemovePlayer = function(chatName)
	local charname, realmname = strsplit("-", chatName)
--local insname = strlower(charname)
	--print("DEBUG | REGISTERED REMOVE NAME: ", charname)
	SendEvent("REMOVE_PLAYER", charname)
end

local ChatToggle = CreateFrame("Button", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
ChatToggle:SetSize(21, 21)
ChatToggle:SetPoint("BOTTOMLEFT", Bottom, "BOTTOMLEFT", 0, 0)
ChatToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(ChatToggle)
ChatToggle:SetScript("OnMouseUp", function(self)
	if self.NeedsReset then
		self.Arrow:SetTextColor(1, 1, 1)
		self.NeedsReset = false
	end

	if SlotzContainer:IsShown() then
		SlotzContainer:Hide()
		self.Arrow:SetText("◄")
	else
		SlotzContainer:Show()
		self.Arrow:SetText("►")
	end
end)
ChatToggle.Arrow = ChatToggle:CreateFontString(nil, "OVERLAY")
ChatToggle.Arrow:SetPoint("CENTER", ChatToggle, "CENTER", 0, 0)
ChatToggle.Arrow:SetFont("Interface\\AddOns\\CrossGambling\\media\\Arial.ttf", 12)
ChatToggle.Arrow:SetTextColor(unpack(FontColor))
ChatToggle.Arrow:SetText("◄")
ChatToggle.Arrow:SetShadowOffset(1.25, -1.25)
ChatToggle.Arrow:SetShadowColor(0, 0, 0)

local AddPlayer = function(name)
	for i = 1, #Players do
		if (Players[i].Name == name) then
			return
		end
	end

	local PlayerSlot = CreateFrame("Frame", nil, PlayerSlotz, BackdropTemplateMixin and "BackdropTemplate")
	PlayerSlot:SetSize(220, 15)
	SetTemplateDark(PlayerSlot)

	PlayerSlot.Name = name

	PlayerSlot.Label = PlayerSlot:CreateFontString(nil, "OVERLAY")
	PlayerSlot.Label:SetPoint("LEFT", PlayerSlot, 4, 0)
	PlayerSlot.Label:SetFont(Font, 12)
	PlayerSlot.Label:SetJustifyH("LEFT")
	PlayerSlot.Label:SetTextColor(unpack(FontColor))
	PlayerSlot.Label:SetText(name)
	PlayerSlot.Label:SetShadowOffset(1.25, -1.25)
	PlayerSlot.Label:SetShadowColor(0, 0, 0)

	PlayerSlot.TotalFrame = CreateFrame("Frame", nil, PlayerSlot, BackdropTemplateMixin and "BackdropTemplate")
	PlayerSlot.TotalFrame:SetSize(78, 15)
	PlayerSlot.TotalFrame:SetPoint("RIGHT", PlayerSlot, 0, 0)
	SetTemplateDark(PlayerSlot.TotalFrame)


	PlayerSlot.Total = PlayerSlot.TotalFrame:CreateFontString(nil, "OVERLAY", BackdropTemplateMixin and "BackdropTemplate")
	PlayerSlot.Total:SetPoint("CENTER", PlayerSlot.TotalFrame, 4, 0)
	PlayerSlot.Total:SetFont(Font, 12)
	PlayerSlot.Total:SetJustifyH("CENTER")
	PlayerSlot.Total:SetTextColor(unpack(FontColor))
	PlayerSlot.Total:SetShadowOffset(1.25, -1.25)
	PlayerSlot.Total:SetShadowColor(0, 0, 0)

	tinsert(Players, PlayerSlot)

	SortPlayers()
	
end

local RemovePlayer = function(name)
	local Player

	for i = 1, #Players do
		if (Players[i].Name == name) then
			Player = Players[i]
			tremove(Players, i)
			break
		end
	end

	if Player then
		Player:Hide()
		SortPlayers()
	end
end

-- Editbox
local EditBoxOnMouseDown = function(self)
	self:SetAutoFocus(true)
	self:SetText("") -- Clears the editbox whenever it is clicked on.
end

local EditBoxOnEditFocusLost = function(self)
	self:SetAutoFocus(false)
end

local EditBoxOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local EditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (Value == "" or Value == " ") then
		self:SetText(CurrentRollValue)

		return
	end
end

local CG_Rolls = function()
	tsort(Rolls, function(a, b)
		return a[2] > b[2]
	end)
    
	local Winner = Rolls[1]
	local Loser = Rolls[#Rolls]
	local Diff = Winner[2] - Loser[2]
	
	if (CrossGambling["GameMode"]) then
	GameMode2 = floor(CrossGambling_EditBox:GetText())
	Diff = Diff - GameMode2
	CrossGambling["GameMode1"]  = (CrossGambling["GameMode1"] or 0);
	else 
	GameMode2 = floor(Diff)
	end

	if (not CrossGambling["stats"][Winner[1]]) then
		CrossGambling["stats"][Winner[1]] = 0
	end

	if (not CrossGambling["stats"][Loser[1]]) then
		CrossGambling["stats"][Loser[1]] = 0
	end

	-- If the user is set as an CGHost (meaning they started the game), and if silent mode is disabled, they will report the results to the current channel.
if(isCGHost) then
		if(ChatFrame:IsShown() and CrossGambling["isHouseCut"] == false) then
			SendEvent(format("CHAT_MSG:%s:%s:%s owes %s %sg", PlayerName, PlayerClass, Loser[1], Winner[1], Comma(GameMode2)))
			SendEvent("RESET_GAME")
        elseif(ChatFrame:IsShown() and CrossGambling["isHouseCut"] == true) then 
		    SendEvent(format("CHAT_MSG:%s:%s:%s owes %s %s gold! Guild cut is %s", PlayerName, PlayerClass, Loser[1], Winner [1], Comma(GameMode2), GameMode2 * (GuildCut:GetText()/100)))	
			SendEvent("RESET_GAME")
		elseif(CrossGambling["isHouseCut"] == true) then
			SendChatMessage(format(" %s owes %s %s gold! Guild Cut Is %s", Loser[1], Winner [1], Comma(GameMode2), GameMode2 * (GuildCut:GetText()/100)), ReportChannel, nil)	
			SendEvent("RESET_GAME")
		else
			SendChatMessage(format(" %s owes %s %s gold!", Loser[1], Winner [1], Comma(GameMode2)), ReportChannel, nil)	
			SendEvent("RESET_GAME")
		end	
		if(CrossGambling["isHouseCut"] == true) then
			CrossGambling["house"] = (CrossGambling["house"] or 0) + GameMode2 * (GuildCut:GetText()/100);	
		end
	
		CrossGambling["stats"][Winner[1]] = CrossGambling["stats"][Winner[1]] + GameMode2
		CrossGambling["stats"][Loser[1]] = CrossGambling["stats"][Loser[1]] - GameMode2
end

	for i = #Rolls, 1, -1 do
		tremove(Rolls, 1)
	end
end



-- Checking Rolls

local CheckRolls = function()
	local NumPlayers = #Players
	local Count = 0

	for i = 1, #Players do
		if Players[i].HasRolled then
			Count = Count + 1
		end
	end

	if (Count == NumPlayers) then
		CG_Rolls()
	end
end

function CrossGambling1:OnInitialize()
	local defaults = {
	    global = {
			minimap = {
				hide = false,
			}
		}
	}
    self.db = LibStub("AceDB-3.0"):New("CrossGambling", defaults)
	self:ConstructMiniMapIcon()
end


function Minimap_Toggle()
	if CrossGambling["minimap"] then
		-- minimap is shown, set to false, and hide
		CrossGambling["minimap"] = false
	    GUI:Show()	
        isCGHost = false		
     else
		-- minimap is now shown, set to true, and show
		CrossGambling["minimap"] = true
		GUI:Hide()
		CrossGambling["active"] = 0;
		isCGHost = false
	end
end

local Events = {}

function CrossGambling_OnClickCHAT()
	if(CrossGambling["chat"] == nil) then CrossGambling["chat"] = 1; end

	CrossGambling["chat"] = (CrossGambling["chat"] % #chatmethods) + 1;

	chatmethod = chatmethods[CrossGambling["chat"]];
	CrossGambling_CHAT_Button:SetText(chatmethod);
end

-- Will work on later 
function CrossGambling_OnClickRoll1()
   if CGEnter.Label:GetText() == "Join Game" then
		SendEvent("ADD_PLAYER", PlayerName)
  --print("DEBUG | EBOnEnPressed | PName: ", PlayerName, " // PClass: ", PlayerClass, " // Value: ", Value)
	CGEnter.Label:SetText("Leave Game")
	elseif CGEnter.Label:GetText() == "Leave Game" then
	SendEvent("REMOVE_PLAYER", PlayerName)
	CGEnter.Label:SetText("Join Game")
   end
end

function CrossGambling_GameMode_Button()
if GameMode_Button_Button:GetText() == "< Game Mode >" then
 GameMode_Button_Button:SetText("< BigTwo >")
 CrossGambling["GameMode1"] = "2";
 elseif GameMode_Button_Button:GetText() == "< BigTwo >" then
 GameMode_Button_Button:SetText("< 501 >")
 CrossGambling["GameMode1"] = "501";
 elseif GameMode_Button_Button:GetText() == "< 501 >" then
 GameMode_Button_Button:SetText("< Game Mode >")
end
end

function CrossGambling_ToggleHouse()
	if (CrossGambling["isHouseCut"]) then
		CrossGambling["isHouseCut"] = false
		 CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned off.")
	else
		CrossGambling["isHouseCut"] = true
		 CrossGambling_HouseCut.Label:SetText("Guild Cut (ON)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned on.")
	end
end

Events["RESET_ALL"] = function()
	if(isCGHost) then
	for i = 1, #Players do
		Players[1].HasRolled = false
		Players[1].Total:SetText("")
		RemovePlayer(Players[1].Name)
	
end


    CrossGambling["stats"] = { }
	CrossGambling["house"] = 0
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00CG ALL STATS RESET!")
    isCGHost = false
	EnableButton(AcceptRolls)
    DisableButton(RollGame)
	DisableButton(RollMe)
	DisableButton(LastCall)
   CGEnter.Label:SetText("Join Game")
  end
end

Events["RESET_GAME"] = function()
	    isCGHost = false
        EnableButton(AcceptRolls)
        DisableButton(RollGame)
		DisableButton(RollMe)
		DisableButton(LastCall)
	    CGEnter.Label:SetText("Join Game")
end

Events["ADD_PLAYER"] = function(name)
	if(CrossGambling_ChkBan(tostring(name)) == 0) then
	AddPlayer(name)
    elseif(isCGHost == true) then 
	RemovePlayer(name)
	SendChatMessage(format(" Sorry %s is banned.", name), ReportChannel, nil)
	end
end

Events["REMOVE_PLAYER"] = function(name)
	RemovePlayer(name)
end

Events["PLAYER_ROLL"] = function(name, value)
	for i = 1, #Players do
		if (Players[i].Name == name and not Players[i].HasRolled) then
			Players[i].HasRolled = true
			Players[i].Total:SetText(Comma(value))

			tinsert(Rolls, {Players[i].Name, tonumber(value)})

			CheckRolls()
		end
	end
end

Events["SET_ROLL"] = function(value)
	CurrentRollValue = tonumber(value)
end

Events["START_GAME"] = function()
  if(ChatFrame:IsShown() == true and isCGHost == true ) then
   EnableButton(LastCall)
  	if GameMode_Button_Button:GetText() == "< Game Mode >" then
local RollNotification = "has started a roll!"
    SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, RollNotification))
	SendEvent(format("CHAT_MSG:%s:%s:%s:%s", PlayerName, PlayerClass, "Current Bet", CurrentRollValue))
		SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, "Press Join Game to play!"))
		CrossGambling["lastroll"] = CrossGambling_EditBox:GetText()
	  elseif GameMode_Button_Button:GetText() == "< 501 >" or "< BigTwo >" then
	local RollNotification = "has started a roll!"
    SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, RollNotification))
	SendEvent(format("CHAT_MSG:%s:%s:%s:%s", PlayerName, PlayerClass, "Current Bet", CrossGambling_EditBox:GetText()))
	CrossGambling["GameMode"] = CrossGambling["GameMode1"]
end
    elseif(ChatFrame:IsShown() == false and isCGHost == true ) then
	 EnableButton(LastCall)
		if GameMode_Button_Button:GetText() == "< Game Mode >" then
	SendChatMessage(format(" CrossGambling: User's Roll - ( %s %s", CurrentRollValue, ") - Type 1 to Join  (-1 to withdraw)"), ReportChannel, nil)
	CrossGambling["lastroll"] = CrossGambling_EditBox:GetText()
	  elseif GameMode_Button_Button:GetText() == "< 501 >" or "< BigTwo >" then
	SendChatMessage(format(" CrossGambling: User's Roll - ( %s %s", CurrentRollValue, ") - Type 1 to Join  (-1 to withdraw)"), ReportChannel, nil)
	SendChatMessage(format("Current Bet is %s", CrossGambling_EditBox:GetText(), ") - Type 1 to Join  (-1 to withdraw)"), ReportChannel, nil)
	CrossGambling["GameMode"] = CrossGambling["GameMode1"]
end

 end
		DisableButton(AcceptRolls)
        DisableButton(RollGame)
		DisableButton(RollMe)
		SendEvent("REMOVE_PLAYER", PlayerName)
	    CGEnter.Label:SetText("Join Game")

end


Events["LastCall"] = function()
 if(ChatFrame:IsShown() == true and  isCGHost == true ) then
  	local RollNotification = "Last Call!"
    SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, RollNotification))
	EnableButton(RollGame)
    elseif(ChatFrame:IsShown() == false and isCGHost == true) then
	SendChatMessage(" Last Call to Enter", ReportChannel, nil)
	EnableButton(RollGame)
end

end


Events["CLOSE_GAME"] = function()
 if(ChatFrame:IsShown() == true and  isCGHost == true ) then
  	local RollNotification = "Press Roll Me!"
    SendEvent(format("CHAT_MSG:%s:%s:%s", PlayerName, PlayerClass, RollNotification))
    elseif(ChatFrame:IsShown() == false and isCGHost == true) then
	SendChatMessage(" Entries have closed. Roll now!", ReportChannel, nil)
	SendChatMessage(format(" Type /roll %s", CurrentRollValue), ReportChannel, nil)
		EnableButton(AcceptRolls)
end
	for i = 1, #Players do
		if (Players[i].Name == PlayerName) then
			EnableButton(RollMe)
            EnableButton(AcceptRolls)
			break
		end
	end
end

function ParseChatRoll(tempString2)
	local tempString1 = tempString2
	local player, junk, actualRoll, range = strsplit(" ", tempString1)

	function CheckPlayers(player)
		for i=1, #Players do
			if (Players[i].Name == tostring(player)) then
				return true
			end
		end
		return false
	end


	if junk == "rolls" and CheckPlayers(player)==true then
		minRoll, maxRoll = strsplit("-",range)
		minRoll = tonumber(strsub(minRoll,2))
		maxRoll = tonumber(strsub(maxRoll,1,-2))
		actualRoll = tonumber(actualRoll)


		if(minRoll == 1 and maxRoll == CurrentRollValue) then
			SendEvent("PLAYER_ROLL", player..":"..tostring(actualRoll))
		end

	end
end

local function Print(pre, red, text)
	if red == "" then red = "/CG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre..GREEN_FONT_COLOR_CODE..red..FONT_COLOR_CODE_CLOSE..": "..text)
end

function CrossGambling_SlashCmd(msg)
	local msg = msg:lower();
	local msgPrint = 0;
	if (msg == "" or msg == nil) then
	    Print("", "", "~Following Commands for CrossGambling~");
		Print("", "", "show - Shows the frame");
		Print("", "", "hide - Hides the frame");
		Print("", "", "reset - Resets the AddOn");
		Print("", "", "fullstats - list full stats");
		Print("", "", "resetstats - Resets the stats");
		Print("", "", "joinstats [main] [alt] - Apply [alt]'s win/losses to [main]");
		Print("", "", "minimap - Toggle minimap show/hide");
		Print("", "", "unjoinstats [alt] - Unjoin [alt]'s win/losses from whomever it was joined to");
		Print("", "", "ban - Ban's the user from being able to roll");
		Print("", "", "unban - Unban's the user");
		Print("", "", "listban - Shows ban list");
		Print("", "", "house - Toggles guild house cut");
		msgPrint = 1;
	end
	if (msg == "hide") then
	    GUI:IsShown();
		GUI:Hide();
	    isCGHost = false
		CrossGambling["active"] = 0;
		msgPrint = 1;
	end
	if (msg == "show") then
	GUI:IsShown();
		GUI:Show();
		isCGHost = false
		msgPrint = 1;
	end
	
	if (msg == "reset") then
		SendEvent("RESET_ALL")
		msgPrint = 1;
	end
	if (msg == "fullstats") then
		CrossGambling_OnClickSTATS(true)
		msgPrint = 1;
	end
	if (msg == "resetstats") then
		Print("", "", "|cffffff00CG stats have now been reset");
		SendEvent("RESET_ALL")
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 9) == "joinstats") then
		CrossGambling_JoinStats(strsub(msg, 11));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 11) == "unjoinstats") then
		CrossGambling_UnjoinStats(strsub(msg, 13));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 3) == "ban") then
		CrossGambling_AddBan(strsub(msg, 5));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 5) == "unban") then
		CrossGambling_RemoveBan(strsub(msg, 7));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 7) == "listban") then
		CrossGambling_ListBan();
		msgPrint = 1;
	end
    
	if (string.sub(msg, 1, 5) == "house") then
		CrossGambling_ToggleHouse();
		msgPrint = 1;
	end

	if (msgPrint == 0) then
		Print("", "", "|cffffff00Invalid argument for Command /cg");
	end
	
end

SLASH_CrossGambling1 = "/CrossGambler";
SLASH_CrossGambling2 = "/cg";
SlashCmdList["CrossGambling"] = CrossGambling_SlashCmd

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if (prefix ~= "CrossGambling") then
		return
	end

	local Event, Arg1, Arg2 = split(":", message)

	if Events[Event] then
		Events[Event](Arg1, Arg2)
	elseif (Event == "CHAT_MSG" or "PLAYER_ENTERING_WORLD") then
		if (not ChatFrame:IsShown()) then
			ChatToggle.Arrow:SetTextColor(1, 1, 0)
			ChatToggle.NeedsReset = true
		end

    local Player, Class, Message = strmatch(message, "CHAT_MSG:(.*):(%w+):(.*):nil")


  	local Hex = "|c" .. RAID_CLASS_COLORS[Class].colorStr


    if(Message == "has started a roll!") then
      ChatFrame.Chat:AddMessage(format(" %s%s|r %s", Hex, Player, Message))
    elseif(Message == "has reset the game.") then
      ChatFrame.Chat:AddMessage(format(" %s%s|r %s", Hex, Player, Message))
    else
      ChatFrame.Chat:AddMessage(format("[%s%s|r]: %s", Hex, Player, Message))
    end

	end
end)


local EventChatPlayer = CreateFrame("Frame")
DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Cross Gambling for Warcraft 9.0.2 and Classic!> loaded /cg to use")
EventChatPlayer:RegisterEvent("CHAT_MSG_PARTY")
EventChatPlayer:RegisterEvent("CHAT_MSG_PARTY_LEADER")
EventChatPlayer:RegisterEvent("CHAT_MSG_RAID")
EventChatPlayer:RegisterEvent("CHAT_MSG_RAID_LEADER")
EventChatPlayer:RegisterEvent("CHAT_MSG_GUILD")
EventChatPlayer:RegisterEvent("PLAYER_ENTERING_WORLD");
EventChatPlayer:RegisterEvent("CHAT_MSG_SYSTEM")

EventChatPlayer:SetScript("OnEvent", function(self, event, message, sender)

if (event == "PLAYER_ENTERING_WORLD") then
		CrossGambling_EditBox:SetJustifyH("CENTER");
        GuildCut:SetJustifyH("CENTER");
		if(not CrossGambling) then
			CrossGambling = {
				["active"] = 0,
				["chat"] = 1,
				["channel"] = "Channel Name Here",
				["whispers"] = false,
				["strings"] = { },
				["lowtie"] = { },
				["hightie"] = { },
				["bans"] = { },
				["minimap"] = false,

			}
		-- fix older legacy items for new chat channels.  Probably need to iterate through each to see if it should be set.
		elseif tostring(type(CrossGambling["chat"])) ~= "number" then
			CrossGambling["chat"] = 1
		end
		if(not CrossGambling["lastroll"]) then CrossGambling["lastroll"] = 100; end
		if(not CrossGambling["GameMode1"]) then CrossGambling["GameMode1"] = 501; end
		if(not CrossGambling["GameMode"]) then CrossGambling["GameMode"] = false; end
		if(not CrossGambling["stats"]) then CrossGambling["stats"] = { }; end
		if(not CrossGambling["joinstats"]) then CrossGambling["joinstats"] = { }; end
		if(not CrossGambling["chat"]) then CrossGambling["chat"] = 1; end
		if(not CrossGambling["channel"]) then CrossGambling["channel"] = "Channel Text Here"; end
		if(not CrossGambling["bans"]) then CrossGambling["bans"] = { }; end
		--look at house variable something is wrong with it. 
		if(not CrossGambling["house"]) then CrossGambling["house"] = 0; end
		if(not CrossGambling["GuildCut"]) then CrossGambling["GuildCut"] = 10; end
		if(not CrossGambling["isHouseCut"]) then CrossGambling["isHouseCut"] = false; end
    GuildCut:SetText(""..CrossGambling["GuildCut"])
	   CrossGambling_EditBox:SetText(""..CrossGambling["lastroll"]);
		if(CrossGambling["isHouseCut"] == false) then
		CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)");
		else
		CrossGambling_HouseCut.Label:SetText("Guild Cut (ON)");
		end
		if(CrossGambling["active"] == 1) then
			GUI:Show();
			isCGHost = false
		else
		GUI:Hide();	
		isCGHost = false
		end
	end
	if(chatmethod == "PARTY" and (event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER") and CrossGambling["chat"] == 1) then
		if(message == "1") then
			ChatAddPlayer(sender)
		elseif(message == "-1") then
			ChatRemovePlayer(sender)
		end
	elseif(chatmethod == "RAID" and (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER")   and CrossGambling["chat"] == 2) then
		if(message == "2") then
			ChatAddPlayer(sender)
		elseif(message == "-1") then
			ChatRemovePlayer(sender)
		end
    elseif(chatmethod == "GUILD" and (event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_GUILD") and CrossGambling["chat"] == 3) then
		if(message == "2") then
			ChatAddPlayer(sender)
		elseif(message == "-1") then
			ChatRemovePlayer(sender)
		end
	end

	if (event == "CHAT_MSG_SYSTEM" ) then
			local tempString1 = tostring(message)
			ParseChatRoll(tempString1)
	end

end)

function CrossGambling_JoinStats(msg)
	local i = string.find(msg, " ");
	if((not i) or i == -1 or string.find(msg, "[", 1, true) or string.find(msg, "]", 1, true)) then
		CGChatFrame:AddMessage("");
		return;
	end
	local mainname = string.sub(msg, 1, i-1);
	local altname = string.sub(msg, i+1);
	CGChatFrame:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname));
	CrossGambling["joinstats"][altname] = mainname;
end

function CrossGambling_UnjoinStats(altname)
	if(altname ~= nil and altname ~= "") then
		CGChatFrame:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname));
		CrossGambling["joinstats"][altname] = nil;
	else
		local i, e;
		for i, e in pairs(CrossGambling["joinstats"]) do
			CGChatFrame:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e));
		end
	end
end


function CrossGambling_AddTie(name, tietable)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local found = 0;
		for i=1, table.getn(tietable) do
		  	if tietable[i] == insname then
				found = 1;
			end
        	end
		if found == 0 then
		    table.insert(tietable, insname)
			tierolls = tierolls+1
			totalrolls = totalrolls+1
		end
	end
end

function CrossGambling_Remove(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	for i=1, table.getn(CrossGambling.strings) do
		if CrossGambling.strings[i] ~= nil then
		  	if strlower(CrossGambling.strings[i]) == strlower(insname) then
				table.remove(CrossGambling.strings, i)
				totalrolls = totalrolls - 1;
			end
		end
      end
end

function CrossGambling_ListBan()
	local bancnt = 0;
	Print("", "", "|cffffff00To ban do /cg ban (Name) or to unban /cg unban (Name) - The Current Bans:");
	for i=1, table.getn(CrossGambling.bans) do
		bancnt = 1;
		DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", "...", tostring(CrossGambling.bans[i])));
	end
	if (bancnt == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00To ban do /cg ban (Name) or to unban /cg unban (Name).");
	end
end

function CrossGambling_RemoveTie(name, tietable)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	for i=1, table.getn(tietable) do
		if tietable[i] ~= nil then
		  	if strlower(tietable[i]) == insname then
				table.remove(tietable, i)
			end
		end
      end
end

function CrossGambling_ChkBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(CrossGambling.bans) do
			if strlower(CrossGambling.bans[i]) == strlower(insname) then
				return 1
			end
		end
	end
	return 0
end

function CrossGambling_AddBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local banexist = 0;
		for i=1, table.getn(CrossGambling.bans) do
			if CrossGambling.bans[i] == insname then
				Print("", "", "|cffffff00Unable to add to ban list - user already banned.");
				banexist = 1;
			end
		end
		if (banexist == 0) then
			table.insert(CrossGambling.bans, insname)
			Print("", "", "|cffffff00User is now banned!");
			local string3 = strjoin(" ", "", "User Banned from rolling! -> ",insname, "!")
			DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", string3));
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end

function CrossGambling_RemoveBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(CrossGambling.bans) do
			if strlower(CrossGambling.bans[i]) == strlower(insname) then
				table.remove(CrossGambling.bans, i)
				Print("", "", "|cffffff00User removed from ban successfully.");
				return;
			end
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end
C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")

