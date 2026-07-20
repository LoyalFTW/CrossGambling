local RaffleMode = {}
RaffleMode.name        = "Raffle"
RaffleMode.description = "Join to buy a ticket at the wager price - the host can buy one too. Once entries close, the host rolls 1-to-the-wager and that number picks one random ticket-holder as the winner. Every other entrant then pays the winner one wager's worth of gold."
RaffleMode.minPlayers  = 2

function RaffleMode:OnStartRolls(addon, game)
    local wager = addon.db.global.wager or 1
    addon:AnnounceOrPrint(string.format(
        "CrossGambling: Raffle! %s rolls 1-%d to draw the winning ticket!",
        game.hostName or "The host", wager
    ))
end

function RaffleMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local wager = addon.db.global.wager or 1
    if minRoll ~= 1 or maxRoll ~= wager then return end
    if not game.hostName or playerName ~= game.hostName then return end
    if #game.players == 0 then return end

    local winnerIndex = ((actualRoll - 1) % #game.players) + 1
    local winner       = game.players[winnerIndex]

    local lines = { string.format("CrossGambling: Winning ticket is %d! %s takes the pot!", actualRoll, winner.name) }

    for i = 1, #game.players do
        local p = game.players[i]
        if p.name ~= winner.name then
            addon:updatePlayerStat(winner.name, wager, RaffleMode.name)
            addon:updatePlayerStat(p.name, -wager, RaffleMode.name)
            addon:AddAuditEntry({
                timestamp = time(),
                action    = "debt",
                loser     = p.name,
                winner    = winner.name,
                amount    = wager,
            })
            table.insert(lines, string.format("%s owes %s %sg!", p.name, winner.name, addon:addCommas(wager)))
        end
    end

    addon:AnnounceOrPrint(table.concat(lines, " "))
    addon.game.result = nil
    addon:CloseGame()
end

CrossGambling:RegisterMode(RaffleMode)
