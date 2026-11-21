local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


local HotPotatoMode = {}
HotPotatoMode.name        = "HotPotato"
HotPotatoMode.description = L["HotPotatoMode_EveryoneRolls1100EachRoundThe"]
HotPotatoMode.minPlayers  = 3

local MIN_EXPLOSION_ROUND = 1
local MAX_EXPLOSION_ROUND = 4
local ROLL_MAX            = 100

local function everyoneSet(game)
    local set = {}
    for i = 1, #game.players do
        set[game.players[i].name] = true
    end
    return set
end

local function payOut(addon, game, lowVal)
    local hp    = game.hotpotato
    hp.exploded = true
    local wager = addon:GetWager()
    local lines = { string.format(L["HotPotatoMode_RolledLowestBOOMThePotatoExplodesThey"], hp.holder, lowVal) }

    for i = 1, #game.players do
        local p = game.players[i]
        if p.name ~= hp.holder then
            table.insert(lines, addon:SettleDebt(hp.holder, p.name, wager, HotPotatoMode.name))
        end
    end

    addon:FinishGame(lines)
end

local function resolveRound(addon, game)
    local hp = game.hotpotato
    local lowest, lowVal = addon:FindRollExtremes(hp.pending)
    table.sort(lowest)

    if #lowest == 0 then
        addon:FinishGame({ L["ClassicMode_NotEnoughRollsToSettleTheGame"] })
        return
    end

    if #lowest > 1 then
        addon:Announce(string.format(
            L["HotPotatoMode_TieAtBetweenTypeRollToSee"],
            lowVal, table.concat(lowest, ", "), ROLL_MAX
        ))
        hp.pending = {}
        for _, name in ipairs(lowest) do
            hp.pending[name] = true
        end
        addon:ClearRolls(hp.pending)
        return
    end

    hp.holder = lowest[1]

    if hp.round >= hp.explosionRound then
        payOut(addon, game, lowVal)
        return
    end

    addon:Announce(string.format(
        L["HotPotatoMode_RolledLowestAndCatchesThePotatoThe"],
        hp.holder, lowVal
    ))

    hp.round   = hp.round + 1
    hp.pending = everyoneSet(game)
    addon:ClearRolls()
    addon:Announce(string.format(L["HotPotatoMode_PassItFastRoundEveryoneTypeRoll"], hp.round, ROLL_MAX))
end

function HotPotatoMode:OnStartRolls(addon, game)
    game.hotpotato = {
        round = 1,
        explosionRound = math.random(MIN_EXPLOSION_ROUND, MAX_EXPLOSION_ROUND),
        holder = nil,
        pending = everyoneSet(game),
    }
    addon:Announce(string.format(
        L["HotPotatoMode_HOTPOTATOTheHiddenFuseWillBlow"],
        ROLL_MAX
    ))
end

function HotPotatoMode:GetRollRange(addon, game)
    return 1, ROLL_MAX
end

function HotPotatoMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local hp = game.hotpotato
    if not hp then return end
    if minRoll ~= 1 or maxRoll ~= ROLL_MAX then return end
    if not hp.pending[playerName] then return end

    local player = addon:getPlayerByName(playerName)
    if not player or player.roll ~= nil then return end

    addon:RecordRoll(playerName, actualRoll)

    if not addon:hasPendingRolls(hp.pending) then
        resolveRound(addon, game)
    end
end

function HotPotatoMode:OnPlayerLeave(addon, game, playerName)
    local hp = game.hotpotato
    if not hp then return end

    if #game.players < 2 then
        addon:FinishGame({ string.format(L["ClassicMode_LeftNotEnoughPlayersRemainTheGame"], playerName) })
        return
    end

    if not hp.pending then return end

    hp.pending[playerName] = nil

    if next(hp.pending) == nil then
        addon:FinishGame({ string.format(L["ClassicMode_LeftNotEnoughPlayersRemainInThis"], playerName) })
        return
    end

    if not addon:hasPendingRolls(hp.pending) then
        resolveRound(addon, game)
    end
end

function HotPotatoMode:OnEnd(addon, game)
    game.hotpotato = nil
end

CrossGambling:RegisterMode(HotPotatoMode)
