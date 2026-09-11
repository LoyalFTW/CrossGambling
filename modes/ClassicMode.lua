
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
        addon:Announce(tieType .. " tie breaker! " .. addon:String(names) .. " /roll " .. RollCeiling(addon) .. " now!")
    end

    local function Settle(addon, game)
        local hl = game.highlow

        if not hl.winners[1] or not hl.losers[1] then
            addon:FinishGame({ "CrossGambling: Not enough rolls to settle - the game is closed." })
            return
        end

        local grossAmount = hl.amountOwed
        if addon:BeginDoubleOrNothing(hl.losers[1], hl.winners[1], grossAmount, Mode.name) then
            return
        end

        local amount, houseAmount = grossAmount, 0
        if options.allowHouseCut then
            amount, houseAmount = addon:ApplyHouseCut(amount)
        end

        local line = addon:SettleDebt(hl.losers[1], hl.winners[1], grossAmount, Mode.name, amount)
        if houseAmount > 0 then
            line = line .. " Plus " .. addon:addCommas(houseAmount) .. "g to the guild."
        end
        addon:FinishGame({ line })
    end

    local function Resolve(addon, game)
        local hl = game.highlow
        local lowest, lowValue, highest, highValue = addon:FindRollExtremes(hl.pending)

        if hl.stage == "main" then
            if highValue == lowValue then
                addon:Announce("Everyone rolled " .. highValue .. "! No winners this round.")
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
            addon:FinishGame({ string.format("CrossGambling: %s left. Not enough players remain - the game is closed.", playerName) })
            return
        end

        if not hl.pending then return end

        hl.pending[playerName] = nil
        RemoveFromList(hl.winners or {}, playerName)
        RemoveFromList(hl.losers or {}, playerName)

        if hl.stage ~= "main" and (not hl.winners[1] or not hl.losers[1]) then
            addon:FinishGame({ string.format("CrossGambling: %s left. The tie-break can no longer be settled - the game is closed.", playerName) })
            return
        end

        if next(hl.pending) == nil then
            addon:FinishGame({ string.format("CrossGambling: %s left. Not enough players remain in this round - the game is closed.", playerName) })
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
    "Everyone rolls 1-wager. Highest roll wins the difference from the lowest roll. Ties at the top or bottom are settled with a re-roll between the tied players.",
    { allowHouseCut = true }
))
