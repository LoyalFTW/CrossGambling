function CrossGambling:joinStats(info, args)
    local mainname, altname = string.match(args, "^(%S+)%s+(%S+)$")
    if not mainname or not altname then
        DEFAULT_CHAT_FRAME:AddMessage("Invalid format. Use: <mainname> <altname>")
        return
    end

    self.db.global.altStats = self.db.global.altStats or {}

    local altStats = {
        stats = self.db.global.stats[altname] or 0,
        deathrollStats = self.db.global.deathrollStats[altname] or 0,
    }
    self.db.global.altStats[altname] = altStats

    self.db.global.stats[mainname] = self.db.global.stats[mainname] or 0
    self.db.global.deathrollStats[mainname] = self.db.global.deathrollStats[mainname] or 0

    self.db.global.stats[mainname] = self.db.global.stats[mainname] + altStats.stats
    self.db.global.deathrollStats[mainname] = self.db.global.deathrollStats[mainname] + altStats.deathrollStats

    self.db.global.joinstats = self.db.global.joinstats or {}
    self.db.global.joinstats[altname] = mainname

    self.db.global.stats[altname] = nil
    self.db.global.deathrollStats[altname] = nil

    self.db.global.mergeAudit = self.db.global.mergeAudit or {}
    self.db.global.mergeAudit[altname] = {
        mainname = mainname,
        statsAdded = altStats.stats,
        deathrollStatsAdded = altStats.deathrollStats,
        timestamp = time()
    }
	
	self.db.global.auditLog = self.db.global.auditLog or {}
    table.insert(self.db.global.auditLog, {
        action = "joinStats",
        mainname = mainname,
        altname = altname,
        statsAdded = altStats.stats,
        deathrollStatsAdded = altStats.deathrollStats,
        timestamp = time()
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("Joined alt '%s' to main '%s'", altname, mainname))
end


function CrossGambling:unjoinStats(info, altname)
    if not altname or altname == "" then
        for alt, main in pairs(self.db.global.joinstats or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Currently joined: alt '%s' -> main '%s'", alt, main))
        end
        return
    end

    local mainname = self.db.global.joinstats[altname]
    if not mainname then
        DEFAULT_CHAT_FRAME:AddMessage("Alt is not joined to any main.")
        return
    end

    local altStats = self.db.global.altStats and self.db.global.altStats[altname]
    if not altStats then
        DEFAULT_CHAT_FRAME:AddMessage("No saved stats found for alt.")
        return
    end

    self.db.global.stats[mainname] = (self.db.global.stats[mainname] or 0) - altStats.stats
    self.db.global.deathrollStats[mainname] = (self.db.global.deathrollStats[mainname] or 0) - altStats.deathrollStats

    self.db.global.stats[altname] = altStats.stats
    self.db.global.deathrollStats[altname] = altStats.deathrollStats

    self.db.global.joinstats[altname] = nil
    self.db.global.altStats[altname] = nil

    self.db.global.mergeAudit = self.db.global.mergeAudit or {}
    self.db.global.mergeAudit[altname .. "_unmerged_" .. time()] = {
        action = "unmerge",
        mainname = mainname,
        statsRemoved = altStats.stats,
        deathrollStatsRemoved = altStats.deathrollStats,
        timestamp = time()
    }

	self.db.global.auditLog = self.db.global.auditLog or {}
    table.insert(self.db.global.auditLog, {
        action = "unjoinStats",
        mainname = mainname,
        altname = altname,
        pointsRemoved = altStats.stats,
        deathrollStatsRemoved = altStats.deathrollStats,
        timestamp = time()
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s' from main '%s'", altname, mainname))
end

function CrossGambling:auditMerges()
    if not self.db.global.auditLog or #self.db.global.auditLog == 0 then
        self:Print("No audit log entries found.")
        return
    end

    self:Print("-- Audit Log --")
    for i, entry in ipairs(self.db.global.auditLog) do
        if entry.action == "updateStat" then
            self:Print(string.format(
                "%d. [%s] Updated stats for %s: old=%d, added=%d, new=%d",
                i, entry.timestamp, entry.player, entry.oldAmount, entry.addedAmount, entry.newAmount
            ))
        elseif entry.action == "joinStats" then
            self:Print(string.format(
                "%d. [%s] Joined alt '%s' to main '%s' with %d stats and %d deathroll stats",
                i, entry.timestamp, entry.altname, entry.mainname, entry.statsAdded or 0, entry.deathrollStatsAdded or 0
            ))
        elseif entry.action == "unjoinStats" then
            self:Print(string.format(
                "%d. [%s] Unjoined alt '%s' from main '%s', points subtracted: %d, deathroll: %d",
                i, entry.timestamp, entry.altname, entry.mainname, entry.pointsRemoved or 0, entry.deathrollStatsRemoved or 0
            ))
        end
    end
end

function CrossGambling:reportStats(full)
    SendChatMessage("-- CrossGambling All Time Stats --", self.game.chatMethod)
    SendChatMessage(string.format("The house has taken %s total.", (self.db.global.housestats or 0)), self.game.chatMethod)

    local combinedStats, houseStats = {}, {}

    for playerName, amount in pairs(self.db.global.stats or {}) do
        local mainName = self:getMainName(playerName)

        if playerName == mainName then
            local totalAmount, aliases = amount, {}

            for altname, main in pairs(self.db.global.joinstats or {}) do
                if main == mainName then
                    table.insert(aliases, altname)
                end
            end

            for _, alias in ipairs(aliases) do
                if self.db.global.stats[alias] then
                    totalAmount = totalAmount + self.db.global.stats[alias]
                    self.db.global.stats[alias] = nil
                end
                if self.db.global.deathrollStats[alias] then
                    totalAmount = totalAmount + self.db.global.deathrollStats[alias]
                    self.db.global.deathrollStats[alias] = nil
                end
            end

            combinedStats[mainName] = (combinedStats[mainName] or 0) + totalAmount

            if self.db.global.houseStats and self.db.global.houseStats[mainName] then
                houseStats[mainName] = (houseStats[mainName] or 0) + self.db.global.houseStats[mainName]
            end
        else
            self.db.global.stats[playerName] = nil
        end
    end

    if next(combinedStats) == nil then
        SendChatMessage("No stats to report.", self.game.chatMethod)
        return
    end

    local sortedStats = {}
    for mainName, totalAmount in pairs(combinedStats) do
        table.insert(sortedStats, {name = mainName, amount = totalAmount})
    end
    table.sort(sortedStats, function(a, b) return a.amount > b.amount end)

    local winners, losers = {}, {}
    for _, stat in ipairs(sortedStats) do
        if stat.amount > 0 then table.insert(winners, stat) else table.insert(losers, stat) end
    end

    if full then
        for k, v in ipairs(sortedStats) do
            local sortsign = v.amount < 0 and "lost" or "won"
            local houseDebt = houseStats[v.name] or 0
            local statMessage = string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount))
            if houseDebt > 0 then
                statMessage = statMessage .. string.format(" and owes the house %d.", houseDebt)
            end
            SendChatMessage(statMessage, self.game.chatMethod)
        end
        return
    end

    SendChatMessage("-- Top 3 Winners --", self.game.chatMethod)
		for i = 1, math.min(3, #winners) do
			SendChatMessage(string.format("%d. %s won %d total", i, winners[i].name, math.abs(winners[i].amount)), self.game.chatMethod)
		end

		table.sort(losers, function(a, b)
			return a.amount < b.amount
		end)

		SendChatMessage("-- Top 3 Losers --", self.game.chatMethod)
		for i = 1, math.min(3, #losers) do
			SendChatMessage(string.format("%d. %s lost %d total", i, losers[i].name, math.abs(losers[i].amount)), self.game.chatMethod)
		end

end

function CrossGambling:getMainName(playerName)
    return (self.db.global.joinstats[strlower(playerName)] or playerName):gsub("^%l", string.upper)
end

function CrossGambling:reportSessionStats()
    SendChatMessage("-- Current Session Stats --", self.game.chatMethod)

    local sessionSortlist = self:sortStats(self.game.sessionStats or {})
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
    for name, amount in pairs(stats or {}) do
        table.insert(sortedStats, {name = name, amount = amount})
    end
    table.sort(sortedStats, function(a, b) return a.amount > b.amount end)
    return sortedStats
end

function CrossGambling:updatePlayerStat(playerName, amount, isDeathroll)
    self.game.sessionStats[playerName] = (self.game.sessionStats[playerName] or 0) + amount
    self.db.global.stats[playerName] = (self.db.global.stats[playerName] or 0) + amount
    if isDeathroll then
        self.db.global.deathrollStats[playerName] = (self.db.global.deathrollStats[playerName] or 0) + amount
    end
end

function CrossGambling:reportDeathrollStats()
    SendChatMessage("-- Deathroll Stats --", self.game.chatMethod)
    local deathrollSortlist = self:sortStats(self.db.global.deathrollStats or {})
    if #deathrollSortlist == 0 then
        SendChatMessage("No stats available for Deathrolls.", self.game.chatMethod)
    else
        self:reportSortedStats(deathrollSortlist, "Deathrolls")
    end
end

function CrossGambling:listAlts(info)
    for mainname, altname in pairs(self.db.global.joinstats or {}) do
        self:Print("[main] " .. mainname .. " is merged with [alt] " .. altname)
    end
end

function CrossGambling:updateStat(info, args)
    local player, amount = strsplit(" ", args)
    amount = tonumber(amount)

    if player and amount then
        local oldAmount = self.db.global.stats[player] or 0
        self:updatePlayerStat(player, amount)
        local newAmount = self.db.global.stats[player] or 0
		
		self.db.global.auditLog = self.db.global.auditLog or {}
        table.insert(self.db.global.auditLog, {
            action = "updateStat",
            player = player,
            oldAmount = oldAmount,
            addedAmount = amount,
            newAmount = newAmount,
            timestamp = time()
        })

        self:Print(string.format("Successfully updated stats for %s (%d -> %d), added %d", player, oldAmount, newAmount, amount))
    else
        self:Print("Invalid input for updating stats.")
    end
end


function CrossGambling:deleteStat(info, player)
    self.db.global.stats[player] = nil
    self.db.global.deathrollStats[player] = nil
    self:Print("Successfully removed stats for " .. player .. ".")
end

function CrossGambling:resetStats(info)
    self.db.global.stats = {}
    self.db.global.joinstats = {}
    self.db.global.deathrollStats = {}
    self.db.global.altStats = {}
    self.db.global.mergeAudit = {}
    self.game.sessionStats = {}
    self:Print("All stats have been reset.")
end
