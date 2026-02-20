function CrossGambling:GameStart()
  if self.game.mode == "1v1DeathRoll" then
        self.currentRoll = self.db.global.wager
        self.currentPlayerIndex = 1
    end

    local word = self.db.global.joinWord or "1"
    local leave = self.db.global.leaveWord or "-1"
    self:Announce("CrossGambling: A new game has been started! Type " .. word .. " to join! (" .. leave .. " to withdraw)")
end

function CrossGambling:RegisterGame(text, playerName)
    local word = self.db.global.joinWord or "1"
    local leave = self.db.global.leaveWord or "-1"
    local function matches(input, target)
        if tonumber(target) then
            return input == target
        end
        return input:lower() == target:lower()
    end
    if matches(text, word) then
        if self.game.mode == "1v1DeathRoll" then
            if #self.game.players == 2 then
                self:Announce("CrossGambling: This is a 1v1 DeathRoll. Only 2 players can join.")
                return
            end
        end
		if (self.game.realmFilter == true and self:CheckRealm(playerName) == 0) then
			self:Announce("CrossGambling: You are not on (" .. GetRealmName() .. "). You are not eligible to join this game. The host can turn off the Realm Filter in the options." )
		else
			self:SendMsg("ADD_PLAYER", playerName)
		end
    elseif matches(text, leave) then
		self:SendMsg("Remove_Player", playerName)
    end
end

function CrossGambling:CheckRealm(playerName)
	local realmRelationship = UnitRealmRelationship(playerName)

	if (realmRelationship == 2) then
		return 0
	else
		return 1
	end
end


function CrossGambling:String(players)
    local nameString = players[1].name

    if (#players > 1) then
        for i = 2, #players do
            if (i == #players) then
                nameString = nameString .. " and " .. players[i].name
            else
                nameString = nameString .. ", " .. players[i].name
            end
        end
    end

    return nameString
end

function CrossGambling:CResult()
    local winners = {self.game.players[1]}
    local losers = {self.game.players[1]}
    local amountOwed = 0

    for i = 2, #self.game.players do
        if (self.game.players[i].roll < losers[1].roll) then
            losers = {self.game.players[i]}
        elseif (self.game.players[i].roll > winners[1].roll) then
            winners = {self.game.players[i]}
        else
            if (self.game.players[i].roll == losers[1].roll) then
                tinsert(losers, self.game.players[i])
            end

            if (self.game.players[i].roll == winners[1].roll) then
                tinsert(winners, self.game.players[i])
            end
        end
    end

    if (winners[1].name == losers[1].name) then
        losers = {}
    else
        amountOwed = winners[1].roll - losers[1].roll
    end

    return {
        winners = winners,
        losers = losers,
        amountOwed = amountOwed
    }


end


function CrossGambling:detectTie()
    local tieType = ""
    if #self.game.result.winners > 1 then
        tieType = "High"
    elseif #self.game.result.losers > 1 then
        tieType = "Low"
    end

    if tieType ~= "" then
        local tiedPlayers = {}
        for i = 1, #self.game.players do
            if (tieType == "High" and self.game.players[i].roll == self.game.result.winners[1].roll) or
               (tieType == "Low" and self.game.players[i].roll == self.game.result.losers[1].roll) then
                tinsert(tiedPlayers, self.game.players[i])
            end
        end

        if #tiedPlayers > 1 then
            self.game.players = tiedPlayers

            for i = 1, #self.game.players do
                self.game.players[i].roll = nil
            end

            self:TieBreaker(tieType)
        else
            self:CloseGame()
        end
    else
        self:CloseGame()
    end
end

function CrossGambling:TieBreaker(tieType)
    self:Announce(tieType .. " tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!")
end


