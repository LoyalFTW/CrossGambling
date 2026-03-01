CrossGambling.modeRegistry  = CrossGambling.modeRegistry  or {}
CrossGambling.modeListOrder = CrossGambling.modeListOrder or {}

function CrossGambling:RegisterMode(modeObj)
    assert(type(modeObj) == "table", "RegisterMode: mode must be a table")
    assert(type(modeObj.name) == "string" and modeObj.name ~= "", "RegisterMode: mode must have a non-empty .name")
    assert(not self.modeRegistry[modeObj.name], "RegisterMode: a mode named '" .. modeObj.name .. "' is already registered")

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
