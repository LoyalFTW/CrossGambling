local function normalizePlayerName(name)
    if not name then
        return nil
    end

    name = strtrim(tostring(name))
    name = strsplit("-", name, 2)
    if name == "" then
        return nil
    end

    return strlower(name)
end

local function isPlayerBanned(addon, playerName)
    local normalizedPlayerName = normalizePlayerName(playerName)
    if not normalizedPlayerName then
        return false
    end

    for _, bannedPlayer in ipairs((addon and addon.db and addon.db.global and addon.db.global.bans) or {}) do
        if normalizePlayerName(bannedPlayer) == normalizedPlayerName then
            return true
        end
    end

    return false
end

function CrossGambling:DrawSecondEvents()

CGCall["New_Game"] = function()
    if self.game.state == "START" and self.game.host == false then
        self:RegisterChatEvents()
        self.game.state = "REGISTER"
        if CGChat and CGChat.StartListening then
            CGChat:StartListening()
        end
        if CGCall["DisableClient"] then
            CGCall["DisableClient"]()
        end
    end
end

CGCall["ADD_PLAYER"] = function(playerName)
    if isPlayerBanned(self, playerName) then
        CrossGambling:RemovePlayer(playerName)
        self:unregisterPlayer(playerName)
        return
    end

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
    self:SetHouseCut(value)
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
