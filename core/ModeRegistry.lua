CrossGambling.modeRegistry  = CrossGambling.modeRegistry  or {}
CrossGambling.modeListOrder = CrossGambling.modeListOrder or {}

function CrossGambling:RegisterMode(modeObj)
    assert(type(modeObj) == "table", "RegisterMode: mode must be a table")
    assert(type(modeObj.name) == "string" and modeObj.name ~= "", "RegisterMode: mode must have a non-empty .name")
    assert(not self.modeRegistry[modeObj.name], "RegisterMode: a mode named '" .. modeObj.name .. "' is already registered")

    modeObj.description = modeObj.description or ""
    modeObj.minPlayers   = modeObj.minPlayers or 2
    modeObj.maxPlayers   = modeObj.maxPlayers or nil
    modeObj.usesChatPick = modeObj.usesChatPick or false

    self.modeRegistry[modeObj.name] = modeObj
    table.insert(self.modeListOrder, modeObj.name)
end

function CrossGambling:GetCurrentMode()
    return self.modeRegistry[self.game.mode]
end

function CrossGambling:changeGameMode()
    local list = self.modeListOrder
    if #list == 0 then return end

    local current = self.game.mode
    for i = 1, #list do
        if list[i] == current then
            self.game.mode = list[(i % #list) + 1]
            return
        end
    end
    self.game.mode = list[1]
end

function CrossGambling:GetModeList()
    local copy = {}
    for _, name in ipairs(self.modeListOrder) do
        table.insert(copy, name)
    end
    return copy
end

function CrossGambling:DispatchModeHook(hookName, ...)
    local mode = self:GetCurrentMode()
    if mode and type(mode[hookName]) == "function" then
        mode[hookName](mode, self, self.game, ...)
        return true
    end
    return false
end

function CrossGambling:GetModeRulesText(mode)
    if not mode then
        return "No Mode Selected", "Pick a game mode first."
    end

    local rules = (mode.description and mode.description ~= "") and mode.description or "No rules description available for this mode."
    return mode.name, rules
end

function CrossGambling:PostModeRules()
    local title, rules = self:GetModeRulesText(self:GetCurrentMode())
    self:SendChat(string.format("CrossGambling: %s Rules - %s", title, rules))
end

function CrossGambling:ShowGameModeTooltip(button)
    local title, rules = self:GetModeRulesText(self:GetCurrentMode())
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    GameTooltip:AddLine(rules, 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Shift+Click to post these rules in chat.", 0.6, 0.8, 1)
    GameTooltip:Show()
end

function CrossGambling:RefreshGameModeTooltip(button)
    if GameTooltip:IsShown() and GameTooltip:GetOwner() == button then
        self:ShowGameModeTooltip(button)
    end
end

function CrossGambling:AttachGameModeTooltip(button)
    button:HookScript("OnEnter", function(btn)
        self:ShowGameModeTooltip(btn)
    end)

    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
