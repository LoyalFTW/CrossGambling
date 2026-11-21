local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


local DeathRollMode = {}
DeathRollMode.name        = "1v1DeathRoll"
DeathRollMode.description = L["DeathRollMode_1v1OnlyStartingAtTheWagerEach"]
DeathRollMode.minPlayers  = 2
DeathRollMode.maxPlayers  = 2

local function PromptNextRoll(addon, game)
    local dr = game.deathroll
    local currentPlayer = game.players[dr.turn]
    if currentPlayer then
        addon:Announce(format(L["Game_ItSYourTurnTypeRoll"], currentPlayer.name, dr.max))
    end
end

function DeathRollMode:OnStartRolls(addon, game)
    game.deathroll = { max = addon:GetWager(), turn = 1 }
    PromptNextRoll(addon, game)
end

function DeathRollMode:GetRollRange(addon, game)
    return 1, (game.deathroll and game.deathroll.max) or addon:GetWager()
end

function DeathRollMode:GetCurrentTurn(addon, game)
    local dr = game.deathroll
    local currentPlayer = dr and game.players[dr.turn]
    return currentPlayer and currentPlayer.name or nil
end

function DeathRollMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local dr = game.deathroll
    if not dr then return end

    local currentPlayer = game.players[dr.turn]
    if not currentPlayer then
        addon:Announce(L["DeathRollMode_CurrentPlayerIsNil"])
        return
    end

    if playerName ~= currentPlayer.name then
        if addon:getPlayerByName(playerName) then
            addon:Announce(format(L["Game_ItSNotYourTurnItS"], playerName, currentPlayer.name))
        end
        return
    end

    if minRoll ~= 1 or maxRoll ~= dr.max then
        addon:Announce(L["Game_RollDoesNotMatchTheExpectedRange"] .. dr.max .. ").")
        return
    end

    addon:RecordRoll(playerName, actualRoll)

    if actualRoll == 1 then
        local loser  = currentPlayer
        local winner = game.players[3 - dr.turn]
        dr.loser = loser.name
        dr.winner = winner.name
        local wager  = addon:GetWager()
        if addon:BeginDoubleOrNothing(loser.name, winner.name, wager, DeathRollMode.name) then
            return
        end
        local line   = addon:SettleDebt(loser.name, winner.name, wager, DeathRollMode.name)
        addon:FinishGame({ format(L["DeathRollMode_RollsA1AndLoses"], loser.name, line) })
    else
        dr.max  = actualRoll
        dr.turn = 3 - dr.turn
        PromptNextRoll(addon, game)
    end
end

function DeathRollMode:OnPlayerLeave(addon, game, playerName)
    if not game.deathroll then return end

    local remaining = game.players[1]
    if remaining then
        addon:FinishGame({ format(L["DeathRollMode_LeftWinsByDefault"], playerName, remaining.name) })
    else
        addon:CloseGame()
    end
end

function DeathRollMode:OnRemoteRoll(addon, game, playerName, value)
    local roll = tonumber(value)
    if not roll then return end

    game.deathroll = game.deathroll or { max = addon:GetWager(), turn = 1 }
    if roll > 1 then
        game.deathroll.max = roll
    end
end

function DeathRollMode:OnEnd(addon, game)
    game.deathroll = nil
end

CrossGambling:RegisterMode(DeathRollMode)
