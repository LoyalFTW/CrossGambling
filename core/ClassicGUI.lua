local CrossGamblingUI
function CrossGambling:toggleUi2()
if (CrossGamblingUI:IsVisible()) then
CrossGamblingUI:Hide()
else
CrossGamblingUI:Show()
end
end

function CrossGambling:ShowClassic(info)
	if (CrossGamblingUI:IsVisible() ~= true) then
        CrossGamblingUI:Show()
	else
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:HideClassic(info)
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

local MainHeader = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
MainHeader:SetSize(CrossGamblingUI:GetSize(), 21)
MainHeader:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)

local MainMenu = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
MainMenu:SetSize(CrossGamblingUI:GetSize(), 21)
MainMenu:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)

local OptionsButton = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
OptionsButton:SetSize(CrossGamblingUI:GetSize(), 21)
OptionsButton:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
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

local CGOptions = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGOptions:SetSize(100, 21)
CGOptions:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", -25, 0)
CGOptions:SetFrameStrata("MEDIUM")
CGOptions:SetText("Options")
CGOptions:SetNormalFontObject("GameFontNormal")
CGOptions:SetScript("OnMouseUp", function(self)
	CrossGambling:ToggleOptionsMenu()
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

local CGGuildPercent = CreateFrame("EditBox", nil, OptionsButton, "InputBoxTemplate")
CGGuildPercent:SetSize(140, 30)
CGGuildPercent:SetPoint("TOPLEFT", CGOptions, -22, -85)
CGGuildPercent:SetAutoFocus(false)
CGGuildPercent:SetMaxLetters(2)
CGGuildPercent:SetJustifyH("CENTER")
CGGuildPercent:SetText(self.db.global.houseCut)
CGGuildPercent:SetScript("OnEnterPressed", EditBoxOnEnterPressed)

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


local CGLastCall = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGLastCall:SetSize(150, 28)
CGLastCall:SetPoint("TOPLEFT", CGAcceptOnes, "BOTTOMLEFT", -0, -3)
CGLastCall:SetText("Last Call!")
CGLastCall:SetNormalFontObject("GameFontNormal")
CGLastCall:SetScript("OnClick", function()
self:SendMsg("LastCall")
end)

local CGStartRoll = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGStartRoll:SetSize(150, 28)
CGStartRoll:SetPoint("TOPLEFT", CGLastCall, "BOTTOMLEFT", -0, -3)
CGStartRoll:SetText("Start Rolling")
CGStartRoll:SetNormalFontObject("GameFontNormal")
CGStartRoll:SetScript("OnClick", function()
self:CGRolls()
CGStartRoll:SetText("Whos Left?")
end)

local CGEnter = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGEnter:SetSize(150, 28)
CGEnter:SetPoint("TOPLEFT", CGGameMode, "BOTTOMLEFT", -0, -25)
CGEnter:SetText("Join Game")
CGEnter:SetNormalFontObject("GameFontNormal")
CGEnter:SetScript("OnClick", function()
	if (CGEnter:GetText() == "Join Game") then
        SendChatMessage(CrossGambling.db.global.joinWord or "1", self.game.chatMethod)
        CGEnter:SetText("Leave Game")
    elseif (CGEnter:GetText() == "Leave Game") then
        SendChatMessage(CrossGambling.db.global.leaveWord or "-1", self.game.chatMethod)
        CGEnter:SetText("Join Game")
    end
end)


local CGRollMe = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGRollMe:SetSize(150, 28)
CGRollMe:SetPoint("TOPLEFT", CGEnter, "BOTTOMLEFT", -0, -3)
CGRollMe:SetText("Roll Me")
CGRollMe:SetNormalFontObject("GameFontNormal")
CGRollMe:SetScript("OnClick", function()
  rollMe()
end)

local CGCloseGame = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGCloseGame:SetSize(150, 28)
CGCloseGame:SetPoint("TOPLEFT", CGRollMe, "BOTTOMLEFT", -0, -3)
CGCloseGame:SetText("Close")
CGCloseGame:SetNormalFontObject("GameFontNormal")
CGCloseGame:SetScript("OnClick", function()
  CrossGamblingUI:Hide()
end)

local CGFullStats = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGFullStats:SetSize(150, 28)
CGFullStats:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
CGFullStats:SetText("Full Stats")
CGFullStats:SetNormalFontObject("GameFontNormal")
CGFullStats:SetScript("OnClick", function(full)
  self:reportStats(full)
end)

local CGDeathStats = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGDeathStats:SetSize(150, 28)
CGDeathStats:SetPoint("TOPLEFT", CGFullStats, "BOTTOMLEFT", -0, -3)
CGDeathStats:SetText("DeathRoll Stats")
CGDeathStats:SetNormalFontObject("GameFontNormal")
CGDeathStats:SetScript("OnClick", function()
  self:reportDeathrollStats()
end)

local CGGuildCut = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGGuildCut:SetSize(150, 28)
CGGuildCut:SetPoint("TOPLEFT", CGDeathStats, "BOTTOMLEFT", -0, -3)
CGGuildCut:SetText("Guild Cut(OFF)")
CGGuildCut:SetNormalFontObject("GameFontNormal")
CGGuildCut:SetScript("OnClick", function()
  if (self.game.house == true) then
		self.game.house = false
		CGGuildCut:SetText("Guild Cut (OFF)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned off.")
	else
		self.game.house = true
		CGGuildCut:SetText("Guild Cut (ON)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned on.")
	end
end)

local CGReset = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGReset:SetSize(150, 28)
CGReset:SetPoint("TOPLEFT", CGGuildCut, "BOTTOMLEFT", -0, -3)
CGReset:SetText("Reset Stats!")
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

local CGRealmFilter = CreateFrame("Button", "CGRealmFilter", OptionsButton, "UIPanelButtonTemplate")
CGRealmFilter:SetPoint("TOPLEFT", CGReset, "BOTTOMLEFT", -0, -3)
CGRealmFilter:SetSize(150, 28)
CGRealmFilter:SetText("Realm Filter(OFF)")
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

local CGFameShame = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGFameShame:SetSize(150, 28)
CGFameShame:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -3)
CGFameShame:SetText("Fame/Shame")
CGFameShame:SetNormalFontObject("GameFontNormal")
CGFameShame:SetScript("OnClick", function()
  self:reportStats()
end)

local CGSession = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGSession:SetSize(150, 28)
CGSession:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -35)
CGSession:SetText("Session Stats")
CGSession:SetNormalFontObject("GameFontNormal")
CGSession:SetScript("OnClick", function()
  self:reportSessionStats()
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
    CrossGambling.global.auditLog = {}
    CrossGambling:UpdateAuditLogText(searchBox:GetText())
end)

local retentionDays = {5, 10, 30, "Never"}
local retentionCheckboxes = {}

local function OnRetentionChanged(self)
    for _, cb in pairs(retentionCheckboxes) do cb:SetChecked(false) end
    self:SetChecked(true)
    CrossGambling.db.global.auditRetention = self.days
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

auditFrame.searchBox = searchBox
auditFrame.scrollFrame = scrollFrame
auditFrame.content = content

function auditFrame:UpdateLayout()
    local width, height = self:GetSize()
    scrollFrame:SetWidth(width - 50)
    content:SetWidth(scrollFrame:GetWidth())
    CrossGambling:UpdateAuditLogText(searchBox:GetText())
end
auditFrame:SetScript("OnSizeChanged", auditFrame.UpdateLayout)

searchBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
        CrossGambling:UpdateAuditLogText(self:GetText())
    end
end)

local purgeButton = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
purgeButton:SetSize(150, 28)
purgeButton:SetPoint("TOPRIGHT", CGSession, "BOTTOMRIGHT", -2, -35)
purgeButton:SetText("History Log")
purgeButton:SetNormalFontObject("GameFontNormal")
purgeButton:SetScript("OnClick", function()
    if auditFrame:IsShown() then
        auditFrame:Hide()
    else
        CrossGambling:PurgeOldAuditEntries()
        auditFrame:Show()
        auditFrame:UpdateLayout()
    end
end)

CrossGambling.auditFrame = auditFrame

function CrossGambling:PurgeOldAuditEntries()
    local retention = self.db.global.auditRetention
    if not retention or retention == "Never" then return end
    local cutoff = time() - (retention * 86400)
    local newLog = {}
    for _, entry in ipairs(self.db.global.auditLog or {}) do
        if tonumber(entry.timestamp) > cutoff then
            table.insert(newLog, entry)
        end
    end
    self.db.global.auditLog = newLog
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


    local log = self.db.global.auditLog or {}
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
CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
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

local CGChatBox = CreateFrame("EditBox", "CGChatBoxClassic", CGRightMenu)
CGChatBox:SetPoint("TOPLEFT", CGRightMenu, "BOTTOMLEFT", 5, -2)
CGChatBox:SetSize(CGRightMenu:GetWidth() - 10, 22)
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
local cgChatBGClassic = CGChatBox:CreateTexture(nil, "BACKGROUND")
cgChatBGClassic:SetAllPoints(CGChatBox)
cgChatBGClassic:SetColorTexture(0.1, 0.1, 0.1, 0.8)
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
    slider:HookScript("OnMouseUp", function(self,value)
	  CrossScale(self)
    end)

	function CrossScale()
		self.db.global.scale = slider:GetValue()/100
		CrossGamblingUI:SetScale(self.db.global.scale)
	end

	CrossGambling.ClassicUI = {
		CGAcceptOnes = CGAcceptOnes,
		CGLastCall   = CGLastCall,
		CGStartRoll  = CGStartRoll,
		CGEnter      = CGEnter,
	}

	CrossGambling:DrawClassicPlayerFrame(CrossGamblingUI, MainHeader)

end
