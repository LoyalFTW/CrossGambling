local function normalizePlayerName(name)
    if not name then
        return nil
    end

    name = tostring(name)
    name = strtrim(name)
    if name == "" then
        return nil
    end

    return strlower(name)
end

local function getStoredName(statsTable, name)
    local normalized = normalizePlayerName(name)
    if not normalized then
        return nil
    end

    for existingName in pairs(statsTable or {}) do
        if normalizePlayerName(existingName) == normalized then
            return existingName
        end
    end

    return name
end

local function getKnownPlayerName(addon, name)
    return getStoredName(addon.db.global.stats, getStoredName(addon.db.global.deathrollStats, name))
end

local function combineStatsByMain(addon, statsTable)
    local combinedStats = {}

    for playerName, amount in pairs(statsTable or {}) do
        local mainName = addon:getMainName(playerName)
        combinedStats[mainName] = (combinedStats[mainName] or 0) + amount
    end

    return combinedStats
end

function CrossGambling:joinStats(info, args)
    local mainname, altname = string.match(args, "^(%S+)%s+(%S+)$")
    if not mainname or not altname then
        DEFAULT_CHAT_FRAME:AddMessage("Invalid format. Use: <mainname> <altname>")
        return
    end

    self.db.global.altStats = self.db.global.altStats or {}

    local storedMainName = getKnownPlayerName(self, mainname)
    local storedAltName = getKnownPlayerName(self, altname)
    local normalizedMainName = normalizePlayerName(storedMainName)
    local normalizedAltName = normalizePlayerName(storedAltName)

    if normalizedMainName == normalizedAltName then
        DEFAULT_CHAT_FRAME:AddMessage("Main and alt cannot be the same character.")
        return
    end

    local altStats = {
        displayName = storedAltName,
        stats = self.db.global.stats[storedAltName] or 0,
        deathrollStats = self.db.global.deathrollStats[storedAltName] or 0,
    }
    self.db.global.altStats[normalizedAltName] = altStats

    self.db.global.stats[storedMainName] = self.db.global.stats[storedMainName] or 0
    self.db.global.deathrollStats[storedMainName] = self.db.global.deathrollStats[storedMainName] or 0

    self.db.global.stats[storedMainName] = self.db.global.stats[storedMainName] + altStats.stats
    self.db.global.deathrollStats[storedMainName] = self.db.global.deathrollStats[storedMainName] + altStats.deathrollStats

    self.db.global.joinstats = self.db.global.joinstats or {}
    self.db.global.joinstats[normalizedAltName] = storedMainName

    self.db.global.stats[storedAltName] = nil
    self.db.global.deathrollStats[storedAltName] = nil

    self.db.global.mergeAudit = self.db.global.mergeAudit or {}
    self.db.global.mergeAudit[normalizedAltName] = {
        mainname = storedMainName,
        statsAdded = altStats.stats,
        deathrollStatsAdded = altStats.deathrollStats,
        timestamp = time()
    }
	
    self:AddAuditEntry({
        action = "joinStats",
        mainname = storedMainName,
        altname = storedAltName,
        statsAdded = altStats.stats,
        deathrollStatsAdded = altStats.deathrollStats,
        timestamp = time()
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("Joined alt '%s' to main '%s'", storedAltName, storedMainName))
end


function CrossGambling:unjoinStats(info, altname)
    if not altname or altname == "" then
        for alt, main in pairs(self.db.global.joinstats or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Currently joined: alt '%s' -> main '%s'", alt, main))
        end
        return
    end

    local normalizedAltName = normalizePlayerName(altname)
    local mainname = self.db.global.joinstats[normalizedAltName]
    if not mainname then
        DEFAULT_CHAT_FRAME:AddMessage("Alt is not joined to any main.")
        return
    end

    local altStats = self.db.global.altStats and self.db.global.altStats[normalizedAltName]
    if not altStats then
        DEFAULT_CHAT_FRAME:AddMessage("No saved stats found for alt.")
        return
    end

    self.db.global.stats[mainname] = (self.db.global.stats[mainname] or 0) - altStats.stats
    self.db.global.deathrollStats[mainname] = (self.db.global.deathrollStats[mainname] or 0) - altStats.deathrollStats

    local restoredAltName = altStats.displayName or getKnownPlayerName(self, altname)
    self.db.global.stats[restoredAltName] = altStats.stats
    self.db.global.deathrollStats[restoredAltName] = altStats.deathrollStats

    self.db.global.joinstats[normalizedAltName] = nil
    self.db.global.altStats[normalizedAltName] = nil

    self.db.global.mergeAudit = self.db.global.mergeAudit or {}
    self.db.global.mergeAudit[normalizedAltName .. "_unmerged_" .. time()] = {
        action = "unmerge",
        mainname = mainname,
        statsRemoved = altStats.stats,
        deathrollStatsRemoved = altStats.deathrollStats,
        timestamp = time()
    }

    self:AddAuditEntry({
        action = "unjoinStats",
        mainname = mainname,
        altname = restoredAltName,
        pointsRemoved = altStats.stats,
        deathrollStatsRemoved = altStats.deathrollStats,
        timestamp = time()
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s' from main '%s'", restoredAltName, mainname))
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

    local combinedStats = combineStatsByMain(self, self.db.global.stats)

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
            local statMessage = string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount))
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
    local normalizedPlayerName = normalizePlayerName(playerName)
    local mainName = self.db.global.joinstats[normalizedPlayerName] or playerName
    return getKnownPlayerName(self, mainName)
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
    local storedPlayerName = getKnownPlayerName(self, playerName)
    self.game.sessionStats[storedPlayerName] = (self.game.sessionStats[storedPlayerName] or 0) + amount
    self.db.global.stats[storedPlayerName] = (self.db.global.stats[storedPlayerName] or 0) + amount
    if isDeathroll then
        local storedDeathrollName = getKnownPlayerName(self, storedPlayerName)
        self.db.global.deathrollStats[storedDeathrollName] = (self.db.global.deathrollStats[storedDeathrollName] or 0) + amount
    end
end

function CrossGambling:reportDeathrollStats()
    SendChatMessage("-- Deathroll Stats --", self.game.chatMethod)
    local deathrollSortlist = self:sortStats(combineStatsByMain(self, self.db.global.deathrollStats))
    if #deathrollSortlist == 0 then
        SendChatMessage("No stats available for Deathrolls.", self.game.chatMethod)
    else
        self:reportSortedStats(deathrollSortlist, "Deathrolls")
    end
end

function CrossGambling:listAlts(info)
    for altname, mainname in pairs(self.db.global.joinstats or {}) do
        local altStats = self.db.global.altStats and self.db.global.altStats[altname]
        local displayAltName = (altStats and altStats.displayName) or altname
        self:Print("[main] " .. mainname .. " is merged with [alt] " .. displayAltName)
    end
end

function CrossGambling:updateStat(info, args)
    local player, amountStr = strsplit(" ", args)
    local amount = tonumber(amountStr)

    if player and amount then
        local storedPlayerName = getKnownPlayerName(self, player)
        local oldAmount = self.db.global.stats[storedPlayerName] or 0
        self:updatePlayerStat(storedPlayerName, amount)
        local newAmount = self.db.global.stats[storedPlayerName] or 0
		
        self:AddAuditEntry({
            action = "updateStat",
            player = storedPlayerName,
            oldAmount = oldAmount,
            addedAmount = amount,
            newAmount = newAmount,
            timestamp = time()
        })

        self:Print(string.format("Successfully updated stats for %s (%d -> %d), added %d", storedPlayerName, oldAmount, newAmount, amount))
    else
        self:Print("Invalid input for updating stats.")
    end
end


function CrossGambling:deleteStat(info, player)
    local storedStatName = getKnownPlayerName(self, player)
    local storedDeathrollName = getKnownPlayerName(self, player)
    self.db.global.stats[storedStatName] = nil
    self.db.global.deathrollStats[storedDeathrollName] = nil
    self.db.global.joinstats[normalizePlayerName(player)] = nil
    if self.db.global.altStats then
        self.db.global.altStats[normalizePlayerName(player)] = nil
    end
    self:Print("Successfully removed stats for " .. storedStatName .. ".")
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
