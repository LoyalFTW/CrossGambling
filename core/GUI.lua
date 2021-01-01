local CG = "Interface\\AddOns\\CrossGambling\\media\\CG.tga"
local Font = "Fonts\\FRIZQT__.TTF"
local FontColor = {220/255, 220/255, 220/255}
local Players = {}
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

local EnableButton = function(button)
	button:EnableMouse(true)
	button.Label:SetTextColor(1, 1, 1)
end
local DisableButton = function(button)
	button:EnableMouse(false)
	button.Label:SetTextColor(0.3, 0.3, 0.3)
end
local CrossGamblingUI
function CrossGambling:toggleUi()
    if (CrossGamblingUI:IsVisible()) then
        CrossGamblingUI:Hide()
    else
        CrossGamblingUI:Show()
    end
end

function CrossGambling:ShowGUI(info)
    -- Show Inerface
    if (CrossGamblingUI:IsVisible() ~= true) then
        CrossGamblingUI:Show()
    end
end

function CrossGambling:HideGUI(info)
    -- Hide Interface
    if (CrossGamblingUI:IsVisible()) then
        CrossGamblingUI:Hide()
    end
end

local reverse = string.reverse
function CrossGambling:Comma(number)
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
function CrossGambling:ConstructUI()
CrossGamblingUI = CreateFrame("Frame", "CrossGambling", UIParent, BackdropTemplateMixin and "BackdropTemplate")
CrossGamblingUI:SetSize(227, 141) 
CrossGamblingUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
SetTemplate(CrossGamblingUI)
CrossGamblingUI:SetMovable(true)
CrossGamblingUI:EnableMouse(true)
CrossGamblingUI:SetUserPlaced(true)
CrossGamblingUI:SetResizable(true)
CrossGamblingUI:SetMinResize(227, 141)
CrossGamblingUI:RegisterForDrag("LeftButton")
CrossGamblingUI:SetScript("OnDragStart", CrossGamblingUI.StartMoving)
CrossGamblingUI:SetScript("OnDragStop", CrossGamblingUI.StopMovingOrSizing)
CrossGamblingUI:Hide()

local Top = CreateFrame("Frame", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
Top:SetSize(CrossGamblingUI:GetSize(), 21)
Top:SetPoint("BOTTOM", CrossGamblingUI, "TOP", 0, -20)
SetTemplateDark(Top)

local CGHost = CreateFrame("Frame", "CrossgameCGHost", CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
CGHost:SetSize(CrossGamblingUI:GetSize(), 1) 
CGHost:SetPoint("BOTTOMLEFT", CrossGamblingUI, "TOPLEFT")
SetTemplate(CGHost)
CGHost:Show()

local CGHost2 = CreateFrame("Frame", "CrossgameCGHost", CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
CGHost2:SetSize(CrossGamblingUI:GetSize(), 1)
CGHost2:SetPoint("BOTTOMLEFT", CrossGamblingUI, "TOPLEFT")
SetTemplate(CGHost2)
CGHost2:Hide()

local CGHost2Top = CreateFrame("Frame", nil, CGHost2, BackdropTemplateMixin and "BackdropTemplate")
CGHost2Top:SetSize(CGHost2:GetSize(), 21)
CGHost2Top:SetPoint("BOTTOM", CrossGamblingUI, "TOP", 0, -20)
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
	GameTooltip:SetText("Game Modes")
    GameTooltip:AddLine("Change Game Mode", 1, 1, 1, true)
    GameTooltip:Show()
end)
CGCHAT:SetScript("OnLeave", ButtonOnLeave)
CGCHAT:SetScript("OnMouseUp", function()
self:chatMethod()
CGCHAT.Label:SetText(self.game.chatMethod)
end)

CGCHAT.Label = CGCHAT:CreateFontString(nil, "OVERLAY")
CGCHAT.Label:SetPoint("CENTER", CGCHAT, 0, 0)
CGCHAT.Label:SetFont(Font, 12)
CGCHAT.Label:SetJustifyH("CENTER")
CGCHAT.Label:SetTextColor(unpack(FontColor))
CGCHAT.Label:SetText(self.game.chatMethod)
CGCHAT.Label:SetShadowOffset(1.25, -1.25)
CGCHAT.Label:SetShadowColor(0, 0, 0)

local GameMode = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
GameMode:SetSize(108, 20)
GameMode:SetPoint("TOPRIGHT", Top, "BOTTOMRIGHT", -4, -2)
SetTemplateDark(GameMode)
GameMode:SetScript("OnEnter", ButtonOnEnter)
GameMode:HookScript("OnEnter", function(self)
	GameTooltip:SetText("Game Modes")
    GameTooltip:AddLine("Change Game Mode", 1, 1, 1, true)
    GameTooltip:Show()
end)
GameMode:SetScript("OnLeave", ButtonOnLeave)
GameMode:SetScript("OnMouseUp", function()
self:changeGameMode()
GameMode.Label:SetText(self.game.mode)
end)

GameMode.Label = GameMode:CreateFontString(nil, "OVERLAY")
GameMode.Label:SetPoint("CENTER", GameMode, 0, 0)
GameMode.Label:SetFont(Font, 12)
GameMode.Label:SetJustifyH("CENTER")
GameMode.Label:SetTextColor(unpack(FontColor))
GameMode.Label:SetText(self.game.mode)
GameMode.Label:SetShadowOffset(1.25, -1.25)
GameMode.Label:SetShadowColor(0, 0, 0)


local Bottom = CreateFrame("Frame", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
Bottom:SetSize(CrossGamblingUI:GetSize(), 21) 
Bottom:SetPoint("TOP", CrossGamblingUI, "BOTTOM", 0, 1)
SetTemplateDark(Bottom)

CrossGamblingUI.BottomLabel = Bottom:CreateFontString(nil, "OVERLAY")
CrossGamblingUI.BottomLabel:SetPoint("LEFT", Bottom, 25, 0)
CrossGamblingUI.BottomLabel:SetFont(Font, 9.9)
CrossGamblingUI.BottomLabel:SetTextColor(unpack(FontColor))
CrossGamblingUI.BottomLabel:SetJustifyH("LEFT")
CrossGamblingUI.BottomLabel:SetShadowOffset(1.25, -1.25)
CrossGamblingUI.BottomLabel:SetShadowColor(0, 0, 0)
CrossGamblingUI.BottomLabel:SetText("CrossGambling - Loyal@Stormrage")

local EditBoxOnEditFocusLost = function(self)
	self:SetAutoFocus(false)
end

local EditBoxOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
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
CrossGambling_EditBox:SetShadowColor(0, 0, 0)
CrossGambling_EditBox:SetShadowOffset(1.25, -1.25)
CrossGambling_EditBox:SetMaxLetters(6)
CrossGambling_EditBox:SetText(self.db.global.wager)
CrossGambling_EditBox:SetAutoFocus(false)
CrossGambling_EditBox:SetNumeric(true)
CrossGambling_EditBox:EnableKeyboard(true)
CrossGambling_EditBox:EnableMouse(true)
CrossGambling_EditBox:SetNumeric(true)
CrossGambling_EditBox:SetJustifyH("CENTER")
CrossGambling_EditBox:SetMaxLetters(6)
CrossGambling_EditBox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
CrossGambling_EditBox:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

local GuildCutBox = CreateFrame("Frame", nil, CGHost2Top, BackdropTemplateMixin and "BackdropTemplate")
GuildCutBox:SetSize(108, 20)
GuildCutBox:SetPoint("TOPLEFT", CGHost2Top, "BOTTOMLEFT", 114, -24)
SetTemplateDark(GuildCutBox)
GuildCutBox:EnableMouse(true)

local GuildCut = CreateFrame("EditBox", nil, GuildCutBox)
GuildCut:SetPoint("CENTER", GuildCutBox, 0, 0)
GuildCut:SetPoint("BOTTOMRIGHT", GuildCutBox, -4, 2)
GuildCut:SetFont(Font, 16)
GuildCut:SetText(self.db.global.houseCut)
GuildCut:SetShadowColor(0, 0, 0)
GuildCut:SetJustifyH("CENTER")
GuildCut:SetShadowOffset(1.25, -1.25)
GuildCut:SetMaxLetters(2)
GuildCut:SetAutoFocus(false)
GuildCut:SetNumeric(true)
GuildCut:EnableKeyboard(true)
GuildCut:EnableMouse(true)
GuildCut:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
GuildCut:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)

local AcceptRolls = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
AcceptRolls:SetSize(108, 20)
AcceptRolls:SetPoint("TOPLEFT", EditBox, "BOTTOMLEFT", 0, -2)
SetTemplateDark(AcceptRolls)
AcceptRolls:SetScript("OnEnter", ButtonOnEnter)
AcceptRolls:SetScript("OnLeave", ButtonOnLeave)
AcceptRolls:SetScript("OnMouseUp", function()
if AcceptRolls.Label:GetText() == "Host Game" then
AcceptRolls.Label:SetText("New Game")
else
self.game.state = "START"
self:SendEvent("R_NewGame")
--Sets same roll for everyone.
self:SendEvent("SET_ROLL", CrossGambling_EditBox:GetText())
--Switches everyone to same gamemode. 
self:SendEvent("GAME_MODE", GameMode.Label:GetText())
--Switches everyone to proper chatmethod. 
self:SendEvent("Chat_Method", CGCHAT.Label:GetText())

self:SendEvent("SET_HOUSE", GuildCut:GetText())
--Starts a new game but only if they're host. 
self.game.host = true
self:SendEvent("START_GAME")
end
end)



AcceptRolls.Label = AcceptRolls:CreateFontString(nil, "OVERLAY")
AcceptRolls.Label:SetPoint("CENTER", AcceptRolls, 0, 0)
AcceptRolls.Label:SetFont(Font, 12)
AcceptRolls.Label:SetJustifyH("CENTER")
AcceptRolls.Label:SetText("Host Game")
AcceptRolls.Label:SetShadowOffset(1.25, -1.25)
AcceptRolls.Label:SetShadowColor(0, 0, 0)

local ChatFrame = CreateFrame("Frame", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
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
local SendEvent = function(event, arg1)
	if self.game.chatMethod then
		local Event = event .. ":" .. tostring(arg1)
		C_ChatInfo.SendAddonMessage("CrossGambling", Event, self.game.chatMethod)
    --print("DEBUG | Event: ", event, " // Channel: ", Channel)
	end
end
local EditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (Value == "" or Value == " ") then
		self:SetText("|cffB0B0B0Chat...|r")

		return
	end
	local PlayerName = UnitName("player")
	local PlayerClass = select(2, UnitClass("player"))
	--Cant figure out will work on some other time. 
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
local ChatToggle = CreateFrame("Button", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
ChatToggle:SetSize(21, 21)
ChatToggle:SetPoint("BOTTOMRIGHT", Bottom, "BOTTOMRIGHT", 0, 0)
ChatToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(ChatToggle)
ChatToggle:SetScript("OnMouseUp", function()
    
	if ChatFrame:IsShown() then
		ChatFrame:Hide()
		self.game.chatframeOption = true
	else
		ChatFrame:Show()
		self.game.chatframeOption = false

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
CGEnter:SetScript("OnMouseUp", function()
    if (CGEnter.Label:GetText() == "Join Game") then
		if(self.game.chatframeOption == false) then
			local InOrOut = "1"	
			self:SendEvent("ADD_PLAYER", self.game.PlayerName)
			self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, InOrOut))
        else
			SendChatMessage("1" , self.game.chatMethod)	
		end
		CGEnter.Label:SetText("Leave Game")
    elseif (CGEnter.Label:GetText() == "Leave Game") then
           if(self.game.chatframeOption == false) then
			local InOrOut = "-1"
			self:SendEvent("Remove_Player", self.game.PlayerName)
			self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, InOrOut))
        else
			SendChatMessage("-1" , self.game.chatMethod)	
		end
		CGEnter.Label:SetText("Join Game")
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

local RollMe = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
RollMe:SetSize(108, 20)
RollMe:SetPoint("TOPRIGHT", CGEnter, "BOTTOMRIGHT", 0, -2)
SetTemplateDark(RollMe)
RollMe:SetScript("OnEnter", ButtonOnEnter)
RollMe:SetScript("OnLeave", ButtonOnLeave)
RollMe:SetScript("OnMouseUp", function()
rollMe()
end)

RollMe.Label = RollMe:CreateFontString(nil, "OVERLAY")
RollMe.Label:SetPoint("CENTER", RollMe, 0, 0)
RollMe.Label:SetFont(Font, 12)
RollMe.Label:SetJustifyH("CENTER")
RollMe.Label:SetTextColor(unpack(FontColor))
RollMe.Label:SetText("Roll Me")
RollMe.Label:SetShadowOffset(1.25, -1.25)
RollMe.Label:SetShadowColor(0, 0, 0)

local LastCall = CreateFrame("Frame", nil, CGHost, BackdropTemplateMixin and "BackdropTemplate")
LastCall:SetSize(108, 20)
LastCall:SetPoint("TOPLEFT", AcceptRolls, "BOTTOMLEFT", 0, -2)
SetTemplateDark(LastCall)
LastCall:SetScript("OnEnter", ButtonOnEnter)
LastCall:HookScript("OnEnter", function(self)

end)
LastCall:SetScript("OnLeave", ButtonOnLeave)
LastCall:SetScript("OnMouseUp", function()
	self:SendEvent("LastCall")
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
RollGame:SetScript("OnMouseUp", function()
self:CGRolls()
end)

RollGame.Label = RollGame:CreateFontString(nil, "OVERLAY")
RollGame.Label:SetPoint("CENTER", RollGame, 0, 0)
RollGame.Label:SetFont(Font, 12)
RollGame.Label:SetJustifyH("CENTER")
RollGame.Label:SetTextColor(unpack(FontColor))
RollGame.Label:SetText("Start Rolling")
RollGame.Label:SetShadowOffset(1.25, -1.25)
RollGame.Label:SetShadowColor(0, 0, 0)

EnableButton(RollGame)
EnableButton(LastCall)
EnableButton(RollMe)
EnableButton(CGEnter)

local CGHostToggle = CreateFrame("Button", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
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
    CrossGamblingUI:Hide()
end)


Close.Label = Close:CreateFontString(nil, "OVERLAY")
Close.Label:SetPoint("CENTER", Close, 0, 0)
Close.Label:SetFont(Font, 12)
Close.Label:SetJustifyH("CENTER")
Close.Label:SetTextColor(unpack(FontColor))
Close.Label:SetText("Close")
Close.Label:SetShadowOffset(1.25, -1.25)
Close.Label:SetShadowColor(0, 0, 0)

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
ViewStats:SetScript("OnMouseUp", function()
	self:reportStats()
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
ViewStats:SetScript("OnMouseUp", function(full)
	self:reportStats(full)
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
CrossGambling_HouseCut:SetScript("OnMouseUp", function()
	if (self.game.house == true) then
		self.game.house = false
		CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned off.")
	else
		self.game.house = true
		CrossGambling_HouseCut.Label:SetText("Guild Cut (ON)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned on.")
	end
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
CGReset:SetScript("OnMouseUp", function()
      self:SendEvent("RESET_STATS")
	  self.game.host = false
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

CrossGamblingUI.BottomLabel = Top:CreateFontString(nil, "OVERLAY")
CrossGamblingUI.BottomLabel:SetPoint("LEFT", Top, 2, 0)
CrossGamblingUI.BottomLabel:SetFont(Font, 8)
CrossGamblingUI.BottomLabel:SetTextColor(unpack(FontColor))
CrossGamblingUI.BottomLabel:SetJustifyH("LEFT")
CrossGamblingUI.BottomLabel:SetShadowOffset(1.25, -1.25)
CrossGamblingUI.BottomLabel:SetShadowColor(0, 0, 0)
CrossGamblingUI.BottomLabel:SetText("Silent On: Recommended every one has addon.")

local CGConfigMenu
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
	
	local scrollChild = CGConfigMenu.ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	CGConfigMenu.ScrollFrame:SetScrollChild(self.content);
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
		
		tab.content = CreateFrame("Frame", nil, CGConfigMenu.ScrollFrame);
		tab.content:SetSize(308, 500);
		tab.content:Hide();
		
		-- just for tutorial only:
		table.insert(contents, tab.content);
		
	end
	
	Tab_OnClick(_G[frameName.."Tab1"]);
	
	return unpack(contents);
end

local SlotzContainer = CreateFrame("Frame", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
SlotzContainer:SetPoint("TOPRIGHT", CrossGamblingUI, "TOPLEFT", 0, -20)
SlotzContainer:SetSize(220, 141)
SetTemplate(SlotzContainer)
SlotzContainer:Hide()

local Top = CreateFrame("Frame", nil, SlotzContainer, BackdropTemplateMixin and "BackdropTemplate")
Top:SetSize(SlotzContainer:GetSize(), 21) 
Top:SetPoint("TOP", SlotzContainer, "Top", 0, 21)
Top:SetFrameLevel(15)
SetTemplateDark(Top)

CrossGamblingUI.BottomLabel = Top:CreateFontString(nil, "OVERLAY")
CrossGamblingUI.BottomLabel:SetPoint("CENTER", Top, 2, 0)
CrossGamblingUI.BottomLabel:SetFont(Font, 10)
CrossGamblingUI.BottomLabel:SetTextColor(unpack(FontColor))
CrossGamblingUI.BottomLabel:SetJustifyH("CENTER")
CrossGamblingUI.BottomLabel:SetShadowOffset(1.25, -1.25)
CrossGamblingUI.BottomLabel:SetShadowColor(0, 0, 0)
CrossGamblingUI.BottomLabel:SetText("Roll Tracker")

CGConfigMenu = CreateFrame("Frame", "CGConfig", SlotzContainer, "")
CGConfigMenu:SetSize(0, 0)
CGConfigMenu:SetPoint("CENTER", SlotzContainer, "CENTER", 100, 12)
	
CGConfigMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, CGConfigMenu, "UIPanelScrollFrameTemplate")
CGConfigMenu.ScrollFrame:SetPoint("TOPLEFT", SlotzContainer, "TOPLEFT", 4, -2)
CGConfigMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", SlotzContainer, "BOTTOMRIGHT", -3, 4)
CGConfigMenu.ScrollFrame:SetClipsChildren(true)
CGConfigMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);	
local content1 = SetTabs(CGConfigMenu, 1, "Appearance")
	
local PlayerSlotz = CreateFrame("Frame", nil, content1, BackdropTemplateMixin and "BackdropTemplate")
PlayerSlotz:SetPoint("CENTER", content1, "CENTER", 2, 0)
PlayerSlotz:SetSize(220, 10)
PlayerSlotz:Show()

local SortPlayers = function()
	for i = 1, #Players do
		if (i == 1) then
			Players[i]:SetPoint("TOPLEFT", content1, "TOPLEFT", 0, -3)
		else
			Players[i]:SetPoint("TOP", Players[i-1], "BOTTOM", 0, -2)
		end
	end
end

local ChatToggle = CreateFrame("Button", nil, CrossGamblingUI, BackdropTemplateMixin and "BackdropTemplate")
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

function CrossGambling:AddPlayer(playerName)
	for i = 1, #Players do
		if (Players[i].Name == playerName) then
			return
		end
	end

	local PlayerSlot = CreateFrame("Frame", nil, PlayerSlotz, BackdropTemplateMixin and "BackdropTemplate")
	PlayerSlot:SetSize(220, 15)
	SetTemplateDark(PlayerSlot)

	PlayerSlot.Name = playerName

	PlayerSlot.Label = PlayerSlot:CreateFontString(nil, "OVERLAY")
	PlayerSlot.Label:SetPoint("LEFT", PlayerSlot, 4, 0)
	PlayerSlot.Label:SetFont(Font, 12)
	PlayerSlot.Label:SetJustifyH("LEFT")
	PlayerSlot.Label:SetTextColor(unpack(FontColor))
	PlayerSlot.Label:SetText(playerName)
	PlayerSlot.Label:SetShadowOffset(1.25, -1.25)
	PlayerSlot.Label:SetShadowColor(0, 0, 0)

	PlayerSlot.TotalFrame = CreateFrame("Frame", nil, PlayerSlot, BackdropTemplateMixin and "BackdropTemplate")
	PlayerSlot.TotalFrame:SetSize(78, 15)
	PlayerSlot.TotalFrame:SetPoint("RIGHT", PlayerSlot, 0, 0)
	SetTemplateDark(PlayerSlot.TotalFrame)


	PlayerSlot.Total = PlayerSlot.TotalFrame:CreateFontString(nil, "OVERLAY", BackdropTemplateMixin and "BackdropTemplate")
	PlayerSlot.Total:SetPoint("CENTER", PlayerSlot.TotalFrame, -7, 0)
	PlayerSlot.Total:SetFont(Font, 12)
	PlayerSlot.Total:SetJustifyH("CENTER")
	PlayerSlot.Total:SetTextColor(unpack(FontColor))
	PlayerSlot.Total:SetShadowOffset(1.25, -1.25)
	PlayerSlot.Total:SetShadowColor(0, 0, 0)

	tinsert(Players, PlayerSlot)

	SortPlayers()
	
end

function CrossGambling:RemovePlayer(name)
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
-- These events have to stay in the ui.lua file for now. 
CGEvents["R_NewGame"] = function()
for i = 1, #Players do
		Players[1].HasRolled = false
		Players[1].Total:SetText("")
		CrossGambling:RemovePlayer(Players[1].Name)
	    
end
CGEnter.Label:SetText("Join Game")
end


CGEvents["RESET_STATS"] = function()
for i = 1, #Players do
		Players[1].HasRolled = false
		Players[1].Total:SetText("")
		CrossGambling:RemovePlayer(Players[1].Name)
	    
end
	CGEnter.Label:SetText("Join Game")
	self:UnRegisterChatEvents()
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
    self.game.state = "START"
    self.game.players = {}
    self.game.result = nil
    self.db.global.stats = {}
	self.db.global.joinstats = {}
	self.db.global.housestats = 0
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00CG ALL STATS RESET!")
end

CGEvents["PLAYER_ROLL"] = function(playerName, value)
	for i = 1, #Players do
		if (Players[i].Name == playerName) then
			Players[i].Total:SetText(self:Comma(value))


		end
	end
end

CGEvents["DisableClient"] = function()
      DisableButton(AcceptRolls)
	  DisableButton(LastCall)
      DisableButton(RollGame)
	  self.game.players = {}
	  self.game.result = nil
	if(self.game.host) then
		EnableButton(AcceptRolls)
		EnableButton(LastCall)
		EnableButton(RollGame)
	end
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("CHAT_MSG_ADDON")
EventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
	if (prefix ~= "CrossGambling") then
		return
	end
    local split = strsplit
	local Event, Arg1, Arg2 = split(":", message)

	if CGEvents[Event] then
		CGEvents[Event](Arg1, Arg2)
	elseif (Event == "CHAT_MSG" or "PLAYER_ENTERING_WORLD") then
		

    local Player, Class, Message = strmatch(message, "CHAT_MSG:(.*):(%w+):(.*):nil")


  	local Hex = "|c" .. RAID_CLASS_COLORS[Class].colorStr

    ChatFrame.Chat:AddMessage(format("[%s%s|r]: %s", Hex, Player, Message))

	end
end)

end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")