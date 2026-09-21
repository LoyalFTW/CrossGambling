
CGCall = CGCall or {}

local ADDON_PREFIX = "CrossGambling"
local ROSTER_PREFIX = "CGRoster"
local PROTOCOL_VERSION = 2
local SNAPSHOT_CHUNK_SIZE = 160
local MAX_SNAPSHOT_SIZE = 32768

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
    DOUBLE_OR_NOTHING_OFFER = true,
    DOUBLE_OR_NOTHING_ROLL = true,
    STATE_CHUNK = true,
}

local skipStateBroadcast = {
    GAME_OVER = true,
    ADD_PLAYER = true,
    Remove_Player = true,
}

local immediateMessages = {
    R_NewGame = true,
    New_Game = true,
    GAME_OVER = true,
    CHAT_MSG = true,
}

local function EncodeLengthValue(tag, value)
    value = tostring(value)
    return tag .. #value .. ":" .. value
end

local function EncodeValue(value, depth)
    depth = depth or 0
    if depth > 8 then
        return "z"
    end
    local valueType = type(value)
    if valueType == "nil" then
        return "z"
    elseif valueType == "boolean" then
        return value and "b1" or "b0"
    elseif valueType == "number" then
        return EncodeLengthValue("n", value)
    elseif valueType == "string" then
        return EncodeLengthValue("s", value)
    elseif valueType ~= "table" then
        return "z"
    end
    local keys = {}
    for key in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return a < b
        end
        return type(a) < type(b)
    end)
    local encoded = { "t", tostring(#keys), ":" }
    for _, key in ipairs(keys) do
        encoded[#encoded + 1] = EncodeValue(key, depth + 1)
        encoded[#encoded + 1] = EncodeValue(value[key], depth + 1)
    end
    return table.concat(encoded)
end

local function DecodeLength(payload, position)
    local colon = payload:find(":", position, true)
    if not colon then
        return nil
    end
    local length = tonumber(payload:sub(position, colon - 1))
    if not length or length < 0 or length ~= math.floor(length) then
        return nil
    end
    return length, colon + 1
end

local function DecodeValue(payload, position, depth, budget)
    depth = depth or 0
    if depth > 8 or budget.count > 2000 then
        return nil
    end
    local tag = payload:sub(position, position)
    if tag == "z" then
        return nil, position + 1, true
    elseif tag == "b" then
        local flag = payload:sub(position + 1, position + 1)
        if flag ~= "0" and flag ~= "1" then
            return nil
        end
        return flag == "1", position + 2, true
    elseif tag == "s" or tag == "n" then
        local length, valueStart = DecodeLength(payload, position + 1)
        if not length then
            return nil
        end
        local valueEnd = valueStart + length - 1
        if valueEnd > #payload then
            return nil
        end
        local value = payload:sub(valueStart, valueEnd)
        if tag == "n" then
            value = tonumber(value)
            if value == nil or value ~= value or value == math.huge or value == -math.huge then
                return nil
            end
        end
        return value, valueEnd + 1, true
    elseif tag ~= "t" then
        return nil
    end
    local count, entryStart = DecodeLength(payload, position + 1)
    if not count or count > 500 or count ~= math.floor(count) then
        return nil
    end
    local result = {}
    local cursor = entryStart
    for _ = 1, count do
        budget.count = budget.count + 1
        local key, nextCursor, keyOk = DecodeValue(payload, cursor, depth + 1, budget)
        if not keyOk or (type(key) ~= "string" and type(key) ~= "number") then
            return nil
        end
        local decoded, afterValue, valueOk = DecodeValue(payload, nextCursor, depth + 1, budget)
        if not valueOk then
            return nil
        end
        result[key] = decoded
        cursor = afterValue
    end
    return result, cursor, true
end

local function CopyTable(source, depth)
    if type(source) ~= "table" then
        return source
    end
    depth = depth or 0
    if depth > 6 then
        return nil
    end
    local copy = {}
    for key, value in pairs(source) do
        if type(key) == "string" or type(key) == "number" then
            local valueType = type(value)
            if valueType == "table" then
                copy[key] = CopyTable(value, depth + 1)
            elseif valueType == "string" or valueType == "number" or valueType == "boolean" then
                copy[key] = value
            end
        end
    end
    return copy
end

local function IsInInstanceGroup()
    return LE_PARTY_CATEGORY_INSTANCE ~= nil and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
end

function CrossGambling:ResolveChatChannel(method)
    if (method == "PARTY" or method == "RAID") and IsInInstanceGroup() then
        return "INSTANCE_CHAT"
    end
    if method == "RAID" and IsInGroup() and not IsInRaid() then
        return "PARTY"
    end
    if method == "PARTY" and IsInRaid() then
        return "RAID"
    end
    return method
end

function CrossGambling:NewSessionId()
    return string.format("%x%x", time(), math.random(1, 1073741823))
end

function CrossGambling:GetCommProtocolVersion()
    return PROTOCOL_VERSION
end

function CrossGambling:SendProtocolMessage(event, payload, sessionId, method, priorityOverride)
    self.outgoingProtocolSequence = (self.outgoingProtocolSequence or 0) + 1
    local message = table.concat({
        "V" .. PROTOCOL_VERSION,
        sessionId or "-",
        tostring(self.outgoingProtocolSequence),
        event,
        payload or "",
    }, "|")
    local channel = self:ResolveChatChannel(method or (self.game and self.game.chatMethod))
    if channel then
        local priority = priorityOverride or (event == "STATE_CHUNK" and "BULK" or immediateMessages[event] and "ALERT" or "NORMAL")
        pcall(ChatThrottleLib.SendAddonMessage, ChatThrottleLib, priority, ADDON_PREFIX, message, channel)
    end
end

function CrossGambling:SendMsg(event, arg1)
    local msg = event
    if arg1 ~= nil then
        msg = msg .. ":" .. tostring(arg1)
    end

    local method = self.game and self.game.chatMethod
    if method then
        if self.game.sessionId then
            self:SendProtocolMessage(event, arg1 ~= nil and tostring(arg1) or "", self.game.sessionId, method)
        end
        if event ~= "STATE_CHUNK" then
            local priority = immediateMessages[event] and "ALERT" or "NORMAL"
            pcall(ChatThrottleLib.SendAddonMessage, ChatThrottleLib, priority, ADDON_PREFIX, msg, self:ResolveChatChannel(method))
        end
    end
end

function CrossGambling:BuildPublicGameState()
    local game = self.game or {}
    local snapshot = {
        mode = game.mode,
        state = game.state,
        chatMethod = game.chatMethod,
        wager = game.wager,
        houseCut = game.houseCut,
        house = game.house == true,
        hostName = game.hostName,
        doubleOrNothingEnabled = game.doubleOrNothingEnabled == true,
        rosterRevision = game.rosterRevision or 0,
        liveRevision = game.liveRevision or 0,
        players = CopyTable(game.players or {}),
        highlow = CopyTable(game.highlow),
        deathroll = CopyTable(game.deathroll),
        elimination = CopyTable(game.elimination),
        overunder = CopyTable(game.overunder),
        doubleOrNothing = CopyTable(game.doubleOrNothing),
        completedDoubleOrNothing = CopyTable(game.completedDoubleOrNothing),
    }
    if game.hotpotato then
        snapshot.hotpotato = {
            round = game.hotpotato.round,
            holder = game.hotpotato.holder,
            pending = CopyTable(game.hotpotato.pending),
            exploded = game.hotpotato.exploded == true,
        }
    end
    return snapshot
end

function CrossGambling:SendStateSnapshot(priority)
    local game = self.game
    if not game or not game.host or not game.sessionId or game.state == "START" then
        return
    end
    local payload = EncodeValue(self:BuildPublicGameState())
    if #payload > MAX_SNAPSHOT_SIZE then
        return
    end
    self.snapshotSequence = (self.snapshotSequence or 0) + 1
    local snapshotId = tostring(self.snapshotSequence)
    local total = math.max(1, math.ceil(#payload / SNAPSHOT_CHUNK_SIZE))
    for index = 1, total do
        local startAt = ((index - 1) * SNAPSHOT_CHUNK_SIZE) + 1
        local chunk = payload:sub(startAt, startAt + SNAPSHOT_CHUNK_SIZE - 1)
        self:SendProtocolMessage("STATE_CHUNK", table.concat({ snapshotId, index, total, chunk }, "|"), game.sessionId, game.chatMethod, priority or "BULK")
    end
end

function CrossGambling:QueueStateBroadcast(delay)
    local game = self.game
    if not game or not game.host or not game.sessionId or self.stateBroadcastSession == game.sessionId then
        return
    end
    local sessionId = game.sessionId
    self.stateBroadcastSession = sessionId
    C_Timer.After(delay or 0.2, function()
        if self.stateBroadcastSession == sessionId then
            self.stateBroadcastSession = nil
        end
        if self.game and self.game.host and self.game.sessionId == sessionId then
            self:SendStateSnapshot()
        end
    end)
end

function CrossGambling:RequestStateSync()
    if not self.game or self.game.host or self.game.state ~= "START" then
        return
    end
    local sent = {}
    if IsInGroup() then
        local channel = self:ResolveChatChannel(IsInRaid() and "RAID" or "PARTY")
        sent[channel] = true
        self:SendProtocolMessage("SYNC_REQUEST", "", "-", channel)
    end
    if IsInGuild() and not sent.GUILD then
        self:SendProtocolMessage("SYNC_REQUEST", "", "-", "GUILD")
    end
end

function CrossGambling:ApplyStateSnapshot(snapshot, sender, sessionId)
    if self.closedSessions and self.closedSessions[sessionId] then
        return
    end
    if type(snapshot) ~= "table" or type(snapshot.players) ~= "table" then
        return
    end
    if not self.modeRegistry[snapshot.mode] then
        return
    end
    local validStates = {
        REGISTER = true,
        ROLL = true,
        DOUBLE_OR_NOTHING_OFFER = true,
        DOUBLE_OR_NOTHING_ROLL = true,
    }
    if not validStates[snapshot.state] then
        return
    end
    local tableFields = {
        "highlow",
        "deathroll",
        "elimination",
        "hotpotato",
        "overunder",
        "doubleOrNothing",
        "completedDoubleOrNothing",
    }
    for _, field in ipairs(tableFields) do
        if snapshot[field] ~= nil and type(snapshot[field]) ~= "table" then
            return
        end
    end
    if #snapshot.players > 80 then
        return
    end
    local players = {}
    local seenPlayers = {}
    for index = 1, #snapshot.players do
        local player = snapshot.players[index]
        local name = type(player) == "table" and player.name or nil
        if type(name) ~= "string" or name == "" or #name > 64 or seenPlayers[name] then
            return
        end
        local roll = player.roll
        if roll ~= nil and type(roll) ~= "string" and type(roll) ~= "number" then
            return
        end
        if type(roll) == "string" and #roll > 32 then
            return
        end
        if type(roll) == "number" and (roll ~= roll or roll == math.huge or roll == -math.huge) then
            return
        end
        seenPlayers[name] = true
        players[index] = { name = name, roll = roll }
    end
    local game = self.game
    local previousSessionId = game.sessionId
    if game.state ~= "START" and (game.hostName ~= sender or game.sessionId ~= sessionId) then
        return
    end
    game.sessionId = sessionId
    game.protocolVersion = PROTOCOL_VERSION
    game.host = false
    game.hostName = sender
    game.mode = snapshot.mode
    game.state = snapshot.state
    game.chatMethod = snapshot.chatMethod == "GUILD" and "GUILD" or snapshot.chatMethod == "RAID" and "RAID" or "PARTY"
    game.wager = self:ValidateWager(snapshot.wager) or self:GetWager()
    game.houseCut = self:NormalizeHouseCutValue(snapshot.houseCut) or self:GetHouseCut()
    game.house = snapshot.house == true
    game.doubleOrNothingEnabled = snapshot.doubleOrNothingEnabled == true
    local snapshotRosterRevision = tonumber(snapshot.rosterRevision)
    local snapshotLiveRevision = tonumber(snapshot.liveRevision)
    local currentRosterRevision = tonumber(game.rosterRevision) or 0
    local currentLiveRevision = tonumber(game.liveRevision) or 0
    local rosterIsCurrent = previousSessionId ~= sessionId or currentRosterRevision == 0 or (snapshotRosterRevision and snapshotRosterRevision >= currentRosterRevision)
    local liveStateIsCurrent = previousSessionId ~= sessionId or currentLiveRevision == 0 or (snapshotLiveRevision and snapshotLiveRevision >= currentLiveRevision)
    local replaceRoster = rosterIsCurrent and liveStateIsCurrent
    if replaceRoster then
        game.players = players
        game.playerIndexByName = nil
        game.rosterRevision = snapshotRosterRevision or currentRosterRevision
        game.liveRevision = snapshotLiveRevision or currentLiveRevision
    end
    if liveStateIsCurrent then
        game.liveRevision = snapshotLiveRevision or currentLiveRevision
        game.highlow = snapshot.highlow
        game.deathroll = snapshot.deathroll
        game.elimination = snapshot.elimination
        game.hotpotato = snapshot.hotpotato
        game.overunder = snapshot.overunder
        game.doubleOrNothing = snapshot.doubleOrNothing
        game.completedDoubleOrNothing = snapshot.completedDoubleOrNothing
    end
    self.syncCandidate = nil
    if self.ClearCompletedGameBoard then
        self:ClearCompletedGameBoard()
    end
    if CGCall["DisableClient"] then
        CGCall["DisableClient"]()
    end
    if self.QueueGameBoardRefresh then
        self:QueueGameBoardRefresh()
    end
end

function CrossGambling:ReceiveStateChunk(payload, sender, sessionId, sequence)
    local snapshotId, indexText, totalText, chunk = strmatch(payload or "", "^([^|]+)|(%d+)|(%d+)|(.*)$")
    local index = tonumber(indexText)
    local total = tonumber(totalText)
    if not snapshotId or not index or not total or total < 1 or total > 256 or index < 1 or index > total then
        return
    end
    local now = GetTime()
    self.snapshotBuffers = self.snapshotBuffers or {}
    for key, buffer in pairs(self.snapshotBuffers) do
        if now - buffer.createdAt > 15 then
            self.snapshotBuffers[key] = nil
        end
    end
    local key = sender .. "\031" .. sessionId .. "\031" .. snapshotId
    local buffer = self.snapshotBuffers[key]
    if not buffer then
        buffer = { chunks = {}, received = 0, total = total, size = 0, createdAt = now, maxSequence = sequence or 0 }
        self.snapshotBuffers[key] = buffer
    elseif buffer.total ~= total then
        self.snapshotBuffers[key] = nil
        return
    end
    if not buffer.chunks[index] then
        buffer.chunks[index] = chunk
        buffer.received = buffer.received + 1
        buffer.size = buffer.size + #chunk
        buffer.maxSequence = math.max(buffer.maxSequence or 0, sequence or 0)
    end
    if buffer.size > MAX_SNAPSHOT_SIZE then
        self.snapshotBuffers[key] = nil
        return
    end
    if buffer.received ~= buffer.total then
        return
    end
    local serialized = table.concat(buffer.chunks)
    self.snapshotBuffers[key] = nil
    local stateSequenceKey = sender .. "\031" .. sessionId
    if buffer.maxSequence < ((self.lastAppliedStateSequences and self.lastAppliedStateSequences[stateSequenceKey]) or 0) then
        return
    end
    local snapshot, position, ok = DecodeValue(serialized, 1, 0, { count = 0 })
    if ok and position == #serialized + 1 then
        self:ApplyStateSnapshot(snapshot, sender, sessionId)
        self.lastAppliedStateSequences = self.lastAppliedStateSequences or {}
        self.lastAppliedStateSequences[stateSequenceKey] = math.max(self.lastAppliedStateSequences[stateSequenceKey] or 0, buffer.maxSequence)
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
    pcall(SendChatMessage, msg, self:ResolveChatChannel(method))
end

function CrossGambling:CanSendToChannel(method)
    local channel = self:ResolveChatChannel(method)
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

function CrossGambling:GetUnavailableChannelMessage(method)
    if method == "PARTY" then
        return "You're not in a party."
    elseif method == "RAID" then
        return "You're not in a raid."
    elseif method == "GUILD" then
        return "You're not in a guild."
    end
    return "The selected chat channel is not available."
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

function CrossGambling:SendLiveRosterMessage(operation, playerName)
    local game = self.game
    if not game or not game.host or not game.sessionId then
        return
    end

    if operation == "N" then
        game.rosterRevision = 0
    else
        game.rosterRevision = (game.rosterRevision or 0) + 1
    end

    local channel = self:ResolveChatChannel(game.chatMethod)
    if channel then
        local message = table.concat({ game.sessionId, tostring(game.rosterRevision), operation, playerName or "" }, "|")
        pcall(C_ChatInfo.SendAddonMessage, ROSTER_PREFIX, message, channel)
    end
end

function CrossGambling:SendLiveRollMessage(playerName, value)
    local game = self.game
    if not game or not game.host or not game.sessionId then
        return
    end

    game.liveRevision = (game.liveRevision or 0) + 1
    local channel = self:ResolveChatChannel(game.chatMethod)
    if channel then
        local message = table.concat({ game.sessionId, tostring(game.liveRevision), "L", playerName, tostring(value) }, "|")
        pcall(C_ChatInfo.SendAddonMessage, ROSTER_PREFIX, message, channel)
    end
end

function CrossGambling:OnLiveRosterMessage(msg, channel, sender)
    local sessionId, revisionText, operation, playerName = strmatch(msg or "", "^([^|]+)|(%d+)|([NARL])|(.*)$")
    local revision = tonumber(revisionText)
    local shortSender = self:ShortPlayerName(sender)
    local game = self.game
    if not sessionId or not revision or not shortSender or self:NormalizePlayerName(shortSender) == self:NormalizePlayerName(game.PlayerName) or game.host or (self.closedSessions and self.closedSessions[sessionId]) then
        return
    end

    if operation == "L" then
        if game.sessionId ~= sessionId or game.hostName ~= shortSender or revision <= (game.liveRevision or 0) then
            return
        end
        local rollPlayer, rollValue = strmatch(playerName, "^([^|]+)|(.*)$")
        local player = rollPlayer and self:getPlayerByName(self:ShortPlayerName(rollPlayer)) or nil
        if not player or rollValue == nil or #rollValue > 32 then
            return
        end
        player.roll = tonumber(rollValue) or rollValue
        game.liveRevision = revision
        self:DispatchModeHook("OnRemoteRoll", player.name, rollValue)
        self:QueueGameBoardRefresh()
        return
    end

    if operation == "N" then
        if game.sessionId == sessionId and (game.rosterRevision or 0) > revision then
            return
        end
        if game.state ~= "START" and (game.sessionId ~= sessionId or game.hostName ~= shortSender) then
            return
        end
        if game.sessionId ~= sessionId then
            self:ResetGameState()
        end
        game.sessionId = sessionId
        game.protocolVersion = PROTOCOL_VERSION
        game.host = false
        game.hostName = shortSender
        game.state = "REGISTER"
        game.rosterRevision = revision
        self:ResetPlayers()
        if CGCall["DisableClient"] then
            CGCall["DisableClient"]()
        end
        self:QueueGameBoardRefresh()
        return
    end

    if game.sessionId ~= sessionId then
        if game.state ~= "START" then
            return
        end
        self:ResetGameState()
        game.sessionId = sessionId
        game.protocolVersion = PROTOCOL_VERSION
        game.hostName = shortSender
        game.state = "REGISTER"
        if CGCall["DisableClient"] then
            CGCall["DisableClient"]()
        end
    elseif game.hostName ~= shortSender then
        return
    end

    if revision <= (game.rosterRevision or 0) or playerName == "" or #playerName > 64 then
        return
    end

    playerName = self:ShortPlayerName(playerName)
    game.rosterRevision = revision
    if operation == "A" then
        self:registerPlayer(playerName)
    else
        self:unregisterPlayer(playerName)
    end
    self:QueueGameBoardRefresh()
end


function CrossGambling:OnAddonMessage(event, prefix, msg, channel, sender)
    if prefix == ROSTER_PREFIX then
        self:OnLiveRosterMessage(msg, channel, sender)
        return
    end
    if prefix ~= ADDON_PREFIX or type(msg) ~= "string" then
        return
    end

    local shortSender = self:ShortPlayerName(sender)
    if self:NormalizePlayerName(shortSender) == self:NormalizePlayerName(self.game and self.game.PlayerName) then
        local isPanelChat = strmatch(msg, "^CHAT_MSG:") or strmatch(msg, "^V%d+|[^|]+|%d+|CHAT_MSG|")
        if not isPanelChat then
            return
        end
    end
    local protocol, sessionId, sequenceText, protocolEvent, protocolPayload = strmatch(msg, "^V(%d+)|([^|]+)|(%d+)|([^|]+)|(.*)$")
    local receivedProtocolSequence
    local receivedSessionId
    if protocol then
        if tonumber(protocol) ~= PROTOCOL_VERSION then
            return
        end
        self.protocolPeers = self.protocolPeers or {}
        self.protocolPeers[shortSender] = PROTOCOL_VERSION
        self.protocolSequences = self.protocolSequences or {}
        self.protocolSeenSequences = self.protocolSeenSequences or {}
        local sequenceKey = shortSender .. "\031" .. sessionId
        local sequence = tonumber(sequenceText)
        local highestSequence = self.protocolSequences[sequenceKey] or 0
        local seenSequences = self.protocolSeenSequences[sequenceKey]
        if sequence < highestSequence - 512 then
            return
        end
        if not seenSequences then
            seenSequences = {}
            self.protocolSeenSequences[sequenceKey] = seenSequences
        elseif seenSequences[sequence] then
            return
        end
        seenSequences[sequence] = true
        highestSequence = math.max(highestSequence, sequence)
        self.protocolSequences[sequenceKey] = highestSequence
        local sequenceFloor = highestSequence - 512
        for seenSequence in pairs(seenSequences) do
            if seenSequence < sequenceFloor then
                seenSequences[seenSequence] = nil
            end
        end
        receivedProtocolSequence = sequence
        receivedSessionId = sessionId

        if protocolEvent == "SYNC_REQUEST" then
            local hostChannel = self.game and self:ResolveChatChannel(self.game.chatMethod)
            if self.game.host and self.game.state ~= "START" and hostChannel == channel then
                self:QueueStateBroadcast(0.1)
            end
            return
        end

        local isStart = protocolEvent == "R_NewGame" or protocolEvent == "New_Game"
        if protocolEvent == "CHAT_MSG" then
            if self.game.state == "START" or self.game.sessionId ~= sessionId then
                return
            end
        elseif self.game.host then
            if shortSender ~= self.game.hostName or sessionId ~= self.game.sessionId then
                return
            end
        elseif self.game.sessionId ~= sessionId or self.game.hostName ~= shortSender then
            if isStart and (self.game.state == "START" or self.game.hostName == shortSender) then
                if self.game.sessionId ~= sessionId then
                    self:ResetGameState()
                end
                self.game.sessionId = sessionId
                self.game.protocolVersion = PROTOCOL_VERSION
                self.game.hostName = shortSender
            elseif protocolEvent == "STATE_CHUNK" and self.game.state == "START" then
                if self.closedSessions and self.closedSessions[sessionId] then
                    return
                end
                local candidate = self.syncCandidate
                if candidate and GetTime() - candidate.createdAt > 15 then
                    candidate = nil
                    self.syncCandidate = nil
                end
                if candidate and (candidate.sender ~= shortSender or candidate.sessionId ~= sessionId) then
                    return
                end
                self.syncCandidate = candidate or { sender = shortSender, sessionId = sessionId, createdAt = GetTime() }
            else
                return
            end
        end

        if protocolEvent == "STATE_CHUNK" then
            if self.game.host then
                return
            end
            self:ReceiveStateChunk(protocolPayload, shortSender, sessionId, sequence)
            return
        end
        msg = protocolEvent
        if protocolPayload ~= "" then
            msg = msg .. ":" .. protocolPayload
        end
    elseif self.protocolPeers and self.protocolPeers[shortSender] == PROTOCOL_VERSION then
        return
    end

    local eventType, rest = strmatch(msg, "^([^:]+):?(.*)$")
    if not eventType then
        return
    end

    if eventType == "CHAT_MSG" then
        local name, class, message = strmatch(rest, "^([^:]+):([^:]+):(.+)$")
        if name and message then
            self:OnPanelChatMessage(name, class, message, shortSender)
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

    if receivedProtocolSequence then
        self.lastAppliedStateSequences = self.lastAppliedStateSequences or {}
        local stateSequenceKey = shortSender .. "\031" .. receivedSessionId
        self.lastAppliedStateSequences[stateSequenceKey] = math.max(self.lastAppliedStateSequences[stateSequenceKey] or 0, receivedProtocolSequence)
    end

    if self.game.host and not skipStateBroadcast[eventType] then
        self:QueueStateBroadcast()
    end
end

function CrossGambling:OnGameMessage(eventType, arg1, arg2, sender)
    local game = self.game

    if eventType == "R_NewGame" then
        if not game.host and (game.rosterRevision or 0) == 0 then
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
            self.closedSessions = self.closedSessions or {}
            if game.sessionId then
                self.closedSessions[game.sessionId] = true
            end
            self:CaptureCompletedGameBoard()
            self:ResetGameState()
        end
    elseif eventType == "DOUBLE_OR_NOTHING_OFFER" then
        if not game.host and arg1 then
            local loser, winner, amount = strsplit("|", arg1)
            game.doubleOrNothing = { loser = loser, winner = winner, amount = tonumber(amount), accepted = {} }
            game.state = "DOUBLE_OR_NOTHING_OFFER"
        end
    elseif eventType == "DOUBLE_OR_NOTHING_ROLL" then
        if not game.host and arg1 then
            local loser, winner, turn, maxRoll = strsplit("|", arg1)
            game.doubleOrNothing = game.doubleOrNothing or {}
            game.doubleOrNothing.loser = loser
            game.doubleOrNothing.winner = winner
            game.doubleOrNothing.turn = turn
            game.doubleOrNothing.max = tonumber(maxRoll)
            game.state = "DOUBLE_OR_NOTHING_ROLL"
        end
    end

    if self.QueueGameBoardRefresh then
        self:QueueGameBoardRefresh()
    end
end

function CrossGambling:OnPanelChatMessage(name, class, message, sender)
    if self.game.host and self.game.state == "DOUBLE_OR_NOTHING_OFFER" then
        self:HandleDoubleOrNothingChat(sender or name, message)
    end

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

    if (self.game.rosterRevision or 0) == 0 then
        self:ResetGameState(self.game.sessionId ~= nil)
    end
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
C_ChatInfo.RegisterAddonMessagePrefix(ROSTER_PREFIX)
