local CG = CrossGambling

function CG:handleChatMsg(_, text, playerName)
    if (self.game.state == "REGISTER") then
        local playerName = strsplit("-", playerName, 2)
        self:RegisterGame(text, playerName)
    end
end

function CG:handleSystemMessage(_, text)
    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")

    if not playerName or not actualRoll or not minRoll or not maxRoll then
        return
    end

    minRoll, maxRoll = tonumber(minRoll), tonumber(maxRoll)
    actualRoll = tonumber(actualRoll)

    if self.game.mode == "1v1DeathRoll" then
        if minRoll ~= 1 or maxRoll ~= self.currentRoll then
            self:Announce("Error: Roll does not match expected range.")
            return
        end

        local currentPlayer = self.game.players[self.currentPlayerIndex]
        if not currentPlayer then
            self:Announce("Error: Current player is nil.")
            return
        end

        if playerName ~= currentPlayer.name then
            self:Announce(format("%s, it's not your turn! It's %s's turn.", playerName, currentPlayer.name))
            return
        end

        CGCall["PLAYER_ROLL"](playerName, actualRoll)

        if actualRoll == 1 then
            local loser = currentPlayer
            local winner = self.game.players[3 - self.currentPlayerIndex]
            self:Announce(format("%s rolls a 1 and loses! %s owes %s %s", loser.name, loser.name, winner.name, self.db.global.wager))
            self:updatePlayerStat(loser.name, -self.db.global.wager, true)
            self:updatePlayerStat(winner.name, self.db.global.wager, true)
            return
        else
            self.currentRoll = actualRoll
            self.currentPlayerIndex = 3 - self.currentPlayerIndex
            self:PromptNextRoll()
        end
    else
        if minRoll == 1 and maxRoll == self.db.global.wager then
            for i = 1, #self.game.players do
                if self.game.players[i].name == playerName and self.game.players[i].roll == nil then
                    self.game.players[i].roll = actualRoll
                    self:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))
                end
            end
        end

        if #self:CheckRolls() == 0 then
            self:CGResults()
        end
    end
end
