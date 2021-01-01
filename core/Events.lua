function CrossGambling:drawEvents()
CGEvents["START_GAME"] = function()
       -- Starts a new game
    if (self.game.state == "START" and self.game.host == true) then
        -- Start listening to chat messages
		self:RegisterChatEvents()
        -- Change the game state to REGISTRATION
        self.game.state = "REGISTER"
        self:GameStart()
        -- Inform players of the selected Game Mode and Wager
        if (self.game.house == false) then
			local RollNotification = "Wager - " .. self:Comma(self.db.global.wager) .. "g"
				if(self.game.chatframeOption == false and self.game.host == true) then	
					self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
				else
					SendChatMessage("Game Mode - " .. self.game.mode .. " - Wager - " .. self:Comma(self.db.global.wager) .. "g", self.game.chatMethod)
                end  	
        else
            local RollNotification = "Wager - " .. self:Comma(self.db.global.wager) .. "g - House Cut - " .. self.db.global.houseCut .. "%"
				if(self.game.chatframeOption == false and self.game.host == true) then	
					self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
				else
					SendChatMessage("Game Mode - " .. self.game.mode .. " - Wager - " .. self:Comma(self.db.global.wager) .. "g - House Cut - " .. self.db.global.houseCut .. "%", self.game.chatMethod)
                end  
		 end
		-- Disable Button for clients.
		self:SendEvent("DisableClient")
    end
end
-- Triggers the roll me function, which sends to all clients.
CGEvents["ROLL_ME"] = function(maxAmount, minAmount)
   CrossGambling:rollMe()
end

-- Triggers Add Function for all clients.
CGEvents["ADD_PLAYER"] = function(playerName)
	  CrossGambling:AddPlayer(playerName)
	  self:registerPlayer(playerName)
end
-- Triggers Remove Function for all clients.
CGEvents["Remove_Player"] = function(playerName)
	  CrossGambling:RemovePlayer(playerName)
	  self:unregisterPlayer(playerName)
end
-- Sets the roll for all clients.
CGEvents["SET_ROLL"] = function(value)
	self.db.global.wager = tonumber(value)
end 
-- Sets the game mode for all clients.
CGEvents["GAME_MODE"] = function(value)
 self.game.mode = tostring(value)
end
CGEvents["SET_HOUSE"] = function(value)
        self.db.global.houseCut = tostring(value)
end
-- Sets everyone to proper chatMethod for all clients.
CGEvents["Chat_Method"] = function(value)
 self.game.chatMethod = tostring(value)
end
-- Lets the players know what the roll amount is.
CGEvents["START_ROLLS"] = function(maxAmount)
	if (self.game.mode == "BigTwo") then
		self.db.global.wager = 2
	elseif (self.game.mode == "501") then
		self.db.global.wager = 501
	else
		self.db.global.wager = self.db.global.wager
	end
	function rollMe(maxAmount, minAmount)
			if (minAmount == nil) then
				minAmount = 1
			end
    RandomRoll(minAmount, self.db.global.wager)
	end
	if(self.game.host == true) then
		local RollNotification = "Press Roll Me!"
	if(self.game.chatframeOption == false and self.game.host == true) then	
		self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
	else
		SendChatMessage("Entries have closed. Roll now!", self.game.chatMethod)
		SendChatMessage(format("Type /roll %s", self.db.global.wager), self.game.chatMethod)
    end
  end
end

CGEvents["LastCall"] = function()
	if(self.game.chatframeOption == false and self.game.host == true) then
		local RollNotification = "Last Call!"
		self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
    elseif(self.game.host == true) then 
		SendChatMessage("Last Call to Enter", self.game.chatMethod)
	end
end

end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")