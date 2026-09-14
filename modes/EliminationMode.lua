
local EliminationMode = {}
EliminationMode.name        = "Elimination"
EliminationMode.description = "Everyone rolls 1-wager each round; the lowest roller is eliminated. Once it's down to the final two, it switches to DeathRoll rules (shrinking range, roll a 1 and you lose) to decide the winner."
EliminationMode.minPlayers  = 3

local LOSER_MARK = "Loser"

local function finishElimination(addon, game, winnerName)
    local elim  = game.elimination
    elim.winner = winnerName
    local wager = addon:GetWager()
    local lines = { string.format("CrossGambling: %s wins the Elimination pot!", winnerName) }

    for _, entry in ipairs(elim.eliminationOrder) do
        table.insert(lines, addon:SettleDebt(entry.name, winnerName, wager, EliminationMode.name))
    end

    addon:FinishGame(lines)
end

local function startFinale(addon, game)
    local elim  = game.elimination
    local wager = addon:GetWager()

    local finalists = {}
    for i = 1, #game.players do
        local name = game.players[i].name
        if elim.alive[name] then
            table.insert(finalists, name)
        end
    end

    elim.finale          = true
    elim.finaleOrder     = finalists
    elim.finaleMax       = wager
    elim.finaleTurnIndex = 1
    elim.pending         = nil
    addon:ClearRolls(elim.alive)

    addon:Announce(string.format(
        "CrossGambling: Final 1v1! %s vs %s - DeathRoll rules now! %s types /roll %d first!",
        finalists[1], finalists[2], finalists[1], wager
    ))
end

local function startRound(addon, game)
    local elim  = game.elimination
    local wager = addon:GetWager()

    elim.round   = elim.round + 1
    elim.pending = {}
    for name in pairs(elim.alive) do
        elim.pending[name] = true
    end
    addon:ClearRolls(elim.pending)

    addon:Announce(string.format(
        "CrossGambling: Round %d - %d players remain, type /roll %d!",
        elim.round, addon:CountKeys(elim.alive), wager
    ))
end

local function resolveEliminationStep(addon, game)
    local elim = game.elimination
    local lowest, lowestVal = addon:FindRollExtremes(elim.pending)
    table.sort(lowest)

    if #lowest > 1 then
        addon:Announce(string.format(
            "CrossGambling: Tie at %d between %s! Type /roll %d to see who's out.",
            lowestVal, table.concat(lowest, ", "), addon:GetWager()
        ))

        elim.pending = {}
        for _, name in ipairs(lowest) do
            elim.pending[name] = true
        end
        addon:ClearRolls(elim.pending)
        return
    end

    local loser = lowest[1]
    if not loser then return end

    elim.alive[loser] = nil
    table.insert(elim.eliminationOrder, { name = loser, round = elim.round })
    addon:RecordRoll(loser, LOSER_MARK)

    addon:Announce(string.format("CrossGambling: %s rolled lowest (%d) and is out!", loser, lowestVal))

    if addon:CountKeys(elim.alive) == 2 then
        startFinale(addon, game)
    else
        startRound(addon, game)
    end
end

function EliminationMode:OnStartRolls(addon, game)
    local wager = addon:GetWager()
    game.elimination = { alive = {}, pending = {}, eliminationOrder = {}, round = 1 }

    for i = 1, #game.players do
        local name = game.players[i].name
        game.elimination.alive[name]   = true
        game.elimination.pending[name] = true
    end

    addon:Announce(string.format(
        "CrossGambling: Elimination! Everyone types /roll %d each round - lowest roll is out. The last two settle it with DeathRoll rules!",
        wager
    ))
end

function EliminationMode:GetRollRange(addon, game)
    local elim = game.elimination
    if elim and elim.finale then
        return 1, elim.finaleMax
    end
    return 1, addon:GetWager()
end

function EliminationMode:GetCurrentTurn(addon, game)
    local elim = game.elimination
    if elim and elim.finale then
        return elim.finaleOrder[elim.finaleTurnIndex]
    end
    return nil
end

function EliminationMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local elim = game.elimination
    if not elim then return end

    if elim.finale then
        local expected = elim.finaleOrder[elim.finaleTurnIndex]
        if playerName ~= expected then return end
        if minRoll ~= 1 or maxRoll ~= elim.finaleMax then return end

        addon:RecordRoll(playerName, actualRoll)

        if actualRoll == 1 then
            local winnerName = elim.finaleOrder[3 - elim.finaleTurnIndex]
            table.insert(elim.eliminationOrder, { name = playerName, round = elim.round + 1 })
            addon:Announce(string.format("CrossGambling: %s rolls a 1 and is eliminated!", playerName))
            finishElimination(addon, game, winnerName)
        else
            elim.finaleMax = actualRoll
            elim.finaleTurnIndex = 3 - elim.finaleTurnIndex
            addon:Announce(string.format(
                "CrossGambling: %s, it's your turn! Roll 1-%d",
                elim.finaleOrder[elim.finaleTurnIndex], elim.finaleMax
            ))
        end
        return
    end

    if not elim.alive[playerName] or not elim.pending[playerName] then return end
    if minRoll ~= 1 or maxRoll ~= addon:GetWager() then return end

    local player = addon:getPlayerByName(playerName)
    if not player or player.roll ~= nil then return end

    addon:RecordRoll(playerName, actualRoll)

    if not addon:hasPendingRolls(elim.pending) then
        resolveEliminationStep(addon, game)
    end
end

function EliminationMode:OnPlayerLeave(addon, game, playerName)
    local elim = game.elimination
    if not elim or not elim.alive[playerName] then return end

    local wasPending = elim.pending ~= nil and elim.pending[playerName] or false
    elim.alive[playerName] = nil
    if elim.pending then
        elim.pending[playerName] = nil
    end

    local aliveCount = addon:CountKeys(elim.alive)

    if aliveCount <= 1 then
        local winner = next(elim.alive)
        if winner then
            finishElimination(addon, game, winner)
        end
        return
    end

    if elim.finale then
        return
    end

    if aliveCount == 2 then
        startFinale(addon, game)
        return
    end

    if wasPending and not addon:hasPendingRolls(elim.pending) then
        resolveEliminationStep(addon, game)
    end
end

function EliminationMode:OnEnd(addon, game)
    game.elimination = nil
end

CrossGambling:RegisterMode(EliminationMode)
