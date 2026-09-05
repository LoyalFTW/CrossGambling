
local chatMethods = { "PARTY", "RAID", "GUILD" }

local chatEventsByMethod = {
    PARTY = { "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" },
    RAID  = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" },
    INSTANCE_CHAT = { "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" },
    GUILD = { "CHAT_MSG_GUILD" },
}

local allChatEvents = {
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD",
}

local rollResultPattern
local rollResultTemplate
local function GetRollResultPattern()
    if rollResultPattern and rollResultTemplate == RANDOM_ROLL_RESULT then
        return rollResultPattern
    end

    local template = RANDOM_ROLL_RESULT
    rollResultTemplate = template
    local hasNamePlaceholder = type(template) == "string" and (
        template:find("%s", 1, true) or template:find("%%%d+%$s")
    )
    if hasNamePlaceholder then
        local pattern = template:gsub("%%(%d+)%$", "%%")
        pattern = pattern:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
        pattern = pattern:gsub("%%s", "(%%S+)"):gsub("%%d", "(%%d+)")
        rollResultPattern = "^" .. pattern .. "%.?$"
    else
        rollResultPattern = "^(%S+) rolls (%d+) %((%d+)%-(%d+)%)%.?$"
    end

    return rollResultPattern
end


function CrossGambling:RegisterChatEvents()
    if not self.game.host then
        return
    end

    if self:ShouldSuspendChatEventsInCombat() then
        self:SuspendRegistrationChatEvents()
        return
    end

    self.chatEventsSuspendedForCombat = false

    local channel = self:ResolveChatChannel(self.game.chatMethod)
    local events = chatEventsByMethod[channel] or chatEventsByMethod.PARTY
    for _, eventName in ipairs(events) do
        self:RegisterEvent(eventName, "handleChatMsg")
    end
    self.chatEventsRegistered = true
end

function CrossGambling:UnRegisterChatEvents()
    for _, eventName in ipairs(allChatEvents) do
        self:UnregisterEvent(eventName)
    end
    self.chatEventsRegistered = false
end

function CrossGambling:chatMethod()
    local current = self.game.chatMethod
    local wasRegistered = self.chatEventsRegistered == true

    local newMethod = chatMethods[1]
    for i = 1, #chatMethods do
        if current == chatMethods[i] then
            newMethod = chatMethods[(i % #chatMethods) + 1]
            break
        end
    end
    self.game.chatMethod = newMethod

    if wasRegistered then
        self:UnRegisterChatEvents()
        self:RegisterChatEvents()
    end
end


function CrossGambling:IsHighImpactCombatContext()
    if self.bossEncounterActive then
        return true
    end

    local _, instanceType = IsInInstance()
    return instanceType == "arena" or instanceType == "pvp"
end

function CrossGambling:ShouldSuspendChatEventsInCombat()
    return self.db
        and self.db.global
        and self.db.global.suspendChatEventsInCombat ~= false
        and InCombatLockdown()
        and self:IsHighImpactCombatContext()
end

function CrossGambling:SuspendRegistrationChatEvents()
    if self.game.state == "START" then
        return
    end

    self.chatEventsSuspendedForCombat = true
    self:UnRegisterChatEvents()
end

function CrossGambling:ResumeRegistrationChatEvents()
    if not self.chatEventsSuspendedForCombat then
        return
    end

    local mode = self:GetCurrentMode()
    local pickPhaseActive = self.game.state == "ROLL" and mode and mode.usesChatPick

    if self.game.state == "REGISTER" or pickPhaseActive then
        self:RegisterChatEvents()
    end
end

function CrossGambling:OnCombatStart()
    if self:ShouldSuspendChatEventsInCombat() then
        self:SuspendRegistrationChatEvents()
    end
end

function CrossGambling:OnCombatEnd()
    self:ResumeRegistrationChatEvents()
end

function CrossGambling:OnEncounterStart()
    self.bossEncounterActive = true

    if self:ShouldSuspendChatEventsInCombat() then
        self:SuspendRegistrationChatEvents()
    end
end

function CrossGambling:OnEncounterEnd()
    self.bossEncounterActive = false

    if not self:ShouldSuspendChatEventsInCombat() then
        self:ResumeRegistrationChatEvents()
    end
end


function CrossGambling:handleChatMsg(_, text, playerName)
    if self:ShouldSuspendChatEventsInCombat() then
        self:SuspendRegistrationChatEvents()
        return
    end

    if not self.game.host then
        return
    end

    playerName = self:ShortPlayerName(playerName)

    if self.game.state == "REGISTER" then
        self:RegisterGame(text, playerName)
    elseif self.game.state == "ROLL" then
        self:DispatchModeHook("OnChatText", playerName, text)
    end
end

function CrossGambling:handleSystemMessage(_, text)
    if self.game.state ~= "ROLL" or not self.game.host then
        return
    end

    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, GetRollResultPattern())
    if not playerName or not actualRoll or not minRoll or not maxRoll then
        return
    end

    self:DispatchModeHook("OnRollReceived", self:ShortPlayerName(playerName), tonumber(actualRoll), tonumber(minRoll), tonumber(maxRoll))
end
