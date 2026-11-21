local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


local OverUnderMode = {}
OverUnderMode.name         = "OverUnder"
OverUnderMode.description  = L["OverUnderMode_BasedOnTheRealCrapsOverUnder"]
OverUnderMode.minPlayers   = 2
OverUnderMode.usesChatPick = true
OverUnderMode.hostRolls    = true

local TARGET   = 50
local ROLL_MAX = 100

function OverUnderMode:OnStartRolls(addon, game)
    game.overunder = { picks = {}, resolved = false }
    addon:Announce(string.format(
        L["OverUnderMode_OverUnderTargetIsTypeOverOr"],
        TARGET, game.hostName or L["OverUnderMode_TheHost"], ROLL_MAX
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
    addon:Announce(playerName .. L["OverUnderMode_Picks"] .. (pick == "over" and L["OverUnderMode_ChoiceOver"] or L["OverUnderMode_ChoiceUnder"]) .. "!")
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
        addon:Announce(table.concat(missingPicks, ", ") .. L["OverUnderMode_StillNeedsToPickOverOrUnder"])
        return
    end

    ou.resolved = true
    ou.result = actualRoll
    ou.outcomes = {}

    local bank     = game.hostName
    local wager    = addon:GetWager()
    local exactHit = actualRoll == TARGET
    local lines    = { string.format(
        L["OverUnderMode_OverUnderRolledTarget"],
        actualRoll, TARGET, exactHit and L["OverUnderMode_ExactHitTheHouseTakesEveryBet"] or ""
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
                table.insert(lines, string.format(L["OverUnderMode_WinsGFromTheHouse"], player.name, (pick == "over" and L["OverUnderMode_ChoiceOver"] or L["OverUnderMode_ChoiceUnder"]), addon:addCommas(wager)))
            else
                ou.outcomes[player.name] = false
                addon:SettleDebt(player.name, bank, wager, OverUnderMode.name)
                table.insert(lines, string.format(L["OverUnderMode_PaysGToTheHouse"], player.name, (pick == "over" and L["OverUnderMode_ChoiceOver"] or L["OverUnderMode_ChoiceUnder"]), addon:addCommas(wager)))
            end
        end
    end

    addon:FinishGame(lines)
end

function OverUnderMode:OnEnd(addon, game)
    game.overunder = nil
end

CrossGambling:RegisterMode(OverUnderMode)
