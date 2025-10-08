function CrossGambling:DrawSecondEvents()

function add_commas(value) 
return #tostring(value) > 3 and tostring(value):gsub("^(-?%d+)(%d%d%d)", "%1,%2"):gsub("(%d)(%d%d%d)", ",%1,%2") or tostring(value) 
end


CGCall["New_Game"] = function()
    if (self.game.state == "START" and self.game.host == true) then
        self:RegisterChatEvents()

        self.game.state = "REGISTER"
        self:GameStart()

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
        
        if self.game.chatframeOption then
            SendChatMessage(initialPrompt, self.game.chatMethod)
        else
            self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, initialPrompt))
        end


        if self.game.mode == "1v1DeathRoll" then
            self.currentRoll = self.db.global.wager  
            self.currentPlayerIndex = 1 
            self:PromptNextRoll() 
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