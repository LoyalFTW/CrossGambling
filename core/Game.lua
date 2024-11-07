function CrossGambling:GameStart()
  if self.game.mode == "1v1DeathRoll" then
        -- Initialize current roll to the wager for 1v1 Deathroll
        self.currentRoll = self.db.global.wager
        self.currentPlayerIndex = 1
    end

    if self.game.chatframeOption == false then
        local RollNotification = "has started a roll!"
        self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
    else
        SendChatMessage("CrossGambling: A new game has been started! Type 1 to join! (-1 to withdraw)", self.game.chatMethod)
    end
end

function CrossGambling:RegisterGame(text, playerName)
        -- Handle player joining
    if text == "1" then
        -- For 1v1DeathRoll mode, enforce exactly 2 players
        if self.game.mode == "1v1DeathRoll" then
            -- Allow the player to join only if the game has fewer than 2 players
            if #self.game.players == 2 then
                SendChatMessage("CrossGambling: This is a 1v1 DeathRoll. Only 2 players can join.", self.game.chatMethod)
                return
            end
        end
		if (self.game.realmFilter == true and self:CheckRealm(playerName) == 0) then
			SendChatMessage("CrossGambling: You are not on (" .. GetRealmName() .. "). You are not eligible to join this game. The host can turn off the Realm Filter in the options." , self.game.chatMethod)
		else
			self:SendMsg("ADD_PLAYER", playerName)		
		end
    elseif (text == "-1") then
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
    -- Add an And or Comma between names of tied players. 
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
        -- New loser.
        if (self.game.players[i].roll < losers[1].roll) then
            losers = {self.game.players[i]}
        -- New winner.
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

    -- Incase all players tie. 
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
    -- Determine the type of tiebreaker (High/Low).
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
            -- Continue game until no more ties.
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
    if self.game.chatframeOption == false and self.game.host == true then
        local RollNotification = tieType .. " tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!"
        self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
    else
        SendChatMessage(tieType .. " tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!", self.game.chatMethod)
    end
end

















C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")