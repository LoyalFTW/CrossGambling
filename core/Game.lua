
function CrossGambling:ResetGameState()
    local game = self.game

    self:UnregisterEvent("CHAT_MSG_SYSTEM")
    self:UnRegisterChatEvents()
    self.chatEventsSuspendedForCombat = false

    game.state = "START"
    game.host = false
    game.hostName = nil
    game.wager = nil
    game.houseCut = nil
    game.result = nil
    self:ResetPlayers()
end

function CrossGambling:HostNewGame()
    local game = self.game
    local global = self.db.global

    if not self:CanSendToChannel(game.chatMethod) then
        self:Print(self:GetUnavailableChannelMessage(game.chatMethod))
        return false
    end

    if game.state ~= "START" then
        self:ResetGameState()
    end

    game.host = true
    game.hostName = game.PlayerName
    game.wager = global.wager
    game.houseCut = global.houseCut
    self:ResetPlayers()

    if CGCall["R_NewGame"] then
        CGCall["R_NewGame"]()
    end

    game.state = "REGISTER"
    self:RegisterChatEvents()
    self:GameStart()

    local summary = "Game Mode - " .. game.mode .. " - Wager - " .. self:addCommas(game.wager) .. "g"
    if game.house then
        summary = summary .. " - House Cut - " .. game.houseCut .. "%"
    end
    self:Announce(summary)

    self:SendMsg("R_NewGame")
    self:SendMsg("New_Game")
    self:SendMsg("SET_WAGER", game.wager)
    self:SendMsg("GAME_MODE", game.mode)
    self:SendMsg("Chat_Method", game.chatMethod)
    self:SendMsg("SET_HOUSE", game.houseCut)
    self:SendMsg("HOST_NAME", game.PlayerName)
    return true
end

function CrossGambling:GameStart()
    local handled = self:DispatchModeHook("OnStart")
    if not handled then
        local joinWord, leaveWord = self:GetJoinWords()
        self:Announce("CrossGambling: A new game has been started! Type " .. joinWord .. " to join! (" .. leaveWord .. " to withdraw)")
    end
end

function CrossGambling:RegisterGame(text, playerName)
    local joinWord, leaveWord = self:GetJoinWords()
    local lowered = self:TrimInput(text):lower()

    if lowered == joinWord:lower() then
        if self:IsPlayerBanned(playerName) then
            self:Announce("Sorry " .. playerName .. ", you're banned.")
            return
        end

        if self:getPlayerByName(playerName) then
            return
        end

        local mode = self:GetCurrentMode()
        if mode and mode.maxPlayers and #self.game.players >= mode.maxPlayers then
            self:Announce("CrossGambling: This game mode is full (" .. mode.maxPlayers .. " max).")
            return
        end

        local handled, allowed = self:DispatchModeHook("OnPlayerJoin", playerName)
        if handled and allowed == false then
            return
        end

        if self.game.realmFilter == true and self:CheckRealm(playerName) == 0 then
            self:Announce("CrossGambling: You are not on (" .. GetRealmName() .. "). You are not eligible to join this game. The host can turn off the Realm Filter in the options.")
            return
        end

        self:SendMsg("ADD_PLAYER", playerName)

    elseif lowered == leaveWord:lower() then
        if self:getPlayerByName(playerName) then
            self:SendMsg("Remove_Player", playerName)
        end
    end
end

function CrossGambling:CheckRealm(playerName)
    local realmRelationship = UnitRealmRelationship(playerName)
    return (realmRelationship == 2) and 0 or 1
end

function CrossGambling:CGRolls()
    local game = self.game

    if game.state == "REGISTER" then
        local mode = self:GetCurrentMode()
        local minPlayers = (mode and mode.minPlayers) or 2

        if #game.players < minPlayers then
            self:Announce("Not enough Players! This mode needs at least " .. minPlayers .. ".")
            return
        end

        game.state = "ROLL"
        if not (mode and mode.usesChatPick) then
            self:UnRegisterChatEvents()
        end
        self:RegisterEvent("CHAT_MSG_SYSTEM", "handleSystemMessage")

        self:SendMsg("Disable_Join")
        if CGCall["Disable_Join"] then
            CGCall["Disable_Join"]()
        end

        self:Announce("Entries have closed. Roll now!")
        self:DispatchModeHook("OnStartRolls")

    elseif game.state == "ROLL" then
        local turn = self:GetCurrentTurn()
        if turn then
            local _, maxRoll = self:GetRollRange()
            self:Announce(format("%s, it's your turn! Type /roll %d", turn, maxRoll))
            return
        end

        local playersRoll = self:CheckRolls()
        if #playersRoll > 0 then
            self:Announce(table.concat(playersRoll, ", ") .. " still needs to roll!")
        end
    end
end

function CrossGambling:GetRollRange()
    local handled, minRoll, maxRoll = self:DispatchModeHook("GetRollRange")
    if handled and minRoll and maxRoll then
        return minRoll, maxRoll
    end
    return 1, self:GetWager()
end

function CrossGambling:rollMe()
    local minRoll, maxRoll = self:GetRollRange()
    RandomRoll(minRoll, maxRoll)
end

function CrossGambling:GetCurrentTurn()
    local handled, turn = self:DispatchModeHook("GetCurrentTurn")
    if handled then
        return turn
    end
    return nil
end


function CrossGambling:SettleDebt(loserName, winnerName, amount, modeName, winnerAmount)
    winnerAmount = winnerAmount or amount
    self:updatePlayerStat(loserName, -amount, modeName)
    self:updatePlayerStat(winnerName, winnerAmount, modeName)

    self:AddAuditEntry({
        timestamp = time(),
        action    = "debt",
        loser     = loserName,
        winner    = winnerName,
        amount    = amount,
    })

    return string.format("%s owes %s %sg!", loserName, winnerName, self:addCommas(winnerAmount))
end

function CrossGambling:ApplyHouseCut(amount)
    if not self.game.house then
        return amount, 0
    end

    local houseAmount = math.floor(amount * (self:GetHouseCut() / 100))
    if houseAmount > 0 then
        self:updatePlayerStat("guild", houseAmount)
        self.db.global.housestats = (self.db.global.housestats or 0) + houseAmount
    end

    return amount - houseAmount, houseAmount
end

function CrossGambling:FinishGame(lines)
    for _, line in ipairs(lines or {}) do
        self:Announce(line)
    end
    self:CloseGame()
end

function CrossGambling:CloseGame()
    self:DispatchModeHook("OnEnd")

    if self.game.host then
        self:SendMsg("GAME_OVER")
    end

    self:ResetGameState()

    if CGCall["GAME_OVER"] then
        CGCall["GAME_OVER"]()
    end
end
