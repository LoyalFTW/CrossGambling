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

function CrossGambling:GameStart()
    local handled = self:DispatchModeHook("OnStart")
    if not handled then
        local joinWord  = self.db.global.joinWord  or "1"
        local leaveWord = self.db.global.leaveWord or "-1"
        if self.game.chatframeOption == false then
            self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, "has started a roll!"))
        else
            self:SendChat("CrossGambling: A new game has been started! Type " .. joinWord .. " to join! (" .. leaveWord .. " to withdraw)")
        end
    end
end

function CrossGambling:RegisterGame(text, playerName)
    local joinWord  = self.db.global.joinWord  or "1"
    local leaveWord = self.db.global.leaveWord or "-1"

    if text:lower() == joinWord:lower() then
        if isPlayerBanned(self, playerName) then
            self:SendChat("Sorry " .. playerName .. ", you're banned.")
            return
        end

        local mode    = self:GetCurrentMode()
        local allowed = true
        if mode and type(mode.OnPlayerJoin) == "function" then
            allowed = mode:OnPlayerJoin(self, self.game, playerName)
        end

        if allowed == false then return end

        if self.game.realmFilter == true and self:CheckRealm(playerName) == 0 then
            self:SendChat("CrossGambling: You are not on (" .. GetRealmName() .. "). You are not eligible to join this game. The host can turn off the Realm Filter in the options.")
        else
            self:SendMsg("ADD_PLAYER", playerName)
        end

    elseif text:lower() == leaveWord:lower() then
        self:SendMsg("Remove_Player", playerName)
    end
end

function CrossGambling:CheckRealm(playerName)
    local realmRelationship = UnitRealmRelationship(playerName)
    return (realmRelationship == 2) and 0 or 1
end

function CrossGambling:String(players)
    local nameString = players[1].name
    if #players > 1 then
        for i = 2, #players do
            if i == #players then
                nameString = nameString .. " and " .. players[i].name
            else
                nameString = nameString .. ", " .. players[i].name
            end
        end
    end
    return nameString
end

function CrossGambling:CResult()
    local winners    = { self.game.players[1] }
    local losers     = { self.game.players[1] }
    local amountOwed = 0

    for i = 2, #self.game.players do
        local p = self.game.players[i]
        if p.roll < losers[1].roll then
            losers = { p }
        elseif p.roll > winners[1].roll then
            winners = { p }
        else
            if p.roll == losers[1].roll  then tinsert(losers,  p) end
            if p.roll == winners[1].roll then tinsert(winners, p) end
        end
    end

    if winners[1].name == losers[1].name then
        losers = {}
    else
        amountOwed = winners[1].roll - losers[1].roll
    end

    return { winners = winners, losers = losers, amountOwed = amountOwed }
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
            local p = self.game.players[i]
            if (tieType == "High" and p.roll == self.game.result.winners[1].roll) or
               (tieType == "Low"  and p.roll == self.game.result.losers[1].roll)  then
                tinsert(tiedPlayers, p)
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
    if self.game.chatframeOption == false and self.game.host == true then
        self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, tieType .. " tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!"))
    else
        self:SendChat(tieType .. " tie breaker! " .. self:String(self.game.players) .. " /roll " .. self.db.global.wager .. " now!")
    end
end

function CrossGambling:CloseGame()
    self:DispatchModeHook("OnEnd")
    self:UnregisterEvent("CHAT_MSG_SYSTEM")

    if self.game.result ~= nil then
        if #self.game.result.losers > 0 and #self.game.result.winners > 0 then
            local houseAmount = 0
            if self.game.house == true then
                houseAmount = math.floor(self.game.result.amountOwed * (self.db.global.houseCut / 100))
                self.game.result.amountOwed = self.game.result.amountOwed - houseAmount
            end

            for i = 1, #self.game.result.losers do
                local RollNotification
                if self.game.house == true then
                    RollNotification = self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. self:addCommas(self.game.result.amountOwed) .. " gold! plus " .. self:addCommas(houseAmount) .. " to the guild"
                    self:updatePlayerStat("guild", houseAmount)
                else
                    RollNotification = self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. self:addCommas(self.game.result.amountOwed) .. " gold!"
                end

                if self.game.chatframeOption == false and self.game.host == true then
                    self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
                else
                    self:SendChat(RollNotification)
                end

                self:updatePlayerStat(self.game.result.losers[i].name, self.game.result.amountOwed * -1)
                self:updatePlayerStat(self.game.result.winners[i].name, self.game.result.amountOwed * #self.game.result.losers)

                self:AddAuditEntry({
                    timestamp = time(),
                    action    = "debt",
                    loser     = self.game.result.losers[i].name,
                    winner    = self.game.result.winners[i].name,
                    amount    = self.game.result.amountOwed,
                })
            end
        else
            if self.game.chatframeOption == false and self.game.host == true then
                self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, "No winners this round!"))
            else
                self:SendChat("No winners this round!")
            end
        end
    end

    self.currentRoll  = nil
    self.game.state   = "START"
    self.game.players = {}
    self.game.result  = nil
    self.game.host    = false
end

function CrossGambling:rollMe(minAmount)
    local wager     = self.db.global.wager or 100
    minAmount       = minAmount or 1
    local maxAmount = (self.currentRoll and self.game.mode == "1v1DeathRoll") and self.currentRoll or wager
    RandomRoll(minAmount, maxAmount)
end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")
