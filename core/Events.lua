function CrossGambling:DrawSecondEvents()

CGCall["New_Game"] = function()
    if self.game.state == "START" and self.game.host == false then
        self:RegisterChatEvents()
        self.game.state = "REGISTER"
        if CGCall["DisableClient"] then
            CGCall["DisableClient"]()
        end
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

CGCall["START_ROLLS"] = function()
    self:SendMsg("Disable_Join")

    if self.game.host then
        local prompt = "Entries have closed. Roll now!"
        if self.game.chatframeOption then
            self:SendChat(prompt)
        else
            self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, prompt))
        end

        self:DispatchModeHook("OnStartRolls")
    end
end

CGCall["LastCall"] = function()
    if self.game.chatframeOption == false and self.game.host == true then
        self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, "Last Call!"))
    elseif self.game.host == true then
        self:SendChat("Last Call to Enter")
    end
end

end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")
