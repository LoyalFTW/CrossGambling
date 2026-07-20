local EliminationMode = {}
EliminationMode.name        = "Elimination"
EliminationMode.description = "Everyone rolls 1-wager each round; the lowest roller is eliminated. Once it's down to the final two, it switches to DeathRoll rules (shrinking range, roll a 1 and you lose) to decide the winner."
EliminationMode.minPlayers  = 3

local LOSER_MARK = "Loser"

local function finishElimination(addon, game, winnerName)
    local elim  = game.elimination
    local wager = addon.db.global.wager or 0
    local lines = { string.format("CrossGambling: %s wins the Elimination pot!", winnerName or "Nobody") }

    if winnerName then
        for _, entry in ipairs(elim.eliminationOrder) do
            addon:updatePlayerStat(winnerName, wager, EliminationMode.name)
            addon:updatePlayerStat(entry.name, -wager, EliminationMode.name)
            addon:AddAuditEntry({
                timestamp = time(),
                action    = "debt",
                loser     = entry.name,
                winner    = winnerName,
                amount    = wager,
            })
            table.insert(lines, string.format("%s owes %s %sg!", entry.name, winnerName, addon:addCommas(wager)))
        end
    end

    addon:AnnounceOrPrint(table.concat(lines, " "))
    addon.game.result = nil
    addon:CloseGame()
end

local function startFinale(addon, game)
    local elim  = game.elimination
    local wager = addon.db.global.wager or 0

    local finalists = {}
    for i = 1, #game.players do
        local name = game.players[i].name
        if elim.alive[name] then
            table.insert(finalists, name)
        end
    end

    elim.finale          = true
    elim.finaleOrder      = finalists
    elim.finaleMax        = wager
    elim.finaleTurnIndex  = 1
    elim.pending          = nil

    for _, name in ipairs(finalists) do
        local player = addon:getPlayerByName(name)
        if player then player.roll = nil end
    end

    addon:AnnounceOrPrint(string.format(
        "CrossGambling: Final 1v1! %s vs %s - DeathRoll rules now! %s rolls 1-%d first!",
        finalists[1], finalists[2], finalists[1], wager
    ))
end

local function resolveEliminationStep(addon, game)
    local elim  = game.elimination
    local wager = addon.db.global.wager or 0

    local lowestVal
    local tied = {}
    for name in pairs(elim.pending) do
        local player = addon:getPlayerByName(name)
        if player and player.roll then
            if lowestVal == nil or player.roll < lowestVal then
                lowestVal = player.roll
                tied = { name }
            elseif player.roll == lowestVal then
                table.insert(tied, name)
            end
        end
    end
    table.sort(tied)

    if #tied > 1 then
        addon:AnnounceOrPrint(string.format(
            "CrossGambling: Tie at %d between %s! Re-roll to see who's out.",
            lowestVal, table.concat(tied, ", ")
        ))

        elim.pending = {}
        for _, name in ipairs(tied) do
            elim.pending[name] = true
            local player = addon:getPlayerByName(name)
            if player then player.roll = nil end
        end
        return
    end

    local loser = tied[1]
    if not loser then return end

    elim.alive[loser] = nil
    table.insert(elim.eliminationOrder, { name = loser, round = elim.round })

    local loserPlayer = addon:getPlayerByName(loser)
    if loserPlayer then loserPlayer.roll = LOSER_MARK end
    if CGCall and CGCall["PLAYER_ROLL"] then
        CGCall["PLAYER_ROLL"](loser, LOSER_MARK)
    end
    addon:SendMsg("PLAYER_ROLL", loser .. ":" .. LOSER_MARK)

    addon:AnnounceOrPrint(string.format("CrossGambling: %s rolled lowest (%d) and is out!", loser, lowestVal))

    local aliveCount = 0
    for _ in pairs(elim.alive) do
        aliveCount = aliveCount + 1
    end

    if aliveCount == 2 then
        startFinale(addon, game)
        return
    end

    elim.round = elim.round + 1
    elim.pending = {}
    for name in pairs(elim.alive) do
        elim.pending[name] = true
        local player = addon:getPlayerByName(name)
        if player then player.roll = nil end
    end

    addon:AnnounceOrPrint(string.format(
        "CrossGambling: Round %d - %d players remain, roll 1-%d!",
        elim.round, aliveCount, wager
    ))
end

function EliminationMode:OnStartRolls(addon, game)
    local wager = addon.db.global.wager or 0
    game.elimination = { alive = {}, pending = {}, eliminationOrder = {}, round = 1 }

    for i = 1, #game.players do
        local name = game.players[i].name
        game.elimination.alive[name]   = true
        game.elimination.pending[name] = true
    end

    addon:AnnounceOrPrint(string.format(
        "CrossGambling: Elimination! Everyone rolls 1-%d each round - lowest roll is out. The last two settle it with DeathRoll rules!",
        wager
    ))
end

function EliminationMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local elim = game.elimination
    if not elim then return end

    if elim.finale then
        local expected = elim.finaleOrder[elim.finaleTurnIndex]
        if playerName ~= expected then return end
        if minRoll ~= 1 or maxRoll ~= elim.finaleMax then return end

        if CGCall and CGCall["PLAYER_ROLL"] then
            CGCall["PLAYER_ROLL"](playerName, tostring(actualRoll))
        end
        addon:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))

        if actualRoll == 1 then
            local winnerName = elim.finaleOrder[3 - elim.finaleTurnIndex]
            table.insert(elim.eliminationOrder, { name = playerName, round = elim.round + 1 })
            addon:AnnounceOrPrint(string.format("CrossGambling: %s rolls a 1 and is eliminated!", playerName))
            finishElimination(addon, game, winnerName)
        else
            elim.finaleMax = actualRoll
            elim.finaleTurnIndex = 3 - elim.finaleTurnIndex
            addon:AnnounceOrPrint(string.format(
                "CrossGambling: %s, it's your turn! Roll 1-%d",
                elim.finaleOrder[elim.finaleTurnIndex], elim.finaleMax
            ))
        end
        return
    end

    if not elim.alive[playerName] or not elim.pending[playerName] then return end

    local wager = addon.db.global.wager or 0
    if minRoll ~= 1 or maxRoll ~= wager then return end

    local player = addon:getPlayerByName(playerName)
    if not player or player.roll ~= nil then return end

    player.roll = actualRoll
    if CGCall and CGCall["PLAYER_ROLL"] then
        CGCall["PLAYER_ROLL"](playerName, tostring(actualRoll))
    end
    addon:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))

    for name in pairs(elim.pending) do
        local p = addon:getPlayerByName(name)
        if p and p.roll == nil then
            return
        end
    end

    resolveEliminationStep(addon, game)
end

function EliminationMode:OnEnd(addon, game)
    game.elimination = nil
end

CrossGambling:RegisterMode(EliminationMode)
