CrossGambling1 = LibStub("AceAddon-3.0"):NewAddon("CrossGambling1")
local CrossGambling1	= LibStub("AceAddon-3.0"):GetAddon("CrossGambling1")
local AcceptOnes = "false";
local AcceptRolls = "false";
local HousePercent = 10;
local Test = 100; 
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
	"RAID",
	"PARTY",
	"GUILD",
	"CHANNEL"
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
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetBackdropColor(0.21, 0.21, 0.21)
end

local SetTemplateDark = function(self)
	self:SetBackdrop(Backdrop)
	self:SetBackdropBorderColor(0, 0, 1)
	self:SetBackdropColor(0.12, 0.12, 0.12)
end


local GUI = CreateFrame("Frame", "CrossGambling_Frame", UIParent)
GUI:SetSize(227, 108) 
GUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
SetTemplate(GUI)
GUI:SetMovable(true)
GUI:EnableMouse(true)
GUI:SetUserPlaced(true)
GUI:RegisterForDrag("LeftButton")
GUI:SetScript("OnDragStart", GUI.StartMoving)
GUI:SetScript("OnDragStop", GUI.StopMovingOrSizing)

GUI:Hide()

local Top = CreateFrame("Frame", nil, GUI)
Top:SetSize(GUI:GetSize(), 21) -- Default is 228, 21
Top:SetPoint("BOTTOM", GUI, "TOP", 0, -1)
SetTemplateDark(Top)

GUI.TopLabel = Top:CreateFontString(nil, "OVERLAY")
GUI.TopLabel:SetPoint("TOPLEFT", Top, "TOPLEFT", 4, -4)
GUI.TopLabel:SetFont(Font, 16)
GUI.TopLabel:SetTextColor(unpack(FontColor))
GUI.TopLabel:SetShadowOffset(1.25, -1.25)
GUI.TopLabel:SetShadowColor(0, 0, 0)

-- Admin panel
local Admin = CreateFrame("Frame", "CrossGambleAdmin", GUI)
Admin:SetSize(112, 128) --Original Size: 120, 96
Admin:SetPoint("BOTTOMLEFT", GUI, "TOPLEFT", -111, -128)
SetTemplate(Admin)
Admin:Hide()

local AdminTop = CreateFrame("Frame", nil, Admin)
AdminTop:SetSize(Admin:GetSize(), 21)
AdminTop:SetPoint("BOTTOM", Admin, "TOP", 0, -1)
SetTemplateDark(AdminTop)

AdminTop.TopLabel = AdminTop:CreateFontString(nil, "OVERLAY")
AdminTop.TopLabel:SetPoint("CENTER", AdminTop, "CENTER", 0, -1)
AdminTop.TopLabel:SetFont(Font, 16)
AdminTop.TopLabel:SetTextColor(unpack(FontColor))
AdminTop.TopLabel:SetText("CrossGambling")
AdminTop.TopLabel:SetShadowOffset(1.25, -1.25)
AdminTop.TopLabel:SetShadowColor(0, 0, 0)

local Admin2 = CreateFrame("Frame", "CrossGambleAdmin", GUI)
Admin2:SetSize(112, 128) --Original Size: 120, 96
Admin2:SetPoint("BOTTOMLEFT", GUI, "TOPRIGHT", 0, -128)
SetTemplate(Admin2)
Admin2:Hide()

local Admin2Top = CreateFrame("Frame", nil, Admin2)
Admin2Top:SetSize(Admin2:GetSize(), 21)
Admin2Top:SetPoint("BOTTOM", Admin2, "TOP", 0, -1)
SetTemplateDark(Admin2Top)

Admin2Top.TopLabel = Admin2Top:CreateFontString(nil, "OVERLAY")
Admin2Top.TopLabel:SetPoint("CENTER", Admin2Top, "CENTER", 0, -1)
Admin2Top.TopLabel:SetFont(Font, 16)
Admin2Top.TopLabel:SetTextColor(unpack(FontColor))
Admin2Top.TopLabel:SetShadowOffset(1.25, -1.25)
Admin2Top.TopLabel:SetShadowColor(0, 0, 0)



-- Commands panel

-----------------------
--    USER BUTTONS   --
-----------------------

-- Button Enter and Button Leave Functions
local ButtonOnEnter = function(self)
	self:SetBackdropColor(0.17, 0.17, 0.17)
	SetTemplateDark(GameTooltip)
	GameTooltip:SetOwner(AdminTop, "ANCHOR_BOTTOMLEFT", -2, 21)
end

local ButtonOnLeave = function(self)
	self:SetBackdropColor(0.12, 0.12, 0.12)
	GameTooltip:Hide()
end

-- Enter Button
EnterButton = CreateFrame("Frame", "CrossGambleJoinButton", GUI)
EnterButton:SetSize(63, 21)
EnterButton:SetPoint("LEFT", Top, 20, 0)
SetTemplateDark(EnterButton)
EnterButton:SetScript("OnEnter", ButtonOnEnter)
EnterButton:SetScript("OnLeave", ButtonOnLeave)
EnterButton:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickRoll1()
end)



EnterButton.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

EnterButton.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

EnterButton.Label = EnterButton:CreateFontString(nil, "OVERLAY")
EnterButton.Label:SetPoint("CENTER", EnterButton, 0, 0)
EnterButton.Label:SetFont(Font, 14)
EnterButton.Label:SetJustifyH("CENTER")
EnterButton.Label:SetTextColor(unpack(FontColor))
EnterButton.Label:SetText("     Join Game")
EnterButton.Label:SetShadowOffset(1.25, -1.25)
EnterButton.Label:SetShadowColor(0, 0, 0)


CG_MinimapButton = CreateFrame("Frame", "CrossGambleJoinButton", GUI)
CG_MinimapButton:SetSize(63, 21)
CG_MinimapButton:SetPoint("LEFT", Top, 20, 0)
SetTemplateDark(CG_MinimapButton)
CG_MinimapButton:SetScript("OnEnter", ButtonOnEnter)
CG_MinimapButton:SetScript("OnLeave", ButtonOnLeave)
CG_MinimapButton:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickRoll1()
end)



CG_MinimapButton.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

CG_MinimapButton.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

CG_MinimapButton.Label = CG_MinimapButton:CreateFontString(nil, "OVERLAY")
CG_MinimapButton.Label:SetPoint("CENTER", CG_MinimapButton, 0, 0)
CG_MinimapButton.Label:SetFont(Font, 14)
CG_MinimapButton.Label:SetJustifyH("CENTER")
CG_MinimapButton.Label:SetTextColor(unpack(FontColor))
CG_MinimapButton.Label:SetText("     Join Game")
CG_MinimapButton.Label:SetShadowColor(0, 0, 0)
CG_MinimapButton.Label:SetShadowOffset(1.25, -1.25)

-- Pass Button
PassButton = CreateFrame("Frame", "CrossGamblePassButton", GUI)
PassButton:SetSize(63, 21)
PassButton:SetPoint("LEFT", EnterButton, "RIGHT", 40, 0)
SetTemplateDark(PassButton)
PassButton:SetScript("OnEnter", ButtonOnEnter)
PassButton:SetScript("OnLeave", ButtonOnLeave)
PassButton:SetScript("OnMouseUp", function(self)
      CrossGambling_OnClickRoll2()
end)

PassButton.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

PassButton.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

PassButton.Label = PassButton:CreateFontString(nil, "OVERLAY")
PassButton.Label:SetPoint("CENTER", PassButton, 0, 0)
PassButton.Label:SetFont(Font, 14)
PassButton.Label:SetJustifyH("CENTER")
PassButton.Label:SetTextColor(unpack(FontColor))
PassButton.Label:SetText("|     Leave Game")
PassButton.Label:SetShadowOffset(1.25, -1.25)
PassButton.Label:SetShadowColor(0, 0, 0)



CHAT = CreateFrame("Frame", nil, GUI)
CHAT:SetSize(228, 21)
CHAT:SetPoint("TOPLEFT", GUI, "CENTER", -114, 90)
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


local Bottom = CreateFrame("Frame", nil, GUI)
Bottom:SetSize(GUI:GetSize(), 21) -- Default is 228
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

-- Editbox
local EditBoxDown = function(self)
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

local EditBoxOnEnterPressed2 = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (Value == "" or Value == " ") then
		self:SetText(CurrentRollValue)

		return
	end
end


------------------------
--    ADMIN BUTTONS   --
------------------------


local EditBox = CreateFrame("Frame", nil, Admin)
EditBox:SetPoint("TOPLEFT", Admin, 3, -3)
EditBox:SetSize(Admin:GetSize()-6, 21)
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
CrossGambling_EditBox:SetScript("OnMouseDown", EditBoxOnMouseDown)
CrossGambling_EditBox:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
CrossGambling_EditBox:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
CrossGambling_EditBox:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)


-- New Game Button

AcceptRolls = CreateFrame("Frame", nil, Admin)
AcceptRolls:SetSize(Admin:GetSize()-6, 21)
AcceptRolls:SetPoint("TOPLEFT", EditBox, "BOTTOMLEFT", 0, -2)
SetTemplateDark(AcceptRolls)
AcceptRolls:SetScript("OnEnter", ButtonOnEnter)
AcceptRolls:HookScript("OnEnter", function(self)


end)
AcceptRolls:SetScript("OnLeave", ButtonOnLeave)
AcceptRolls:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickACCEPTONES()
	CrossGambling["Test"] = false; 
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

LastCall = CreateFrame("Frame", nil, Admin)
LastCall:SetSize(Admin:GetSize()-6, 21)
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


-- Close
RollGame = CreateFrame("Frame", nil, Admin)
RollGame:SetSize(Admin:GetSize()-6, 21)
RollGame:SetPoint("TOPLEFT", LastCall, "BOTTOMLEFT", 0, -2)
SetTemplateDark(RollGame)
RollGame:SetScript("OnEnter", ButtonOnEnter)
RollGame:HookScript("OnEnter", function(self)
	GameTooltip:SetText("Start Rolling")
	GameTooltip:AddLine("Step 2. Closes entry to the game and allows users to roll.", 1, 1, 1, true)
	GameTooltip:Show()
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

-- Reset
Reset = CreateFrame("Frame", nil, Admin)
Reset:SetSize(Admin:GetSize()-6, 21)
Reset:SetPoint("TOPLEFT", RollGame, "BOTTOMLEFT", 0, -2)
SetTemplateDark(Reset)
Reset:SetScript("OnEnter", ButtonOnEnter)
Reset:HookScript("OnEnter", function(self)
end)
Reset:SetScript("OnLeave", ButtonOnLeave)
Reset:SetScript("OnMouseUp", function(self)
	CrossGambling_ROLL()
end)

Reset.Label = Reset:CreateFontString(nil, "OVERLAY")
Reset.Label:SetPoint("CENTER", Reset, 0, 0)
Reset.Label:SetFont(Font, 14)
Reset.Label:SetJustifyH("CENTER")
Reset.Label:SetTextColor(unpack(FontColor))
Reset.Label:SetText("Reset Game")
Reset.Label:SetShadowOffset(1.25, -1.25)
Reset.Label:SetShadowColor(0, 0, 0)

RollGame:Disable()
LastCall:Disable()
EnterButton:Enable()
PassButton:Enable()


-- Chat window
local ChatFrame = CreateFrame("Frame", nil, GUI)
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

-- Editbox
local EditBox2Down = function(self)
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
  --print("DEBUG | EBOnEnPressed | PName: ", PlayerName, " // PClass: ", PlayerClass, " // Value: ", Value)

	self:SetText("|cffB0B0B0Chat...|r")
end

local EditBoxOnEnterPressed2 = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (Value == "" or Value == " ") then
		self:SetText("|cffB0B0B0Chat...|r")

		return
	end

end

local ButtonOnEnter = function(self)
	self:SetBackdropColor(0.17, 0.17, 0.17)
	SetTemplateDark(GameTooltip)
	GameTooltip:SetOwner(Admin2Top, "ANCHOR_BOTTOMRIGHT", -2, 21)
end

GameMode = CreateFrame("Frame", nil, Admin2)
GameMode:SetSize(112, 10)
GameMode:SetPoint("CENTER", Admin2Top, "CENTER", 0, -1)
SetTemplateDark(GameMode)
GameMode:SetScript("OnEnter", ButtonOnEnter)
GameMode:HookScript("OnEnter", function(self)
	GameTooltip:SetText("GameModes")
    GameTooltip:AddLine("Change Game Mode", 1, 1, 1, true)
    GameTooltip:Show()
end)
GameMode:SetScript("OnLeave", ButtonOnLeave)
GameMode:SetScript("OnMouseUp", function(self)
CrossGambling_GameMode()
end)

GameMode_Button = GameMode:CreateFontString(nil, "OVERLAY")
GameMode_Button:SetPoint("CENTER", GameMode, 0, 0)
GameMode_Button:SetFont(Font, 14)
GameMode_Button:SetJustifyH("CENTER")
GameMode_Button:SetTextColor(unpack(FontColor))
GameMode_Button:SetText("Munty's Casino")
GameMode_Button:SetShadowOffset(1.25, -1.25)
GameMode_Button:SetShadowColor(0, 0, 0)

local EditBox = CreateFrame("Frame", nil, Admin2)
EditBox:SetPoint("TOPLEFT", Admin2, 3, -3)
EditBox:SetSize(Admin2:GetSize()-6, 21)
SetTemplateDark(EditBox)
EditBox:EnableMouse(true)

CrossGambling_EditBox2 = CreateFrame("EditBox", nil, EditBox)
CrossGambling_EditBox2:SetPoint("CENTER", EditBox, 0, 0)
CrossGambling_EditBox2:SetPoint("BOTTOMRIGHT", EditBox, -4, 2)
CrossGambling_EditBox2:SetFont(Font, 16)
CrossGambling_EditBox2:SetText("501")
CrossGambling_EditBox2:SetShadowColor(0, 0, 0)
CrossGambling_EditBox2:SetShadowOffset(1.25, -1.25)
CrossGambling_EditBox2:SetMaxLetters(6)
CrossGambling_EditBox2:SetAutoFocus(false)
CrossGambling_EditBox2:SetNumeric(true)
CrossGambling_EditBox2:EnableKeyboard(false)
CrossGambling_EditBox2:EnableMouse(false)
CrossGambling_EditBox2:SetScript("OnMouseDown", EditBoxOnMouseDown)
CrossGambling_EditBox2:SetScript("OnEscapePressed", EditBoxOnEscapePressed)
CrossGambling_EditBox2:SetScript("OnEnterPressed", EditBoxOnEnterPressed2)
CrossGambling_EditBox2:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)


AcceptRolls = CreateFrame("Frame", nil, Admin2)
AcceptRolls:SetSize(Admin2:GetSize()-6, 21)
AcceptRolls:SetPoint("TOPLEFT", EditBox, "BOTTOMLEFT", 0, -2)
SetTemplateDark(AcceptRolls)
AcceptRolls:SetScript("OnEnter", ButtonOnEnter)
AcceptRolls:HookScript("OnEnter", function(self)

end)
AcceptRolls:SetScript("OnLeave", ButtonOnLeave)
AcceptRolls:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickACCEPT501()
	CrossGambling["Test"] = true;
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


CrossGambling_HouseCut = CreateFrame("Frame", nil, Admin2)
CrossGambling_HouseCut:SetSize(Admin2:GetSize()-6, 21)
CrossGambling_HouseCut:SetPoint("TOPLEFT", Admin2, 3, -105)
SetTemplateDark(CrossGambling_HouseCut)
CrossGambling_HouseCut:SetScript("OnEnter", ButtonOnEnter)
CrossGambling_HouseCut:HookScript("OnEnter", function(self)
	GameTooltip:SetText("Guild Cut")
    GameTooltip:AddLine("Sets The Guild Cut to 10%", 1, 1, 1, true)
    GameTooltip:Show()

end)
CrossGambling_HouseCut:SetScript("OnLeave", ButtonOnLeave)
CrossGambling_HouseCut:SetScript("OnMouseUp", function(self)
	CrossGambling_ToggleHouse()
end)

CrossGambling_HouseCut.Disable = function(self)
	self.Label:SetTextColor(0.3, 0.3, 0.3)
	self:EnableMouse(false)
end

CrossGambling_HouseCut.Enable = function(self)
	self.Label:SetTextColor(unpack(FontColor))
	self:EnableMouse(true)
end

CrossGambling_HouseCut.Label = CrossGambling_HouseCut:CreateFontString(nil, "OVERLAY")
CrossGambling_HouseCut.Label:SetPoint("CENTER", CrossGambling_HouseCut, 0, 0)
CrossGambling_HouseCut.Label:SetFont(Font, 14)
CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)")
CrossGambling_HouseCut.Label:SetJustifyH("CENTER")
CrossGambling_HouseCut.Label:SetTextColor(unpack(FontColor))



CrossGambling_HouseCut.Label:SetShadowOffset(1.25, -1.25)
CrossGambling_HouseCut.Label:SetShadowColor(0, 0, 0)


-- Chat toggle

local AdminToggle = CreateFrame("Button", nil, GUI)
AdminToggle:SetSize(21, 21)
AdminToggle:SetPoint("TOPRIGHT", Top, "TOPRIGHT", 0, 0)
AdminToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(AdminToggle)
AdminToggle:SetScript("OnMouseUp", function(self)
	if self.NeedsReset then
		self.Arrow:SetTextColor(1, 1, 1)
		self.NeedsReset = false
	end

	if Admin2:IsShown() then
		Admin2:Hide()
		self.Arrow:SetText("►")
		
	else
		Admin2:Show()
		self.Arrow:SetText("◄")
	end
end)

AdminToggle.Arrow = AdminToggle:CreateFontString(nil, "OVERLAY")
AdminToggle.Arrow:SetPoint("CENTER", AdminToggle, "CENTER", 0, 0)
AdminToggle.Arrow:SetFont("Interface\\AddOns\\CrossGambling\\Media\\Arial.ttf", 12)
AdminToggle.Arrow:SetTextColor(unpack(FontColor))
AdminToggle.Arrow:SetText("►")
AdminToggle.Arrow:SetShadowOffset(1.25, -1.25)
AdminToggle.Arrow:SetShadowColor(0, 0, 0)

-- Admin Toggle
local AdminToggle = CreateFrame("Button", nil, Top)
AdminToggle:SetSize(21, 21)
AdminToggle:SetPoint("TOPLEFT", Top, "TOPLEFT", 0, 0)
AdminToggle:SetFrameStrata("MEDIUM")
SetTemplateDark(AdminToggle)
AdminToggle:SetScript("OnMouseUp", function(self)
	if Admin:IsShown() then
		Admin:Hide()
		self.Arrow:SetText("◄")
		
	else
		Admin:Show()
		self.Arrow:SetText("►")
	
	end
end)

AdminToggle.Arrow = AdminToggle:CreateFontString(nil, "OVERLAY")
AdminToggle.Arrow:SetPoint("CENTER", AdminToggle, "CENTER", 1, 0)
AdminToggle.Arrow:SetFont("Interface\\AddOns\\CrossGambling\\Media\\Arial.ttf", 12)
AdminToggle.Arrow:SetTextColor(unpack(FontColor))
AdminToggle.Arrow:SetText("◄")
AdminToggle.Arrow:SetShadowOffset(1.25, -1.25)
AdminToggle.Arrow:SetShadowColor(0, 0, 0)

-- Exit Button

local Close = CreateFrame("Button", nil, Top)
Close:SetSize(21, 21)
Close:SetPoint("BOTTOMRIGHT", Bottom, "BOTTOMRIGHT", 0, 0)
Close:SetFrameStrata("MEDIUM")
SetTemplateDark(Close)
Close:SetScript("OnMouseUp", function(self)
	GUI:Hide()
end)
Close:SetScript("OnEnter", function(self) self.X:SetTextColor(1, 0.1, 0.1) end)
Close:SetScript("OnLeave", function(self) self.X:SetTextColor(unpack(FontColor)) end)

Close.X = Close:CreateFontString(nil, "OVERLAY")
Close.X:SetPoint("CENTER", Close, "CENTER", 0.5, -1)
Close.X:SetFont(Font, 16)
Close.X:SetTextColor(unpack(FontColor))
Close.X:SetText("×")
Close.X:SetShadowOffset(1.25, -1.25)
Close.X:SetShadowColor(0, 0, 0)

-- View Stats Button

local ViewStats = CreateFrame("Button", nil, Bottom)
ViewStats:SetSize(21, 21)
ViewStats:SetPoint("BOTTOMLEFT", Bottom, "BOTTOMLEFT", 0, 0)
ViewStats:SetFrameStrata("MEDIUM")
SetTemplateDark(ViewStats)
ViewStats:SetScript("OnMouseUp", function(self)
	CrossGambling_OnClickSTATS(full)
end)
ViewStats:SetScript("OnEnter", function(self) self.X:SetTextColor(1, 0.1, 0.1) end)
ViewStats:SetScript("OnLeave", function(self) self.X:SetTextColor(unpack(FontColor)) end)

ViewStats.X = ViewStats:CreateFontString(nil, "OVERLAY")
ViewStats.X:SetPoint("CENTER", ViewStats, "CENTER", 1, -1)
ViewStats.X:SetFont(Font, 16)
ViewStats.X:SetTextColor(unpack(FontColor))
ViewStats.X:SetText("+")
ViewStats.X:SetShadowOffset(1.25, -1.25)
ViewStats.X:SetShadowColor(0, 0, 0)


-- Debug Stuff. Will be cleaned up.

__IGAdd = AddPlayer
__IGRem = RemovePlayer
__IGRoll = PlayerRoll




function CrossGambling_OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Cross Gambling for Warcraft 8.2.5 and Classic!> loaded /cg to use");

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
	
	-- Member Initializers
	local defaults = {
	    global = {
			minimap = {
				hide = false,
			}
		}
	}
    self.db = LibStub("AceDB-3.0"):New("CrossGambling", defaults)
	-- Register with the minimap icon frame
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





function CrossGambling_ROLL()
  if not reset_dialog then
   local Reset = CreateFrame("Frame", "CrossGambling_Frame", UIParent)
Reset:SetSize(300, 80) 
Reset:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
SetTemplate(Reset)
Reset:SetMovable(true)
Reset:EnableMouse(true)
Reset:SetUserPlaced(true)
Reset:RegisterForDrag("LeftButton")
Reset:SetScript("OnDragStart", Reset.StartMoving)
Reset:SetScript("OnDragStop", Reset.StopMovingOrSizing)
Reset:Hide()

local Top = CreateFrame("Frame", nil, Reset)
Top:SetSize(Reset:GetSize(), 21) -- Default is 228, 21
Top:SetPoint("BOTTOM", Reset, "TOP", 0, -1)
SetTemplateDark(Top)

Reset.TopLabel = Top:CreateFontString(nil, "OVERLAY")
Reset.TopLabel:SetPoint("CENTER", Top, "CENTER", 10, -4)
Reset.TopLabel:SetFont(Font, 16)
Reset.TopLabel:SetText("CrossGambling")
Reset.TopLabel:SetTextColor(unpack(FontColor))
Reset.TopLabel:SetShadowOffset(1.25, -1.25)
Reset.TopLabel:SetShadowColor(0, 0, 0)



Reset:RegisterForDrag('LeftButton')
Reset:SetScript('OnDragStart', function(Reset) Reset:StartMoving() end)
Reset:SetScript('OnDragStop', function(Reset) Reset:StopMovingOrSizing() end)

    local desc = Reset:CreateFontString("ARTWORK")
    desc:SetFontObject("GameFontHighlight")
    desc:SetJustifyV("TOP")
    desc:SetJustifyH("LEFT")
    desc:SetPoint("CENTER", 18, -42)
    desc:SetPoint("BOTTOMRIGHT", -18, 48)
    desc:SetText("Are you sure you want to Reset all stats?")

    local yes_button = CreateFrame("CheckButton", "Yes", Reset, "OptionsButtonTemplate")
	SetTemplateDark(Bottom)
    getglobal(yes_button:GetName() .. "Text"):SetText("Yes")

    yes_button:SetScript("OnClick", function(self)
      print("Stats Reset")
      CrossGambling_ResetStats();
	  CrossGambling_Reset();
      reset_dialog:Hide()
    end)

    local no_button = CreateFrame("CheckButton", "No", Reset, "OptionsButtonTemplate")
    getglobal(no_button:GetName() .. "Text"):SetText("No")

    no_button:SetScript("OnClick", function(self)
	print("Game Reset")
	CrossGambling_Reset();
      reset_dialog:Hide()
    end)
    --position buttons
    yes_button:SetPoint("BOTTOMRIGHT", -180, 14)
    no_button:SetPoint("BOTTOMRIGHT", -45, 14)
    reset_dialog = Reset
  end
  reset_dialog:Show()
end



local function ChatMsg(msg, chatType, language, channel)
	chatType = chatType or chatmethod
	channelnum = GetChannelName(channel or CrossGambling["channel"] or "gambling")
	SendChatMessage(msg, chatType, language, channelnum)
end

function hide_from_xml()
	CrossGambling_SlashCmd("hide")
	CrossGambling["active"] = 0;
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
	if (msg == "minimap") then
		Minimap_Toggle()
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
			if (not LastCall:Disable() and totalrolls == 1) then
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
			LastCall:Enable();
		end
		if totalrolls == 1 then
			LastCall:Enable();
			AcceptRolls:Enable();
			AcceptRolls:SetText("Open Entry");
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
		CrossGambling_EditBox2:SetJustifyH("CENTER");
		if(not CrossGambling) then
			CrossGambling = {
				["active"] = 0,
				["chat"] = 1,
				["channel"] = "gambling",
				["whispers"] = false,
				["strings"] = { },
				["lowtie"] = { },
				["hightie"] = { },
				["bans"] = { },
				
			}
		-- fix older legacy items for new chat channels.  Probably need to iterate through each to see if it should be set.
		elseif tostring(type(CrossGambling["chat"])) ~= "number" then
			CrossGambling["chat"] = 1
		end
		if(not CrossGambling["lastroll"]) then CrossGambling["lastroll"] = 100; end
		if(not CrossGambling["Test1"]) then CrossGambling["Test1"] = 501; end
		if(not CrossGambling["Test"]) then CrossGambling["Test"] = false; end
		if(not CrossGambling["stats"]) then CrossGambling["stats"] = { }; end
		if(not CrossGambling["joinstats"]) then CrossGambling["joinstats"] = { }; end
		if(not CrossGambling["chat"]) then CrossGambling["chat"] = 1; end
		if(not CrossGambling["channel"]) then CrossGambling["channel"] = "gambling"; end
		if(not CrossGambling["whispers"]) then CrossGambling["whispers"] = false; end
		if(not CrossGambling["bans"]) then CrossGambling["bans"] = { }; end
		if(not CrossGambling["house"]) then CrossGambling["house"] = 0; end
		if(not CrossGambling["isHouseCut"]) then CrossGambling["isHouseCut"] = false; end
        
		

		CrossGambling_EditBox2:SetText(""..CrossGambling["Test1"]);
		CrossGambling_EditBox:SetText(""..CrossGambling["lastroll"]);
		chatmethod = chatmethods[CrossGambling["chat"]];
		CrossGambling_CHAT_Button:SetText(chatmethod); 


		if CrossGambling["minimap"] then
			-- show minimap
			CrossGambling_Frame:Show()
		else
			CrossGambling_Frame:Hide()
		end


		if(CrossGambling["whispers"] == false) then

			whispermethod = false;
		else
			CrossGambling_WHISPER_Button:SetText("(Whispers)");
			whispermethod = true;
		end
		if(CrossGambling["active"] == 1) then
			GUI:Show();
		else
		GUI:Hide();

		
			
		end
	end

	-- IF IT'S A RAID MESSAGE... --
	if ((event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and AcceptOnes=="true" and CrossGambling["chat"] == 1) then
		local msg, _,_,_,name = ... -- name no realm
		CrossGambling_ParseChatMsg(msg, name)
	end

	if ((event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_PARTY")and AcceptOnes=="true" and CrossGambling["chat"] == 2) then
		local msg, name = ... -- name no realm
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
end




function Minimap_Toggle()
	if CrossGambling["minimap"] then
		-- minimap is shown, set to false, and hide
		CrossGambling["minimap"] = false
		CrossGambling_Frame:Hide()
	else
		-- minimap is now shown, set to true, and show
		CrossGambling["minimap"] = true
		CrossGambling_Frame:Show()
	end
end

function CrossGambling_OnClickCHAT()
	if(CrossGambling["chat"] == nil) then CrossGambling["chat"] = 1; end

	CrossGambling["chat"] = (CrossGambling["chat"] % #chatmethods) + 1;

	chatmethod = chatmethods[CrossGambling["chat"]];
	CrossGambling_CHAT_Button:SetText(chatmethod);
end

-- Will work on later 

function CrossGambling_GameMode()
if(CrossGambling["Test"] == false) then
 GameMode_Button:SetText("< BigTwo >");
 CrossGambling_EditBox2:SetText("2");
 CrossGambling["isHouseCut"] = false
  CrossGambling_HouseCut.Label:SetText("Guild Cut (OFF)");
		Print("", "", "|cffffff00Guild cut has been turned off.");
 else
 GameMode_Button:SetText("< Munty's Casino >");
  CrossGambling_EditBox2:SetText("501");
end
end

function CrossGambling_OnClickWHISPERS()
	if(CrossGambling["whispers"] == nil) then CrossGambling["whispers"] = false; end

	CrossGambling["whispers"] = not CrossGambling["whispers"];

	if(CrossGambling["whispers"] == false) then
		CrossGambling_WHISPER_Button:SetText("(No Whispers)");
		whispermethod = false;
	else
		CrossGambling_WHISPER_Button:SetText("(Whispers)");
		whispermethod = true;
	end
end

function CrossGambling_ChangeChannel(channel)
	CrossGambling["channel"] = channel
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
		for k = 0,  #sortlistamount do
			local sortsign = "won";
			if(sortlistamount[k] < 0) then sortsign = "lost"; end
			ChatMsg(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), chatmethod);
		end

		if (CrossGambling["house"] > 0) then
			ChatMsg(string.format("The house has taken %s total.", (CrossGambling["house"])), chatmethod);
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
	LastCall:Enable();
	RollGame:Enable();
end

function CrossGambling_OnClickACCEPTONES()
	if CrossGambling_EditBox:GetText() ~= "" and CrossGambling_EditBox:GetText() ~= "1" then
		CrossGambling_Reset();
		RollGame:Disable();
		LastCall:Disable();
		AcceptOnes = "true";
		local fakeroll = "";
		ChatMsg(format("%s%s%s%s", "CrossGambling:. User's Roll - (", CrossGambling_EditBox:GetText(), ") - Type 1 to Join  (-1 to withdraw)", fakeroll));
        CrossGambling["lastroll"] = CrossGambling_EditBox:GetText();
		theMax = tonumber(CrossGambling_EditBox:GetText());
		low = theMax+1;
		tielow = theMax+1;
		CrossGambling_EditBox:ClearFocus();
		LastCall:Disable();
		CrossGambling_EditBox:ClearFocus();
	else
		message("Please enter a number to roll from.", chatmethod);
	end
end

function CrossGambling_OnClickACCEPT501()
	if CrossGambling_EditBox2:GetText() ~= "" and CrossGambling_EditBox2:GetText() ~= "1" then
		CrossGambling_Reset();
		RollGame:Enable();
		LastCall:Enable();
		AcceptOnes = "true";
		local fakeroll = "";
		ChatMsg(format("%s%s", "CrossGambling(Muntys Casino): User's Roll ", CrossGambling_EditBox2:GetText()));
		ChatMsg(format("%s%s%s%s", "Type 1 to Join -1 to withdraw ", "Current Bet Is ", CrossGambling_EditBox:GetText()," gold"));
		CrossGambling["Test"] = CrossGambling_EditBox2:GetText();
		theMax = tonumber(CrossGambling_EditBox2:GetText());
		low = theMax+1;
		tielow = theMax+1;
		CrossGambling_EditBox2:ClearFocus();
		LastCall:Disable();
		CrossGambling_EditBox2:ClearFocus();
	else
		message("Please enter a number to roll from.", chatmethod);
	end
end


function CrossGambling_OnClickRoll1()
	ChatMsg("1");
end
function CrossGambling_OnClickRoll2()
	ChatMsg("-1");
end

CG_Settings = {
	MinimapPos = 75

}


-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
function CG_MinimapButton_Reposition()
	CG_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(CG_Settings.MinimapPos)),(80*sin(CG_Settings.MinimapPos))-52)
end


function CG_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70
	ypos = ypos/UIParent:GetScale()-ymin-70

	CG_Settings.MinimapPos = math.deg(math.atan2(ypos,xpos))
	CG_MinimapButton_Reposition()
end


function CG_MinimapButton_OnClick()
	DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1).." was clicked.")
end

function CrossGambling_Report()
	local goldowed = high - low
	local houseCut = 0
	local Test2 = ""
	if (CrossGambling["Test"]) then
	Test2 = floor(CrossGambling_EditBox:GetText())
	goldowed = goldowed - Test2
	goldowed = high - low
	CrossGambling["Test1"]  = (CrossGambling["Test1"] or 0);
	else 
	Test2 = floor(goldowed)
	goldowed = high - low
	end
	if (CrossGambling["isHouseCut"]) then
		houseCut = floor(goldowed * (HousePercent/100))
		goldowed = goldowed - houseCut
		CrossGambling["house"] = (CrossGambling["house"] or 0) + houseCut;	
	end
	if (goldowed ~= 0) then
		lowname = lowname:gsub("^%l", string.upper)
		highname = highname:gsub("^%l", string.upper)
local string3 = string.format("%s owes %s %s gold! %s ", lowname, highname, (Test2), "Congrats");	

	if (CrossGambling["isHouseCut"] and houseCut > 1) then
			string3 = string.format("%s owes %s %s gold and %s gold to the guild bank!", lowname, highname, (Test2), (houseCut));
		end

		CrossGambling["stats"][highname] = (CrossGambling["stats"][highname] or 0) + Test2;
		CrossGambling["stats"][lowname] = (CrossGambling["stats"][lowname] or 0) - Test2;

		ChatMsg(string3);
	else
		ChatMsg("It was a tie! No payouts on this roll!");
	end
end



function CrossGambling_Report2()
print(name,"rolled a",roll,"out of",minRoll,"to",maxRoll)


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

function CrossGambling_ResetCmd()
	ChatMsg(".:CrossGambling:. Game has been reset", chatmethod)
end

function CrossGambling_EditBox_OnLoad()
    CrossGambling_EditBox:SetNumeric(true);
	CrossGambling_EditBox:SetAutoFocus(false);

end

function CrossGambling_EditBox_OnEnterPressed()
    CrossGambling_EditBox:ClearFocus();
	lastroll = "";
end
