local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


local RaffleMode = {}
RaffleMode.name        = "Raffle"
RaffleMode.description = L["RaffleMode_JoinToBuyATicketAtThe"]
RaffleMode.minPlayers  = 2
RaffleMode.hostRolls   = true

function RaffleMode:OnStartRolls(addon, game)
    addon:Announce(string.format(
        L["RaffleMode_RaffleTypesRollToDrawTheWinning"],
        game.hostName or L["RaffleMode_TheHost"], #game.players
    ))
end

function RaffleMode:GetRollRange(addon, game)
    return 1, math.max(1, #game.players)
end

function RaffleMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local wager = addon:GetWager()
    if minRoll ~= 1 or maxRoll ~= #game.players then return end
    if not game.hostName or playerName ~= game.hostName then return end
    if #game.players == 0 then return end

    local winner = game.players[actualRoll]
    addon:RecordRoll(winner.name, "Winner")

    local lines = { string.format(L["RaffleMode_WinningTicketIsTakesThePot"], actualRoll, winner.name) }

    for i = 1, #game.players do
        local p = game.players[i]
        if p.name ~= winner.name then
            table.insert(lines, addon:SettleDebt(p.name, winner.name, wager, RaffleMode.name))
        end
    end

    addon:FinishGame(lines)
end

CrossGambling:RegisterMode(RaffleMode)
