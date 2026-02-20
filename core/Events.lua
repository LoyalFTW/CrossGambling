function CrossGambling:DrawSecondEvents()

CGCall["New_Game"] = function()
    if (self.game.state == "START" and self.game.host == true) then
        self:RegisterChatEvents()

        self.game.state = "REGISTER"
        self:GameStart()

        if (self.game.house == false) then
            self:Announce("Game Mode - " .. self.game.mode .. " - Wager - " .. add_commas(self.db.global.wager) .. "g")
        else
            self:Announce("Game Mode - " .. self.game.mode .. " - Wager - " .. add_commas(self.db.global.wager) .. "g - House Cut - " .. self.db.global.houseCut .. "%")
        end

        self:SendMsg("DisableClient")
    end
end

CGCall["ADD_PLAYER"] = function(playerName)
	CrossGambling:AddPlayer(playerName)
	self:registerPlayer(playerName)
end

CGCall["Remove_Player"] = function(playerName)
	CrossGambling:RemovePlayer(playerName)
	self:unregisterPlayer(playerName)
end

CGCall["SET_WAGER"] = function(value)
	self.db.global.wager = tonumber(value)
end 

CGCall["GAME_MODE"] = function(value)
	self.game.mode = tostring(value)
end
CGCall["SET_HOUSE"] = function(value)
	self.db.global.houseCut = tostring(value)
end

CGCall["Chat_Method"] = function(value)
	self.game.chatMethod = tostring(value)
end

CGCall["START_ROLLS"] = function(maxAmount)
    self:SendMsg("Disable_Join")
    
    self.db.global.wager = (self.game.mode == "BigTwo") and 2 or self.db.global.wager
    
	function rollMe(minAmount)
        minAmount = minAmount or 1
        RandomRoll(minAmount, self.db.global.wager)
    end
 
    if self.game.host then
        local initialPrompt = "Entries have closed. Roll now!"
        
        self:Announce(initialPrompt)


        if self.game.mode == "1v1DeathRoll" then
            self.currentRoll = self.db.global.wager  
            self.currentPlayerIndex = 1 
            self:PromptNextRoll() 
        end
    end
end


CGCall["LastCall"] = function()
	if(self.game.host == true) then
		self:Announce("Last Call to Enter")
	end
end



end

