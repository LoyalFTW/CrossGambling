
local ADDON_NAME = ...
local addonObject = CrossGambling
local F = _G.Foundry_1_0
local chatMethods = { "PARTY", "RAID", "GUILD" }
local uiThemes = { "Classic", "Slick" }

local DEFAULT_WAGER = 1000
local DEFAULT_HOUSE_CUT = 10

local defaults = {
    global = {
        minimap = {
            hide = false,
        },
        wager = DEFAULT_WAGER,
        minWager = 1,
        maxWager = 1000000,
        testingMode = false,
        houseCut = DEFAULT_HOUSE_CUT,
        colors = { frameColor = {r = 0.27, g = 0.27, b = 0.27}, buttonColor = {r = 0.30, g = 0.30, b = 0.30}, sideColor = {r = 0.20, g = 0.20, b = 0.20}, fontColor = {r = 1, g = 0, b = 0} },
        themechoice = 1,
        theme = uiThemes[2],
        stats = {},
        deathrollStats = {},
        modeStats = {},
        housestats = 0,
        joinstats = {},
        altStats = {},
        scale = 1,
        scalevalue = 1,
        fontvalue = 14,
        bans = {},
        auditLog = {},
        auditRetention = 30,
        auditMaxEntries = 500,
        suspendChatEventsInCombat = true,
    },
}

local LEGACY_DB_KEYS = {
    "global", "profiles", "profileKeys", "namespaces",
    "char", "realm", "class", "race", "faction", "factionrealm", "factionrealmregion", "locale",
}

local function ReclaimGlobalFromSavedVariables()
    local saved = _G.CrossGambling
    _G.CrossGambling = addonObject

    if saved == addonObject or type(saved) ~= "table" then
        return
    end

    local current = _G.CrossGamblingDB
    if type(current) == "table" and next(current) ~= nil then
        return
    end

    local migrated = {}
    for _, key in ipairs(LEGACY_DB_KEYS) do
        if type(saved[key]) == "table" then
            migrated[key] = saved[key]
        end
    end

    if next(migrated) ~= nil then
        _G.CrossGamblingDB = migrated
    end
end

function CrossGambling:NewGameState()
    local defaultMode = (self.modeListOrder and self.modeListOrder[1]) or "Classic"

    return {
        chatMethod = chatMethods[1],
        mode = defaultMode,
        state = "START",
        chatframeOption = true,
        realmFilter = false,
        house = false,
        host = false,
        hostName = nil,
        wager = nil,
        houseCut = nil,
        players = {},
        playerIndexByName = nil,
        PlayerName = UnitName("player"),
        PlayerClass = select(2, UnitClass("player")),
        result = nil,
        sessionStats = {},
    }
end

function CrossGambling:InitDB()
    ReclaimGlobalFromSavedVariables()

    self.db = F.DB:New({
        name = ADDON_NAME,
        sv = "CrossGamblingDB",
        defaults = defaults,
        defaultProfile = true,
    })
    self.game = self:NewGameState()
    self:RebuildBanCache()
end


function CrossGambling:GetWagerLimits()
    local global = self.db and self.db.global
    return (global and global.minWager) or 1, (global and global.maxWager) or 1000000
end

function CrossGambling:ValidateWager(value)
    local minWager, maxWager = self:GetWagerLimits()
    return self:ClampInteger(value, minWager, maxWager)
end

function CrossGambling:GetWager()
    if self.game and self.game.wager then
        return self.game.wager
    end

    return (self.db and self.db.global and self.db.global.wager) or DEFAULT_WAGER
end

function CrossGambling:SetWager(value)
    if not self.db or not self.db.global then
        return
    end

    local normalizedValue = self:ValidateWager(value) or self.db.global.wager or DEFAULT_WAGER
    self.db.global.wager = normalizedValue

    if self.wagerInput then
        self.wagerInput:SetText(tostring(normalizedValue))
    end
end


function CrossGambling:NormalizeHouseCutValue(value)
    return self:ClampInteger(value, 0, 100)
end

function CrossGambling:GetHouseCut()
    if self.game and self.game.houseCut then
        return self.game.houseCut
    end

    return (self.db and self.db.global and self.db.global.houseCut) or DEFAULT_HOUSE_CUT
end

function CrossGambling:SetHouseCut(value)
    if not self.db or not self.db.global then
        return
    end

    local normalizedValue = self:NormalizeHouseCutValue(value) or self.db.global.houseCut or DEFAULT_HOUSE_CUT
    self.db.global.houseCut = normalizedValue

    if self.guildPercentInput then
        self.guildPercentInput:SetText(tostring(normalizedValue))
    end
end


function CrossGambling:GetJoinWords()
    local global = self.db and self.db.global
    local joinWord = (global and global.joinWord) or "1"
    local leaveWord = (global and global.leaveWord) or "-1"
    return joinWord, leaveWord
end


function CrossGambling:IsTestingMode()
    return self.db and self.db.global and self.db.global.testingMode == true
end

function CrossGambling:SetTestingMode(info, args)
    if not self.db or not self.db.global then
        return
    end

    local value = self:TrimInput(args):lower()
    if value == "on" then
        self.db.global.testingMode = true
    elseif value == "off" then
        self.db.global.testingMode = false
    else
        self:Print("Usage: /cg testing on|off (currently " .. (self.db.global.testingMode and "ON" or "OFF") .. ")")
        return
    end

    self:Print("CrossGambling: Testing mode is now " .. (self.db.global.testingMode and "ON" or "OFF") .. ".")
end


function CrossGambling:RebuildBanCache()
    self.banLookup = {}

    local bans = self.db and self.db.global and self.db.global.bans
    if not bans then
        return
    end

    for i = 1, #bans do
        local normalizedName = self:NormalizePlayerName(bans[i])
        if normalizedName then
            self.banLookup[normalizedName] = true
        end
    end
end

function CrossGambling:IsPlayerBanned(playerName)
    local normalizedPlayerName = self:NormalizePlayerName(playerName)
    if not normalizedPlayerName then
        return false
    end

    if not self.banLookup then
        self:RebuildBanCache()
    end

    return self.banLookup[normalizedPlayerName] == true
end

function CrossGambling:banPlayer(info, playerName)
    playerName = self:TrimInput(playerName)
    if playerName == "" then
        self:Print("Error: No name provided.")
        return
    end

    if self:IsPlayerBanned(playerName) then
        self:Print(playerName .. " Unable to add to ban list - user already banned.")
        return
    end

    table.insert(self.db.global.bans, playerName)
    self:RebuildBanCache()

    local shortName = self:ShortPlayerName(playerName)
    if self.game and self.game.host then
        self:SendMsg("Remove_Player", shortName)
    else
        self:RemovePlayer(shortName)
        self:unregisterPlayer(shortName)
    end

    self:Print(playerName .. " has been added to the ban list.")
end

function CrossGambling:unbanPlayer(info, playerName)
    playerName = self:TrimInput(playerName)
    if playerName == "" then
        self:Print("Error: No name provided.")
        return
    end

    local normalizedPlayerName = self:NormalizePlayerName(playerName)
    local bans = self.db.global.bans
    for i = 1, #bans do
        if self:NormalizePlayerName(bans[i]) == normalizedPlayerName then
            table.remove(bans, i)
            self:RebuildBanCache()
            self:Print(playerName .. " has been removed from the ban list.")
            return
        end
    end

    self:Print(playerName .. " is not currently banned!")
end

function CrossGambling:listBans(info)
    local bans = self.db.global.bans
    if #bans == 0 then
        self:Print("There are no bans currently.")
        return
    end

    for _, ban in ipairs(bans) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s", "...", tostring(ban)))
    end
    self:Print("The Current Bans, to unban use /cg unban [PlayerName]")
end
