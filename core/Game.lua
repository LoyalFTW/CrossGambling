function CrossGambling:GameStart()
	if(self.game.chatframeOption == false) then
		local RollNotification = "has started a roll!"
		self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
    else
		SendChatMessage("CrossGambling: A new game has been started! Type 1 to join! (-1 to withdraw)" , self.game.chatMethod)	
    end
end

function CrossGambling:RegisterGame(text, playerName)
    if (text == "1") then
		self:SendEvent("ADD_PLAYER", playerName)
    elseif (text == "-1") then
		self:SendEvent("Remove_Player", playerName)   
    end
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
    -- Does a tie-breaker Hi-End/Low-End
    local tieBreakers = {}

    if (#self.game.result.winners > 1 and #self.game.result.losers ~= 0) then
        tieBreakers = self.game.result.winners
    elseif (#self.game.result.losers > 1 and #self.game.result.winners ~= 0) then
        tieBreakers = self.game.result.losers
    end

    if (#tieBreakers > 0) then
        -- Continue game until no more ties. 
        self.game.players = tieBreakers

        for i = 1, #self.game.players do
            self.game.players[i].roll = nil
        end

        self:TieBreaker()
    else
        self:CloseGame()
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

function CrossGambling:TieBreaker()
    -- Lets player know there was a Hi-End/Low-End tie and needs to be resolved. 
    if (#self.game.result.winners > 1) then
		if(self.game.chatframeOption == false and self.game.host == true) then
			local RollNotification = "High end tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!"
			self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
		else
			SendChatMessage("High end tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!", self.game.chatMethod)
		end
    elseif (#self.game.result.losers > 1) then
	    if(self.game.chatframeOption == false and self.game.host == true) then
			local RollNotification = "Low end tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!"
			self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
		else
			SendChatMessage("Low end tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!", self.game.chatMethod)
		end
    end
end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")