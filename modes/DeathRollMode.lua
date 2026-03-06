local DeathRollMode = {}
DeathRollMode.name  = "1v1DeathRoll"

function DeathRollMode:OnStart(addon, game)
    addon.currentRoll        = addon.db.global.wager
    addon.currentPlayerIndex = 1
end

function DeathRollMode:OnPlayerJoin(addon, game, playerName)
    if #game.players >= 2 then
        addon:SendChat("CrossGambling: This is a 1v1 DeathRoll. Only 2 players can join.")
        return false
    end
    return true
end

function DeathRollMode:OnStartRolls(addon, game)
    addon.currentRoll        = addon.db.global.wager
    addon.currentPlayerIndex = 1
    addon:PromptNextRoll()
end

function DeathRollMode:OnRollReceived(addon, game, playerName, actualRoll, minRoll, maxRoll)
    if minRoll ~= 1 or maxRoll ~= addon.currentRoll then
        addon:SendChat("CrossGambling: Roll does not match the expected range (1-" .. addon.currentRoll .. ").")
        return
    end

    local currentPlayer = game.players[addon.currentPlayerIndex]
    if not currentPlayer then
        addon:SendChat("CrossGambling: Current player is nil.")
        return
    end

    if playerName ~= currentPlayer.name then
        addon:SendChat(format("%s, it's not your turn! It's %s's turn.", playerName, currentPlayer.name))
        return
    end

    CGCall["PLAYER_ROLL"](playerName, actualRoll)

    if actualRoll == 1 then
        local loser  = currentPlayer
        local winner = game.players[3 - addon.currentPlayerIndex]
        addon:SendChat(format(
            "%s rolls a 1 and loses! %s owes %s %s gold.",
            loser.name, loser.name, winner.name,
            addon:addCommas(addon.db.global.wager)
        ))
        addon:updatePlayerStat(loser.name,  -addon.db.global.wager, true)
        addon:updatePlayerStat(winner.name,  addon.db.global.wager, true)
        addon:UnRegisterChatEvents()
        addon:UnregisterEvent("CHAT_MSG_SYSTEM")
        addon.game.state   = "START"
        addon.game.players = {}
        addon.game.result  = nil
    else
        addon.currentRoll        = actualRoll
        addon.currentPlayerIndex = 3 - addon.currentPlayerIndex
        addon:PromptNextRoll()
    end
end

function DeathRollMode:OnClose(addon, game)
    addon.currentRoll        = nil
    addon.currentPlayerIndex = nil
end

CrossGambling:RegisterMode(DeathRollMode)