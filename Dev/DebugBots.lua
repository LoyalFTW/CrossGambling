local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


local BOT_STEP_DELAY = 0.35
local BOT_MAX_STEPS  = 300

local function botLog(msg)
    DEFAULT_CHAT_FRAME:AddMessage(L["DebugBots_CGBotTest"] .. msg)
end

function CrossGambling:SimulateRoll(playerName, minRoll, maxRoll)
    local roll = math.random(minRoll, maxRoll)
    botLog(string.format(L["DebugBots_Rolls"], playerName, roll, minRoll, maxRoll))
    self:DispatchModeHook("OnRollReceived", playerName, roll, minRoll, maxRoll)
    return roll
end

function CrossGambling:GetNextBotRoller()
    local turn = self:GetCurrentTurn()
    if turn then
        return turn
    end

    local mode = self:GetCurrentMode()
    if mode and mode.hostRolls then
        return self.game.hostName
    end

    local pending = self:CheckRolls()
    return pending[1]
end

function CrossGambling:StepBots(token)
    if token ~= self.botTestToken then return end
    if not self:IsBotTest() then return end
    if self.game.state ~= "ROLL" then
        botLog(L["DebugBots_TestGameFinished"])
        return
    end

    self.botTestSteps = (self.botTestSteps or 0) + 1
    if self.botTestSteps > BOT_MAX_STEPS then
        botLog(L["DebugBots_StoppedExceededTheSafetyStepLimitSomething"])
        self:StopBotTest()
        return
    end

    local mode = self:GetCurrentMode()

    if mode and mode.usesChatPick and not self.botPicksDone then
        self.botPicksDone = true
        for i = 1, #self.game.players do
            local name = self.game.players[i].name
            local pick = math.random(2) == 1 and "over" or "under"
            botLog(name .. L["OverUnderMode_Picks"] .. (pick == "over" and L["OverUnderMode_ChoiceOver"] or L["OverUnderMode_ChoiceUnder"]))
            self:DispatchModeHook("OnChatText", name, pick)
        end
    else
        local roller = self:GetNextBotRoller()
        if roller then
            local minRoll, maxRoll = self:GetRollRange()
            self:SimulateRoll(roller, minRoll, maxRoll)
        else
            botLog(L["DebugBots_NobodyLeftToRollButTheGame"])
            self:StopBotTest()
            return
        end
    end

    C_Timer.After(BOT_STEP_DELAY, function()
        self:StepBots(token)
    end)
end

function CrossGambling:StartBotTest(info, args)
    if not self:IsTestingMode() then
        self:Print(L["DebugBots_TestingModeIsOffEnableItFirst"])
        return
    end

    local botCount = tonumber(args)
    if not botCount or botCount < 1 then
        self:Print(L["DebugBots_UsageCgTestbotsNumberOfBotsEGCg"])
        return
    end
    botCount = math.floor(botCount)

    if self.game.state ~= "START" then
        self:Print(L["DebugBots_FinishOrResetTheCurrentGameCg"])
        return
    end

    local mode = self:GetCurrentMode()
    if not mode then
        self:Print(L["DebugBots_NoModeSelected"])
        return
    end

    self:BuildUI()

    local wager = self.wagerInput and self:ValidateWager(self.wagerInput:GetText()) or self.db.global.wager

    if mode.minPlayers and botCount < mode.minPlayers then
        botCount = mode.minPlayers
    end
    if mode.maxPlayers and botCount > mode.maxPlayers then
        botCount = mode.maxPlayers
    end

    self.botTestToken = (self.botTestToken or 0) + 1
    local token = self.botTestToken
    self.botTestSteps = 0
    self.botPicksDone = false

    botLog(string.format(L["DebugBots_StartingABotTestGameInMode"], botCount, self:GetModeDisplayName(mode.name)))

    self:ResetGameState()
    self:ClearCompletedGameBoard()
    self.game.host     = true
    self.game.botTest  = true
    self.game.hostName = self.game.PlayerName
    self.game.wager    = wager
    self.game.houseCut = self.db.global.houseCut
    self.game.state    = "REGISTER"
    self:ResetPlayers()
    if CGCall["R_NewGame"] then
        CGCall["R_NewGame"]()
    end

    for i = 1, botCount do
        local botName = "TestBot" .. i
        if self:registerPlayer(botName) then
            self:AddPlayer(botName)
        end
    end

    self:CGRolls()

    C_Timer.After(BOT_STEP_DELAY, function()
        self:StepBots(token)
    end)
end

function CrossGambling:StopBotTest()
    if not self:IsBotTest() then
        self:Print(L["DebugBots_NoBotTestIsRunning"])
        return
    end
    self.botTestToken = (self.botTestToken or 0) + 1
    if self.game.state ~= "START" then
        self:CloseGame()
    end
    self:Print(L["DebugBots_BotTestStopped"])
end
