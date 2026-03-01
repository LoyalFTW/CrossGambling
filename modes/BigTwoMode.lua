local BigTwoMode = {}
BigTwoMode.name  = "BigTwo"

function BigTwoMode:OnStartRolls(addon, game)
    addon.db.global.wager = 2
end

function BigTwoMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    if minRoll ~= 1 or maxRoll ~= addon.db.global.wager then return end

    for i = 1, #game.players do
        local player = game.players[i]
        if player.name == playerName and player.roll == nil then
            player.roll = actualRoll
            addon:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))
        end
    end

    if #addon:CheckRolls() == 0 then
        addon:CGResults()
    end
end

CrossGambling:RegisterMode(BigTwoMode)
