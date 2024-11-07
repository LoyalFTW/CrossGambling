function CrossGambling:DrawSecondEvents()

function add_commas(value) 
return #tostring(value) > 3 and tostring(value):gsub("^(-?%d+)(%d%d%d)", "%1,%2"):gsub("(%d)(%d%d%d)", ",%1,%2") or tostring(value) 
end


CGCall["New_Game"] = function()
    -- Starts a new game
    if (self.game.state == "START" and self.game.host == true) then
        -- Start listening to chat messages
        self:RegisterChatEvents()

        -- Change the game state to REGISTRATION
        self.game.state = "REGISTER"
        self:GameStart()

        -- Inform players of the selected Game Mode and Wager
        if (self.game.house == false) then
            local RollNotification = "Wager - " .. add_commas(self.db.global.wager) .. "g"
            if(self.game.chatframeOption == false and self.game.host == true) then
                self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
            else
                SendChatMessage("Game Mode - " .. self.game.mode .. " - Wager - " .. add_commas(self.db.global.wager) .. "g", self.game.chatMethod)
            end
        else
            local RollNotification = "Wager - " .. add_commas(self.db.global.wager) .. "g - House Cut - " .. self.db.global.houseCut .. "%"
            if(self.game.chatframeOption == false and self.game.host == true) then
                self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
            else
                SendChatMessage("Game Mode - " .. self.game.mode .. " - Wager - " .. add_commas(self.db.global.wager) .. "g - House Cut - " .. self.db.global.houseCut .. "%", self.game.chatMethod)
            end
        end

        -- Disable Button for clients.
        self:SendMsg("DisableClient")
    end
end

-- Triggers Add Function for all clients.
CGCall["ADD_PLAYER"] = function(playerName)
	CrossGambling:AddPlayer(playerName)
	self:registerPlayer(playerName)
end
-- Triggers Remove Function for all clients.
CGCall["Remove_Player"] = function(playerName)
	CrossGambling:RemovePlayer(playerName)
	self:unregisterPlayer(playerName)
end
-- Sets the roll for all clients.
CGCall["SET_WAGER"] = function(value)
	self.db.global.wager = tonumber(value)
end 
-- Sets the game mode for all clients.
CGCall["GAME_MODE"] = function(value)
	self.game.mode = tostring(value)
end
CGCall["SET_HOUSE"] = function(value)
	self.db.global.houseCut = tostring(value)
end
-- Sets everyone to proper chatMethod for all clients.
CGCall["Chat_Method"] = function(value)
	self.game.chatMethod = tostring(value)
end
-- Lets the players know what the roll amount is.
CGCall["START_ROLLS"] = function(maxAmount)
    self:SendMsg("Disable_Join")
    
    -- Set the wager based on the game mode
    self.db.global.wager = (self.game.mode == "BigTwo") and 2 or self.db.global.wager
    
	function rollMe(minAmount)
        minAmount = minAmount or 1
        RandomRoll(minAmount, self.db.global.wager)
    end
    -- Initial prompt to start the rolls
    if self.game.host then
        local initialPrompt = "Entries have closed. Roll now!"
        
        if self.game.chatframeOption then
            SendChatMessage(initialPrompt, self.game.chatMethod)
        else
            self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, initialPrompt))
        end

        -- Only start prompting rolls if the mode is 1v1 DeathRoll
        if self.game.mode == "1v1DeathRoll" then
            self.currentRoll = self.db.global.wager  -- Initialize the first roll amount
            self.currentPlayerIndex = 1  -- Start with the first player
            self:PromptNextRoll()  -- Call the function to prompt the first player
        end
    end
end


CGCall["LastCall"] = function()
	if(self.game.chatframeOption == false and self.game.host == true) then
		local RollNotification = "Last Call!"
		self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
    elseif(self.game.host == true) then 
		SendChatMessage("Last Call to Enter", self.game.chatMethod)
	end
end



end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")