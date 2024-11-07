function CrossGambling:Copy_Table(src, dest)
    -- Adding the old stats to the new table. 
    for index, value in pairs(src) do
        if type(value) == "table" then
            dest[index] = {}
            self:Copy_Table(value, dest[index])
        else
            dest[index] = value
        end
    end
end

function CrossGambling:reportStats(full)
    -- Post the stats to the chat channel
    SendChatMessage("-- CrossGambling All Time Stats --", self.game.chatMethod)
    SendChatMessage(string.format("The house has taken %s total.", (self.db.global.housestats)), self.game.chatMethod)

    local sortlistname = {}
    local sortlistamount = {}
    local n = 0

    -- Allows for the old stats to be removed and updated to the new table. 
    if CrossGambling["stats"] then
        self:Copy_Table(self.db.global.stats, CrossGambling["stats"])
        CrossGambling["stats"] = nil
    end

    for i, j in pairs(self.db.global.stats) do
        local name = i
        if self.db.global.joinstats[strlower(i)] then
            name = self.db.global.joinstats[strlower(i)]:gsub("^%l", string.upper)
        end
        local found = false
        for k = 1, n do
            if strlower(name) == strlower(sortlistname[k]) then
                sortlistamount[k] = (sortlistamount[k] or 0) + j
                found = true
                break
            end
        end
        if not found then
            n = n + 1
            sortlistname[n] = name
            sortlistamount[n] = j
        end
    end

    -- Sort the stats
    for i = 1, n - 1 do
        for j = i + 1, n do
            if sortlistamount[j] > sortlistamount[i] then
                sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i]
                sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i]
            end
        end
    end

    if full then
        for k = 1, n do
            local sortsign = sortlistamount[k] < 0 and "lost" or "won"
            SendChatMessage(string.format("%d. %s %s %d total", k, sortlistname[k], sortsign, math.abs(sortlistamount[k])), self.game.chatMethod)
        end
        return
    end

    local x1 = math.min(3, n)
    SendChatMessage("-- Top 3 Winners --", self.game.chatMethod)
    for i = 1, x1 do
        local sortsign = sortlistamount[i] < 0 and "lost" or "won"
        SendChatMessage(string.format("%d. %s %s %d total", i, sortlistname[i], sortsign, math.abs(sortlistamount[i])), self.game.chatMethod)
    end

    SendChatMessage("-- Top 3 Losers --", self.game.chatMethod)
    local x2 = math.max(0, n - 3)
    for i = x2 + 1, n do
        local sortsign = sortlistamount[i] < 0 and "lost" or "won"
        SendChatMessage(string.format("%d. %s %s %d total", i, sortlistname[i], sortsign, math.abs(sortlistamount[i])), self.game.chatMethod)
    end
end

function CrossGambling:reportSessionStats()
    -- Report the current session statistics
    SendChatMessage("-- Current Session Stats --", self.game.chatMethod)

    local sessionSortlist = self:sortStats(self.game.sessionStats)
    
    if #sessionSortlist == 0 then
        SendChatMessage("No stats available for the current session.", self.game.chatMethod)
    else
        self:reportSortedStats(sessionSortlist, "Current Session")
    end
end

function CrossGambling:reportSortedStats(sortlist, title)
    for k, v in ipairs(sortlist) do
        local sortsign = v.amount < 0 and "lost" or "won"
        SendChatMessage(string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount)), self.game.chatMethod)
    end
end

function CrossGambling:sortStats(stats)
    local sortedStats = {}
    for name, amount in pairs(stats) do
        table.insert(sortedStats, {name = name, amount = amount})
    end
    table.sort(sortedStats, function(a, b) return a.amount > b.amount end)
    return sortedStats
end

function CrossGambling:updatePlayerStat(playerName, amount, isDeathroll)
    -- Update a given player's stats by adding the given amount.
    if (self.db.global.stats[playerName] == nil) then
        self.db.global.stats[playerName] = 0
    end
    self.db.global.stats[playerName] = self.db.global.stats[playerName] + amount

    -- Update session stats
    if (self.game.sessionStats[playerName] == nil) then
        self.game.sessionStats[playerName] = 0
    end
    self.game.sessionStats[playerName] = self.game.sessionStats[playerName] + amount

    -- Update deathroll stats if applicable
    if isDeathroll then
        if (self.db.global.deathrollStats[playerName] == nil) then
            self.db.global.deathrollStats[playerName] = 0
        end
        self.db.global.deathrollStats[playerName] = self.db.global.deathrollStats[playerName] + amount
    end
end

function CrossGambling:reportDeathrollStats()
    -- Report the deathroll statistics
    SendChatMessage("-- Deathroll Stats --", self.game.chatMethod)

    local deathrollSortlist = self:sortStats(self.db.global.deathrollStats)

    if #deathrollSortlist == 0 then
        SendChatMessage("No stats available for Deathrolls.", self.game.chatMethod)
    else
        self:reportSortedStats(deathrollSortlist, "Deathrolls")
    end
end


function CrossGambling:joinStats(info, args)
    local i = string.find(args, " ")
    if not i or i == -1 or string.find(args, "[", 1, true) or string.find(args, "]", 1, true) then
        DEFAULT_CHAT_FRAME:AddMessage("")
        return
    end
    local mainname = string.sub(args, 1, i - 1)
    local altname = string.sub(args, i + 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname))
    self.db.global.joinstats[altname] = mainname
end

function CrossGambling:unjoinStats(info, altname)
    if altname ~= nil and altname ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname))
        self.db.global.joinstats[altname] = nil
    else
        for i, e in pairs(self.db.global.joinstats) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e))
        end
    end
end

function CrossGambling:listAlts(info)
    -- Alt List
    for mainname, altname in pairs(self.db.global.joinstats) do
        self:Print("[main] " .. mainname .. " is merged with [alt] " .. altname)
    end
end

function CrossGambling:updateStat(info, args)
    local player, amount = strsplit(" ", args)
    amount = tonumber(amount)

    if player ~= nil and amount ~= nil then
        local oldAmount = self.db.global.stats[player] or 0
        self:updatePlayerStat(player, amount)
        self:Print("Successfully updated stats for " .. player .. " (" .. oldAmount .. " -> " .. self.db.global.stats[player] .. ")")
    else
        self:Print("Could not add given amount (" .. tostring(amount) .. ") to " .. tostring(player) .. "'s stats due to invalid input.")
    end
end

function CrossGambling:deleteStat(info, player)
    if self.db.global.stats[player] ~= nil then
        self.db.global.stats[player] = nil
    end
    self:Print("Successfully removed stats for " .. player .. ".")
end

function CrossGambling:resetStats(info)
    self.db.global.stats = {}
    self.db.global.joinstats = {}
    self.game.sessionStats = {}
    self.db.global.deathrollStats = {}
end


