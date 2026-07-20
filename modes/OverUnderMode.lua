local OverUnderMode = {}
OverUnderMode.name        = "OverUnder"
OverUnderMode.description = "Based on the real craps \"Over/Under 7\" bet, scaled to 1-100. Everyone types \"over\" or \"under\" to bet on whether the host's roll will land above or below 50 (even-money payout). Roll exactly 50 and every bet loses to the house, same as rolling the pivot number in craps."
OverUnderMode.minPlayers  = 2
OverUnderMode.usesChatPick = true

local TARGET = 50

function OverUnderMode:OnStartRolls(addon, game)
    game.overunder = { picks = {}, resolved = false }
    addon:AnnounceOrPrint(string.format(
        "CrossGambling: Over/Under! Target is %d. Type \"over\" or \"under\" to lock in your pick, then %s rolls 1-100 to decide!",
        TARGET, game.hostName or "the host"
    ))
end

function OverUnderMode:OnChatText(addon, game, playerName, text)
    local ou = game.overunder
    if not ou or ou.resolved then return end

    if not addon:getPlayerByName(playerName) then return end
    if ou.picks[playerName] then return end

    local pick = strtrim(text):lower()
    if pick ~= "over" and pick ~= "under" then return end

    ou.picks[playerName] = pick
    addon:AnnounceOrPrint(playerName .. " picks " .. pick .. "!")
end

function OverUnderMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local ou = game.overunder
    if not ou or ou.resolved then return end
    if minRoll ~= 1 or maxRoll ~= 100 then return end
    if not game.hostName or playerName ~= game.hostName then return end

    ou.resolved = true

    local bank     = game.hostName
    local wager    = addon.db.global.wager or 0
    local exactHit = actualRoll == TARGET
    local lines    = { string.format(
        "CrossGambling: Over/Under rolled %d (target %d)!%s",
        actualRoll, TARGET, exactHit and " Exact hit - the house takes every bet!" or ""
    ) }

    for i = 1, #game.players do
        local player = game.players[i]
        local pick   = ou.picks[player.name]

        if pick then
            local won = not exactHit and (
                (pick == "over"  and actualRoll > TARGET) or
                (pick == "under" and actualRoll < TARGET)
            )
            local winnerName = won and player.name or bank
            local loserName  = won and bank or player.name

            if winnerName ~= loserName then
                addon:updatePlayerStat(winnerName, wager, OverUnderMode.name)
                addon:updatePlayerStat(loserName, -wager, OverUnderMode.name)
                addon:AddAuditEntry({
                    timestamp = time(),
                    action    = "debt",
                    loser     = loserName,
                    winner    = winnerName,
                    amount    = wager,
                })
            end

            if won then
                table.insert(lines, string.format("%s (%s) wins %sg from the house!", player.name, pick, addon:addCommas(wager)))
            else
                table.insert(lines, string.format("%s (%s) pays %sg to the house.", player.name, pick, addon:addCommas(wager)))
            end
        end
    end

    addon:AnnounceOrPrint(table.concat(lines, " "))

    addon.game.result = nil
    addon:CloseGame()
end

function OverUnderMode:OnEnd(addon, game)
    game.overunder = nil
end

CrossGambling:RegisterMode(OverUnderMode)
