local BOT_STEP_DELAY = 0.35
local BOT_MAX_STEPS  = 300

local function botLog(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[CG Bot Test]|r " .. msg)
end

local function classicRange(addon)
    return 1, addon.db.global.wager or 100
end

local function fixedRange()
    return 1, 100
end

function CrossGambling:SimulateRoll(playerName, minRoll, maxRoll)
    local roll = math.random(minRoll, maxRoll)
    botLog(string.format("%s rolls %d (%d-%d)", playerName, roll, minRoll, maxRoll))
    self:DispatchModeHook("OnRollReceived", playerName, roll, minRoll, maxRoll)
    return roll
end

function CrossGambling:StepRoundRobinBots(token, rangeFn)
    if token ~= self.botTestToken then return end
    if self.game.state ~= "ROLL" then
        botLog("Test game finished.")
        return
    end

    self.botTestSteps = (self.botTestSteps or 0) + 1
    if self.botTestSteps > BOT_MAX_STEPS then
        botLog("Stopped - exceeded the safety step limit. Something may be stuck.")
        self:StopBotTest()
        return
    end

    local elim = self.game.elimination
    if elim and elim.finale then
        local nextPlayer = elim.finaleOrder[elim.finaleTurnIndex]
        if nextPlayer then
            self:SimulateRoll(nextPlayer, 1, elim.finaleMax)
        end
    else
        local nextPlayer
        for i = 1, #self.game.players do
            if self.game.players[i].roll == nil then
                nextPlayer = self.game.players[i].name
                break
            end
        end

        if nextPlayer then
            local minRoll, maxRoll = rangeFn(self)
            self:SimulateRoll(nextPlayer, minRoll, maxRoll)
        end
    end

    C_Timer.After(BOT_STEP_DELAY, function()
        self:StepRoundRobinBots(token, rangeFn)
    end)
end

function CrossGambling:StepDeathRollBots(token)
    if token ~= self.botTestToken then return end
    if self.game.state ~= "ROLL" then
        botLog("Test game finished.")
        return
    end

    self.botTestSteps = (self.botTestSteps or 0) + 1
    if self.botTestSteps > BOT_MAX_STEPS then
        botLog("Stopped - exceeded the safety step limit. Something may be stuck.")
        self:StopBotTest()
        return
    end

    local player = self.game.players[self.currentPlayerIndex]
    if player then
        self:SimulateRoll(player.name, 1, self.currentRoll or 100)
    end

    C_Timer.After(BOT_STEP_DELAY, function()
        self:StepDeathRollBots(token)
    end)
end

function CrossGambling:StepOverUnderBots(token)
    if token ~= self.botTestToken then return end

    for i = 1, #self.game.players do
        local name = self.game.players[i].name
        local pick = math.random(2) == 1 and "over" or "under"
        botLog(name .. " picks " .. pick)
        self:DispatchModeHook("OnChatText", name, pick)
    end

    C_Timer.After(BOT_STEP_DELAY, function()
        if token ~= self.botTestToken then return end
        self:SimulateRoll(self.game.hostName, 1, 100)
    end)
end

function CrossGambling:StartBotTest(info, args)
    if not (self.db and self.db.global and self.db.global.testingMode) then
        self:Print("CrossGambling: Testing mode is off. Enable it first with /cg testing on.")
        return
    end

    local botCount = tonumber(args)
    if not botCount or botCount < 1 then
        self:Print("Usage: /cg testbots <numberOfBots> (e.g. /cg testbots 4)")
        return
    end
    botCount = math.floor(botCount)

    if self.game.state ~= "START" then
        self:Print("CrossGambling: Finish or reset the current game (/cg stoptest) before starting a bot test.")
        return
    end

    local mode = self:GetCurrentMode()
    if not mode then
        self:Print("CrossGambling: No mode selected.")
        return
    end

    self:BuildUI()

    if self.wagerInput then
        self:SetWager(self.wagerInput:GetText())
    end

    if mode.name == "1v1DeathRoll" then
        botCount = 2
    else
        if mode.minPlayers and botCount < mode.minPlayers then
            botCount = mode.minPlayers
        end
        if mode.maxPlayers and botCount > mode.maxPlayers then
            botCount = mode.maxPlayers
        end
    end

    self.botTestToken = (self.botTestToken or 0) + 1
    local token = self.botTestToken
    self.botTestSteps = 0

    botLog(string.format("Starting a %d-bot test game in %s mode.", botCount, mode.name))

    self.game.host     = true
    self.game.hostName = self.game.PlayerName
    self.game.state    = "REGISTER"
    self.game.result   = nil
    self.game.players  = {}
    self.game.playerIndexByName = nil

    for i = 1, botCount do
        local botName = "TestBot" .. i
        if type(self.AddPlayer) == "function" then
            self:AddPlayer(botName)
        end
        self:registerPlayer(botName)
    end

    self:CGRolls()

    C_Timer.After(BOT_STEP_DELAY, function()
        if token ~= self.botTestToken then return end

        if mode.name == "1v1DeathRoll" then
            self:StepDeathRollBots(token)
        elseif mode.name == "OverUnder" then
            self:StepOverUnderBots(token)
        elseif mode.name == "Raffle" then
            self:SimulateRoll(self.game.hostName, 1, self.db.global.wager or 1)
        else
            local rangeFn = (mode.name == "Classic" or mode.name == "Elimination") and classicRange or fixedRange
            self:StepRoundRobinBots(token, rangeFn)
        end
    end)
end

function CrossGambling:StopBotTest()
    self.botTestToken = (self.botTestToken or 0) + 1
    if self.game.state ~= "START" then
        self:CloseGame()
    end
    self:Print("CrossGambling: Bot test stopped.")
end
