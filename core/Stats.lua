function CrossGambling:joinStats(info, args)
    local mainname, altname = string.match(args, "^(%S+)%s+(%S+)$")
    if mainname and altname then
        -- Save alt's stats to a separate table before joining
        self.db.global.altStats = self.db.global.altStats or {}
        self.db.global.altStats[altname] = {
            stats = self.db.global.stats[altname] or 0,
            deathrollStats = self.db.global.deathrollStats[altname] or 0,
        }

        -- Ensure main stats are initialized if nil
        self.db.global.stats[mainname] = self.db.global.stats[mainname] or 0
        self.db.global.deathrollStats[mainname] = self.db.global.deathrollStats[mainname] or 0

        -- Debug: Print current stats before merging
        print("Before merge - Main stats:", self.db.global.stats[mainname], "Alt stats:", self.db.global.stats[altname])
        print("Before merge - Main deathrollStats:", self.db.global.deathrollStats[mainname], "Alt deathrollStats:", self.db.global.deathrollStats[altname])

        -- Merge alt's stats into the main's stats
        self.db.global.stats[mainname] = self.db.global.stats[mainname] + self.db.global.altStats[altname].stats
        self.db.global.deathrollStats[mainname] = self.db.global.deathrollStats[mainname] + self.db.global.altStats[altname].deathrollStats

        -- Debug: Print current stats after merging but before clearing alt stats
        print("After merge - Main stats:", self.db.global.stats[mainname], "Alt stats:", self.db.global.stats[altname])
        print("After merge - Main deathrollStats:", self.db.global.deathrollStats[mainname], "Alt deathrollStats:", self.db.global.deathrollStats[altname])

        -- Move clearing of alt stats to the end, to avoid potential interference
        self.db.global.joinstats[altname] = mainname
        self.db.global.stats[altname] = nil
        self.db.global.deathrollStats[altname] = nil

        DEFAULT_CHAT_FRAME:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname))
    else
        DEFAULT_CHAT_FRAME:AddMessage("Invalid format. Please provide '<mainname> <altname>'")
    end
end



function CrossGambling:unjoinStats(info, altname)
    if altname and altname ~= "" then
        local mainname = self.db.global.joinstats[altname]
        if mainname and self.db.global.altStats and self.db.global.altStats[altname] then
            -- Subtract alt's stats from the main's stats upon unjoining
            self.db.global.stats[mainname] = (self.db.global.stats[mainname] or 0) - (self.db.global.altStats[altname].stats or 0)
            self.db.global.deathrollStats[mainname] = (self.db.global.deathrollStats[mainname] or 0) - (self.db.global.altStats[altname].deathrollStats or 0)

            -- Restore alt's original stats
            self.db.global.stats[altname] = self.db.global.altStats[altname].stats
            self.db.global.deathrollStats[altname] = self.db.global.altStats[altname].deathrollStats

            -- Clear alt stats from temp storage and unjoin
            self.db.global.altStats[altname] = nil
            self.db.global.joinstats[altname] = nil

            DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s'", altname))
        else
            DEFAULT_CHAT_FRAME:AddMessage("Alt is not joined or stats not available.")
        end
    else
        for i, e in pairs(self.db.global.joinstats) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Currently joined: alt '%s' -> main '%s'", i, e))
        end
    end
end


function CrossGambling:reportStats(full)
    -- Post the stats to the chat channel
    SendChatMessage("-- CrossGambling All Time Stats --", self.game.chatMethod)
    SendChatMessage(string.format("The house has taken %s total.", (self.db.global.housestats or 0)), self.game.chatMethod)

    local combinedStats = {}
    local houseStats = {}

    -- Process stats for main players, including their alts
    for playerName, amount in pairs(self.db.global.stats) do
        local mainName = self:getMainName(playerName)
        
        -- Skip non-main players
        if playerName == mainName then
            local totalAmount = amount
            local aliases = {}

            -- Find the aliases (alts) for this main player
            for altname, main in pairs(self.db.global.joinstats) do
                if main == mainName then
                    table.insert(aliases, altname)
                end
            end

            -- Add stats of all aliases to the main player's total
            for _, alias in ipairs(aliases) do
                if self.db.global.stats[alias] then
                    totalAmount = totalAmount + self.db.global.stats[alias]  -- Add the alias stats
                    self.db.global.stats[alias] = nil  -- Remove the alias stats after merging
                end

                -- Only add Deathroll stats from alias once, avoiding double-counting
                if self.db.global.deathrollStats[alias] then
                    totalAmount = totalAmount + self.db.global.deathrollStats[alias]
                    self.db.global.deathrollStats[alias] = nil  -- Remove after merging
                end
            end



            -- Store combined stats for this main player
            combinedStats[mainName] = (combinedStats[mainName] or 0) + totalAmount

            -- Merge house stats for this main player
            if self.db.global.houseStats and self.db.global.houseStats[mainName] then
                houseStats[mainName] = (houseStats[mainName] or 0) + self.db.global.houseStats[mainName]
            end
        else
            -- If it's an alt, skip it since its stats have already been merged
            self.db.global.stats[playerName] = nil
        end
    end

    -- Check if there are any combined stats to report
    if next(combinedStats) == nil then
        SendChatMessage("No stats to report.", self.game.chatMethod)
        return
    end

    -- Now sort the combined stats
    local sortedStats = {}
    for mainName, totalAmount in pairs(combinedStats) do
        table.insert(sortedStats, {name = mainName, amount = totalAmount})
    end
    table.sort(sortedStats, function(a, b) return a.amount > b.amount end)

    -- Separate winners (positive amounts) and losers (negative amounts)
    local winners = {}
    local losers = {}
    for _, stat in ipairs(sortedStats) do
        if stat.amount > 0 then
            table.insert(winners, stat)
        else
            table.insert(losers, stat)
        end
    end

    -- Report full stats if requested
    if full then
        for k, v in ipairs(sortedStats) do
            local sortsign = v.amount < 0 and "lost" or "won"
            local houseDebt = houseStats[v.name] or 0  -- House debt
 
            local statMessage = string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount))
            if houseDebt > 0 then
                statMessage = statMessage .. string.format(" and owes the house %d.", houseDebt)
            end


            SendChatMessage(statMessage, self.game.chatMethod)
        end
        return
    end

    -- Top 3 Winners
    local topWinnersCount = math.min(3, #winners)
    SendChatMessage("-- Top 3 Winners --", self.game.chatMethod)
    for i = 1, topWinnersCount do
        local sortsign = winners[i].amount < 0 and "lost" or "won"
        SendChatMessage(string.format("%d. %s %s %d total", i, winners[i].name, sortsign, math.abs(winners[i].amount)), self.game.chatMethod)
    end

    -- Top 3 Losers
    local topLosersCount = math.min(3, #losers)
    SendChatMessage("-- Top 3 Losers --", self.game.chatMethod)
    for i = 1, topLosersCount do
        local sortsign = losers[i].amount < 0 and "lost" or "won"
        SendChatMessage(string.format("%d. %s %s %d total", i, losers[i].name, sortsign, math.abs(losers[i].amount)), self.game.chatMethod)
    end
end

function CrossGambling:getMainName(playerName)
    return (self.db.global.joinstats[strlower(playerName)] or playerName):gsub("^%l", string.upper)
end

function CrossGambling:reportSessionStats()
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
    -- Update session stats
    self.game.sessionStats[playerName] = (self.game.sessionStats[playerName] or 0) + amount

    -- Update global stats (without including deathrolls)
    self.db.global.stats[playerName] = (self.db.global.stats[playerName] or 0) + amount

    -- Only update deathroll stats if it's a deathroll
    if isDeathroll then
        self.db.global.deathrollStats[playerName] = (self.db.global.deathrollStats[playerName] or 0) + amount
    end
end

function CrossGambling:reportDeathrollStats()
    SendChatMessage("-- Deathroll Stats --", self.game.chatMethod)

    local deathrollSortlist = self:sortStats(self.db.global.deathrollStats)
    
    if #deathrollSortlist == 0 then
        SendChatMessage("No stats available for Deathrolls.", self.game.chatMethod)
    else
        self:reportSortedStats(deathrollSortlist, "Deathrolls")
    end
end

function CrossGambling:listAlts(info)
    for mainname, altname in pairs(self.db.global.joinstats) do
        self:Print("[main] " .. mainname .. " is merged with [alt] " .. altname)
    end
end

function CrossGambling:updateStat(info, args)
    local player, amount = strsplit(" ", args)
    amount = tonumber(amount)

    if player and amount then
        local oldAmount = self.db.global.stats[player] or 0
        self:updatePlayerStat(player, amount)
        self:Print(string.format("Successfully updated stats for %s (%d -> %d)", player, oldAmount, self.db.global.stats[player]))
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
    self.db.global.stats, self.db.global.joinstats, self.game.sessionStats, self.db.global.deathrollStats = {}, {}, {}, {}
    self:Print(string.format("All stats have been reset.", self.game.chatMethod))
end

