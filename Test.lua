CrossGambling1 = LibStub("AceAddon-3.0"):NewAddon("CrossGambling1")
local CrossGambling1 = LibStub("AceAddon-3.0"):GetAddon("CrossGambling1")
local AcceptOnes = "false";
local AcceptRolls = "false";
local House = 0;
local HousePercent = 10;
local GameMode1 = 501;
local GameMode = 100; 
local totalrolls = 0
local tierolls = 0;
local theMax
local lowname = ""
local highname = ""
local low = 0
local high = 0
local tie = 0
local highbreak = 0;
local lowbreak = 0;
local tiehigh = 0;
local tielow = 0;
local whispermethod = false;
local totalentries = 0;
local highplayername = "";
local lowplayername = "";
local lastroll = "";
local rollCmd = SLASH_RANDOM1:upper();
local debugLevel = 0;
local virag_debug = false
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
-- GUI
local Blank = "Interface\\AddOns\\CrossGambling\\Media\\Blank.tga"
local Font = "Interface\\AddOns\\CrossGambling\\Media\\PTSans.ttf"
local FontColor = {220/255, 220/255, 220/255}

local Backdrop = {
	bgFile = Blank,
	edgeFile = Blank,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {left = 1, right = 1, top = 1, bottom = 1},
}

local BackdropBorder = {
	edgeFile = Blank,
	edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local SetTemplate = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(2, 2, 1)
	self:SetBackdropColor(0.22, 0.22, 0.22)
end

local SetTemplateDark = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(3, 3, 1)
	self:SetBackdropColor(0.17, 0.17, 0.17)
end

local GUI = CreateFrame("Frame", "CrossGambling_Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
GUI:SetSize(227, 121) 
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
Top:SetPoint("BOTTOM", GUI, "TOP", 0, 0)
SetTemplateDark(Top)

local Admin = CreateFrame("Frame", "CrossGambleAdmin", GUI, BackdropTemplateMixin and "BackdropTemplate")
Admin:SetSize(GUI:GetSize(), 1) 
Admin:SetPoint("BOTTOMLEFT", GUI, "TOPLEFT")
SetTemplate(Admin)
Admin:Show()

local Admin2 = CreateFrame("Frame", "CrossGambleAdmin", GUI, BackdropTemplateMixin and "BackdropTemplate")
Admin2:SetSize(GUI:GetSize(), 1)
Admin2:SetPoint("BOTTOMLEFT", GUI, "TOPLEFT")
SetTemplate(Admin2)
Admin2:Hide()

local Admin2Top = CreateFrame("Frame", nil, Admin2, BackdropTemplateMixin and "BackdropTemplate")
Admin2Top:SetSize(Admin2:GetSize(), 21)
Admin2Top:SetPoint("BOTTOM", Admin2, "TOP", 0, -1)
SetTemplateDark(Admin2Top)

local ButtonOnEnter = function(self)
	self:SetBackdropColor(0.27, 0.27, 0.27)
	SetTemplateDark(GameTooltip)
	GameTooltip:SetOwner(Admin2Top, "ANCHOR_BOTTOMRIGHT", -2, 21)
end

local ButtonOnLeave = function(self)
      self:SetBackdropColor(0.17, 0.17, 0.17)
	  GameTooltip:Hide()
end

function CrossGambling_OnClickRoll()

if GameMode_Button_Button:GetText() == "< Game Mode >" then
hash_SlashCmdList[rollCmd](CrossGambling_EditBox:GetText())
elseif GameMode_Button_Button:GetText() == "< 501 >" or "< BigTwo >" then
hash_SlashCmdList[rollCmd](CrossGambling["GameMode1"]);
end
end

CHAT = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
CHAT:SetSize(108, 20)
CHAT:SetPoint("TOPLEFT", Top, "BOTTOMLEFT", 5, -2)
SetTemplateDark(CHAT)
CHAT:SetScript("OnEnter", ButtonOnEnter)
CHAT:HookScript("OnEnter", function(self)
	GameTooltip:SetText(chatmethod)
	GameTooltip:AddLine("Change Chat Method", 1, 1, 1, true)
	GameTooltip:Show()
end)
CHAT:SetScript("OnLeave", ButtonOnLeave)
CHAT:SetScript("OnMouseUp", function(self)
CrossGambling_OnClickCHAT()
end)

CrossGambling_CHAT_Button = CHAT:CreateFontString(nil, "OVERLAY")
CrossGambling_CHAT_Button:SetPoint("CENTER", CHAT, 0, 0)
CrossGambling_CHAT_Button:SetFont(Font, 14)
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
GUI.BottomLabel:SetPoint("LEFT", Bottom, 22, 0)
GUI.BottomLabel:SetFont(Font, 12)
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


local EditBox = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
EditBox:SetPoint("TOPLEFT", CHAT, 0, -23)
EditBox:SetSize(Admin:GetSize()-9, 21)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

CrossGambling_EditBox = CreateFrame("EditBox", nil, EditBox)
CrossGambling_EditBox:SetPoint("CENTER", EditBox, 0, 0)
CrossGambling_EditBox:SetPoint("BOTTOMRIGHT", EditBox, -4, 2)
CrossGambling_EditBox:SetFont(Font, 16)
CrossGambling_EditBox:SetText("100")
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

AcceptRolls = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
AcceptRolls:SetSize(108, 20)
AcceptRolls:SetPoint("TOPLEFT", EditBox, "BOTTOMLEFT", 0, -2)
SetTemplateDark(AcceptRolls)
AcceptRolls:SetScript("OnEnter", ButtonOnEnter)
AcceptRolls:HookScript("OnEnter", function(self)


end)
AcceptRolls:SetScript("OnLeave", ButtonOnLeave)
AcceptRolls:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickACCEPTONES()
	CrossGambling["GameMode"] = false; 
end)

AcceptRolls.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

AcceptRolls.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

AcceptRolls.Label = AcceptRolls:CreateFontString(nil, "OVERLAY")
AcceptRolls.Label:SetPoint("CENTER", AcceptRolls, 0, 0)
AcceptRolls.Label:SetFont(Font, 14)
AcceptRolls.Label:SetJustifyH("CENTER")
AcceptRolls.Label:SetTextColor(unpack(FontColor))
AcceptRolls.Label:SetText("New Game")
AcceptRolls.Label:SetShadowOffset(1.25, -1.25)
AcceptRolls.Label:SetShadowColor(0, 0, 0)

CGEnter = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
CGEnter:SetSize(108, 20)
CGEnter:SetPoint("TOPRIGHT", EditBox, "BOTTOMRIGHT", -0, -2)
SetTemplateDark(CGEnter)
CGEnter:SetScript("OnEnter", ButtonOnEnter)
CGEnter:SetScript("OnLeave", ButtonOnLeave)
CGEnter:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickRoll1()
end)

CGEnter.Disable = function()
	CGEnter.Label:SetTextColor(0.3, 0.3, 0.3)
	CGEnter:EnableMouse(false)
end

CGEnter.Enable = function(self)
	CGEnter.Label:SetTextColor(unpack(FontColor))
	CGEnter:EnableMouse(true)
end

CGEnter.Label = CGEnter:CreateFontString(nil, "OVERLAY")
CGEnter.Label:SetPoint("CENTER", CGEnter, 0, 0)
CGEnter.Label:SetFont(Font, 14)
CGEnter.Label:SetJustifyH("CENTER")
CGEnter.Label:SetTextColor(unpack(FontColor))
CGEnter.Label:SetText("Join Game")
CGEnter.Label:SetShadowOffset(1.25, -1.25)
CGEnter.Label:SetShadowColor(0, 0, 0)

RollMe = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
RollMe:SetSize(108, 20)
RollMe:SetPoint("TOPRIGHT", CGEnter, "BOTTOMRIGHT", 0, -2)
SetTemplateDark(RollMe)
RollMe:SetScript("OnEnter", ButtonOnEnter)
RollMe:SetScript("OnLeave", ButtonOnLeave)
RollMe:SetScript("OnMouseUp", function(self)
      CrossGambling_OnClickRoll()
end)

RollMe.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

RollMe.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

RollMe.Label = RollMe:CreateFontString(nil, "OVERLAY")
RollMe.Label:SetPoint("CENTER", RollMe, 0, 0)
RollMe.Label:SetFont(Font, 14)
RollMe.Label:SetJustifyH("CENTER")
RollMe.Label:SetTextColor(unpack(FontColor))
RollMe.Label:SetText("Roll Me")
RollMe.Label:SetShadowOffset(1.25, -1.25)
RollMe.Label:SetShadowColor(0, 0, 0)

GameMode_Button = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
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
GameMode_Button_Button:SetFont(Font, 14)
GameMode_Button_Button:SetJustifyH("CENTER")
GameMode_Button_Button:SetTextColor(unpack(FontColor))
GameMode_Button_Button:SetText("< Game Mode >")
GameMode_Button_Button:SetShadowOffset(1.25, -1.25)
GameMode_Button_Button:SetShadowColor(0, 0, 0)

LastCall = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
LastCall:SetSize(108, 20)
LastCall:SetPoint("TOPLEFT", AcceptRolls, "BOTTOMLEFT", 0, -2)
SetTemplateDark(LastCall)
LastCall:SetScript("OnEnter", ButtonOnEnter)
LastCall:HookScript("OnEnter", function(self)

end)
LastCall:SetScript("OnLeave", ButtonOnLeave)
LastCall:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickLASTCALL();
	
end)

LastCall.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

LastCall.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

LastCall.Label = LastCall:CreateFontString(nil, "OVERLAY")
LastCall.Label:SetPoint("CENTER", LastCall, 0, 0)
LastCall.Label:SetFont(Font, 14)
LastCall.Label:SetJustifyH("CENTER")
LastCall.Label:SetTextColor(unpack(FontColor))
LastCall.Label:SetText("Last Call")
LastCall.Label:SetShadowOffset(1.25, -1.25)
LastCall.Label:SetShadowColor(0, 0, 0)

RollGame = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
RollGame:SetSize(108, 20)
RollGame:SetPoint("TOPLEFT", LastCall, "BOTTOMLEFT", 0, -2)
SetTemplateDark(RollGame)
RollGame:SetScript("OnEnter", ButtonOnEnter)
RollGame:HookScript("OnEnter", function(self)

end)
RollGame:SetScript("OnLeave", ButtonOnLeave)
RollGame:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickROLL()
end)

RollGame.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

RollGame.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

RollGame.Label = RollGame:CreateFontString(nil, "OVERLAY")
RollGame.Label:SetPoint("CENTER", RollGame, 0, 0)
RollGame.Label:SetFont(Font, 14)
RollGame.Label:SetJustifyH("CENTER")
RollGame.Label:SetTextColor(unpack(FontColor))
RollGame.Label:SetText("Start Rolling")
RollGame.Label:SetShadowOffset(1.25, -1.25)
RollGame.Label:SetShadowColor(0, 0, 0)

RollGame:Disable()
LastCall:Disable()
RollMe:Disable()
CGEnter:Enable()

local ChatFrame = CreateFrame("Frame", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
ChatFrame:SetPoint("TOPLEFT", Top, "TOPRIGHT", 2, 0)
ChatFrame:SetSize(260, 205)
SetTemplate(ChatFrame)
ChatFrame:Hide()

ChatFrame.Chat = CreateFrame("ScrollingMessageFrame", nil, ChatFrame)
ChatFrame.Chat:SetPoint("CENTER", ChatFrame, 2, 3)
ChatFrame.Chat:SetSize(ChatFrame:GetWidth() - 8, ChatFrame:GetHeight() - 6)
ChatFrame.Chat:SetFont(Font, 14)
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



AcceptRolls.Label = AcceptRolls:CreateFontString(nil, "OVERLAY")
AcceptRolls.Label:SetPoint("CENTER", AcceptRolls, 0, 0)
AcceptRolls.Label:SetFont(Font, 14)
AcceptRolls.Label:SetJustifyH("CENTER")
AcceptRolls.Label:SetTextColor(unpack(FontColor))
AcceptRolls.Label:SetText("New Game")
AcceptRolls.Label:SetShadowOffset(1.25, -1.25)
AcceptRolls.Label:SetShadowColor(0, 0, 0)

local AdminToggle = CreateFrame("Button", nil, GUI, BackdropTemplateMixin and "BackdropTemplate")
AdminToggle:SetSize(63, 21)
AdminToggle:SetPoint("TOPRIGHT", Top, "TOPRIGHT", -30, 0)
SetTemplateDark(AdminToggle)
AdminToggle:SetScript("OnMouseUp", function(self)
    if Admin:IsShown() then
		Admin:Hide()
		Admin2:Show()
	end
end)

AdminToggle.Arrow = AdminToggle:CreateFontString(nil, "OVERLAY")
AdminToggle.Arrow:SetPoint("CENTER", AdminToggle, "CENTER", 0, 0)
AdminToggle.Arrow:SetTextColor(unpack(FontColor))
AdminToggle.Arrow:SetFont(Font, 14)
AdminToggle.Arrow:SetText("Options")
AdminToggle.Arrow:SetShadowOffset(1.25, -1.25)
AdminToggle.Arrow:SetShadowColor(0, 0, 0)

local AdminToggle = CreateFrame("Button", nil, Top, BackdropTemplateMixin and "BackdropTemplate")
AdminToggle:SetSize(63, 21)
AdminToggle:SetPoint("TOPLEFT", Top, "TOPLEFT", 30, 0)
AdminToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(AdminToggle)
AdminToggle:SetScript("OnMouseUp", function(self)
    if Admin2:IsShown() then
		Admin2:Hide()
		Admin:Show()
	end
end)

AdminToggle.Arrow = AdminToggle:CreateFontString(nil, "OVERLAY")
AdminToggle.Arrow:SetPoint("CENTER", AdminToggle, "CENTER", 0, 0)
AdminToggle.Arrow:SetTextColor(unpack(FontColor))
AdminToggle.Arrow:SetFont(Font, 14)
AdminToggle.Arrow:SetText("Main")
AdminToggle.Arrow:SetShadowOffset(1.25, -1.25)
AdminToggle.Arrow:SetShadowColor(0, 0, 0)


Close = CreateFrame("Frame", nil, Admin, BackdropTemplateMixin and "BackdropTemplate")
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
Close.Label:SetFont(Font, 14)
Close.Label:SetJustifyH("CENTER")
Close.Label:SetTextColor(unpack(FontColor))
Close.Label:SetText("Close")
Close.Label:SetShadowOffset(1.25, -1.25)
Close.Label:SetShadowColor(0, 0, 0)

local ViewStats = CreateFrame("Button", nil, Admin2, BackdropTemplateMixin and "BackdropTemplate")
ViewStats:SetSize(108, 20)
ViewStats:SetPoint("TOPRIGHT", Admin2, "BOTTOMRIGHT", -5, -2)
ViewStats:SetFrameStrata("MEDIUM")
SetTemplateDark(ViewStats)
ViewStats:SetScript("OnEnter", ButtonOnEnter)
ViewStats:SetScript("OnLeave", ButtonOnLeave)
ViewStats:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickSTATS()
end)

ViewStats.X = ViewStats:CreateFontString(nil, "OVERLAY")
ViewStats.X:SetPoint("CENTER", ViewStats, "CENTER", 1, -1)
ViewStats.X:SetFont(Font, 16)
ViewStats.X:SetTextColor(unpack(FontColor))
ViewStats.X:SetText("Fame/Shame")
ViewStats.X:SetShadowOffset(1.25, -1.25)
ViewStats.X:SetShadowColor(0, 0, 0)

local EditBox = CreateFrame("Frame", nil, Admin2, BackdropTemplateMixin and "BackdropTemplate")
EditBox:SetSize(108, 20)
EditBox:SetPoint("TOPLEFT", ViewStats, "BOTTOMLEFT", 0, -2)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

GuildCut = CreateFrame("EditBox", nil, EditBox)
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

local ViewStats = CreateFrame("Button", nil, Admin2, BackdropTemplateMixin and "BackdropTemplate")
ViewStats:SetSize(108, 20)
ViewStats:SetPoint("TOPLEFT", Admin2, "BOTTOMLEFT", 5, -2)
ViewStats:SetFrameStrata("MEDIUM")
SetTemplateDark(ViewStats)
ViewStats:SetScript("OnEnter", ButtonOnEnter)
ViewStats:SetScript("OnLeave", ButtonOnLeave)
ViewStats:SetScript("OnMouseUp", function(self, full)
	CrossGambling_OnClickSTATS(full)
end)

ViewStats.X = ViewStats:CreateFontString(nil, "OVERLAY")
ViewStats.X:SetPoint("CENTER", ViewStats, "CENTER", 1, -1)
ViewStats.X:SetFont(Font, 16)
ViewStats.X:SetTextColor(unpack(FontColor))
ViewStats.X:SetText("Full Stats")
ViewStats.X:SetShadowOffset(1.25, -1.25)
ViewStats.X:SetShadowColor(0, 0, 0)

CrossGambling_HouseCut = CreateFrame("Frame", nil, Admin2, BackdropTemplateMixin and "BackdropTemplate")
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
CrossGambling_HouseCut.Label:SetFont(Font, 14)
CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)")
CrossGambling_HouseCut.Label:SetJustifyH("CENTER")
CrossGambling_HouseCut.Label:SetTextColor(unpack(FontColor))
CrossGambling_HouseCut.Label:SetShadowOffset(1.25, -1.25)
CrossGambling_HouseCut.Label:SetShadowColor(0, 0, 0)

CGReset = CreateFrame("Frame", nil, Admin2, BackdropTemplateMixin and "BackdropTemplate")
CGReset:SetSize(108, 20)
CGReset:SetPoint("TOPRIGHT", CrossGambling_HouseCut, "BOTTOMRIGHT", 0, -55)
SetTemplateDark(CGReset)
CGReset:SetScript("OnEnter", ButtonOnEnter)
CGReset:SetScript("OnLeave", ButtonOnLeave)
CGReset:SetScript("OnMouseUp", function(self)
      CrossGambling_ResetStats()
end)

CGReset.Label = CGReset:CreateFontString(nil, "OVERLAY")
CGReset.Label:SetPoint("CENTER", CGReset, 0, 0)
CGReset.Label:SetFont(Font, 14)
CGReset.Label:SetJustifyH("CENTER")
CGReset.Label:SetTextColor(unpack(FontColor))
CGReset.Label:SetText("Reset Stats")
CGReset.Label:SetShadowOffset(1.25, -1.25)
CGReset.Label:SetShadowColor(0, 0, 0)

function CrossGambling_OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Cross Gambling for Warcraft 9.0.1 and Classic!> loaded /cg to use");

	self:RegisterEvent("CHAT_MSG_RAID");
	self:RegisterEvent("CHAT_MSG_CHANNEL");
	self:RegisterEvent("CHAT_MSG_RAID_LEADER");
	self:RegisterEvent("CHAT_MSG_PARTY_LEADER");
	self:RegisterEvent("CHAT_MSG_PARTY");
	self:RegisterEvent("CHAT_MSG_GUILD");
	self:RegisterEvent("CHAT_MSG_SYSTEM");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterForDrag("LeftButton");
    
	RollGame:Disable();
	AcceptRolls:Enable();
	LastCall:Disable();
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

local EventFrame=CreateFrame("Frame");
EventFrame:RegisterEvent("CHAT_MSG_WHISPER");-- Need to register an event to receive it
EventFrame:SetScript("OnEvent",function(self,event,msg,sender)
    if msg:lower():find("!stats") then--    We're making sure the command is case insensitive by casting it to lowercase before running a pattern check
        ChatMsg("Work in Progress","WHISPER",nil,sender);
    end
end);

local function Print(pre, red, text)
	if red == "" then red = "/CG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre..GREEN_FONT_COLOR_CODE..red..FONT_COLOR_CODE_CLOSE..": "..text)
end

local function DebugMsg(level, text)
  if debugLevel < level then return end

  if level == 1 then
	level = " INFO: "
  elseif level == 2 then
	level = " DEBUG: "
  elseif level == 3 then
	  level = " ERROR: "
  end
  Print("","",GRAY_FONT_COLOR_CODE..date("%H:%M:%S")..RED_FONT_COLOR_CODE..level..FONT_COLOR_CODE_CLOSE..text)
end

local function ChatMsg(msg, chatType, language, channel)
	chatType = chatType or chatmethod
	channelnum = GetChannelName(channel or CrossGambling["channel"] or "Channel Text Here")
	SendChatMessage(msg, chatType, language, channelnum)
end

function CrossGambling_SlashCmd(msg)
	local msg = msg:lower();
	local msgPrint = 0;
	if (msg == "" or msg == nil) then
	    Print("", "", "~Following commands for CrossGambling~");
		Print("", "", "show - Shows the frame");
		Print("", "", "hide - Hides the frame");
		Print("", "", "channel - Change the custom channel for gambling");
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
		CrossGambling["active"] = 0;
		msgPrint = 1;
	end
	if (msg == "show") then
	GUI:IsShown();
		GUI:Show();
		CrossGambling["active"] = 1;
		msgPrint = 1;
	end
	
	if (msg == "reset") then
		CrossGambling_Reset();
		CrossGambling_ResetCmd()
		msgPrint = 1;
	end
	if (msg == "fullstats") then
		CrossGambling_OnClickSTATS(true)
		msgPrint = 1;
	end
	if (msg == "resetstats") then
		Print("", "", "|cffffff00CG stats have now been reset");
		CrossGambling_ResetStats();
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 7) == "channel") then
		CrossGambling_ChangeChannel(strsub(msg, 9));
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
		Print("", "", "|cffffff00Invalid argument for command /cg");
	end
	
end

SLASH_CrossGambling1 = "/CrossGambler";
SLASH_CrossGambling2 = "/cg";
SlashCmdList["CrossGambling"] = CrossGambling_SlashCmd

function CrossGambling_ParseChatMsg(arg1, arg2)
	if (arg1 == "1") then
		if(CrossGambling_ChkBan(tostring(arg2)) == 0) then
			CrossGambling_Add(tostring(arg2));
			if (not LastCall:Enable() and totalrolls == 1) then
				LastCall:Disable();
			end
			if totalrolls == 2 then
				LastCall:Enable();
			
			end
		else
			ChatMsg("Sorry, but you're banned from the game!");
		end

	elseif(arg1 == "-1") then
		CrossGambling_Remove(tostring(arg2));
		if (LastCall:Enable() and totalrolls == 0) then
			LastCall:Disable();
		end
		if totalrolls == 1 then
			LastCall:Disable();
		end
	end
end

local function OptionsFormatter(text, prefix)
	if prefix == "" or prefix == nil then prefix = "/CG" end
	DEFAULT_CHAT_FRAME:AddMessage(string.format("%s%s%s: %s", GREEN_FONT_COLOR_CODE, prefix, FONT_COLOR_CODE_CLOSE, text))
end

function CrossGambling_OnEvent(self, event, ...)

	-- LOADS ALL DATA FOR INITIALIZATION OF ADDON --
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
		end
		if(not CrossGambling["lastroll"]) then CrossGambling["lastroll"] = 100; end
		if(not CrossGambling["GameMode1"]) then CrossGambling["GameMode1"] = 501; end
		if(not CrossGambling["GameMode"]) then CrossGambling["GameMode"] = false; end
		if(not CrossGambling["stats"]) then CrossGambling["stats"] = { }; end
		if(not CrossGambling["joinstats"]) then CrossGambling["joinstats"] = { }; end
		if(not CrossGambling["chat"]) then CrossGambling["chat"] = 1; end
		if(not CrossGambling["channel"]) then CrossGambling["channel"] = "Channel Text Here"; end
		if(not CrossGambling["whispers"]) then CrossGambling["whispers"] = false; end
		if(not CrossGambling["bans"]) then CrossGambling["bans"] = { }; end
		if(not CrossGambling["house"]) then CrossGambling["house"] = { }; end
		if(not CrossGambling["isHouseCut"]) then CrossGambling["isHouseCut"] = false; end
        
		CrossGambling_EditBox:SetText(""..CrossGambling["lastroll"]);
		if(CrossGambling["isHouseCut"] == false) then
		CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)");
		else
		CrossGambling_HouseCut.Label:SetText("Guild Cut (ON)");
		end
	
		if(CrossGambling["active"] == 1) then
			GUI:Show();
		else
		GUI:Hide();	
		end
	end

	-- IF IT'S A RAID MESSAGE... --
	if ((event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_PARTY")and AcceptOnes=="true" and CrossGambling["chat"] == 1) then
		local msg, name = ... -- name no realm
		CrossGambling_ParseChatMsg(msg, name)
	end
	
	if ((event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and AcceptOnes=="true" and CrossGambling["chat"] == 2) then
		local msg, _,_,_,name = ... -- name no realm
		CrossGambling_ParseChatMsg(msg, name)
	end

    if ((event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_GUILD")and AcceptOnes=="true" and CrossGambling["chat"] == 3) then
		local msg, name = ... -- name no realm
		CrossGambling_ParseChatMsg(msg, name)
	end
	
	if event == "CHAT_MSG_CHANNEL" and AcceptOnes=="true" and CrossGambling["chat"] == 4 then
		local msg,_,_,_,name,_,_,_,channelName = ...
		if channelName == CrossGambling["channel"] then
			CrossGambling_ParseChatMsg(msg, name)
		end
	end

	if (event == "CHAT_MSG_SYSTEM" and AcceptRolls=="true") then
		local msg = ...
		CrossGambling_ParseRoll(tostring(msg));
	end
end


function CrossGambling_ResetStats()
	CrossGambling["stats"] = { };
	CrossGambling["house"] = 0;
	Print("", "", "|cffffff00CG All Stats Have Been Reset!");
end

function Minimap_Toggle()
	if CrossGambling["minimap"] then
		-- minimap is shown, set to false, and hide
		CrossGambling["minimap"] = false
	    CrossGambling_Frame:Show()
	else
		-- minimap is now shown, set to true, and show
		CrossGambling["minimap"] = true
		CrossGambling_Frame:Hide()
	end
end

function CrossGambling_OnClickCHAT()
	if(CrossGambling["chat"] == nil) then CrossGambling["chat"] = 1; end

	CrossGambling["chat"] = (CrossGambling["chat"] % #chatmethods) + 1;

	chatmethod = chatmethods[CrossGambling["chat"]];
	CrossGambling_CHAT_Button:SetText(chatmethod);
end

-- Will work on later 
function CrossGambling_OnClickRoll1()
   if CGEnter.Label:GetText() == "Join Game" then
	ChatMsg("1")
	CGEnter.Label:SetText("Leave Game")
	elseif CGEnter.Label:GetText() == "Leave Game" then
	ChatMsg("-1")
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

function CrossGambling_JoinStats(msg)
	local i = string.find(msg, " ");
	if((not i) or i == -1 or string.find(msg, "[", 1, true) or string.find(msg, "]", 1, true)) then
		ChatFrame1:AddMessage("");
		return;
	end
	local mainname = string.sub(msg, 1, i-1);
	local altname = string.sub(msg, i+1);
	ChatFrame1:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname));
	CrossGambling["joinstats"][altname] = mainname;
end

function CrossGambling_UnjoinStats(altname)
	if(altname ~= nil and altname ~= "") then
		ChatFrame1:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname));
		CrossGambling["joinstats"][altname] = nil;
	else
		local i, e;
		for i, e in pairs(CrossGambling["joinstats"]) do
			ChatFrame1:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e));
		end
	end
end

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
			ChatMsg(string.format("The house has taken %s total.", (CrossGambling["house"])), chatmethod);
		end
		for k = 0,  #sortlistamount do
			local sortsign = "won";
			if(sortlistamount[k] < 0) then sortsign = "lost"; end
			ChatMsg(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), chatmethod);
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
		ChatMsg(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), chatmethod);
	end

	if(x1+1 < x2) then
		ChatMsg("...", chatmethod);
	end

	for i = x2, n-1 do
		sortsign = "won";
		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), chatmethod);
	end
				if (CrossGambling["house"] > 0) then
			ChatMsg(string.format("~The house has taken %s total.~", (CrossGambling["house"])), chatmethod);
		end
		
end

function CrossGambling_OnClickROLL()
	if (totalrolls > 0 and AcceptRolls == "true") then
		if table.getn(CrossGambling.strings) ~= 0 then
			CrossGambling_List();
		end
		return;
	end
	if (totalrolls >1) then
		AcceptOnes = "false";
		AcceptRolls = "true";
		if (tie == 0) then
			ChatMsg("Roll now!");
		end

		if (lowbreak == 1) then
			ChatMsg(format("%s%d%s", "Low end tiebreaker! Roll 1-", theMax, " now!"));
			CrossGambling_List();
		end

		if (highbreak == 1) then
			ChatMsg(format("%s%d%s", "High end tiebreaker! Roll 1-", theMax, " now!"));
			CrossGambling_List();
		end

		CrossGambling_EditBox:ClearFocus();

	end

	if (AcceptOnes == "true" and totalrolls <2) then
		ChatMsg("Not enough Players!");
	end
end

function CrossGambling_OnClickLASTCALL()
	ChatMsg("Last Call to join!");
	CrossGambling_EditBox:ClearFocus();
	RollMe:Enable();
	LastCall:Enable();
	RollGame:Enable();
end

function CrossGambling_OnClickACCEPTONES()
	if CrossGambling_EditBox:GetText() ~= "" and CrossGambling_EditBox:GetText() ~= "1" then
		CrossGambling_Reset();
		RollMe:Disable();
		RollGame:Disable();
		LastCall:Disable();
	    CGEnter.Label:SetText("Join Game")
		AcceptOnes = "true";
		local fakeroll = "";
		if GameMode_Button_Button:GetText() == "< Game Mode >" then
		ChatMsg(format("%s%s%s%s", "CrossGambling: User's Roll - (", CrossGambling_EditBox:GetText(), ") - Type 1 to Join  (-1 to withdraw)", fakeroll));
       CrossGambling["lastroll"] = CrossGambling_EditBox:GetText();
	   	theMax = tonumber(CrossGambling_EditBox:GetText());
	   elseif GameMode_Button_Button:GetText() == "< 501 >" or "< BigTwo >" then
		ChatMsg(format("%s%s", "CrossGambling: User's Roll ", CrossGambling["GameMode1"]));
		ChatMsg(format("%s%s%s%s", "Type 1 to Join -1 to withdraw ", "Current Bet Is ", CrossGambling_EditBox:GetText()," gold"));
		CrossGambling["GameMode"] = CrossGambling["GameMode1"];
		theMax = tonumber(CrossGambling["GameMode1"]);
		end
		low = theMax+1;
		tielow = theMax+1;
		CrossGambling_EditBox:ClearFocus();
	else
		message("Please enter a number to roll from.", chatmethod);
	end
end

function CrossGambling_Report()
	local goldowed = high - low
	local houseCut = 0
	local GameMode2 = ""
	if (CrossGambling["GameMode"]) then
	GameMode2 = floor(CrossGambling_EditBox:GetText())
	goldowed = goldowed - GameMode2
	goldowed = high - low
	CrossGambling["GameMode1"]  = (CrossGambling["GameMode1"] or 0);
	else 
	GameMode2 = floor(goldowed)
	goldowed = high - low
	end
	if (CrossGambling["isHouseCut"]) then
		houseCut = floor(goldowed * (GuildCut:GetText()/100))
		goldowed = goldowed - houseCut
		CrossGambling["house"] = (CrossGambling["house"] or 0) + houseCut;	
	end
	if (goldowed ~= 0) then
		lowname = lowname:gsub("^%l", string.upper)
		highname = highname:gsub("^%l", string.upper)
local string3 = string.format("%s owes %s %s gold! %s ", lowname, highname, (GameMode2), "Congrats");	

	if (CrossGambling["isHouseCut"] and houseCut > 1) then
			string3 = string.format("%s owes %s %s gold and %s gold to the guild bank!", lowname, highname, (GameMode2), (houseCut));
		end

		CrossGambling["stats"][highname] = (CrossGambling["stats"][highname] or 0) + GameMode2;
		CrossGambling["stats"][lowname] = (CrossGambling["stats"][lowname] or 0) - GameMode2;

		ChatMsg(string3);
	else
		ChatMsg("It was a tie! No payouts on this roll!");
	end
end

function CrossGambling_Tiebreaker()
	tierolls = 0;
	totalrolls = 0;
	tie = 1;
	if table.getn(CrossGambling.lowtie) == 1 then
		CrossGambling.lowtie = {};
	end
	if table.getn(CrossGambling.hightie) == 1 then
		CrossGambling.hightie = {};
	end
	totalrolls = table.getn(CrossGambling.lowtie) + table.getn(CrossGambling.hightie);
	tierolls = totalrolls;
	if (table.getn(CrossGambling.hightie) == 0 and table.getn(CrossGambling.lowtie) == 0) then
		CrossGambling_Report();
	else
		AcceptRolls = "false";
		if table.getn(CrossGambling.lowtie) > 0 then
			lowbreak = 1;
			highbreak = 0;
			tielow = theMax+1;
			tiehigh = 0;
			CrossGambling.strings = CrossGambling.lowtie;
			CrossGambling.lowtie = {};
			CrossGambling_OnClickROLL();
		end
		if table.getn(CrossGambling.hightie) > 0  and table.getn(CrossGambling.strings) == 0 then
			lowbreak = 0;
			highbreak = 1;
			tielow = theMax+1;
			tiehigh = 0;
			CrossGambling.strings = CrossGambling.hightie;
			CrossGambling.hightie = {};
			CrossGambling_OnClickROLL();
		end
	end
end

function CrossGambling_ParseRoll(temp2)
	local temp1 = strlower(temp2);

	local player, junk, roll, range = strsplit(" ", temp1);

	if junk == "rolls" and CrossGambling_Check(player)==1 then
		minRoll, maxRoll = strsplit("-",range);
		minRoll = tonumber(strsub(minRoll,2));
		maxRoll = tonumber(strsub(maxRoll,1,-2));
		roll = tonumber(roll);
		if (maxRoll == theMax and minRoll == 1) then
			if (tie == 0) then
				if (roll == high) then
					if table.getn(CrossGambling.hightie) == 0 then
						CrossGambling_AddTie(highname, CrossGambling.hightie);
					end
					CrossGambling_AddTie(player, CrossGambling.hightie);
				end
				if (roll>high) then
					highname = player
					highplayername = player
					if (high == 0) then
						high = roll
						if (whispermethod) then
							ChatMsg(string.format("You have the HIGHEST roll so far: %s and you might win a max of %sg", roll, (high - 1)),"WHISPER",GetDefaultLanguage("player"),player);
						end
					else
						high = roll
						if (whispermethod) then
							ChatMsg(string.format("You have the HIGHEST roll so far: %s and you might win %sg from %s", roll, (high - low), lowplayername),"WHISPER",GetDefaultLanguage("player"),player);
							ChatMsg(string.format("%s now has the HIGHEST roller so far: %s and you might owe him/her %sg", player, roll, (high - low)),"WHISPER",GetDefaultLanguage("player"),lowplayername);
						end
					end
					CrossGambling.hightie = {};

				end
				if (roll == low) then
					if table.getn(CrossGambling.lowtie) == 0 then
						CrossGambling_AddTie(lowname, CrossGambling.lowtie);
					end
					CrossGambling_AddTie(player, CrossGambling.lowtie);
				end
				if (roll<low) then
					lowname = player
					lowplayername = player
					low = roll
					if (high ~= low) then
						if (whispermethod) then
							ChatMsg(string.format("You have the LOWEST roll so far: %s and you might owe %s %sg ", roll, highplayername, (high - low)),"WHISPER",GetDefaultLanguage("player"),player);
						end
					end
					CrossGambling.lowtie = {};

				end
			else
				if (lowbreak == 1) then
					if (roll == tielow) then

						if table.getn(CrossGambling.lowtie) == 0 then
							CrossGambling_AddTie(lowname, CrossGambling.lowtie);
						end
						CrossGambling_AddTie(player, CrossGambling.lowtie);
					end
					if (roll<tielow) then
						lowname = player
						tielow = roll;
						CrossGambling.lowtie = {};

					end
				end
				if (highbreak == 1) then
					if (roll == tiehigh) then
						if table.getn(CrossGambling.hightie) == 0 then
							CrossGambling_AddTie(highname, CrossGambling.hightie);
						end
						CrossGambling_AddTie(player, CrossGambling.hightie);
					end
					if (roll>tiehigh) then
						highname = player
						tiehigh = roll;
						CrossGambling.hightie = {};

					end
				end
			end
			CrossGambling_Remove(tostring(player));
			totalentries = totalentries + 1;

			if table.getn(CrossGambling.strings) == 0 then
				if tierolls == 0 then
					CrossGambling_Report();
				else
					if totalentries == 2 then
						CrossGambling_Report();
					else
						CrossGambling_Tiebreaker();
					end
				end
			end
		end
	end
end

function CrossGambling_Check(player)
	for i=1, table.getn(CrossGambling.strings) do
		if strlower(CrossGambling.strings[i]) == tostring(player) then
			return 1
		end
	end
	return 0
end

function CrossGambling_List()
	for i=1, table.getn(CrossGambling.strings) do
	  	local string3 = strjoin(" ", "", tostring(CrossGambling.strings[i]):gsub("^%l", string.upper),"still needs to roll.")
		ChatMsg(string3);
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

function CrossGambling_ToggleHouse()
	if (CrossGambling["isHouseCut"]) then
		CrossGambling["isHouseCut"] = false
		 CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)");
		Print("", "", "|cffffff00Guild cut has been turned off.");
	else
		CrossGambling["isHouseCut"] = true
		 CrossGambling_HouseCut.Label:SetText("Guild Cut (ON)");
		Print("", "", "|cffffff00Guild cut has been turned on.");
	end
end

function CrossGambling_Add(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local found = 0;
		for i=1, table.getn(CrossGambling.strings) do
		  	if CrossGambling.strings[i] == insname then
				found = 1;
			end
        	end
		if found == 0 then
		      	table.insert(CrossGambling.strings, insname)
			totalrolls = totalrolls+1
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

function CrossGambling_Reset()
		CrossGambling["strings"] = { };
		CrossGambling["lowtie"] = { };
		CrossGambling["hightie"] = { };
		AcceptOnes = "false"
		AcceptRolls = "false"
		totalrolls = 0
		theMax = 0
		tierolls = 0;
		lowname = ""
		highname = ""
		low = theMax
		high = 0
		tie = 0
		lastroll = 100;
		highbreak = 0;
		lowbreak = 0;
		tiehigh = 0;
		tielow = 0;
		totalentries = 0;
		highplayername = "";
		lowplayername = "";
		RollGame:Disable();
		LastCall:Disable();
		Print("", "", "|cffffff00CG has now been reset");
end

