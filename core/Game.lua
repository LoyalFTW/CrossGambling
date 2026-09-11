
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
    game.doubleOrNothingEnabled = false
    game.doubleOrNothing = nil
    self:ResetPlayers()
end

function CrossGambling:HostNewGame()
    local game = self.game
    local global = self.db.global

    if not self:CanSendToChannel(game.chatMethod) then
        self:Print(self:GetUnavailableChannelMessage(game.chatMethod))
        return false
    end

    if game.doubleOrNothing then
        local requestedMode = game.mode
        game.mode = game.doubleOrNothing.mode or game.mode
        self:SettleDoubleOrNothing(game.doubleOrNothing.amount, "Double or Nothing ended by the host.")
        game.mode = requestedMode
    end

    if game.state ~= "START" then
        self:ResetGameState()
    end

    game.host = true
    game.hostName = game.PlayerName
    game.wager = global.wager
    game.houseCut = global.houseCut
    game.doubleOrNothingEnabled = global.doubleOrNothingEnabled == true
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
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if self.game and self.game.state == "DOUBLE_OR_NOTHING_ROLL" and doubleOrNothing then
        return 1, doubleOrNothing.max
    end

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
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if self.game and self.game.state == "DOUBLE_OR_NOTHING_ROLL" and doubleOrNothing then
        return doubleOrNothing.turn
    end

    local handled, turn = self:DispatchModeHook("GetCurrentTurn")
    if handled then
        return turn
    end
    return nil
end

function CrossGambling:SettleDoubleOrNothing(amount, resultLine)
    local game = self.game
    local doubleOrNothing = game and game.doubleOrNothing
    if not doubleOrNothing then
        return
    end

    game.doubleOrNothing = nil
    game.state = "ROLL"

    if amount > 0 then
        local winnerAmount, houseAmount = self:ApplyHouseCut(amount)
        local debtLine = self:SettleDebt(doubleOrNothing.loser, doubleOrNothing.winner, amount, doubleOrNothing.mode, winnerAmount)
        if houseAmount > 0 then
            debtLine = debtLine .. " Plus " .. self:addCommas(houseAmount) .. "g to the guild."
        end
        if doubleOrNothing.started then
            self:AddAuditEntry({
                timestamp = time(),
                action = "doubleOrNothing",
                loser = doubleOrNothing.loser,
                winner = doubleOrNothing.winner,
                originalAmount = doubleOrNothing.amount,
                finalAmount = amount,
                outcome = doubleOrNothing.outcome or "cancelled",
                rolledOne = doubleOrNothing.rolledOne,
                mode = doubleOrNothing.mode,
            })
        end
        self:FinishGame({ resultLine .. " " .. debtLine })
    else
        if doubleOrNothing.started then
            self:AddAuditEntry({
                timestamp = time(),
                action = "doubleOrNothing",
                loser = doubleOrNothing.loser,
                winner = doubleOrNothing.winner,
                originalAmount = doubleOrNothing.amount,
                finalAmount = 0,
                outcome = doubleOrNothing.outcome or "cleared",
                rolledOne = doubleOrNothing.rolledOne,
                mode = doubleOrNothing.mode,
            })
        end
        self:FinishGame({ resultLine .. " Nothing is owed!" })
    end
end

function CrossGambling:DeclineDoubleOrNothing(reason)
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if not doubleOrNothing or self.game.state ~= "DOUBLE_OR_NOTHING_OFFER" then
        return
    end

    self:SettleDoubleOrNothing(doubleOrNothing.amount, reason or "Double or Nothing declined.")
end

function CrossGambling:SyncDoubleOrNothingRoll()
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if not doubleOrNothing or not self.game.host then
        return
    end

    self:SendMsg("DOUBLE_OR_NOTHING_ROLL", table.concat({
        doubleOrNothing.loser,
        doubleOrNothing.winner,
        doubleOrNothing.turn,
        tostring(doubleOrNothing.max),
    }, "|"))
end

function CrossGambling:StartDoubleOrNothingRoll()
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if not doubleOrNothing then
        return
    end

    self.game.state = "DOUBLE_OR_NOTHING_ROLL"
    doubleOrNothing.started = true
    doubleOrNothing.turn = doubleOrNothing.loser
    doubleOrNothing.max = doubleOrNothing.amount
    self:UnRegisterChatEvents()
    self:SyncDoubleOrNothingRoll()
    self:Announce(string.format("Double or Nothing! %s starts: type /roll %d.", doubleOrNothing.turn, doubleOrNothing.max))
end

function CrossGambling:HandleDoubleOrNothingChat(playerName, text)
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if not doubleOrNothing or self.game.state ~= "DOUBLE_OR_NOTHING_OFFER" then
        return
    end

    local normalizedName = self:NormalizePlayerName(playerName)
    local loserKey = self:NormalizePlayerName(doubleOrNothing.loser)
    local winnerKey = self:NormalizePlayerName(doubleOrNothing.winner)
    if normalizedName ~= loserKey and normalizedName ~= winnerKey then
        return
    end

    local response = self:TrimInput(text):lower()
    if response == "pass" then
        self:DeclineDoubleOrNothing(playerName .. " passed.")
        return
    end
    if response ~= "1" or doubleOrNothing.accepted[normalizedName] then
        return
    end

    doubleOrNothing.accepted[normalizedName] = true
    if doubleOrNothing.accepted[loserKey] and doubleOrNothing.accepted[winnerKey] then
        self:StartDoubleOrNothingRoll()
    else
        local waitingFor = normalizedName == loserKey and doubleOrNothing.winner or doubleOrNothing.loser
        self:Announce(playerName .. " accepted Double or Nothing. Waiting for " .. waitingFor .. ".")
    end
end

function CrossGambling:HandleDoubleOrNothingRoll(playerName, actualRoll, minRoll, maxRoll)
    local doubleOrNothing = self.game and self.game.doubleOrNothing
    if not doubleOrNothing or self.game.state ~= "DOUBLE_OR_NOTHING_ROLL" then
        return
    end

    if playerName ~= doubleOrNothing.turn then
        if playerName == doubleOrNothing.loser or playerName == doubleOrNothing.winner then
            self:Announce(string.format("%s, it's not your turn! It's %s's turn.", playerName, doubleOrNothing.turn))
        end
        return
    end

    if minRoll ~= 1 or maxRoll ~= doubleOrNothing.max then
        self:Announce("CrossGambling: Roll does not match the expected range (1-" .. doubleOrNothing.max .. ").")
        return
    end

    self:RecordRoll(playerName, actualRoll)
    if actualRoll == 1 then
        doubleOrNothing.rolledOne = playerName
        if playerName == doubleOrNothing.loser then
            doubleOrNothing.outcome = "doubled"
            self:SettleDoubleOrNothing(doubleOrNothing.amount * 2, playerName .. " rolled a 1. The debt is doubled!")
        else
            doubleOrNothing.outcome = "cleared"
            self:SettleDoubleOrNothing(0, playerName .. " rolled a 1. The debt is cleared!")
        end
        return
    end

    doubleOrNothing.max = actualRoll
    doubleOrNothing.turn = playerName == doubleOrNothing.loser and doubleOrNothing.winner or doubleOrNothing.loser
    self:SyncDoubleOrNothingRoll()
    self:Announce(string.format("%s, it's your turn! Type /roll %d", doubleOrNothing.turn, doubleOrNothing.max))
end

function CrossGambling:BeginDoubleOrNothing(loserName, winnerName, amount, modeName)
    local game = self.game
    amount = tonumber(amount)
    if not game or not game.host or not game.doubleOrNothingEnabled or not amount or amount < 2 then
        return false
    end

    local doubleOrNothing = {
        loser = loserName,
        winner = winnerName,
        amount = amount,
        mode = modeName,
        accepted = {},
    }
    game.doubleOrNothing = doubleOrNothing
    game.state = "DOUBLE_OR_NOTHING_OFFER"
    self:RegisterChatEvents()
    self:SendMsg("DOUBLE_OR_NOTHING_OFFER", table.concat({ loserName, winnerName, tostring(amount) }, "|"))
    self:Announce(string.format("%s owes %s %sg. %s and %s: type 1 within 30 seconds for Double or Nothing, or type pass to settle now.", loserName, winnerName, self:addCommas(amount), loserName, winnerName))

    C_Timer.After(30, function()
        if self.game and self.game.doubleOrNothing == doubleOrNothing and self.game.state == "DOUBLE_OR_NOTHING_OFFER" then
            self:DeclineDoubleOrNothing("Double or Nothing timed out.")
        end
    end)
    return true
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
    if self.game.doubleOrNothing then
        self:SettleDoubleOrNothing(self.game.doubleOrNothing.amount, "Double or Nothing ended.")
        return
    end

    self:DispatchModeHook("OnEnd")

    if self.game.host then
        self:SendMsg("GAME_OVER")
    end

    self:ResetGameState()

    if CGCall["GAME_OVER"] then
        CGCall["GAME_OVER"]()
    end
end
