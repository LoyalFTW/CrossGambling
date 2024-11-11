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
    -- Show Inerface
	if (CrossGamblingUI:IsVisible() ~= true) then
        CrossGamblingUI:Show()
		LoadColor()
	else 
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:HideSlick(info)
    -- Hide Interface
    if (CrossGamblingUI:IsVisible()) then
        CrossGamblingUI:Hide()
    end
end 

function CrossGambling:DrawMainEvents()
-- Theme Changer (Needs work)
CGTheme = CreateFrame("Frame", "CrossGamblingTheme", UIParent, "BasicFrameTemplateWithInset")
CGTheme:SetSize(1000, 320) 
CGTheme:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CGTheme:SetMovable(true)
CGTheme:EnableMouse(true)
CGTheme:SetUserPlaced(true)
CGTheme:Show()
CrossGamblingTheme:SetScript("OnLeave", function()
	self.db.global.themechoice = 0
end)
if self.db.global.themechoice == 1 then
CrossGamblingTheme:Show()
else
CrossGamblingTheme:Hide()
end
local CGThemeHeader = CGTheme:CreateFontString(nil, "ARTWORK", "GameFontNormal")
CGThemeHeader:SetPoint("TOP", CGTheme, "TOP", 0, -2)
CGThemeHeader:SetText("CrossGambling")

local CGThemeText = CGTheme:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CGThemeText:SetPoint("TOP", CGTheme, "TOP", 0, -50)
CGThemeText:SetText("New theme picker, choose between Classic or New Style! After picking, and confirming, your game will reload. \nBoth frames are Resizable! All frames and panels are movable and in the new style you can change its colors.")

local OldTheme = CreateFrame("CheckButton", nil, CGTheme, "ChatConfigCheckButtonTemplate")
OldTheme:SetSize(40, 40)
OldTheme:SetPoint("BOTTOMLEFT", CGTheme, "BOTTOMLEFT", 220, 5)
OldTheme:SetScript("OnEnter", ButtonOnEnter)
OldTheme:SetScript("OnLeave", ButtonOnLeave)
OldTheme:SetText("Old Theme")
OldTheme:SetScript("OnMouseUp", function()
self.db.global.theme = "Classic"
end)

local NewTheme = CreateFrame("CheckButton", nil, CGTheme,"ChatConfigCheckButtonTemplate")
NewTheme:SetSize(40, 40)
NewTheme:SetPoint("BOTTOMLEFT", CGTheme, "BOTTOMLEFT", 620, 5)
NewTheme:SetScript("OnEnter", ButtonOnEnter)
NewTheme:SetScript("OnLeave", ButtonOnLeave)
NewTheme:SetScript("OnMouseUp", function()
NewTheme:SetText("New Theme")
self.db.global.theme = "Slick"
end)

local CGThemeClassic = CGTheme:CreateTexture(nil, "ARTWORK")
CGThemeClassic:SetPoint("BOTTOMLEFT", CGTheme, "BOTTOMLEFT", 0, 10)
CGThemeClassic:SetTexture("Interface\\AddOns\\CrossGambling\\media\\ClassicTheme.tga") 

local CGThemeConfirm = CreateFrame("Button", nil, CGTheme, "BackdropTemplate")
CGThemeConfirm:SetSize(100, 21)
CGThemeConfirm:SetPoint("BOTTOMLEFT", CGTheme, "BOTTOMRIGHT", -550, 10)
CGThemeConfirm:SetText("Confirm")
CGThemeConfirm:SetNormalFontObject("GameFontNormal")
ButtonColors(CGThemeConfirm)
CGThemeConfirm:SetScript("OnMouseUp", function(self)
ReloadUI()
end)

local CGThemeSlick = CGTheme:CreateTexture(nil, "ARTWORK")
CGThemeSlick:SetPoint("BOTTOMRIGHT", CGTheme, "BOTTOMRIGHT", 0, 10)
CGThemeSlick:SetTexture("Interface\\AddOns\\CrossGambling\\media\\NewTheme.tga") 
CGThemeSlick:SetSize(608, 280)

--Create Main UI
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
-- Header to hold options
local MainHeader = CreateFrame("Frame", nil, CrossGamblingUI, "BackdropTemplate")
MainHeader:SetSize(CrossGamblingUI:GetSize(), 21)
MainHeader:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
ButtonColors(MainHeader)
-- Main Button
local MainMenu = CreateFrame("Frame", nil, CrossGamblingUI, "BackdropTemplate")
MainMenu:SetSize(CrossGamblingUI:GetSize(), 21)
MainMenu:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
--Options Button
local OptionsButton = CreateFrame("Frame", nil, CrossGamblingUI, "BackdropTemplate")
OptionsButton:SetSize(CrossGamblingUI:GetSize(), 21)
OptionsButton:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
OptionsButton:Hide()

-- Main Menu
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
-- Footer
local MainFooter = CreateFrame("Button", nil, CrossGamblingUI, "BackdropTemplate")
MainFooter:SetSize(CrossGamblingUI:GetSize(), 15)
MainFooter:SetPoint("BOTTOMLEFT", CrossGamblingUI, 0, 0)
MainFooter:SetText("CrossGambling - Jay@Tichondrius")
MainFooter:SetNormalFontObject("GameFontNormal")
ButtonColors(MainFooter)
-- Options Menu
local CGOptions = CreateFrame("Button", nil, MainHeader,  "BackdropTemplate")
CGOptions:SetSize(63, 21)
CGOptions:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", -30, 0)
CGOptions:SetFrameStrata("MEDIUM")
CGOptions:SetText("Options")
CGOptions:SetNormalFontObject("GameFontNormal")
ButtonColors(CGOptions)
CGOptions:SetScript("OnMouseUp", function(self)
	if MainMenu:IsShown() then
		MainMenu:Hide()
		OptionsButton:Show()
	end
end)




local fontColor = {r = 1.0, g = 1.0, b = 1.0} 
function setFontColor(r, g, b)
    fontColor.r, fontColor.g, fontColor.b = r, g, b
    --print("Font Color Set: " .. fontColor.r .. ", " .. fontColor.g .. ", " .. fontColor.b)
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
		--print("Setting font color with RGB values:", newR, newG, newB)
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
CGEditBox:SetSize(200, 30)
CGEditBox:SetSize(MainHeader:GetSize()-25, 25)
CGEditBox:SetPoint("TOPLEFT", GCchatMethod, 10, -30)
CGEditBox:SetAutoFocus(false)
CGEditBox:SetTextInsets(10, 10, 5, 5)
CGEditBox:SetMaxLetters(6)
CGEditBox:SetJustifyH("CENTER")
CGEditBox:SetText(self.db.global.wager)
-- Left Side Controls
local CGGuildPercent = CreateFrame("EditBox", nil, OptionsButton, "InputBoxTemplate")
CGGuildPercent:SetSize(100, 30)
CGGuildPercent:SetPoint("TOPLEFT", CGOptions, -10, -56)
CGGuildPercent:SetAutoFocus(false)
CGGuildPercent:SetTextInsets(10, 10, 5, 5)
CGGuildPercent:SetMaxLetters(2)
CGGuildPercent:SetJustifyH("CENTER")
CGGuildPercent:SetText(self.db.global.houseCut)
CGGuildPercent:SetScript("OnEnterPressed", EditBoxOnEnterPressed)

local CGAcceptOnes = CreateFrame("Button", nil, MainMenu, "BackdropTemplate")
CGAcceptOnes:SetSize(105, 30)
CGAcceptOnes:SetPoint("TOPLEFT", GCchatMethod, "BOTTOMLEFT", -0, -25)
CGAcceptOnes:SetText("New Game")
CGAcceptOnes:SetNormalFontObject("GameFontNormal")
ButtonColors(CGAcceptOnes)

-- Add the following lines to create the highlight effect
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
-- End of highlight effect code

CGAcceptOnes:SetScript("OnClick", function()
    CGAcceptOnes:Disable()  -- Disable the button during processing

    if CGAcceptOnes:GetText() == "Host Game" then
        CGAcceptOnes:SetText("New Game")
    else
        self.game.state = "START"
        self:SendMsg("R_NewGame")
		
		
        -- Sets same roll for everyone.
        self:SendMsg("SET_WAGER", CGEditBox:GetText())

        -- Switches everyone to the same gamemode.
        self:SendMsg("GAME_MODE", CGGameMode:GetText())

        -- Switches everyone to the proper chat method.
        self:SendMsg("Chat_Method", GCchatMethod:GetText())

        self:SendMsg("SET_HOUSE", CGGuildPercent:GetText())
		
		self.game.host = true
        self:SendMsg("New_Game")


        -- Starts a new game but only if they're the host.
    end

    CGAcceptOnes:Enable()   -- Enable the button after processing
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
-- Right Side Controls 
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
         SendChatMessage("1" , self.game.chatMethod)
        CGEnter:SetText("Leave Game")
    elseif (CGEnter:GetText() == "Leave Game") then
		SendChatMessage("-1" , self.game.chatMethod)
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

-- Options Menu Buttons

-- Left Options
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
    self.game.state = "START"
    self.game.players = {}
    self.game.result = nil
    self:resetStats(info)
end)

-- Create a button to toggle the realm filter
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

-- Function to toggle the realm filter
local function ToggleRealmFilter()
  if(self.game.realmFilter == false) then
    CGRealmFilter:SetText("Realm Filter(ON)")
	self.game.realmFilter = true
  else
    CGRealmFilter:SetText("Realm Filter(OFF)")
	self.game.realmFilter = false
  end
end

-- Set the button's OnClick behavior to toggle the realm filter
CGRealmFilter:SetScript("OnClick", ToggleRealmFilter)

-- Right Options 
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

-- Right Options 
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

local CGClassic = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGClassic:SetSize(105, 30)
CGClassic:SetPoint("TOPRIGHT", CGFameShame, "BOTTOMRIGHT", -0, -54)
CGClassic:SetText("Classic Theme")
CGClassic:SetNormalFontObject("GameFontNormal")
ButtonColors(CGClassic)
CGClassic:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
local highlight = CGClassic:GetHighlightTexture()
highlight:SetBlendMode("ADD")
highlight:SetAllPoints()

CGClassic:SetScript("OnEnter", function(self)
    highlight:Show()
end)

CGClassic:SetScript("OnLeave", function(self)
    highlight:Hide()
end)
CGClassic:SetScript("OnClick", function()
  self.db.global.theme = "Classic"
	  ReloadUI()
end)

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
ChangeColorSide:SetSize(ChangeColorButton:GetSize()) --remove the height
ChangeColorSide:SetPoint("BOTTOMLEFT", ChangeColorButton, "BOTTOMRIGHT", 0, 0) -- change position
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
ChangeColorFrame:SetSize(ChangeColorButton:GetSize()) --remove the height
ChangeColorFrame:SetPoint("BOTTOMLEFT", ChangeColorSide, "BOTTOMRIGHT", 0, 0) -- change position
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
ChangeColorReset:SetSize(ChangeColorButton:GetSize()) --remove the height
ChangeColorReset:SetPoint("BOTTOMLEFT", ChangeColorFrame, "BOTTOMRIGHT", 0, 0) -- change position
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


-- Right Side Menu
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

-- Create the text field frame within the right side menu frame
CGRightMenu.TextField = CreateFrame("ScrollingMessageFrame", nil, CGRightMenu)
CGRightMenu.TextField:SetPoint("CENTER", CGRightMenu, 2, -0)
CGRightMenu.TextField:SetSize(CGRightMenu:GetWidth()-8, -140)
CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", self.db.global.fontvalue, "")
CGRightMenu.TextField:SetFading(false)
CGRightMenu.TextField:SetJustifyH("LEFT")
CGRightMenu.TextField:SetMaxLines(50)
CGRightMenu.TextField:SetScript("OnMouseWheel", function(self, delta)
    if (delta == 1) then
        self:ScrollUp()
    else
        self:ScrollDown()
    end
end)


-- Variables to store the color and font size settings

local function OnChatSubmit(CGChatBox)
    local message = CGChatBox:GetText()
    if message ~= "" and message ~= " " then
        local playerName = UnitName("player")

        -- Apply font color to the message
        local formattedMessage = string.format("[%s]|r: |cFF%02x%02x%02x%s", playerName, fontColor.r * 255, fontColor.g * 255, fontColor.b * 255, message)
		--print("Formatted Message: " .. formattedMessage)  -- Debug print


        -- Send the modified message with player info and formatting
        local messageWithPlayerInfo = string.format("%s:%s", playerNameColor .. playerName, formattedMessage)
        self:SendMsg("CHAT_MSG", messageWithPlayerInfo)

        -- Reset chat box
        CGChatBox:SetText("")
        CGChatBox:ClearFocus()
    end
end


local fontColorButton = CreateFrame("Button", nil, CGRightMenu, "BackdropTemplate")
fontColorButton:SetSize(220, 20) --remove the height
fontColorButton:SetPoint("BOTTOMLEFT", CGRightMenu, "BOTTOMLEFT", 0, -40) -- change position
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
fontSizeSlider:SetMinMaxValues(1, 100)  -- Set the range from 1 to 100
fontSizeSlider:SetValueStep(1)
fontSizeSlider:SetObeyStepOnDrag(true)
-- Load the saved font size from self.db.global.fontvalue
fontSizeSlider:SetValue(self.db.global.fontvalue)
-- Set the slider orientation to horizontal
fontSizeSlider:SetOrientation("HORIZONTAL")
-- Set the slider's text to display the selected value
fontSizeSlider.Low:SetText("1")  
fontSizeSlider.High:SetText("100")  

-- Create a fontString to display the selected value
local sliderText = fontSizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sliderText:SetPoint("TOP", 0, -20)  
sliderText:SetText(self.db.global.fontvalue)  -- Set the initial text

-- Function to update font size and auto-save
local function UpdateFontSize(_, value)
    self.db.global.fontvalue = value
    sliderText:SetText(value)  -- Update the displayed value
    CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", self.db.global.fontvalue, "")  -- Update the chat font size
end

fontSizeSlider:SetScript("OnValueChanged", function(_, value)
    UpdateFontSize(_, value)
end)


local CallFrame = CreateFrame("Frame")
CallFrame:RegisterEvent("CHAT_MSG_ADDON")
CallFrame:SetScript("OnEvent", function(self, event, prefix, msg)
	if prefix ~= "CrossGambling" then return end
		local event_type, arg1, arg2 = strsplit(":", msg)
	if CGCall[event_type] then
		CGCall[event_type](arg1, arg2)
	elseif event_type == "CHAT_MSG" then
	local name, class, message = strmatch(msg, "CHAT_MSG:(%S+):(%S+):(.+)")
	local formatted = string.format("[%s|r]: %s", name, message)
	CGRightMenu.TextField:AddMessage(formatted)
	end
end)

local CGChatBox = CreateFrame("EditBox", nil, CGRightMenu, "BackdropTemplate")
CGChatBox:SetPoint("TOPLEFT", CGRightMenu, "BOTTOMLEFT", 0, -20)
CGChatBox:SetSize(CGRightMenu:GetWidth() - 0, -20)
ButtonColors(CGChatBox)
CGChatBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
CGChatBox:SetAutoFocus(false)
CGChatBox:SetTextInsets(10, 10, 5, 5)
CGChatBox:SetMaxLetters(55)
CGChatBox:SetText("Type Here...")
CGChatBox:SetScript("OnEnterPressed", OnChatSubmit)
CGChatBox:SetScript("OnMouseDown", function(self)
    self:SetText("")
end)

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
  
	--basic slider func
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
      --save value
	  CrossScale(self)
    end)

	function CrossScale()
		self.db.global.scale = slider:GetValue()/100
		CrossGamblingUI:SetScale(self.db.global.scale)
	end
	
-- Left Side Menu
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
    -- loop through the "CGPlayers" table
    for i, player in pairs(CGPlayers) do
        if player.name == name then
            -- remove the player from the "CGPlayers" table
            table.remove(CGPlayers, i)
            -- update the player list
            UpdatePlayerList()
            -- player found and removed, exit the function
            return
        end
    end
end


function CrossGambling:AddPlayer(playerName)
    -- First, check if the player already exists in the "CGPlayers" table
    for i, player in pairs(CGPlayers) do
        if player.name == playerName then
            -- player already exists, exit the function
            return
        end
    end
    -- create a new table to store the player's information
    local newPlayer = {
        name = playerName,
        total = 0,
    }
    -- insert the new player into the "CGPlayers" table
    table.insert(CGPlayers, newPlayer)

    -- sort the "CGPlayers" table by name
    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)
    UpdatePlayerList()
end



-- Create the main frame for the player list
local playerListFrame = CreateFrame("Frame", "PlayerListFrame", CGLeftMenu)
playerListFrame:SetSize(300, 150)
playerListFrame:SetPoint("CENTER")

-- Create a scroll frame to hold the player list
local scrollFrame = CreateFrame("ScrollFrame", "PlayerListScrollFrame", playerListFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(266, 170)
scrollFrame:SetPoint("TOPLEFT", 10, 10)

-- Enable scrolling with the mouse wheel
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
playerButtonsFrame:SetSize(280, 1)  -- Set the height to 1 for dynamic sizing
scrollFrame:SetScrollChild(playerButtonsFrame)

-- Create a new table to store the player buttons
playerButtons = {}

function UpdatePlayerList()
    -- Remove all current player buttons
    for i, button in ipairs(playerButtons) do
        button:Hide()
        button:SetParent(nil)
    end

    -- Sort the player names alphabetically
    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)

    local row = 0
    local column = 0

    -- Iterate through the sorted CGPlayers table and create a button for each player
    for i, player in ipairs(CGPlayers) do
        -- Create a button for each player
        local playerButton = CreateFrame("Button", "PlayerButton" .. i, playerButtonsFrame, "BackdropTemplate")
        playerButton:SetSize(250, 30)
        playerButton:SetPoint("TOPLEFT", 0, -row * 30)
        ButtonColors(playerButton)
		LoadColor()

        -- Create a font string for the button
        local buttonText = playerButton:CreateFontString(nil, "OVERLAY")
        buttonText:SetFont("Fonts\\FRIZQT__.TTF", 20)
        buttonText:SetPoint("LEFT", 5, 0)
        playerButton.text = buttonText

        -- Get the player's class color
        local classColor = RAID_CLASS_COLORS[select(2, UnitClass(player.name))]
        local playerNameColor = "|c" .. classColor.colorStr

        if player.roll ~= nil then
            buttonText:SetText(playerNameColor .. player.name .. "|r : |cFF000000" .. player.roll .. "|r")
        else
            buttonText:SetText(playerNameColor .. player.name .. "|r")
        end

        table.insert(playerButtons, playerButton)
        row = row + 1
    end

    -- Update the height of the scroll frame based on the number of players
    playerButtonsFrame:SetHeight(row * 30)
	

end


CGCall["PLAYER_ROLL"] = function(playerName, value)
    -- find the player in the "CGPlayers" table
    for i, player in pairs(CGPlayers) do
        if player.name == playerName then
            player.roll = value -- change roll to value
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

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")