local function normalizePlayerName(name)
    if not name then
        return nil
    end

    name = strtrim(tostring(name))
    name = strsplit("-", name, 2)
    if name == "" then
        return nil
    end

    return strlower(name)
end

local function isPlayerBanned(addon, playerName)
    local normalizedPlayerName = normalizePlayerName(playerName)
    if not normalizedPlayerName then
        return false
    end

    for _, bannedPlayer in ipairs((addon and addon.db and addon.db.global and addon.db.global.bans) or {}) do
        if normalizePlayerName(bannedPlayer) == normalizedPlayerName then
            return true
        end
    end

    return false
end

local CGPlayers = {}
local playerButtons = {}
local playerButtonsFrame
local CG = "Interface\\AddOns\\CrossGambling\\media\\CG.tga"
local Backdrop = {
	bgFile = CG,
	edgeFile = CG,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {left = 1, right = 1, top = 1, bottom = 1},

}
local playerNameColor = "|c" .. RAID_CLASS_COLORS[select(2, UnitClass("player"))].colorStr
local frameColor  = CGTheme._frameColor
local buttonColor = CGTheme._buttonColor
local sideColor   = CGTheme._sideColor
local fontColor   = CGTheme._fontColor
local BtnClr  = CGTheme._btnFrames
local SideClr = CGTheme._sideFrames

local ButtonColors = function(self)
    if not self.SetBackdrop then Mixin(self, BackdropTemplateMixin) end
    self:SetBackdrop(Backdrop)
    self:SetBackdropBorderColor(0, 0, 0)
    CGTheme:RegisterBtn(self)
end

local SideColor = function(self)
    if not self.SetBackdrop then Mixin(self, BackdropTemplateMixin) end
    self:SetBackdrop(Backdrop)
    self:SetBackdropBorderColor(0, 0, 0)
    CGTheme:RegisterSide(self)
end
local CrossGamblingUI

function CrossGambling:toggleUi()
	self:BuildUI()
	if not CrossGamblingUI then return end
	if (CrossGamblingUI:IsVisible()) then
		CrossGamblingUI:Hide()
	else
		LoadColor()
		CrossGamblingUI:Show()
	end
end

function CrossGambling:ShowSlick(info)
	self:BuildUI()
	if not CrossGamblingUI then return end
	if (CrossGamblingUI:IsVisible() ~= true) then
		CrossGamblingUI:Show()
		LoadColor()
	else
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:HideSlick(info)
	self:BuildUI()
	if not CrossGamblingUI then return end
	if (CrossGamblingUI:IsVisible()) then
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:DrawMainEvents()
    local theme = self.db and self.db.global and self.db.global.theme or "Slick"
    local isSlick = (theme == "Slick")
    local frameName = isSlick and "CrossGamblingSlick" or "CrossGamblingClassic"
    local frameTemplate = isSlick and "BackdropTemplate" or "InsetFrameTemplate"
    local mainWidth, mainHeight = isSlick and 230 or 320, isSlick and 200 or 195

    CrossGamblingUI = CreateFrame("Frame", frameName, UIParent, frameTemplate)
CrossGamblingUI:SetSize(mainWidth, mainHeight)
CrossGamblingUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
if isSlick then
    CrossGamblingUI:SetBackdrop(Backdrop)
    CrossGamblingUI:SetBackdropBorderColor(0, 0, 0)
end
CrossGamblingUI:SetMovable(true)
CrossGamblingUI:EnableMouse(true)
CrossGamblingUI:SetUserPlaced(true)
CrossGamblingUI:SetResizable(true)
CrossGamblingUI:RegisterForDrag("LeftButton")
CrossGamblingUI:SetScript("OnDragStart", CrossGamblingUI.StartMoving)
CrossGamblingUI:SetScript("OnDragStop", CrossGamblingUI.StopMovingOrSizing)
CrossGamblingUI:SetClampedToScreen(true)
self.db.global.scale = self.db.global.scale
CrossGamblingUI:SetScale(self.db.global.scale)
CrossGamblingUI:Hide()
if isSlick then
    CGTheme:RegisterMain(CrossGamblingUI)
end
CGTheme:Init()

local MainHeader = CreateFrame("Frame", nil, CrossGamblingUI, frameTemplate)
MainHeader:SetSize(CrossGamblingUI:GetSize(), 21)
MainHeader:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
MainHeader:EnableMouse(false)
if isSlick then ButtonColors(MainHeader) end

local MainMenu = CreateFrame("Frame", nil, CrossGamblingUI, frameTemplate)
MainMenu:SetSize(CrossGamblingUI:GetSize(), 21)
MainMenu:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
MainMenu:EnableMouse(false)

local OptionsButton = CreateFrame("Frame", nil, CrossGamblingUI, frameTemplate)
OptionsButton:SetSize(CrossGamblingUI:GetSize(), 21)
OptionsButton:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
OptionsButton:EnableMouse(false)
OptionsButton:Hide()

local CGMainMenu = CreateFrame("Button", nil, MainHeader, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGMainMenu:SetSize(isSlick and 63 or 100, 21)
CGMainMenu:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 30, 0)
CGMainMenu:SetFrameStrata("MEDIUM")
CGMainMenu:SetText("Main")
CGMainMenu:SetNormalFontObject("GameFontNormal")
if isSlick then ButtonColors(CGMainMenu) end
CGMainMenu:SetScript("OnMouseUp", function(self)
end)

local MainFooter = CreateFrame("Button", nil, CrossGamblingUI, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
MainFooter:SetSize(CrossGamblingUI:GetSize(), 15)
MainFooter:SetPoint("BOTTOMLEFT", CrossGamblingUI, 0, 0)
MainFooter:SetText("CrossGambling - Jay@Tichondrius")
MainFooter:SetNormalFontObject("GameFontNormal")
if isSlick then ButtonColors(MainFooter) end

local CGOptionsBtn = CreateFrame("Button", nil, MainHeader, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGOptionsBtn:SetSize(isSlick and 63 or 100, 21)
CGOptionsBtn:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", isSlick and -30 or -25, 0)
CGOptionsBtn:SetFrameStrata("MEDIUM")
CGOptionsBtn:SetText("Options")
CGOptionsBtn:SetNormalFontObject("GameFontNormal")
if isSlick then ButtonColors(CGOptionsBtn) end
CGOptionsBtn:SetScript("OnMouseUp", function(self)
    CGOptions:Toggle()
end)

local GCchatMethod = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
GCchatMethod:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
GCchatMethod:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
GCchatMethod:SetText(self.game.chatMethod)
GCchatMethod:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end
GCchatMethod:SetScript("OnClick", function() self:chatMethod() GCchatMethod:SetText(self.game.chatMethod) end)

local CGGameMode = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGGameMode:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGGameMode:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -2)
CGGameMode:SetText(self.game.mode)
CGGameMode:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end
CGGameMode:SetScript("OnClick", function() self:changeGameMode() CGGameMode:SetText(self.game.mode) end)

local CGEditBox = CreateFrame("EditBox", nil, MainMenu, "InputBoxTemplate")
CGEditBox:SetPoint("TOPLEFT",  GCchatMethod, "BOTTOMLEFT",  0, -2)
CGEditBox:SetPoint("TOPRIGHT", CGGameMode,   "BOTTOMRIGHT", 0, -2)
CGEditBox:SetHeight(22)
CGEditBox:SetAutoFocus(false)
CGEditBox:SetTextInsets(10, 10, 5, 5)
CGEditBox:SetMaxLetters(6)
CGEditBox:SetJustifyH("CENTER")
CGEditBox:SetText(self.db.global.wager or "")
CGEditBox:SetScript("OnEnterPressed", function(box)
    local value = tonumber(box:GetText())
    if value then CrossGambling.db.global.wager = value end
    box:ClearFocus()
end)
CGEditBox:SetScript("OnTextChanged", function(box, userInput)
    if userInput then
        local value = tonumber(box:GetText())
        if value then CrossGambling.db.global.wager = value end
    end
end)
CGEditBox:SetScript("OnEditFocusLost", function(box)
    local value = tonumber(box:GetText())
    if value then CrossGambling.db.global.wager = value end
end)

local CGLastCall
local CGStartRoll
local CGEnter

local CGAcceptOnes = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGAcceptOnes:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGAcceptOnes:SetPoint("TOPLEFT", GCchatMethod, "BOTTOMLEFT", -0, -25)
CGAcceptOnes:SetText("New Game")
CGAcceptOnes:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end

local CGGuildPercent = CreateFrame("EditBox", nil, OptionsButton, "InputBoxTemplate")
CGGuildPercent:SetSize(isSlick and 100 or 140, 30)
if isSlick then
    CGGuildPercent:SetPoint("TOPRIGHT", CGOptionsBtn, "BOTTOMRIGHT", 25, -47)
else
    CGGuildPercent:SetPoint("TOPLEFT", CGOptionsBtn, -22, -85)
end
CGGuildPercent:SetAutoFocus(false)
CGGuildPercent:SetTextInsets(10, 10, 5, 5)
CGGuildPercent:SetMaxLetters(2)
CGGuildPercent:SetJustifyH("CENTER")
CGGuildPercent:SetText(self.db.global.houseCut)
CGGuildPercent:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        CrossGambling.db.global.houseCut = value
    end
    self:ClearFocus()
end)
CGGuildPercent:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
CGGuildPercent:SetScript("OnEditFocusLost", function(self)
    self:HighlightText(0, 0)
    local value = tonumber(self:GetText())
    if value then CrossGambling.db.global.houseCut = value end
end)

CGAcceptOnes:SetScript("OnClick", function()
    CGAcceptOnes:Disable()

    if CGAcceptOnes:GetText() == "Host Game" then
        CGAcceptOnes:SetText("New Game")
    else
        self.game.state = "START"
        self.game.host = true
        self.db.global.wager = tonumber(CGEditBox:GetText()) or self.db.global.wager
        self.game.mode = CGGameMode:GetText()
        self.game.chatMethod = GCchatMethod:GetText()
        self.db.global.houseCut = CGGuildPercent:GetText()

        for i = #CGPlayers, 1, -1 do
            CrossGambling:RemovePlayer(CGPlayers[i].name)
        end
        CGStartRoll:SetText("Start Rolling")
        CGEnter:Enable()

        self:RegisterChatEvents()
        self.game.state = "REGISTER"
        self:GameStart()

        if self.game.house == false then
            self:SendChat("Game Mode - " .. self.game.mode .. " - Wager - " .. self:addCommas(self.db.global.wager) .. "g")
        else
            self:SendChat("Game Mode - " .. self.game.mode .. " - Wager - " .. self:addCommas(self.db.global.wager) .. "g - House Cut - " .. self.db.global.houseCut .. "%")
        end

        self:SendMsg("R_NewGame")
        self:SendMsg("New_Game")
        self:SendMsg("SET_WAGER", self.db.global.wager)
        self:SendMsg("GAME_MODE", self.game.mode)
        self:SendMsg("Chat_Method", self.game.chatMethod)
        self:SendMsg("SET_HOUSE", self.db.global.houseCut)
    end

    CGAcceptOnes:Enable()
    CGLastCall:Enable()
    CGStartRoll:Enable()
end)



CGLastCall = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGLastCall:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGLastCall:SetPoint("TOPLEFT", CGAcceptOnes, "BOTTOMLEFT", -0, -3)
CGLastCall:SetText("Last Call!")
CGLastCall:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end
CGLastCall:SetScript("OnClick", function()
    self:SendMsg("LastCall")
end)

CGStartRoll = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGStartRoll:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGStartRoll:SetPoint("TOPLEFT", CGLastCall, "BOTTOMLEFT", -0, -3)
CGStartRoll:SetText("Start Rolling")
CGStartRoll:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end
CGStartRoll:SetScript("OnClick", function()
    self:CGRolls()
    CGStartRoll:SetText("Whos Left?")
end)

CGEnter = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGEnter:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGEnter:SetPoint("TOPLEFT", CGGameMode, "BOTTOMLEFT", -0, -25)
CGEnter:SetText("Join")
CGEnter:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end

local function CGEnter_UpdateJoinText()
    CGEnter:SetText("Join")
end

CGEnter:SetScript("OnClick", function()
    local joinWord  = self.db.global.joinWord  or "1"
    local leaveWord = self.db.global.leaveWord or "-1"
    if CGEnter:GetText() == "Leave" then
        self:SendChat(leaveWord)
        CGEnter:SetText("Join")
    else
        self:SendChat(joinWord)
        CGEnter:SetText("Leave")
    end
end)

local CGRollMe = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGRollMe:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGRollMe:SetPoint("TOPLEFT", CGEnter, "BOTTOMLEFT", -0, -3)
CGRollMe:SetText("Roll Me")
CGRollMe:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end
CGRollMe:SetScript("OnClick", function()
  self:rollMe()
end)

local CGCloseGame = CreateFrame("Button", nil, MainMenu, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
CGCloseGame:SetSize(isSlick and 105 or 150, isSlick and 30 or 28)
CGCloseGame:SetPoint("TOPLEFT", CGRollMe, "BOTTOMLEFT", -0, -3)
CGCloseGame:SetText("Close")
CGCloseGame:SetNormalFontObject("GameFontNormal")
if isSlick then
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
end
CGCloseGame:SetScript("OnClick", function()
  CrossGamblingUI:Hide()
end)



local width, height = CrossGamblingUI:GetSize()
local auditFrame = CreateFrame("Frame", "CrossGamblingAuditLogFrame", UIParent, "BackdropTemplate")
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
    CrossGambling.db.global.auditLog = {}
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
    if self:IsShown() then
        CrossGambling:UpdateAuditLogText(searchBox:GetText())
    end
end
auditFrame:SetScript("OnSizeChanged", auditFrame.UpdateLayout)

searchBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
        CrossGambling:UpdateAuditLogText(self:GetText())
    end
end)

local CGHistoryLog = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGHistoryLog:SetSize(105, 14)
CGHistoryLog:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -2)
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
    self:TrimAuditLog()
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
    local scrollFrame = self.auditFrame.scrollFrame
    local content = self.auditFrame.content

    if not content then
        content = CreateFrame("Frame", nil, scrollFrame)
        content:SetPoint("TOPLEFT")
        content:SetPoint("RIGHT")
        scrollFrame:SetScrollChild(content)
        self.auditFrame.content = content
        content._fontPool = {}
        content._fontUsed = 0
    end

    local pool = content._fontPool
    for i = 1, #pool do
        pool[i]:SetText("")
        pool[i]:Hide()
    end
    content._fontUsed = 0

    content:SetSize(1, 1)

    local log = self.db.global.auditLog or {}
    if #log == 0 then
        local fs = pool[1]
        if not fs then
            fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pool[1] = fs
        end
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        fs:SetText("No audit entries found.")
        fs:Show()
        content._fontUsed = 1
        content:SetHeight(30)
        scrollFrame:SetVerticalScroll(0)
        return
    end

    local yOffset, spacing = -10, 10
    local maxWidth = 560
    local poolIdx = 0

    for _, entry in ipairs(log) do
        if type(entry) == "table" then
            local ts = FormatTimestamp(tonumber(entry.timestamp) or 0)
            local textLine

            if entry.action == "updateStat" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100\226\128\162|r Stats updated for |cffffff00%s|r\n    Before: |cffffff00%d|r\n    Change: |cffff8800%+d|r    After: |cff00ff00%d|r",
                    ts, entry.player or "?", entry.oldAmount or 0, entry.addedAmount or 0, entry.newAmount or 0)
            elseif entry.action == "joinStats" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100\226\128\162|r Joined alt |cffffff00%s|r to main |cffffff00%s|r\n    +%d stats, +%d deathroll",
                    ts, entry.altname or "?", entry.mainname or "?", entry.statsAdded or 0, entry.deathrollStatsAdded or 0)
            elseif entry.action == "unjoinStats" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100\226\128\162|r Unjoined alt |cffffff00%s|r from main |cffffff00%s|r\n    -%d stats, -%d deathroll",
                    ts, entry.altname or "?", entry.mainname or "?", entry.pointsRemoved or 0, entry.deathrollStatsRemoved or 0)
            elseif entry.action == "debt" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100\226\128\162|r |cffffff00%s|r owes |cffffff00%s|r %dg",
                    ts, entry.loser or "?", entry.winner or "?", entry.amount or 0)
            else
                local extra = {}
                for k, v in pairs(entry) do
                    table.insert(extra, k .. "=" .. tostring(v))
                end
                textLine = string.format("|cff999999[%s]|r Unknown entry:\n%s", ts, table.concat(extra, ", "))
            end

            if not filter or filter == "" or textLine:lower():find(filter:lower(), 1, true) then
                poolIdx = poolIdx + 1
                local fs = pool[poolIdx]
                if not fs then
                    fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    pool[poolIdx] = fs
                end
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", 10, yOffset)
                fs:SetWidth(maxWidth)
                fs:SetJustifyH("LEFT")
                fs:SetWordWrap(true)
                fs:SetText(textLine)
                fs:Show()
                yOffset = yOffset - fs:GetStringHeight() - spacing
            end
        end
    end

    content._fontUsed = poolIdx
    local totalHeight = math.max(30, -yOffset + spacing)
    content:SetHeight(totalHeight)
    scrollFrame:SetVerticalScroll(0)
end

local CGClassic = CreateFrame("Button", nil, OptionsButton, "BackdropTemplate")
CGClassic:SetSize(105, 30)
CGClassic:SetPoint("TOPRIGHT", CGGuildPercent, "BOTTOMRIGHT", 0, -25)
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
	local current = self.db.global.theme or "Slick"
	if current == "Classic" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100CrossGambling|r: Already using Classic theme.")
		return
	end
	self.uiBuilt = false
	CGTheme:Switch("Classic")
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
ChangeColorButton:SetScript("OnMouseUp", function() CGTheme:ChangeColor("buttons") end)

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
ChangeColorSide:SetScript("OnMouseUp", function() CGTheme:ChangeColor("sidecolor") end)

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
ChangeColorFrame:SetScript("OnMouseUp", function() CGTheme:ChangeColor("frame") end)

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
ChangeColorReset:SetScript("OnMouseUp", function() CGTheme:ChangeColor("resetColors") end)

local cgRightMenu = CGChat:BuildChatPanel(
    CrossGamblingUI,
    self.game,
    ButtonColors,
    SideColor
)


local cgChatToggle = CGChat:BuildToggleButton(
    MainHeader,
    ButtonColors,
    self.game
)

local CGRightMenu = cgRightMenu

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

	local function CrossScale()
		self.db.global.scale = slider:GetValue()/100
		CrossGamblingUI:SetScale(self.db.global.scale)
	end

    slider:HookScript("OnMouseUp", function(self,value)
	  CrossScale(self)
    end)
	
local CGLeftMenu = CreateFrame("Frame", "CGLeftMenu", CrossGamblingUI, "BackdropTemplate")
CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
CGLeftMenu:SetSize(300, 180)
SideColor(CGLeftMenu)
CGLeftMenu:Show()

local function onUpdate(self, elapsed)
    local mainX, mainY = CrossGamblingUI:GetCenter()
    local leftX, leftY = CGLeftMenu:GetCenter()
    local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
    if distance < 260 then
        CGLeftMenu:ClearAllPoints()
        CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
        CGLeftMenu:SetScript("OnUpdate", nil)
    end
end

CGLeftMenu:SetMovable(true)
CGLeftMenu:EnableMouse(true)
CGLeftMenu:SetUserPlaced(true)
CGLeftMenu:SetClampedToScreen(true)
CGLeftMenu:Hide()

CGLeftMenu:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
        self:SetScript("OnUpdate", onUpdate)
    end
end)
CGLeftMenu:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        self:SetScript("OnUpdate", onUpdate)
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
            self:UpdatePlayerList()
            return
        end
    end
end


function CrossGambling:AddPlayer(playerName)
    if isPlayerBanned(self, playerName) then
        return
    end

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
    self:UpdatePlayerList()
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

playerButtonsFrame = CreateFrame("Frame", "PlayerButtonsFrame", scrollFrame)
playerButtonsFrame:SetSize(280, 1) 
scrollFrame:SetScrollChild(playerButtonsFrame)

playerButtons = {}

function CrossGambling:UpdatePlayerList()
    for i, button in ipairs(playerButtons) do
        button:Hide()
    end

    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)

    local row = 0

    for i, player in ipairs(CGPlayers) do
        local playerButton = playerButtons[i]
        if not playerButton then
            playerButton = CreateFrame("Button", "PlayerButton"..i, playerButtonsFrame, "BackdropTemplate")
            playerButton:SetSize(250, 30)
            ButtonColors(playerButton)
            LoadColor()

            local buttonText = playerButton:CreateFontString(nil, "OVERLAY")
            buttonText:SetFont("Fonts\\FRIZQT__.TTF", 20)
            buttonText:SetPoint("LEFT", 5, 0)
            playerButton.text = buttonText
            playerButtons[i] = playerButton
        end

        playerButton:ClearAllPoints()
        playerButton:SetPoint("TOPLEFT", 0, -row * 30)
        playerButton:Show()

        local _, class = UnitClass(player.name)
        local classColor = class and RAID_CLASS_COLORS[class]

        if classColor and classColor.colorStr then
            local playerNameColor = "|c"..classColor.colorStr
            if player.roll then
                playerButton.text:SetText(playerNameColor..player.name.."|r : |cFF000000"..player.roll.."|r")
            else
                playerButton.text:SetText(playerNameColor..player.name.."|r")
            end
        else
            if player.roll then
                playerButton.text:SetText("|cffffffff"..player.name.."|r : |cFF000000"..player.roll.."|r")
            else
                playerButton.text:SetText("|cffffffff"..player.name.."|r")
            end
        end

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
    CrossGambling:UpdatePlayerList()
end

CGCall["R_NewGame"] = function()
    for i = #CGPlayers, 1, -1 do
        CrossGambling:RemovePlayer(CGPlayers[i].name)
    end
	CGEnter_UpdateJoinText()
	CGStartRoll:SetText("Start Rolling")
	CGEnter:Enable()
end

CGCall["DisableClient"] = function()
		CGAcceptOnes:Disable()
		CGLastCall:Disable()
		CGStartRoll:Disable()
		CrossGambling.game.players = {}
		CrossGambling.game.result = nil
	if(CrossGambling.game.host) then
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
