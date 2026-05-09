local BigTwoMode = {}
BigTwoMode.name  = "BigTwo"

function BigTwoMode:OnStartRolls(addon, game)
    addon.db.global.wager = 2
end

function BigTwoMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    if minRoll ~= 1 or maxRoll ~= addon.db.global.wager then return end

    local player = addon:getPlayerByName(playerName)
    if player and player.roll == nil then
        player.roll = actualRoll
        if CGCall and CGCall["PLAYER_ROLL"] then
            CGCall["PLAYER_ROLL"](playerName, tostring(actualRoll))
        end
        addon:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))
    end

    if #addon:CheckRolls() == 0 then
        addon:CGResults()
    end
end

CrossGambling:RegisterMode(BigTwoMode)
