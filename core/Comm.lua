
CGCall = CGCall or {}

local ADDON_PREFIX = "CrossGambling"

local hostOnlyMessages = {
    SET_WAGER = true,
    GAME_MODE = true,
    Chat_Method = true,
    SET_HOUSE = true,
    HOST_NAME = true,
    ADD_PLAYER = true,
    Remove_Player = true,
    LastCall = true,
    Disable_Join = true,
    PLAYER_ROLL = true,
    GAME_OVER = true,
}

local function IsInInstanceGroup()
    return LE_PARTY_CATEGORY_INSTANCE ~= nil and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
end

local function ResolveChannel(method)
    if (method == "PARTY" or method == "RAID") and IsInInstanceGroup() then
        return "INSTANCE_CHAT"
    end
    return method
end

function CrossGambling:SendMsg(event, arg1)
    local msg = event
    if arg1 ~= nil then
        msg = msg .. ":" .. tostring(arg1)
    end

    local method = self.game and self.game.chatMethod
    if method then
        pcall(ChatThrottleLib.SendAddonMessage, ChatThrottleLib, "NORMAL", ADDON_PREFIX, msg, ResolveChannel(method))
    end
end

function CrossGambling:SendPanelChat(message)
    self:SendMsg("CHAT_MSG", format("%s:%s:%s", self.game.PlayerName, self.game.PlayerClass or "NONE", message))
end

function CrossGambling:SendChat(msg, method)
    method = method or self.game.chatMethod
    if self:IsTestingMode() then
        self:Print("|cff888888[" .. (method or "Chat") .. "]|r " .. msg)
    end
    pcall(SendChatMessage, msg, ResolveChannel(method))
end

function CrossGambling:CanSendToChannel(method)
    local channel = ResolveChannel(method)
    if channel == "INSTANCE_CHAT" then
        return true
    elseif channel == "PARTY" then
        return IsInGroup() and not IsInRaid()
    elseif channel == "RAID" then
        return IsInRaid()
    elseif channel == "GUILD" then
        return IsInGuild()
    end
    return false
end

function CrossGambling:Announce(message)
    local game = self.game
    if not game or not game.host then
        self:Print(message)
        return
    end

    if game.chatframeOption == false then
        self:SendPanelChat(message)
        return
    end

    if self:CanSendToChannel(game.chatMethod) then
        self:SendChat(message, game.chatMethod)
    else
        self:Print(message)
    end
end


function CrossGambling:OnAddonMessage(event, prefix, msg, channel, sender)
    if prefix ~= ADDON_PREFIX or type(msg) ~= "string" then
        return
    end

    local eventType, rest = strmatch(msg, "^([^:]+):?(.*)$")
    if not eventType then
        return
    end

    local shortSender = self:ShortPlayerName(sender)

    if eventType == "CHAT_MSG" then
        local name, class, message = strmatch(rest, "^([^:]+):([^:]+):(.+)$")
        if name and message then
            self:OnPanelChatMessage(name, class, message)
        end
        return
    end

    if (eventType == "R_NewGame" or eventType == "New_Game") and self.game.host then
        return
    end

    if hostOnlyMessages[eventType] and shortSender ~= self.game.hostName then
        return
    end

    local arg1, arg2 = strsplit(":", rest)
    if arg1 == "" then
        arg1 = nil
    end

    self:OnGameMessage(eventType, arg1, arg2, shortSender)

    if CGCall[eventType] then
        CGCall[eventType](arg1, arg2, shortSender)
    end
end

function CrossGambling:OnGameMessage(eventType, arg1, arg2, sender)
    local game = self.game

    if eventType == "R_NewGame" then
        if not game.host then
            self:ResetPlayers()
        end
    elseif eventType == "Disable_Join" then
        if not game.host and game.state == "REGISTER" then
            game.state = "ROLL"
        end
    elseif eventType == "PLAYER_ROLL" then
        if not game.host then
            local player = self:getPlayerByName(arg1)
            if player then
                player.roll = tonumber(arg2) or arg2
            end
            self:DispatchModeHook("OnRemoteRoll", arg1, arg2)
        end
    elseif eventType == "GAME_OVER" then
        if not game.host then
            self:ResetGameState()
        end
    end
end

function CrossGambling:OnPanelChatMessage(name, class, message)
    local panel = self.CGRightMenu
    if not panel or not panel.TextField then
        return
    end

    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local coloredName = (color and color.colorStr) and ("|c" .. color.colorStr .. name) or name
    panel.TextField:AddMessage(string.format("[%s|r]: %s", coloredName, message))
end


CGCall["New_Game"] = function(_, _, sender)
    local self = CrossGambling
    if self.game.host then
        return
    end

    self:ResetGameState()
    self.game.hostName = sender
    self.game.state = "REGISTER"

    if CGCall["DisableClient"] then
        CGCall["DisableClient"]()
    end
end

CGCall["ADD_PLAYER"] = function(playerName)
    local self = CrossGambling
    if not playerName then
        return
    end

    if self:registerPlayer(playerName) then
        self:AddPlayer(playerName)
    end
end

CGCall["Remove_Player"] = function(playerName)
    local self = CrossGambling
    if not playerName then
        return
    end

    self:RemovePlayer(playerName)
    self:unregisterPlayer(playerName)
end

CGCall["SET_WAGER"] = function(value)
    local self = CrossGambling
    self.game.wager = self:ValidateWager(value) or self:GetWager()
end

CGCall["GAME_MODE"] = function(value)
    if value and CrossGambling.modeRegistry[value] then
        CrossGambling.game.mode = value
    end
end

CGCall["HOST_NAME"] = function(value)
    if value then
        CrossGambling.game.hostName = value
    end
end

CGCall["SET_HOUSE"] = function(value)
    local self = CrossGambling
    self.game.houseCut = self:NormalizeHouseCutValue(value) or self:GetHouseCut()
end

CGCall["Chat_Method"] = function(value)
    if value == "PARTY" or value == "RAID" or value == "GUILD" then
        CrossGambling.game.chatMethod = value
    end
end

CGCall["LastCall"] = function()
    CrossGambling:Announce("Last Call to Enter!")
end

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
