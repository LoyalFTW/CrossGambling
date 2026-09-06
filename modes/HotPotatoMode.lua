
local HotPotatoMode = {}
HotPotatoMode.name        = "HotPotato"
HotPotatoMode.description = "Everyone rolls 1-100 each round; the lowest roller catches the potato. Its hidden fuse explodes after a random round from 1 to 4, and whoever is holding it pays everyone else the wager."
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
    local wager = addon:GetWager()
    local lines = { string.format("CrossGambling: %s rolled lowest (%d)... BOOM! The potato explodes! They pay everyone!", hp.holder, lowVal) }

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
        addon:FinishGame({ "CrossGambling: Not enough rolls to settle - the game is closed." })
        return
    end

    if #lowest > 1 then
        addon:Announce(string.format(
            "CrossGambling: Tie at %d between %s! Re-roll 1-%d to see who takes the potato.",
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
        "CrossGambling: %s rolled lowest (%d) and catches the potato... the fuse is still burning!",
        hp.holder, lowVal
    ))

    hp.round   = hp.round + 1
    hp.pending = everyoneSet(game)
    addon:ClearRolls()
    addon:Announce(string.format("CrossGambling: Pass it fast! Round %d - everyone roll 1-%d!", hp.round, ROLL_MAX))
end

function HotPotatoMode:OnStartRolls(addon, game)
    game.hotpotato = {
        round = 1,
        explosionRound = math.random(MIN_EXPLOSION_ROUND, MAX_EXPLOSION_ROUND),
        holder = nil,
        pending = everyoneSet(game),
    }
    addon:Announce(string.format(
        "CrossGambling: HOT POTATO! The hidden fuse will blow sometime in rounds 1-4. Everyone roll 1-%d - lowest catches it!",
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
        addon:FinishGame({ string.format("CrossGambling: %s left. Not enough players remain - the game is closed.", playerName) })
        return
    end

    if not hp.pending then return end

    hp.pending[playerName] = nil

    if next(hp.pending) == nil then
        addon:FinishGame({ string.format("CrossGambling: %s left. Not enough players remain in this round - the game is closed.", playerName) })
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
