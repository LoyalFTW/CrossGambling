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
local function GetAddonRef()
    local ok, addon = pcall(function()
        return LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    end)
    if ok and addon then
        return addon
    end
    return CrossGambling
end

local function GetAuditRetentionOptionsLocal()
    local addon = GetAddonRef()
    if type(addon.GetAuditRetentionOptions) == "function" then
        return addon:GetAuditRetentionOptions()
    end
    return {5, 10, 30, "Never"}
end

local function GetAuditRetentionValueLocal()
    local addon = GetAddonRef()
    if type(addon.GetAuditRetentionValue) == "function" then
        return addon:GetAuditRetentionValue()
    end

    local retention = addon.db and addon.db.global and addon.db.global.auditRetention or 30
    if retention == -1 then
        retention = "Never"
    end
    retention = tonumber(retention) or retention
    for _, option in ipairs(GetAuditRetentionOptionsLocal()) do
        if option == retention then
            return option
        end
    end
    return 30
end

local function SetAuditRetentionLocal(retention)
    local addon = GetAddonRef()
    if type(addon.SetAuditRetention) == "function" then
        addon:SetAuditRetention(retention)
        return
    end

    if retention == -1 then
        retention = "Never"
    end
    if addon.db and addon.db.global then
        addon.db.global.auditRetention = tonumber(retention) or retention
        if type(addon.TrimAuditLog) == "function" then
            addon:TrimAuditLog()
        end
    end
end

local function RefreshAuditLogLocal(filter)
    local addon = GetAddonRef()
    if not addon.auditFrame or not addon.auditFrame.scrollFrame then
        return
    end

    local scrollFrame = addon.auditFrame.scrollFrame
    local content = addon.auditFrame.content
    if not content then
        content = CreateFrame("Frame", nil, scrollFrame)
        content:SetPoint("TOPLEFT")
        content:SetPoint("RIGHT")
        scrollFrame:SetScrollChild(content)
        addon.auditFrame.content = content
    end

    content._fontPool = content._fontPool or {}
    content._fontUsed = content._fontUsed or 0

    local pool = content._fontPool
    for i = 1, #pool do
        pool[i]:SetText("")
        pool[i]:Hide()
    end
    content._fontUsed = 0
    content:SetSize(1, 1)

    local log = (addon.db and addon.db.global and addon.db.global.auditLog) or {}
    if #log == 0 then
        local fs = pool[1]
        if not fs then
            fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pool[1] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        fs:SetText("No audit entries found.")
        fs:Show()
        content._fontUsed = 1
        content:SetHeight(30)
        scrollFrame:SetVerticalScroll(0)
        return
    end

    local loweredFilter = filter and filter ~= "" and filter:lower() or nil
    local yOffset, spacing = -10, 10
    local maxWidth = 560
    local poolIdx = 0
    local function formatTimestamp(ts)
        local t = date("*t", ts)
        return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
    end

    for _, entry in ipairs(log) do
        if type(entry) == "table" then
            local ts = formatTimestamp(tonumber(entry.timestamp) or 0)
            local textLine

            if entry.action == "updateStat" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100*|r Stats updated for |cffffff00%s|r\n    Before: |cffffff00%d|r\n    Change: |cffff8800%+d|r    After: |cff00ff00%d|r",
                    ts, entry.player or "?", entry.oldAmount or 0, entry.addedAmount or 0, entry.newAmount or 0)
            elseif entry.action == "joinStats" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100*|r Joined alt |cffffff00%s|r to main |cffffff00%s|r\n    +%d stats, +%d deathroll",
                    ts, entry.altname or "?", entry.mainname or "?", entry.statsAdded or 0, entry.deathrollStatsAdded or 0)
            elseif entry.action == "unjoinStats" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100*|r Unjoined alt |cffffff00%s|r from main |cffffff00%s|r\n    -%d stats, -%d deathroll",
                    ts, entry.altname or "?", entry.mainname or "?", entry.pointsRemoved or 0, entry.deathrollStatsRemoved or 0)
            elseif entry.action == "debt" then
                textLine = string.format(
                    "|cff999999[%s]|r\n|cffffd100*|r |cffffff00%s|r owes |cffffff00%s|r %dg",
                    ts, entry.loser or "?", entry.winner or "?", entry.amount or 0)
            else
                local extra = {}
                for k, v in pairs(entry) do
                    table.insert(extra, k .. "=" .. tostring(v))
                end
                table.sort(extra)
                textLine = string.format("|cff999999[%s]|r Unknown entry:\n%s", ts, table.concat(extra, ", "))
            end

            if not loweredFilter or textLine:lower():find(loweredFilter, 1, true) then
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

    if poolIdx == 0 then
        local fs = pool[1]
        if not fs then
            fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pool[1] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        fs:SetText("No audit entries found.")
        fs:Show()
        content._fontUsed = 1
        content:SetHeight(30)
    else
        content._fontUsed = poolIdx
        content:SetHeight(math.max(30, -yOffset + spacing))
    end

    scrollFrame:SetVerticalScroll(0)
end
local CrossGamblingUI
function CrossGambling:toggleUi2()
	self:BuildUI()
	if not CrossGamblingUI then return end
	if (CrossGamblingUI:IsVisible()) then
		CrossGamblingUI:Hide()
	else
		CrossGamblingUI:Show()
	end
end

function CrossGambling:ShowClassic(info)
	self:BuildUI()
	if not CrossGamblingUI then return end
	if (CrossGamblingUI:IsVisible() ~= true) then
		CrossGamblingUI:Show()
	else
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:HideClassic(info)
	self:BuildUI()
	if not CrossGamblingUI then return end
	if (CrossGamblingUI:IsVisible()) then
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:DrawMainEvents2()
CrossGamblingUI = CreateFrame("Frame", "CrossGamblingClassic", UIParent, "InsetFrameTemplate")
CrossGamblingUI:SetSize(320, 195) 
CrossGamblingUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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
CGTheme:Init()

local MainHeader = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
MainHeader:SetSize(CrossGamblingUI:GetSize(), 21)
MainHeader:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
MainHeader:EnableMouse(false)

local MainMenu = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
MainMenu:SetSize(CrossGamblingUI:GetSize(), 21)
MainMenu:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
MainMenu:EnableMouse(false)

local OptionsButton = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
OptionsButton:SetSize(CrossGamblingUI:GetSize(), 21)
OptionsButton:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
OptionsButton:EnableMouse(false)
OptionsButton:Hide()

local CGMainMenu = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGMainMenu:SetSize(100, 21)
CGMainMenu:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 30, 0)
CGMainMenu:SetFrameStrata("MEDIUM")
CGMainMenu:SetText("Main")
CGMainMenu:SetNormalFontObject("GameFontNormal")
CGMainMenu:SetScript("OnMouseUp", function(self)
	if OptionsButton:IsShown() then
		OptionsButton:Hide()
		MainMenu:Show()
	end
	
end)

local MainFooter = CreateFrame("Button", nil, CrossGamblingUI, "InsetFrameTemplate")
MainFooter:SetSize(CrossGamblingUI:GetSize(), 15)
MainFooter:SetPoint("BOTTOMLEFT", CrossGamblingUI, 0, 0)
MainFooter:SetText("CrossGambling - Jay@Tichondrius")
MainFooter:SetNormalFontObject("GameFontNormal")

local CGOptionsBtn = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGOptionsBtn:SetSize(100, 21)
CGOptionsBtn:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", -25, 0)
CGOptionsBtn:SetFrameStrata("MEDIUM")
CGOptionsBtn:SetText("Options")
CGOptionsBtn:SetNormalFontObject("GameFontNormal")
CGOptionsBtn:SetScript("OnMouseUp", function(self)
    CGOptions:Toggle()
end)

local GCchatMethod = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
GCchatMethod:SetSize(150, 28)
GCchatMethod:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
GCchatMethod:SetText(self.game.chatMethod)
GCchatMethod:SetNormalFontObject("GameFontNormal")
GCchatMethod:SetScript("OnClick", function() self:chatMethod() GCchatMethod:SetText(self.game.chatMethod) end)

local CGGameMode = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGGameMode:SetSize(150, 28)
CGGameMode:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -2)
CGGameMode:SetText(self.game.mode)
CGGameMode:SetNormalFontObject("GameFontNormal")
CGGameMode:SetScript("OnClick", function() self:changeGameMode() CGGameMode:SetText(self.game.mode) end)

local CGEditBox

local CGGuildPercent = CreateFrame("EditBox", nil, OptionsButton, "InputBoxTemplate")
CGGuildPercent:SetSize(140, 30)
CGGuildPercent:SetPoint("TOPLEFT", CGOptionsBtn, -22, -85)
CGGuildPercent:SetAutoFocus(false)
CGGuildPercent:SetMaxLetters(2)
CGGuildPercent:SetJustifyH("CENTER")
CGGuildPercent:SetText(self.db.global.houseCut)
CGGuildPercent:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then CrossGambling.db.global.houseCut = value end
        self:ClearFocus()
    end)

CGEditBox = CreateFrame("EditBox", nil, MainMenu, "InputBoxTemplate")
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

local CGAcceptOnes = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGAcceptOnes:SetSize(150, 28)
CGAcceptOnes:SetPoint("TOPLEFT", GCchatMethod, "BOTTOMLEFT", -0, -25)
CGAcceptOnes:SetText("New Game")
CGAcceptOnes:SetNormalFontObject("GameFontNormal")

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
        if CGStartRoll then CGStartRoll:SetText("Start Rolling") end
        if CGEnter then CGEnter:Enable() end

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
    if CGLastCall then CGLastCall:Enable() end
    if CGStartRoll then CGStartRoll:Enable() end
end)


CGLastCall = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGLastCall:SetSize(150, 28)
CGLastCall:SetPoint("TOPLEFT", CGAcceptOnes, "BOTTOMLEFT", -0, -3)
CGLastCall:SetText("Last Call!")
CGLastCall:SetNormalFontObject("GameFontNormal")
CGLastCall:SetScript("OnClick", function()
self:SendMsg("LastCall")
end)

CGStartRoll = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGStartRoll:SetSize(150, 28)
CGStartRoll:SetPoint("TOPLEFT", CGLastCall, "BOTTOMLEFT", -0, -3)
CGStartRoll:SetText("Start Rolling")
CGStartRoll:SetNormalFontObject("GameFontNormal")
CGStartRoll:SetScript("OnClick", function()
self:CGRolls()
CGStartRoll:SetText("Whos Left?")
end)

CGEnter = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGEnter:SetSize(150, 28)
CGEnter:SetPoint("TOPLEFT", CGGameMode, "BOTTOMLEFT", -0, -25)
CGEnter:SetText("Join")
CGEnter:SetNormalFontObject("GameFontNormal")
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


local CGRollMe = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGRollMe:SetSize(150, 28)
CGRollMe:SetPoint("TOPLEFT", CGEnter, "BOTTOMLEFT", -0, -3)
CGRollMe:SetText("Roll Me")
CGRollMe:SetNormalFontObject("GameFontNormal")
CGRollMe:SetScript("OnClick", function()
  self:rollMe()
end)

local CGCloseGame = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGCloseGame:SetSize(150, 28)
CGCloseGame:SetPoint("TOPLEFT", CGRollMe, "BOTTOMLEFT", -0, -3)
CGCloseGame:SetText("Close")
CGCloseGame:SetNormalFontObject("GameFontNormal")
CGCloseGame:SetScript("OnClick", function()
  CrossGamblingUI:Hide()
end)



local auditFrame = CreateFrame("Frame", "CrossGamblingAuditLogFrame", UIParent, "BasicFrameTemplateWithInset")
auditFrame:SetSize(CrossGamblingUI:GetSize())
auditFrame:SetPoint("TOP", CrossGamblingUI, "BOTTOM", 0, 30)
auditFrame:SetResizeBounds(300, 200, 800, 800)
auditFrame:SetMovable(true)
auditFrame:SetResizable(true)
auditFrame:EnableMouse(true)
auditFrame:RegisterForDrag("LeftButton")
auditFrame:SetScript("OnDragStart", auditFrame.StartMoving)
auditFrame:SetScript("OnDragStop", auditFrame.StopMovingOrSizing)
auditFrame:Hide()

auditFrame.TitleText:SetText("History Log")

local resizeButton = CreateFrame("Button", nil, auditFrame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", -4, 4)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeButton:SetScript("OnMouseDown", function(_, btn)
    if btn == "LeftButton" then auditFrame:StartSizing("BOTTOMRIGHT") end
end)
resizeButton:SetScript("OnMouseUp", function(_, btn)
    if btn == "LeftButton" then
        auditFrame:StopMovingOrSizing()
        auditFrame:UpdateLayout()
    end
end)

local searchBox = CreateFrame("EditBox", nil, auditFrame, "InputBoxTemplate")
searchBox:SetSize(200, 20)
searchBox:SetPoint("TOPLEFT", 15, -35)
searchBox:SetAutoFocus(false)

local purgeButton = CreateFrame("Button", nil, auditFrame, "UIPanelButtonTemplate")
purgeButton:SetSize(70, 24)
purgeButton:SetPoint("TOPRIGHT", -10, -33)
purgeButton:SetText("Purge Now")
purgeButton:SetScript("OnClick", function()
    CrossGambling.db.global.auditLog = {}
    RefreshAuditLogLocal(searchBox:GetText())
end)

local retentionDays = GetAuditRetentionOptionsLocal()
local retentionCheckboxes = {}

local function OnRetentionChanged(self)
    for _, cb in pairs(retentionCheckboxes) do cb:SetChecked(false) end
    self:SetChecked(true)
    SetAuditRetentionLocal(self.days)
    RefreshAuditLogLocal(searchBox:GetText() or "")
end

local lastCB
for i, val in ipairs(retentionDays) do
    local cb = CreateFrame("CheckButton", nil, auditFrame, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", (i-1)*55, -10)
    cb.Text:SetText(type(val) == "number" and val .. "d" or "Never")
    cb.days = val
    cb:SetScript("OnClick", OnRetentionChanged)
    retentionCheckboxes[i] = cb
    lastCB = cb
end

local scrollFrame = CreateFrame("ScrollFrame", nil, auditFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -100)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 15)

local content = CreateFrame("Frame", nil, scrollFrame)
scrollFrame:SetScrollChild(content)
content._fontPool = {}
content._fontUsed = 0

auditFrame.searchBox = searchBox
auditFrame.scrollFrame = scrollFrame
auditFrame.content = content

function auditFrame:UpdateLayout()
    local width, height = self:GetSize()
    scrollFrame:SetWidth(width - 50)
    content:SetWidth(scrollFrame:GetWidth())
    if self:IsShown() then
        RefreshAuditLogLocal(searchBox:GetText())
    end
end
auditFrame:SetScript("OnSizeChanged", auditFrame.UpdateLayout)

searchBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
        RefreshAuditLogLocal(self:GetText())
    end
end)



GetAddonRef().auditFrame = auditFrame

function CrossGambling:PurgeOldAuditEntries()
    self:TrimAuditLog()
end

C_Timer.After(0.1, function()
    if not CrossGambling.db or not CrossGambling.db.global then
        return 
    end

    for _, cb in pairs(retentionCheckboxes) do
        if GetAuditRetentionValueLocal() == cb.days then
            cb:SetChecked(true)
        end
    end
end)


local function FormatTimestamp(ts)
    local t = date("*t", ts)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function CrossGambling:UpdateAuditLogText(filter)
    if not self.auditFrame or not self.auditFrame.scrollFrame then
        return
    end

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

    if not content._fontPool then
        content._fontPool = {}
    end
    if not content._fontUsed then
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




local CGRightMenu = CreateFrame("Frame", "CGRightMenu", CrossGamblingUI, "InsetFrameTemplate")
CGRightMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPRIGHT", 0, 0)
CGRightMenu:SetSize(220, 150)
CGRightMenu:Hide()

local function onUpdate(self,elapsed)
    local mainX, mainY = CrossGamblingUI:GetCenter()
    local leftX, leftY = CGRightMenu:GetCenter()
    local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
    if distance < 260 then
        CGRightMenu:ClearAllPoints()
        CGRightMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPRIGHT", 0, 0)
        CGRightMenu:SetScript("OnUpdate", nil)
    end
end

CGRightMenu:SetMovable(true)
CGRightMenu:EnableMouse(true)
CGRightMenu:SetUserPlaced(true)
CGRightMenu:SetClampedToScreen(true)

CGRightMenu:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
        self:SetScript("OnUpdate", onUpdate)
    end
end)
CGRightMenu:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        self:SetScript("OnUpdate", onUpdate)
    end
end)

CGRightMenu.TextField = CreateFrame("ScrollingMessageFrame", nil, CGRightMenu)
CGRightMenu.TextField:SetPoint("TOPLEFT",     CGRightMenu, "TOPLEFT",  4, -4)
CGRightMenu.TextField:SetPoint("BOTTOMRIGHT", CGRightMenu, "BOTTOMRIGHT", -4, 30)
CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
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

local function OnChatSubmit(CGChatBox)
    local message = CGChatBox:GetText()
    if message ~= "" and message ~= " " then
        local playerName = UnitName("player")
	local playerClass = select(2, UnitClass("player"))
	local messageWithPlayerInfo = string.format("%s:%s:%s", playerName, playerClass, message)
		self:SendMsg("CHAT_MSG", messageWithPlayerInfo)
    end
    CGChatBox:SetText("")
    CGChatBox:ClearFocus()
end

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

local PLACEHOLDER = "Type Here..."
local CGChatBox = CreateFrame("EditBox", nil, CGRightMenu, "InputBoxTemplate")
CGChatBox:SetPoint("BOTTOMLEFT",  CGRightMenu, "BOTTOMLEFT",  5, 6)
CGChatBox:SetPoint("BOTTOMRIGHT", CGRightMenu, "BOTTOMRIGHT", -5, 6)
CGChatBox:SetHeight(22)
CGChatBox:SetAutoFocus(false)
CGChatBox:SetTextInsets(4, 4, 0, 0)
CGChatBox:SetMaxLetters(55)
CGChatBox:SetText(PLACEHOLDER)
CGChatBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == PLACEHOLDER then self:SetText("") end
end)
CGChatBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then self:SetText(PLACEHOLDER) end
end)
CGChatBox:SetScript("OnEscapePressed", function(self)
    self:SetText(PLACEHOLDER) self:ClearFocus()
end)
CGChatBox:SetScript("OnEnterPressed", OnChatSubmit)

local CGChatToggle = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGChatToggle:SetSize(20, 21) 
CGChatToggle:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", 0, 0)
CGChatToggle:SetText(">")
CGChatToggle:SetNormalFontObject("GameFontNormal")
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

	local function CrossScale()
		self.db.global.scale = slider:GetValue()/100
		CrossGamblingUI:SetScale(self.db.global.scale)
	end

    slider:HookScript("OnMouseUp", function(self,value)
	  CrossScale(self)
    end)
	
local CGLeftMenu = CreateFrame("Frame", "CGLeftMenu", CrossGamblingUI, "InsetFrameTemplate")
CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
CGLeftMenu:SetSize(300, 180)
CGLeftMenu:Hide()

local function onUpdate(self,elapsed)
    local mainX, mainY = CrossGamblingUI:GetCenter()
    local leftX, leftY = CGLeftMenu:GetCenter()
    local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
    if distance < 300 then
        CGLeftMenu:ClearAllPoints()
        CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
        CGLeftMenu:SetScript("OnUpdate", nil)
    end
end

CGLeftMenu:SetMovable(true)
CGLeftMenu:EnableMouse(true)
CGLeftMenu:SetUserPlaced(true)
CGLeftMenu:SetClampedToScreen(true)

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

local CGLeftMenuHeader = CreateFrame("Button", nil, CGLeftMenu, "UIPanelButtonTemplate")
CGLeftMenuHeader:SetSize(CGLeftMenu:GetSize(), 21) 
CGLeftMenuHeader:SetPoint("TOPLEFT", CGLeftMenu, "TOPLEFT", 0, 20)
CGLeftMenuHeader:SetFrameLevel(15)
CGLeftMenuHeader:SetText("Roll Tracker")
CGLeftMenuHeader:SetNormalFontObject("GameFontNormal")

local CGMenuToggle = CreateFrame("Button", nil, MainHeader,  "UIPanelButtonTemplate")
CGMenuToggle:SetSize(20, 21) 
CGMenuToggle:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 0, 0)
CGMenuToggle:SetFrameLevel(15)
CGMenuToggle:SetText("<")
CGMenuToggle:SetNormalFontObject("GameFontNormal")
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
scrollFrame:SetPoint("TOPLEFT", 10, 15)
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
    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)

    for i, button in ipairs(playerButtons) do
        button:Hide()
    end

    for i, player in ipairs(CGPlayers) do
        local playerButton = playerButtons[i]
        if not playerButton then
            playerButton = CreateFrame("Button", "PlayerButton"..i, playerButtonsFrame, "InsetFrameTemplate")
            playerButton:SetSize(260, 20)
            playerButton:SetNormalFontObject("GameFontNormal")
            playerButton:SetHighlightFontObject("GameFontHighlight")
            playerButtons[i] = playerButton
        end

        playerButton:ClearAllPoints()
        playerButton:SetPoint("TOPLEFT", playerButtonsFrame, 0, -i * 20)
        playerButton:Show()

        if player.roll ~= nil then
            playerButton:SetText(player.name .. " : " .. player.roll)
        else
            playerButton:SetText(player.name)
        end
    end

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
