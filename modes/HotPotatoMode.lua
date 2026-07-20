local HotPotatoMode = {}
HotPotatoMode.name        = "HotPotato"
HotPotatoMode.description = "Everyone rolls 1-100 each round; the lowest roller holds the potato. After 5 rounds, whoever's left holding it pays everyone else the wager."
HotPotatoMode.minPlayers  = 3

local MAX_ROUNDS = 5

function HotPotatoMode:OnStartRolls(addon, game)
    game.hotpotato = { round = 1, holder = nil }
    addon:AnnounceOrPrint(string.format(
        "CrossGambling: Hot Potato! Round 1/%d - everyone rolls 1-100. Lowest roll holds the potato!",
        MAX_ROUNDS
    ))
end

function HotPotatoMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local hp = game.hotpotato
    if not hp then return end
    if minRoll ~= 1 or maxRoll ~= 100 then return end

    local player = addon:getPlayerByName(playerName)
    if not player or player.roll ~= nil then return end

    player.roll = actualRoll
    if CGCall and CGCall["PLAYER_ROLL"] then
        CGCall["PLAYER_ROLL"](playerName, tostring(actualRoll))
    end
    addon:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))

    if #addon:CheckRolls() > 0 then return end

    local lowest, lowVal
    for i = 1, #game.players do
        local p = game.players[i]
        if lowVal == nil or p.roll < lowVal then
            lowVal  = p.roll
            lowest  = p.name
        end
    end

    hp.holder = lowest
    addon:AnnounceOrPrint(string.format(
        "CrossGambling: %s rolled lowest (%d) and holds the potato! Round %d/%d complete.",
        lowest, lowVal, hp.round, MAX_ROUNDS
    ))

    if hp.round >= MAX_ROUNDS then
        local wager = addon.db.global.wager or 0
        local lines = { string.format("CrossGambling: %s is left holding the potato and pays everyone!", hp.holder) }

        for i = 1, #game.players do
            local p = game.players[i]
            if p.name ~= hp.holder then
                addon:updatePlayerStat(p.name, wager, HotPotatoMode.name)
                addon:updatePlayerStat(hp.holder, -wager, HotPotatoMode.name)
                addon:AddAuditEntry({
                    timestamp = time(),
                    action    = "debt",
                    loser     = hp.holder,
                    winner    = p.name,
                    amount    = wager,
                })
                table.insert(lines, string.format("%s owes %s %sg!", hp.holder, p.name, addon:addCommas(wager)))
            end
        end

        addon:AnnounceOrPrint(table.concat(lines, " "))
        addon.game.result = nil
        addon:CloseGame()
        return
    end

    hp.round = hp.round + 1
    for i = 1, #game.players do
        game.players[i].roll = nil
    end
    addon:AnnounceOrPrint(string.format("CrossGambling: Round %d/%d - roll 1-100!", hp.round, MAX_ROUNDS))
end

function HotPotatoMode:OnEnd(addon, game)
    game.hotpotato = nil
end

CrossGambling:RegisterMode(HotPotatoMode)
