local resolveCardName

local function findStoredValue(addon, source, playerName)
    local target = addon:NormalizePlayerName(playerName, true)
    if not target then return 0 end
    local total = 0
    for name, value in pairs(source or {}) do
        local resolved = resolveCardName(addon, name)
        if addon:NormalizePlayerName(resolved, true) == target then
            total = total + (tonumber(value) or 0)
        end
    end
    return total
end

resolveCardName = function(addon, playerName)
    local resolved = addon:getMainName(playerName)
    return resolved or playerName
end

local function ensureRecord(global, playerName)
    global.playerCardStats = global.playerCardStats or {}
    local record = global.playerCardStats[playerName]
    if not record then
        record = {
            games = 0,
            wins = 0,
            losses = 0,
            pushes = 0,
            streak = 0,
            bestWinStreak = 0,
            bestLossStreak = 0,
            modes = {},
        }
        global.playerCardStats[playerName] = record
    end
    record.modes = record.modes or {}
    return record
end

local function applyOutcome(record, amount)
    record.games = (record.games or 0) + 1
    if amount > 0 then
        record.wins = (record.wins or 0) + 1
        record.streak = math.max(0, record.streak or 0) + 1
        record.bestWinStreak = math.max(record.bestWinStreak or 0, record.streak)
    elseif amount < 0 then
        record.losses = (record.losses or 0) + 1
        record.streak = math.min(0, record.streak or 0) - 1
        record.bestLossStreak = math.max(record.bestLossStreak or 0, math.abs(record.streak))
    else
        record.pushes = (record.pushes or 0) + 1
    end
end

local function combinedRecord(addon, global, playerName)
    local combined = {
        games = 0,
        wins = 0,
        losses = 0,
        pushes = 0,
        streak = 0,
        bestWinStreak = 0,
        bestLossStreak = 0,
        modes = {},
    }
    local target = addon:NormalizePlayerName(playerName, true)
    local latest = 0
    for name, record in pairs(global.playerCardStats or {}) do
        local resolved = resolveCardName(addon, name)
        if addon:NormalizePlayerName(resolved, true) == target then
            combined.games = combined.games + (record.games or 0)
            combined.wins = combined.wins + (record.wins or 0)
            combined.losses = combined.losses + (record.losses or 0)
            combined.pushes = combined.pushes + (record.pushes or 0)
            combined.bestWinStreak = math.max(combined.bestWinStreak, record.bestWinStreak or 0)
            combined.bestLossStreak = math.max(combined.bestLossStreak, record.bestLossStreak or 0)
            if (record.lastPlayed or 0) >= latest then
                latest = record.lastPlayed or 0
                combined.lastPlayed = record.lastPlayed
                combined.streak = record.streak or 0
            end
            for modeName, mode in pairs(record.modes or {}) do
                local aggregate = combined.modes[modeName]
                if not aggregate then
                    aggregate = { games = 0, wins = 0, losses = 0, pushes = 0 }
                    combined.modes[modeName] = aggregate
                end
                aggregate.games = aggregate.games + (mode.games or 0)
                aggregate.wins = aggregate.wins + (mode.wins or 0)
                aggregate.losses = aggregate.losses + (mode.losses or 0)
                aggregate.pushes = aggregate.pushes + (mode.pushes or 0)
            end
        end
    end
    return combined
end

function CrossGambling:TrackPlayerCardDebt(loserName, winnerName, amount, winnerAmount)
    local game = self.game
    if not game then return end
    game.playerCardOutcome = game.playerCardOutcome or {}
    amount = tonumber(amount) or 0
    winnerAmount = tonumber(winnerAmount) or amount
    game.playerCardOutcome[loserName] = (game.playerCardOutcome[loserName] or 0) - amount
    game.playerCardOutcome[winnerName] = (game.playerCardOutcome[winnerName] or 0) + winnerAmount
end

function CrossGambling:CommitPlayerCardGame()
    local game = self.game
    local global = self.db and self.db.global
    if not game or not global or game.playerCardCommitted then return end
    game.playerCardCommitted = true

    local participants = {}
    for _, player in ipairs(game.players or {}) do
        local name = resolveCardName(self, player.name)
        participants[name] = participants[name] or 0
    end
    for name, amount in pairs(game.playerCardOutcome or {}) do
        local resolved = resolveCardName(self, name)
        participants[resolved] = (participants[resolved] or 0) + amount
    end

    local modeName = game.mode or "Unknown"
    local playedAt = time()
    for name, amount in pairs(participants) do
        local record = ensureRecord(global, name)
        applyOutcome(record, amount)
        record.lastPlayed = playedAt
        local modeRecord = record.modes[modeName]
        if not modeRecord then
            modeRecord = { games = 0, wins = 0, losses = 0, pushes = 0 }
            record.modes[modeName] = modeRecord
        end
        applyOutcome(modeRecord, amount)
    end

    if CrossGamblingPlayerCard and CrossGamblingPlayerCard.Refresh then
        CrossGamblingPlayerCard:Refresh()
    end
end

function CrossGambling:GetPlayerCardData(playerName)
    local global = self.db and self.db.global or {}
    local displayName = resolveCardName(self, playerName)
    local record = combinedRecord(self, global, displayName)
    local modes = {}

    for _, modeName in ipairs(self.modeListOrder or {}) do
        local modeRecord = record.modes and record.modes[modeName] or {}
        local amount = findStoredValue(self, global.modeStats and global.modeStats[modeName], displayName)
        table.insert(modes, {
            name = modeName,
            amount = amount,
            games = modeRecord.games or 0,
            wins = modeRecord.wins or 0,
            losses = modeRecord.losses or 0,
            pushes = modeRecord.pushes or 0,
        })
    end

    return {
        requestedName = playerName,
        name = displayName,
        session = findStoredValue(self, self.game and self.game.sessionStats, displayName),
        lifetime = findStoredValue(self, global.stats, displayName),
        games = record.games or 0,
        wins = record.wins or 0,
        losses = record.losses or 0,
        pushes = record.pushes or 0,
        streak = record.streak or 0,
        bestWinStreak = record.bestWinStreak or 0,
        bestLossStreak = record.bestLossStreak or 0,
        lastPlayed = record.lastPlayed,
        modes = modes,
    }
end
