
local OverUnderMode = {}
OverUnderMode.name         = "OverUnder"
OverUnderMode.description  = "Based on the real craps \"Over/Under 7\" bet, scaled to 1-100. Everyone types \"over\" or \"under\" to bet on whether the host's roll will land above or below 50 (even-money payout). Roll exactly 50 and every bet loses to the house, same as rolling the pivot number in craps."
OverUnderMode.minPlayers   = 2
OverUnderMode.usesChatPick = true
OverUnderMode.hostRolls    = true

local TARGET   = 50
local ROLL_MAX = 100

function OverUnderMode:OnStartRolls(addon, game)
    game.overunder = { picks = {}, resolved = false }
    addon:Announce(string.format(
        "CrossGambling: Over/Under! Target is %d. Type \"over\" or \"under\" to lock in your pick, then %s rolls 1-%d to decide!",
        TARGET, game.hostName or "the host", ROLL_MAX
    ))
end

function OverUnderMode:GetRollRange(addon, game)
    return 1, ROLL_MAX
end

function OverUnderMode:OnChatText(addon, game, playerName, text)
    local ou = game.overunder
    if not ou or ou.resolved then return end

    if not addon:getPlayerByName(playerName) then return end
    if ou.picks[playerName] then return end

    local pick = addon:TrimInput(text):lower()
    if pick ~= "over" and pick ~= "under" then return end

    ou.picks[playerName] = pick
    addon:RecordRoll(playerName, pick)
    addon:Announce(playerName .. " picks " .. pick .. "!")
end

function OverUnderMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    local ou = game.overunder
    if not ou or ou.resolved then return end
    if minRoll ~= 1 or maxRoll ~= ROLL_MAX then return end
    if not game.hostName or playerName ~= game.hostName then return end

    local missingPicks = {}
    for i = 1, #game.players do
        local entrant = game.players[i]
        if entrant.name ~= game.hostName and not ou.picks[entrant.name] then
            table.insert(missingPicks, entrant.name)
        end
    end
    if #missingPicks > 0 then
        addon:Announce(table.concat(missingPicks, ", ") .. " still needs to pick over or under!")
        return
    end

    ou.resolved = true
    ou.result = actualRoll
    ou.outcomes = {}

    local bank     = game.hostName
    local wager    = addon:GetWager()
    local exactHit = actualRoll == TARGET
    local lines    = { string.format(
        "CrossGambling: Over/Under rolled %d (target %d)!%s",
        actualRoll, TARGET, exactHit and " Exact hit - the house takes every bet!" or ""
    ) }

    for i = 1, #game.players do
        local player = game.players[i]
        local pick   = ou.picks[player.name]

        if pick and player.name ~= bank then
            local won = not exactHit and (
                (pick == "over"  and actualRoll > TARGET) or
                (pick == "under" and actualRoll < TARGET)
            )

            if won then
                ou.outcomes[player.name] = true
                addon:SettleDebt(bank, player.name, wager, OverUnderMode.name)
                table.insert(lines, string.format("%s (%s) wins %sg from the house!", player.name, pick, addon:addCommas(wager)))
            else
                ou.outcomes[player.name] = false
                addon:SettleDebt(player.name, bank, wager, OverUnderMode.name)
                table.insert(lines, string.format("%s (%s) pays %sg to the house.", player.name, pick, addon:addCommas(wager)))
            end
        end
    end

    addon:FinishGame(lines)
end

function OverUnderMode:OnEnd(addon, game)
    game.overunder = nil
end

CrossGambling:RegisterMode(OverUnderMode)
