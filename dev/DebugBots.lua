
local BOT_STEP_DELAY = 0.35
local BOT_MAX_STEPS  = 300

local function botLog(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[CG Bot Test]|r " .. msg)
end

function CrossGambling:SimulateRoll(playerName, minRoll, maxRoll)
    local roll = math.random(minRoll, maxRoll)
    botLog(string.format("%s rolls %d (%d-%d)", playerName, roll, minRoll, maxRoll))
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

    local mode = self:GetCurrentMode()

    if mode and mode.usesChatPick and not self.botPicksDone then
        self.botPicksDone = true
        for i = 1, #self.game.players do
            local name = self.game.players[i].name
            local pick = math.random(2) == 1 and "over" or "under"
            botLog(name .. " picks " .. pick)
            self:DispatchModeHook("OnChatText", name, pick)
        end
    else
        local roller = self:GetNextBotRoller()
        if roller then
            local minRoll, maxRoll = self:GetRollRange()
            self:SimulateRoll(roller, minRoll, maxRoll)
        else
            botLog("Nobody left to roll but the game is still open - stopping.")
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

    botLog(string.format("Starting a %d-bot test game in %s mode.", botCount, mode.name))

    self.game.host     = true
    self.game.hostName = self.game.PlayerName
    self.game.wager    = self.db.global.wager
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
    self.botTestToken = (self.botTestToken or 0) + 1
    if self.game.state ~= "START" then
        self:CloseGame()
    end
    self:Print("CrossGambling: Bot test stopped.")
end
