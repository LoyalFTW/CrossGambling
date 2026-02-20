local CGPlayers = {}
local CG = "Interface\\AddOns\\CrossGambling\\media\\CG.tga"
local Backdrop = {
	bgFile = CG,
	edgeFile = CG,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {left = 1, right = 1, top = 1, bottom = 1},

}
local frameColor = {r = 0.27, g = 0.27, b = 0.27}
local buttonColor = {r = 0.30, g = 0.30, b = 0.30}
local sideColor = {r = 0.20, g = 0.20, b = 0.20}
local playerNameColor = "|c" .. RAID_CLASS_COLORS[select(2, UnitClass("player"))].colorStr
local fontColor = ""
local BtnClr, SideClr = {}, {}
local ButtonColors = function(self)
if not self.SetBackdrop then
Mixin(self, BackdropTemplateMixin)
end
self:SetBackdrop(Backdrop)
self:SetBackdropBorderColor(0, 0, 0)
table.insert(BtnClr, self)
end

local SideColor = function(self)
if not self.SetBackdrop then
Mixin(self, BackdropTemplateMixin)
end
self:SetBackdrop(Backdrop)
self:SetBackdropBorderColor(0, 0, 0)
table.insert(SideClr, self)
end
local CrossGamblingUI

function CrossGambling:toggleUi()
if (CrossGamblingUI:IsVisible()) then
CrossGamblingUI:Hide()
else
LoadColor()
CrossGamblingUI:Show()
end
end

function CrossGambling:ShowSlick(info)
	if (CrossGamblingUI:IsVisible() ~= true) then
        CrossGamblingUI:Show()
		LoadColor()
	else
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:HideSlick(info)
    if (CrossGamblingUI:IsVisible()) then
        CrossGamblingUI:Hide()
    end
end

function CrossGambling:DrawMainEvents()


CrossGamblingUI = CreateFrame("Frame", "CrossGamblingSlick", UIParent, "BackdropTemplate")
CrossGamblingUI:SetSize(230, 200)
CrossGamblingUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CrossGamblingUI:SetBackdrop(Backdrop)
CrossGamblingUI:SetMovable(true)
CrossGamblingUI:EnableMouse(true)
CrossGamblingUI:SetUserPlaced(true)
CrossGamblingUI:SetResizable(true)
CrossGamblingUI:SetBackdropBorderColor(0, 0, 0)
CrossGamblingUI:RegisterForDrag("LeftButton")
CrossGamblingUI:SetScript("OnDragStart", CrossGamblingUI.StartMoving)
CrossGamblingUI:SetScript("OnDragStop", CrossGamblingUI.StopMovingOrSizing)
CrossGamblingUI:SetClampedToScreen(true)
self.db.global.scale = self.db.global.scale
CrossGamblingUI:SetScale(self.db.global.scale)
CrossGamblingUI:Hide()

local MainHeader = CreateFrame("Frame", nil, CrossGamblingUI, "BackdropTemplate")
MainHeader:SetSize(CrossGamblingUI:GetSize(), 21)
MainHeader:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
ButtonColors(MainHeader)

local MainMenu = CreateFrame("Frame", nil, CrossGamblingUI, "BackdropTemplate")
MainMenu:SetSize(CrossGamblingUI:GetSize(), 21)
MainMenu:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)

local OptionsButton = CreateFrame("Frame", nil, CrossGamblingUI, "BackdropTemplate")
OptionsButton:SetSize(CrossGamblingUI:GetSize(), 21)
OptionsButton:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
OptionsButton:Hide()

local CGMainMenu = CreateFrame("Button", nil, MainHeader,  "BackdropTemplate")
CGMainMenu:SetSize(63, 21)
CGMainMenu:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 30, 0)
CGMainMenu:SetFrameStrata("MEDIUM")
CGMainMenu:SetText("Main")
CGMainMenu:SetNormalFontObject("GameFontNormal")
ButtonColors(CGMainMenu)
CGMainMenu:SetScript("OnMouseUp", function(self)
	if OptionsButton:IsShown() then
		OptionsButton:Hide()
		MainMenu:Show()
	end

end)

local MainFooter = CreateFrame("Button", nil, CrossGamblingUI, "BackdropTemplate")
MainFooter:SetSize(CrossGamblingUI:GetSize(), 15)
MainFooter:SetPoint("BOTTOMLEFT", CrossGamblingUI, 0, 0)
MainFooter:SetText("CrossGambling - Jay@Tichondrius")
MainFooter:SetNormalFontObject("GameFontNormal")
ButtonColors(MainFooter)

local CGOptions = CreateFrame("Button", nil, MainHeader,  "BackdropTemplate")
CGOptions:SetSize(63, 21)
CGOptions:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", -30, 0)
CGOptions:SetFrameStrata("MEDIUM")
CGOptions:SetText("Options")
CGOptions:SetNormalFontObject("GameFontNormal")
ButtonColors(CGOptions)
CGOptions:SetScript("OnMouseUp", function(self)
	CrossGambling:ToggleOptionsMenu()
end)


local fontColor = {r = 1.0, g = 1.0, b = 1.0}
function setFontColor(r, g, b)
    fontColor.r, fontColor.g, fontColor.b = r, g, b
end
function LoadColor()
    frameColor.r, frameColor.g, frameColor.b = self.db.global.colors.frameColor.r, self.db.global.colors.frameColor.g, self.db.global.colors.frameColor.b
    CrossGamblingUI:SetBackdropColor(frameColor.r, frameColor.g, frameColor.b)

    buttonColor.r, buttonColor.g, buttonColor.b = self.db.global.colors.buttonColor.r, self.db.global.colors.buttonColor.g, self.db.global.colors.buttonColor.b
    sideColor.r, sideColor.g, sideColor.b = self.db.global.colors.sideColor.r, self.db.global.colors.sideColor.g, self.db.global.colors.sideColor.b

    local fontColorRGB = self.db.global.colors.fontColor
    fontColor.r, fontColor.g, fontColor.b = fontColorRGB.r, fontColorRGB.g, fontColorRGB.b
    setFontColor(fontColor.r, fontColor.g, fontColor.b)

    for i = 1, #SideClr do
        SideClr[i]:SetBackdropColor(sideColor.r, sideColor.g, sideColor.b)
    end
    for i = 1, #BtnClr do
        BtnClr[i]:SetBackdropColor(buttonColor.r, buttonColor.g, buttonColor.b)
    end
end


function SaveColor()
	self.db.global.colors.frameColor.r, self.db.global.colors.frameColor.g, self.db.global.colors.frameColor.b = frameColor.r, frameColor.g, frameColor.b
    self.db.global.colors.buttonColor.r, self.db.global.colors.buttonColor.g, self.db.global.colors.buttonColor.b = buttonColor.r, buttonColor.g, buttonColor.b
    self.db.global.colors.sideColor.r, self.db.global.colors.sideColor.g, self.db.global.colors.sideColor.b = sideColor.r, sideColor.g, sideColor.b
	self.db.global.colors.fontColor = fontColor
end


function changeColor(element)
    local color
    if element == "frame" then
        color = frameColor
    elseif element == "buttons" then
        color = buttonColor
    elseif element == "sidecolor" then
        color = sideColor
    elseif element == "fontcolor" then
        color = fontColor
    elseif element == "resetColors" then
        frameColor = { r = 0.27, g = 0.27, b = 0.27 }
        CrossGamblingUI:SetBackdropColor(frameColor.r, frameColor.g, frameColor.b)
        buttonColor = { r = 0.30, g = 0.30, b = 0.30 }
        for i, button in ipairs(BtnClr) do
            button:SetBackdropColor(buttonColor.r, buttonColor.g, buttonColor.b)
        end
        sideColor = { r = 0.20, g = 0.20, b = 0.20 }
        for i, button in ipairs(SideClr) do
            button:SetBackdropColor(sideColor.r, sideColor.g, sideColor.b)
        end
        SaveColor()
        return
    end

    local function ShowColorPicker(r, g, b, a, changedCallback)
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end

	ColorPickerFrame.swatchFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
    end


local function ColorCallback(restore)
    local newR, newG, newB = ColorPickerFrame:GetColorRGB()

		if element == "fontcolor" then

		setFontColor(newR, newG, newB)
		else
        color.r, color.g, color.b = newR, newG, newB

        if element == "frame" then
            CrossGamblingUI:SetBackdropColor(color.r, color.g, color.b)
        elseif element == "buttons" then
            for i, button in ipairs(BtnClr) do
                button:SetBackdropColor(color.r, color.g, color.b)
            end
        elseif element == "sidecolor" then
            for i, button in ipairs(SideClr) do
                button:SetBackdropColor(color.r, color.g, color.b)
            end
        end
    end

    if not restore then
        SaveColor()
    end
end

    ShowColorPicker(color.r, color.g, color.b, nil, ColorCallback)
end

local GCchatMethod = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
GCchatMethod:SetSize(105, 30)
GCchatMethod:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
GCchatMethod:SetText(self.game.chatMethod)
GCchatMethod:SetNormalFontObject("GameFontNormal")
ButtonColors(GCchatMethod)
GCchatMethod:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = GCchatMethod:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

GCchatMethod:SetScript("OnEnter", function(self)
    highlight:Show()
end)

GCchatMethod:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
GCchatMethod:SetScript("OnClick", function() self:chatMethod() GCchatMethod:SetText(self.game.chatMethod) end)

local CGGameMode = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGGameMode:SetSize(105, 30)
CGGameMode:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -2)
CGGameMode:SetText(self.game.mode)
CGGameMode:SetNormalFontObject("GameFontNormal")
ButtonColors(CGGameMode)
CGGameMode:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGGameMode:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGGameMode:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGGameMode:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGGameMode:SetScript("OnClick", function() self:changeGameMode() CGGameMode:SetText(self.game.mode) end)

local CGEditBox = CreateFrame("EditBox", nil, MainMenu, "InputBoxTemplate")
CGEditBox:SetSize(MainHeader:GetSize()-25, 25)
CGEditBox:SetPoint("TOPLEFT", GCchatMethod, 10, -30)
CGEditBox:SetAutoFocus(false)
CGEditBox:SetTextInsets(10, 10, 5, 5)
CGEditBox:SetMaxLetters(6)
CGEditBox:SetJustifyH("CENTER")
CGEditBox:SetText(self.db.global.wager or "")

CGEditBox:SetScript("OnEnterPressed", function(box)
    local value = tonumber(box:GetText())
    if value then
        CrossGambling.db.global.wager = value
    end
    box:ClearFocus()
end)

CGEditBox:SetScript("OnTextChanged", function(box, userInput)
    if userInput then
        local value = tonumber(box:GetText())
        if value then
            CrossGambling.db.global.wager = value
        end
    end
end)

CGEditBox:SetScript("OnEditFocusLost", function(box)
    local value = tonumber(box:GetText())
    if value then
        CrossGambling.db.global.wager = value
    end
end)

local CGAcceptOnes = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGAcceptOnes:SetSize(105, 30)
CGAcceptOnes:SetPoint("TOPLEFT", GCchatMethod, "BOTTOMLEFT", -0, -25)
CGAcceptOnes:SetText("New Game")
CGAcceptOnes:SetNormalFontObject("GameFontNormal")
ButtonColors(CGAcceptOnes)

CGAcceptOnes:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGAcceptOnes:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGAcceptOnes:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGAcceptOnes:SetScript("OnLeave", function(self)
    highlight:Hide()
end)

local CGGuildPercent = CreateFrame("EditBox", nil, OptionsButton, "InputBoxTemplate")
CGGuildPercent:SetSize(100, 30)
CGGuildPercent:SetPoint("TOPRIGHT", CGOptions, "BOTTOMRIGHT", 25, -47)
CGGuildPercent:SetAutoFocus(false)
CGGuildPercent:SetTextInsets(10, 10, 5, 5)
CGGuildPercent:SetMaxLetters(2)
CGGuildPercent:SetJustifyH("CENTER")
CGGuildPercent:SetText(self.db.global.houseCut)
CGGuildPercent:SetScript("OnEnterPressed", EditBoxOnEnterPressed)

CGAcceptOnes:SetScript("OnClick", function()
    CGAcceptOnes:Disable()

    if CGAcceptOnes:GetText() == "Host Game" then
        CGAcceptOnes:SetText("New Game")
    else
        self.game.state = "START"
        self:SendMsg("R_NewGame")
        self.game.host = true
        self:SendMsg("New_Game")
        self.db.global.wager = tonumber(CGEditBox:GetText()) or self.db.global.wager
		self:SendMsg("SET_WAGER", self.db.global.wager)
        self:SendMsg("GAME_MODE", CGGameMode:GetText())
        self:SendMsg("Chat_Method", GCchatMethod:GetText())
        self:SendMsg("SET_HOUSE", CGGuildPercent:GetText())
    end


    CGAcceptOnes:Enable()
end)


local CGLastCall = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGLastCall:SetSize(105, 30)
CGLastCall:SetPoint("TOPLEFT", CGAcceptOnes, "BOTTOMLEFT", -0, -3)
CGLastCall:SetText("Last Call!")
CGLastCall:SetNormalFontObject("GameFontNormal")
ButtonColors(CGLastCall)
CGLastCall:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGLastCall:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGLastCall:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGLastCall:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGLastCall:SetScript("OnClick", function()
self:SendMsg("LastCall")
end)

local CGStartRoll = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGStartRoll:SetSize(105, 30)
CGStartRoll:SetPoint("TOPLEFT", CGLastCall, "BOTTOMLEFT", -0, -3)
CGStartRoll:SetText("Start Rolling")
CGStartRoll:SetNormalFontObject("GameFontNormal")
ButtonColors(CGStartRoll)
CGStartRoll:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGStartRoll:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGStartRoll:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGStartRoll:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGStartRoll:SetScript("OnClick", function()
self:CGRolls()
CGStartRoll:SetText("Whos Left?")
end)

local CGEnter = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGEnter:SetSize(105, 30)
CGEnter:SetPoint("TOPLEFT", CGGameMode, "BOTTOMLEFT", -0, -25)
CGEnter:SetText("Join Game")
CGEnter:SetNormalFontObject("GameFontNormal")
ButtonColors(CGEnter)
CGEnter:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGEnter:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGEnter:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGEnter:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGEnter:SetScript("OnClick", function()
	if (CGEnter:GetText() == "Join Game") then
        SendChatMessage(CrossGambling.db.global.joinWord or "1", self.game.chatMethod)
        CGEnter:SetText("Leave Game")
    elseif (CGEnter:GetText() == "Leave Game") then
        SendChatMessage(CrossGambling.db.global.leaveWord or "-1", self.game.chatMethod)
        CGEnter:SetText("Join Game")
    end
end)

local CGRollMe = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGRollMe:SetSize(105, 30)
CGRollMe:SetPoint("TOPLEFT", CGEnter, "BOTTOMLEFT", -0, -3)
CGRollMe:SetText("Roll Me")
CGRollMe:SetNormalFontObject("GameFontNormal")
ButtonColors(CGRollMe)
CGRollMe:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGRollMe:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGRollMe:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGRollMe:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGRollMe:SetScript("OnClick", function()
  rollMe()
end)

local CGCloseGame = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGCloseGame:SetSize(105, 30)
CGCloseGame:SetPoint("TOPLEFT", CGRollMe, "BOTTOMLEFT", -0, -3)
CGCloseGame:SetText("Close")
CGCloseGame:SetNormalFontObject("GameFontNormal")
ButtonColors(CGCloseGame)
CGCloseGame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGCloseGame:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGCloseGame:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGCloseGame:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGCloseGame:SetScript("OnClick", function()
  CrossGamblingUI:Hide()
end)

local CGFullStats = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGFullStats:SetSize(105, 14)
CGFullStats:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
CGFullStats:SetText("Full Stats")
CGFullStats:SetNormalFontObject("GameFontNormal")
ButtonColors(CGFullStats)
CGFullStats:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGFullStats:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGFullStats:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGFullStats:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGFullStats:SetScript("OnClick", function(full)
  self:reportStats(full)
end)

local CGDeathStats = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGDeathStats:SetSize(105, 14)
CGDeathStats:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -20)
CGDeathStats:SetText("DeathRoll Stats")
CGDeathStats:SetNormalFontObject("GameFontNormal")
ButtonColors(CGDeathStats)
CGDeathStats:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGDeathStats:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGDeathStats:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGDeathStats:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGDeathStats:SetScript("OnClick", function()
  self:reportDeathrollStats()
end)

local CGGuildCut = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGGuildCut:SetSize(105, 30)
CGGuildCut:SetPoint("TOPLEFT", CGDeathStats, "BOTTOMLEFT", -0, -3)
CGGuildCut:SetText("Guild Cut(OFF)")
CGGuildCut:SetNormalFontObject("GameFontNormal")
ButtonColors(CGGuildCut)
CGGuildCut:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGGuildCut:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGGuildCut:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGGuildCut:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGGuildCut:SetScript("OnClick", function()
  if (self.game.house == true) then
		self.game.house = false
		CGGuildCut:SetText("Guild Cut (OFF)");
		DEFAULT_CHAT_FRAME:AddMessage("Guild cut has been turned off.")
	else
		self.game.house = true
		CGGuildCut:SetText("Guild Cut (ON)");
		DEFAULT_CHAT_FRAME:AddMessage("Guild cut has been turned on.")
	end
end)

local CGReset = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGReset:SetSize(105, 30)
CGReset:SetPoint("TOPLEFT", CGGuildCut, "BOTTOMLEFT", -0, -3)
CGReset:SetText("Reset Stats!")
CGReset:SetNormalFontObject("GameFontNormal")
ButtonColors(CGReset)
CGReset:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGReset:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGReset:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGReset:SetScript("OnLeave", function(self)
    highlight:Hide()
end)

CGReset:SetScript("OnMouseDown", function()
    self.game.host = false
    for i = 1, #CGPlayers do
        CGPlayers[1].HasRolled = false
        CrossGambling:RemovePlayer(CGPlayers[1].Name)
    end

    CGEnter:SetText("Join Game")

		CGStartRoll:SetText("Start Rolling")

    self.game.state = "START"
    self.game.players = {}
    self.game.result = nil
    self:resetStats(info)
end)


local CGRealmFilter = CreateFrame("Button", "CGRealmFilter", OptionsButton, "BackdropTemplate")
CGRealmFilter:SetPoint("TOPLEFT", CGReset, "BOTTOMLEFT", -0, -3)
CGRealmFilter:SetSize(105, 30)
ButtonColors(CGRealmFilter)
CGRealmFilter:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGRealmFilter:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGRealmFilter:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGRealmFilter:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGRealmFilter:SetText("Realm Filter(OFF)")
CGRealmFilter:SetNormalFontObject("GameFontNormal")
CGRealmFilter:Show()

local function ToggleRealmFilter()
  if(self.game.realmFilter == false) then
    CGRealmFilter:SetText("Realm Filter(ON)")
	self.game.realmFilter = true
  else
    CGRealmFilter:SetText("Realm Filter(OFF)")
	self.game.realmFilter = false
  end
end

CGRealmFilter:SetScript("OnClick", ToggleRealmFilter)

local CGFameShame = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGFameShame:SetSize(105, 14)
CGFameShame:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -2)
CGFameShame:SetText("Fame/Shame")
CGFameShame:SetNormalFontObject("GameFontNormal")
ButtonColors(CGFameShame)
CGFameShame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGFameShame:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGFameShame:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGFameShame:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGFameShame:SetScript("OnClick", function()
  self:reportStats()
end)

local CGSessionStats = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGSessionStats:SetSize(105, 14)
CGSessionStats:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -20)
CGSessionStats:SetText("Session Stats")
CGSessionStats:SetNormalFontObject("GameFontNormal")
ButtonColors(CGSessionStats)
CGSessionStats:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGSessionStats:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGSessionStats:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGSessionStats:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGSessionStats:SetScript("OnClick", function()
  self:reportSessionStats()
end)

local width, height = CrossGamblingUI:GetSize()
local auditFrame = CreateFrame("Frame", "CrossGamblingAuditLogFrame", CrossGamblingUI, "BackdropTemplate")
auditFrame:SetPoint("TOP", CrossGamblingUI, "BOTTOM", 0, -20)
auditFrame:SetSize(width, height)
auditFrame:SetResizeBounds(width, height, 400, 400)
auditFrame:EnableMouse(true)
auditFrame:SetMovable(true)
auditFrame:SetResizable(true)
auditFrame:RegisterForDrag("LeftButton")
auditFrame:SetScript("OnDragStart", auditFrame.StartMoving)
auditFrame:SetScript("OnDragStop", auditFrame.StopMovingOrSizing)
SideColor(auditFrame)
auditFrame:Hide()

local closeButton = CreateFrame("Button", nil, auditFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() auditFrame:Hide() end)

local resizeButton = CreateFrame("Button", nil, auditFrame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", -4, 4)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeButton:SetScript("OnMouseDown", function(_, btn)
    if btn == "LeftButton" then
        auditFrame:StartSizing("BOTTOMRIGHT")
        auditFrame.isSizing = true
    end
end)
resizeButton:SetScript("OnMouseUp", function(_, btn)
    if btn == "LeftButton" then
        auditFrame:StopMovingOrSizing()
        auditFrame.isSizing = false
        auditFrame:UpdateLayout()
    end
end)

local title = auditFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("History Log")

local searchBox = CreateFrame("EditBox", nil, auditFrame, "InputBoxTemplate")
searchBox:SetSize(200, 20)
searchBox:SetPoint("TOPLEFT", 20, -40)
searchBox:SetAutoFocus(false)

local retentionDays = {5, 10, 30, "Never"}
local retentionCheckboxes = {}

local function OnRetentionChanged(self)
    for _, cb in pairs(retentionCheckboxes) do cb:SetChecked(false) end
    self:SetChecked(true)
    CrossGambling.db.global.auditRetention = self.days
end

local purgeButton = CreateFrame("Button", nil, auditFrame, "BackdropTemplate")
purgeButton:SetSize(80, 20)
purgeButton:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
purgeButton:SetText("Purge Now")
purgeButton:SetNormalFontObject("GameFontNormalSmall")
ButtonColors(purgeButton)
purgeButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlightHistory = purgeButton:GetHighlightTexture()
highlightHistory:SetBlendMode("ADD")
highlightHistory:SetAllPoints()
purgeButton:SetScript("OnClick", function()
    CrossGambling.global.auditLog = {}
    CrossGambling:UpdateAuditLogText(auditFrame.searchBox:GetText() or "")
end)

local checkboxSize = 14
local spacing = 16

for i, val in ipairs(retentionDays) do
    local cb = CreateFrame("CheckButton", nil, auditFrame, "UICheckButtonTemplate")
    cb:SetSize(checkboxSize, checkboxSize)

    if i == 1 then
        cb:SetPoint("LEFT", purgeButton, "RIGHT", 5, 0)
    else
        cb:SetPoint("LEFT", retentionCheckboxes[i - 1], "RIGHT", spacing, 0)
    end

    if cb.Text then cb.Text:Hide() end

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    label:SetPoint("BOTTOM", cb, "TOP", 0, 1)
    label:SetText(type(val) == "number" and (val .. "d") or "Never")

    cb.days = val
    cb:SetScript("OnClick", OnRetentionChanged)
    retentionCheckboxes[i] = cb
end

local scrollFrame = CreateFrame("ScrollFrame", nil, auditFrame, "UIPanelScrollFrameTemplate")
scrollFrame:ClearAllPoints()
scrollFrame:SetPoint("TOPLEFT", purgeButton, "BOTTOMLEFT", 0, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 20)

local content = CreateFrame("Frame", nil, scrollFrame)
scrollFrame:SetScrollChild(content)

auditFrame.searchBox = searchBox
auditFrame.scrollFrame = scrollFrame
auditFrame.content = content

function auditFrame:UpdateLayout()
    local width, height = self:GetSize()
    scrollFrame:SetWidth(width - 55)
    content:SetWidth(scrollFrame:GetWidth())
    CrossGambling:UpdateAuditLogText(searchBox:GetText())
end
auditFrame:SetScript("OnSizeChanged", auditFrame.UpdateLayout)

searchBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
        CrossGambling:UpdateAuditLogText(self:GetText())
    end
end)

local CGHistoryLog = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGHistoryLog:SetSize(105, 14)
CGHistoryLog:SetPoint("TOPRIGHT", CGSessionStats, "BOTTOMRIGHT", 0, -3)
CGHistoryLog:SetText("History Log")
CGHistoryLog:SetNormalFontObject("GameFontNormal")
ButtonColors(CGHistoryLog)
CGHistoryLog:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlightHistory = CGHistoryLog:GetHighlightTexture()
highlightHistory:SetBlendMode("ADD")
highlightHistory:SetAllPoints()

CGHistoryLog:SetScript("OnEnter", function() highlightHistory:Show() end)
CGHistoryLog:SetScript("OnLeave", function() highlightHistory:Hide() end)
CGHistoryLog:SetScript("OnMouseDown", function()
    if auditFrame:IsShown() then
        auditFrame:Hide()
    else
        CrossGambling:PurgeOldAuditEntries()
        auditFrame:Show()
        auditFrame:UpdateLayout()
        CrossGambling:UpdateAuditLogText(auditFrame.searchBox:GetText())
    end
end)

CrossGambling.auditFrame = auditFrame

function CrossGambling:PurgeOldAuditEntries()
    if not self.db or not self.db.global then return end
    local retention = self.db.global.auditRetention or -1
    if retention == -1 or retention == "Never" then return end

    local cutoff = time() - (retention * 86400)
    local newLog = {}

    for _, entry in ipairs(self.global.auditLog or {}) do
        if tonumber(entry.timestamp) > cutoff then
            table.insert(newLog, entry)
        end
    end
    self.global.auditLog = newLog
end

C_Timer.After(0.1, function()
    if not CrossGambling.db or not CrossGambling.db.global then
        return
    end

    for _, cb in pairs(retentionCheckboxes) do
        if CrossGambling.db.global.auditRetention == cb.days then
            cb:SetChecked(true)
        end
    end
end)


local function FormatTimestamp(ts)
    local t = date("*t", ts)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function CrossGambling:UpdateAuditLogText(filter)
    if self.auditFrame.content then
        self.auditFrame.content:Hide()
        self.auditFrame.content:SetParent(nil)
    end

    local scrollFrame = self.auditFrame.scrollFrame

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetPoint("TOPLEFT")
    content:SetPoint("RIGHT")
    scrollFrame:SetScrollChild(content)

    self.auditFrame.content = content

    content:SetSize(1, 1)


    local log = self.global.auditLog or {}
    if #log == 0 then
        local noEntry = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        noEntry:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        noEntry:SetText("No audit entries found.")
        content:SetHeight(30)
        self.auditFrame.scrollFrame:SetVerticalScroll(0)
        return
    end

    local yOffset, spacing = -10, 10
    local maxWidth = 560

    for _, entry in ipairs(log) do
        if type(entry) == "table" then
            local ts = FormatTimestamp(tonumber(entry.timestamp) or 0)
            local textLine

            if entry.action == "updateStat" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100•|r Stats updated for |cffffff00%s|r\n    Before: |cffffff00%d|r\n    Change: |cffff8800%+d|r    After: |cff00ff00%d|r",
                    ts, entry.player or "?", entry.oldAmount or 0, entry.addedAmount or 0, entry.newAmount or 0)
            elseif entry.action == "joinStats" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100•|r Joined alt |cffffff00%s|r to main |cffffff00%s|r\n    +%d stats, +%d deathroll",
                    ts, entry.altname or "?", entry.mainname or "?", entry.statsAdded or 0, entry.deathrollStatsAdded or 0)
            elseif entry.action == "unjoinStats" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100•|r Unjoined alt |cffffff00%s|r from main |cffffff00%s|r\n    -%d stats, -%d deathroll",
                    ts, entry.altname or "?", entry.mainname or "?", entry.pointsRemoved or 0, entry.deathrollStatsRemoved or 0)
            elseif entry.action == "debt" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100•|r |cffffff00%s|r owes |cffffff00%s|r %dg",
                    ts, entry.loser or "?", entry.winner or "?", entry.amount or 0)
            else
                local extra = {}
                for k, v in pairs(entry) do
                    table.insert(extra, k .. "=" .. tostring(v))
                end
                textLine = string.format("|cff999999[%s]|r Unknown entry:\n%s", ts, table.concat(extra, ", "))
            end

            if not filter or filter == "" or textLine:lower():find(filter:lower(), 1, true) then
                local fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                fs:SetPoint("TOPLEFT", 10, yOffset)
                fs:SetWidth(maxWidth)
                fs:SetJustifyH("LEFT")
                fs:SetWordWrap(true)
                fs:SetText(textLine)
                yOffset = yOffset - fs:GetStringHeight() - spacing
            end
        end
    end

    local totalHeight = math.max(30, -yOffset + spacing)
    content:SetHeight(totalHeight)
    self.auditFrame.scrollFrame:SetVerticalScroll(0)
end


local ChangeColorButton = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
ChangeColorButton:SetSize(57.5, 30)
ChangeColorButton:SetPoint("BOTTOMLEFT", MainFooter, "BOTTOMLEFT", 0, 15)
ChangeColorButton:SetText("Button\nColor")
ChangeColorButton:SetNormalFontObject("GameFontNormal")
ButtonColors(ChangeColorButton)
ChangeColorButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = ChangeColorButton:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

ChangeColorButton:SetScript("OnEnter", function(self)
    highlight:Show()
end)

ChangeColorButton:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
ChangeColorButton:SetScript("OnMouseUp", function() changeColor("buttons") end)

local ChangeColorSide = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
ChangeColorSide:SetSize(ChangeColorButton:GetSize())
ChangeColorSide:SetPoint("BOTTOMLEFT", ChangeColorButton, "BOTTOMRIGHT", 0, 0)
ChangeColorSide:SetText("Side\nColor")
ChangeColorSide:SetNormalFontObject("GameFontNormal")
ButtonColors(ChangeColorSide)
ChangeColorSide:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = ChangeColorSide:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

ChangeColorSide:SetScript("OnEnter", function(self)
    highlight:Show()
end)

ChangeColorSide:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
ChangeColorSide:SetScript("OnMouseUp", function() changeColor("sidecolor") end)

local ChangeColorFrame = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
ChangeColorFrame:SetSize(ChangeColorButton:GetSize())
ChangeColorFrame:SetPoint("BOTTOMLEFT", ChangeColorSide, "BOTTOMRIGHT", 0, 0)
ChangeColorFrame:SetText("Frame\nColor")
ChangeColorFrame:SetNormalFontObject("GameFontNormal")
ButtonColors(ChangeColorFrame)
ChangeColorFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = ChangeColorFrame:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

ChangeColorFrame:SetScript("OnEnter", function(self)
    highlight:Show()
end)

ChangeColorFrame:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
ChangeColorFrame:SetScript("OnMouseUp", function() changeColor("frame") end)

local ChangeColorReset = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
ChangeColorReset:SetSize(ChangeColorButton:GetSize())
ChangeColorReset:SetPoint("BOTTOMLEFT", ChangeColorFrame, "BOTTOMRIGHT", 0, 0)
ChangeColorReset:SetText("Reset\nColors")
ChangeColorReset:SetNormalFontObject("GameFontNormal")
ButtonColors(ChangeColorReset)
ChangeColorReset:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = ChangeColorReset:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

ChangeColorReset:SetScript("OnEnter", function(self)
    highlight:Show()
end)

ChangeColorReset:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
ChangeColorReset:SetScript("OnMouseUp", function() changeColor("resetColors") end)

local CGRightMenu = CreateFrame("Frame", "CGRightMenu", CrossGamblingUI, "BackdropTemplate")
CGRightMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPRIGHT", 0, 0)
CGRightMenu:SetSize(220, 150)
SideColor(CGRightMenu)
CGRightMenu:Hide()

local function onUpdate(self,elapsed)
    local mainX, mainY = CrossGamblingUI:GetCenter()
    local leftX, leftY = CGRightMenu:GetCenter()
    local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
    if distance < 220 then
        CGRightMenu:ClearAllPoints()
        CGRightMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPRIGHT", 0, 0)
end
end

CGRightMenu:SetScript("OnUpdate", onUpdate)
CGRightMenu:SetMovable(true)
CGRightMenu:EnableMouse(true)
CGRightMenu:SetUserPlaced(true)
CGRightMenu:SetClampedToScreen(true)

CGRightMenu:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving();
        self.isMoving = true;
    end
end)
CGRightMenu:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing();
        self.isMoving = false;
    end
end)

CGRightMenu.TextField = CreateFrame("ScrollingMessageFrame", nil, CGRightMenu)
CrossGambling.ChatTextField = CGRightMenu.TextField
CGRightMenu.TextField:SetPoint("TOPLEFT", CGRightMenu, 4, -4)
CGRightMenu.TextField:SetSize(CGRightMenu:GetWidth()-8, 120)
CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", self.db.global.fontvalue, "")
CGRightMenu.TextField:SetFading(false)
CGRightMenu.TextField:SetInsertMode("BOTTOM")
CGRightMenu.TextField:SetJustifyH("LEFT")
CGRightMenu.TextField:SetMaxLines(50)
CGRightMenu.TextField:ScrollToBottom()
CGRightMenu.TextField:SetScript("OnMouseWheel", function(self, delta)
    if (delta == 1) then
        self:ScrollUp()
    else
        self:ScrollDown()
    end
end)

local function OnChatSubmit(CGChatBox)
    local message = CGChatBox:GetText()
    if message == "" or message == "Type Here..." then
        CGChatBox:SetText("")
        CGChatBox:ClearFocus()
        return
    end

    local playerName = UnitName("player")
    local playerClass = select(2, UnitClass("player"))
    local tf = CrossGambling and CrossGambling.ChatTextField

    if tf then
                CrossGambling.recentChatMsgs = CrossGambling.recentChatMsgs or {}
        CrossGambling.recentChatMsgs[playerName .. ":" .. message] = GetTime()

        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass]
        local nameStr = color and ("|c" .. color.colorStr .. playerName .. "|r") or playerName
        tf:AddMessage(nameStr .. ": " .. message)
        if tf.ScrollToBottom then tf:ScrollToBottom() end
    end

        local ok, err = pcall(function()
        CrossGambling:SendMsg("CHAT_MSG", playerName .. ":" .. playerClass .. ":" .. message)
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000CG Chat Error:|r " .. tostring(err))
    end

    CGChatBox:SetText("")
    CGChatBox:ClearFocus()
end


local fontColorButton = CreateFrame("Button", nil, CGRightMenu, "BackdropTemplate")
fontColorButton:SetSize(220, 20)
fontColorButton:SetPoint("BOTTOMLEFT", CGRightMenu, "BOTTOMLEFT", 0, -40)
fontColorButton:SetText("Font Color")
fontColorButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = fontColorButton:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

fontColorButton:SetScript("OnEnter", function(self)
    highlight:Show()
end)

fontColorButton:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
fontColorButton:SetNormalFontObject("GameFontNormal")
ButtonColors(fontColorButton)
fontColorButton:SetScript("OnMouseUp", function() changeColor("fontcolor") end)

local fontSizeSlider = CreateFrame("Slider", nil, fontColorButton, "OptionsSliderTemplate")
fontSizeSlider:SetPoint("BOTTOMLEFT", 0, -20)
fontSizeSlider:SetSize(220, 20)
fontSizeSlider:SetMinMaxValues(1, 100)
fontSizeSlider:SetValueStep(1)
fontSizeSlider:SetObeyStepOnDrag(true)
fontSizeSlider:SetValue(self.db.global.fontvalue)
fontSizeSlider:SetOrientation("HORIZONTAL")
fontSizeSlider.Low:SetText("1")
fontSizeSlider.High:SetText("100")


local sliderText = fontSizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sliderText:SetPoint("TOP", 0, -20)
sliderText:SetText(self.db.global.fontvalue)

local function UpdateFontSize(_, value)
    self.db.global.fontvalue = value
    sliderText:SetText(value)
    CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", self.db.global.fontvalue, "")
end

fontSizeSlider:SetScript("OnValueChanged", function(_, value)
    UpdateFontSize(_, value)
end)


local CGChatBox = CreateFrame("EditBox", "CGChatBox", CGRightMenu)
CGChatBox:SetPoint("TOPLEFT", CGRightMenu, "BOTTOMLEFT", 0, -2)
CGChatBox:SetSize(CGRightMenu:GetWidth(), 22)
CGChatBox:SetFrameStrata("DIALOG")
CGChatBox:SetFrameLevel(CGRightMenu:GetFrameLevel() + 10)
CGChatBox:EnableMouse(true)
CGChatBox:EnableKeyboard(true)
CGChatBox:SetAutoFocus(false)
CGChatBox:SetMultiLine(false)
CGChatBox:SetMaxLetters(55)
CGChatBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
CGChatBox:SetTextColor(1, 1, 1, 1)
CGChatBox:SetTextInsets(6, 6, 0, 0)
local cgChatBG = CGChatBox:CreateTexture(nil, "BACKGROUND")
cgChatBG:SetAllPoints(CGChatBox)
cgChatBG:SetColorTexture(0.1, 0.1, 0.1, 0.8)
CGChatBox:SetText("Type Here...")
CGChatBox:SetScript("OnEnterPressed", OnChatSubmit)
CGChatBox:SetScript("OnMouseDown", function(self)
    if self:GetText() == "Type Here..." then
        self:SetText("")
    end
    self:SetFocus()
end)
CGChatBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == "Type Here..." then
        self:SetText("")
    end
end)
CGChatBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
        self:SetText("Type Here...")
    end
end)
CGChatBox:Hide()
CGRightMenu:HookScript("OnShow", function()
    CGChatBox:Show()
    CrossGambling.game.chatframeOption = false
        local tf = CrossGambling and CrossGambling.ChatTextField
    if tf and tf.ScrollToBottom then tf:ScrollToBottom() end
end)
CGRightMenu:HookScript("OnHide", function() CGChatBox:Hide(); CrossGambling.game.chatframeOption = true end)

local CGChatToggle = CreateFrame("Button", nil, MainHeader,  "BackdropTemplate")
CGChatToggle:SetSize(20, 21)
CGChatToggle:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", 0, 0)
CGChatToggle:SetFrameLevel(15)
CGChatToggle:SetText(">")
CGChatToggle:SetNormalFontObject("GameFontNormal")
ButtonColors(CGChatToggle)
CGChatToggle:SetScript("OnMouseDown", function()
   if CGRightMenu:IsShown() then
		CGRightMenu:Hide()
		CGChatToggle:SetText(">")
		self.game.chatframeOption = true

	else
		CGRightMenu:Show()
		CGChatToggle:SetText("<")
		self.game.chatframeOption = false
	end
end)


local valuescale = function(val,valStep)
		 	self.db.global.scalevalue = val
    return floor(val/valStep)*valStep
  end

	local CreateBasicSlider = function(parent, name, title, minVal, maxVal, valStep)
	local slider = CreateFrame("Slider", name, CrossGamblingUI, "OptionsSliderTemplate")
	slider:SetSize(CrossGamblingUI:GetSize(), 21)
	slider:SetPoint("BOTTOM", CrossGamblingUI, "BOTTOM", 0, -20)
    local editbox = CreateFrame("EditBox", "$parentEditBox", slider, "InputBoxTemplate")
    slider:SetMinMaxValues(100, 250)
	self.db.global.scalevalue = self.db.global.scalevalue
	slider:SetValue(self.db.global.scalevalue)
    slider:SetValueStep(valStep)
	slider:SetFrameStrata("LOW")
    slider.text = _G[name.."Text"]
    slider.text:SetText(title)
    slider.textLow = _G[name.."Low"]
    slider.textHigh = _G[name.."High"]
    slider.textLow:SetText("")
    slider.textHigh:SetText("")
    slider.textLow:SetTextColor(0,0,0)
    slider.textHigh:SetTextColor(0.4,0.4,0.4)
    editbox:ClearAllPoints()
    editbox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    editbox:SetText(slider:GetValue())
    editbox:SetAutoFocus(false)

    slider:SetScript("OnValueChanged", function(self,value)
      self.editbox:SetText(valuescale (value,valStep))
    end)
    slider.editbox = editbox
    return slider
  end


    local slider = CreateBasicSlider(parent, "CGSlider", "", 0, 1, 0.001)
    slider:HookScript("OnMouseUp", function(self,value)
	  CrossScale(self)
    end)

	function CrossScale()
		self.db.global.scale = slider:GetValue()/100
		CrossGamblingUI:SetScale(self.db.global.scale)
	end

local CGLeftMenu = CreateFrame("Frame", "CGLeftMenu", CrossGamblingUI, "BackdropTemplate")
CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
CGLeftMenu:SetSize(300, 180)
SideColor(CGLeftMenu)
CGLeftMenu:Show()

local function onUpdate(self,elapsed)
    local mainX, mainY = CrossGamblingUI:GetCenter()
    local leftX, leftY = CGLeftMenu:GetCenter()
    local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
    if distance < 260 then
        CGLeftMenu:ClearAllPoints()
        CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
end
end

CGLeftMenu:SetScript("OnUpdate", onUpdate)
CGLeftMenu:SetMovable(true)
CGLeftMenu:EnableMouse(true)
CGLeftMenu:SetUserPlaced(true)
CGLeftMenu:SetClampedToScreen(true)
CGLeftMenu:Hide()

CGLeftMenu:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving();
        self.isMoving = true;
    end
end)
CGLeftMenu:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing();
        self.isMoving = false;
    end
end)

local CGLeftMenuHeader = CreateFrame("Button", nil, CGLeftMenu,  "BackdropTemplate")
CGLeftMenuHeader:SetSize(CGLeftMenu:GetSize(), 21)
CGLeftMenuHeader:SetPoint("TOPLEFT", CGLeftMenu, "TOPLEFT", 0, 20)
CGLeftMenuHeader:SetFrameLevel(15)
CGLeftMenuHeader:SetText("Roll Tracker")
CGLeftMenuHeader:SetNormalFontObject("GameFontNormal")
ButtonColors(CGLeftMenuHeader)

local CGMenuToggle = CreateFrame("Button", nil, MainHeader,  "BackdropTemplate")
CGMenuToggle:SetSize(20, 21)
CGMenuToggle:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 0, 0)
CGMenuToggle:SetFrameLevel(15)
CGMenuToggle:SetText("<")
CGMenuToggle:SetNormalFontObject("GameFontNormal")
ButtonColors(CGMenuToggle)
CGMenuToggle:SetScript("OnMouseDown", function(self)
   if CGLeftMenu:IsShown() then
		CGLeftMenu:Hide()
		CGMenuToggle:SetText("<")
	else
		CGLeftMenu:Show()
		CGMenuToggle:SetText(">")
	end
end)

function CrossGambling:RemovePlayer(name)
    for i, player in pairs(CGPlayers) do
        if player.name == name then
            table.remove(CGPlayers, i)
            UpdatePlayerList()
            return
        end
    end
end


function CrossGambling:AddPlayer(playerName)
    for i, player in pairs(CGPlayers) do
        if player.name == playerName then
            return
        end
    end

    local newPlayer = {
        name = playerName,
        total = 0,
    }
    table.insert(CGPlayers, newPlayer)
    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)
    UpdatePlayerList()
end

local playerListFrame = CreateFrame("Frame", "PlayerListFrame", CGLeftMenu)
playerListFrame:SetSize(300, 150)
playerListFrame:SetPoint("CENTER")

local scrollFrame = CreateFrame("ScrollFrame", "PlayerListScrollFrame", playerListFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(266, 170)
scrollFrame:SetPoint("TOPLEFT", 10, 10)

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local currentValue = scrollFrame:GetVerticalScroll()
    local rowHeight = 30
    local numRows = #CGPlayers
    local maxRows = math.max(numRows * rowHeight - scrollFrame:GetHeight(), 0)
    local newValue = math.max(0, math.min(currentValue - delta * rowHeight, maxRows))
    scrollFrame:SetVerticalScroll(newValue)
end)

local playerButtonsFrame = CreateFrame("Frame", "PlayerButtonsFrame", scrollFrame)
playerButtonsFrame:SetSize(280, 1)
scrollFrame:SetScrollChild(playerButtonsFrame)

playerButtons = {}

function UpdatePlayerList()
    for i, button in ipairs(playerButtons) do
        button:Hide()
        button:SetParent(nil)
    end

    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)

    local row = 0
    local column = 0

    for i, player in ipairs(CGPlayers) do
    local playerButton = CreateFrame("Button", "PlayerButton"..i, playerButtonsFrame, "BackdropTemplate")
    playerButton:SetSize(250, 30)
    playerButton:SetPoint("TOPLEFT", 0, -row * 30)
    ButtonColors(playerButton)
    LoadColor()

    local buttonText = playerButton:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont("Fonts\\FRIZQT__.TTF", 20)
    buttonText:SetPoint("LEFT", 5, 0)
    playerButton.text = buttonText

    local _, class = UnitClass(player.name)
    local classColor = class and RAID_CLASS_COLORS[class]

    if classColor and classColor.colorStr then
        local playerNameColor = "|c"..classColor.colorStr
        if player.roll then
            buttonText:SetText(playerNameColor..player.name.."|r : |cFF000000"..player.roll.."|r")
        else
            buttonText:SetText(playerNameColor..player.name.."|r")
        end
    else

        if player.roll then
            buttonText:SetText("|cffffffff"..player.name.."|r : |cFF000000"..player.roll.."|r")
        else
            buttonText:SetText("|cffffffff"..player.name.."|r")
        end
    end

		table.insert(playerButtons, playerButton)
		row = row + 1
	end


    playerButtonsFrame:SetHeight(row * 30)


end


CGCall["PLAYER_ROLL"] = function(playerName, value)
    for i, player in pairs(CGPlayers) do
        if player.name == playerName then
            player.roll = value
            break
        end
    end
    UpdatePlayerList()
end

CGCall["R_NewGame"] = function()
    for i = #CGPlayers, 1, -1 do
        CrossGambling:RemovePlayer(CGPlayers[i].name)
    end
	CGEnter:SetText("Join Game")
	CGStartRoll:SetText("Start Rolling")
	CGEnter:Enable()
end

CGCall["DisableClient"] = function()
		CGAcceptOnes:Disable()
		CGLastCall:Disable()
		CGStartRoll:Disable()
		self.game.players = {}
		self.game.result = nil
	if(self.game.host) then
		CGAcceptOnes:Enable()
		CGLastCall:Enable()
		CGStartRoll:Enable()
	end
end

CGCall["Disable_Join"] = function()
CGEnter:Disable()
end


end
