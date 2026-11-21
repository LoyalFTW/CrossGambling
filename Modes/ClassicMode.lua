local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


local function SetFromList(list)
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

local function RemoveFromList(list, name)
    for i = #list, 1, -1 do
        if list[i] == name then
            table.remove(list, i)
        end
    end
end

function CrossGambling:NewHighLowMode(name, description, options)
    options = options or {}

    local Mode = {}
    Mode.name        = name
    Mode.description = description

    local function RollCeiling(addon)
        return options.fixedMax or addon:GetWager()
    end

    local function StartTieBreaker(addon, game, tieType, names)
        local hl = game.highlow
        hl.stage   = (tieType == "High") and "high" or "low"
        hl.pending = SetFromList(names)
        addon:ClearRolls(hl.pending)
        addon:Announce(string.format(tieType == "High" and L["ClassicMode_HighTie"] or L["ClassicMode_LowTie"], addon:String(names), RollCeiling(addon)))
    end

    local function Settle(addon, game)
        local hl = game.highlow

        if not hl.winners[1] or not hl.losers[1] then
            addon:FinishGame({ L["ClassicMode_NotEnoughRollsToSettleTheGame"] })
            return
        end

        local grossAmount = hl.amountOwed
        if addon:BeginDoubleOrNothing(hl.losers[1], hl.winners[1], grossAmount, Mode.name, options.allowHouseCut) then
            return
        end

        local amount, houseAmount = grossAmount, 0
        if options.allowHouseCut then
            amount, houseAmount = addon:ApplyHouseCut(amount)
        end

        local line = addon:SettleDebt(hl.losers[1], hl.winners[1], grossAmount, Mode.name, amount)
        if houseAmount > 0 then
            line = line .. L["Game_Plus"] .. addon:addCommas(houseAmount) .. L["Game_GToTheGuild"]
        end
        addon:FinishGame({ line })
    end

    local function Resolve(addon, game)
        local hl = game.highlow
        local lowest, lowValue, highest, highValue = addon:FindRollExtremes(hl.pending)

        if hl.stage == "main" then
            if highValue == lowValue then
                addon:Announce(L["ClassicMode_EveryoneRolled"] .. highValue .. L["ClassicMode_NoWinnersThisRound"])
                addon:CloseGame()
                return
            end
            hl.winners    = highest
            hl.losers     = lowest
            hl.amountOwed = options.stakeIsWager and addon:GetWager() or (highValue - lowValue)
        elseif hl.stage == "high" then
            hl.winners = highest
        else
            hl.losers = lowest
        end

        if #hl.winners > 1 then
            StartTieBreaker(addon, game, "High", hl.winners)
        elseif #hl.losers > 1 then
            StartTieBreaker(addon, game, "Low", hl.losers)
        else
            Settle(addon, game)
        end
    end

    function Mode:OnStartRolls(addon, game)
        local pending = {}
        for i = 1, #game.players do
            pending[game.players[i].name] = true
        end
        game.highlow = { stage = "main", pending = pending }
        addon:Announce(string.format(L["ClassicMode_EntriesHaveClosedTypeRollNow"], RollCeiling(addon)))
    end

    function Mode:GetRollRange(addon, game)
        return 1, RollCeiling(addon)
    end

    function Mode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
        local hl = game.highlow
        if not hl then return end
        if minRoll ~= 1 or maxRoll ~= RollCeiling(addon) then return end
        if not hl.pending[playerName] then return end

        local player = addon:getPlayerByName(playerName)
        if not player or player.roll ~= nil then return end

        addon:RecordRoll(playerName, actualRoll)

        if not addon:hasPendingRolls(hl.pending) then
            Resolve(addon, game)
        end
    end

    function Mode:OnPlayerLeave(addon, game, playerName)
        local hl = game.highlow
        if not hl then return end

        if #game.players < 2 then
            addon:FinishGame({ string.format(L["ClassicMode_LeftNotEnoughPlayersRemainTheGame"], playerName) })
            return
        end

        if not hl.pending then return end

        hl.pending[playerName] = nil
        RemoveFromList(hl.winners or {}, playerName)
        RemoveFromList(hl.losers or {}, playerName)

        if hl.stage ~= "main" and (not hl.winners[1] or not hl.losers[1]) then
            addon:FinishGame({ string.format(L["ClassicMode_LeftTheTieBreakCanNoLonger"], playerName) })
            return
        end

        if next(hl.pending) == nil then
            addon:FinishGame({ string.format(L["ClassicMode_LeftNotEnoughPlayersRemainInThis"], playerName) })
            return
        end

        if not addon:hasPendingRolls(hl.pending) then
            Resolve(addon, game)
        end
    end

    function Mode:OnEnd(addon, game)
        game.highlow = nil
    end

    return Mode
end

CrossGambling:RegisterMode(CrossGambling:NewHighLowMode(
    "Classic",
    L["ClassicMode_EveryoneRolls1WagerHighestRollWins"],
    { allowHouseCut = true }
))
