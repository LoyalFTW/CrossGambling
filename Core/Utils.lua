local _, ns = ...
local CrossGambling = ns.CG


function CrossGambling:TrimInput(text)
    if not text then
        return ""
    end

    return (tostring(text):gsub("^%s+", ""):gsub("%s+$", ""))
end

function CrossGambling:IsForeverClient()
    if type(RegionalUniqueNamesEnabled) == "function" then
        return RegionalUniqueNamesEnabled() == true
    end
    local interfaceVersion = select(4, GetBuildInfo())
    return type(interfaceVersion) == "number"
        and interfaceVersion >= 16000
        and interfaceVersion < 20000
end

function CrossGambling:GetSurnameSeparator()
    local separators = Constants and Constants.CharacterNameSeparatorConsts
    return separators and separators.CHARACTERNAME_SURNAME_SEPARATOR or " "
end

function CrossGambling:GetUnitPlayerName(unit)
    local name, surname = (UnitNameUnmodified or UnitName)(unit or "player")
    if issecretvalue and (issecretvalue(name) or issecretvalue(surname)) then
        return nil
    end
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if self:IsForeverClient() and type(surname) == "string" and surname ~= "" then
        local suffix = self:GetSurnameSeparator() .. surname
        if name:sub(-#suffix) ~= suffix then
            name = name .. suffix
        end
    end
    return name
end

function CrossGambling:ParsePlayerNameArguments(args, count)
    args = self:TrimInput(args)
    if count == 1 then
        if args:sub(1, 1) == '"' then
            args = args:match('^"([^"]+)"$')
        end
        args = args and self:TrimInput(args)
        return args and args ~= "" and args or nil
    end
    local names = {}
    local position = 1
    local quoted = false
    while position <= #args do
        local startAt = args:find("%S", position)
        if not startAt then break end
        if args:sub(startAt, startAt) == '"' then
            local endAt = args:find('"', startAt + 1, true)
            if not endAt or (endAt < #args and not args:sub(endAt + 1, endAt + 1):match("%s")) then
                return nil
            end
            local name = self:TrimInput(args:sub(startAt + 1, endAt - 1))
            if name == "" then return nil end
            names[#names + 1] = name
            position = endAt + 1
            quoted = true
        else
            local endAt = args:find("%s", startAt) or (#args + 1)
            names[#names + 1] = args:sub(startAt, endAt - 1)
            position = endAt
        end
    end
    if not quoted and self:IsForeverClient() and #names == count * 2 then
        local fullNames = {}
        for index = 1, count do
            fullNames[index] = names[index * 2 - 1] .. self:GetSurnameSeparator() .. names[index * 2]
        end
        names = fullNames
    end
    if #names ~= count then return nil end
    return unpack(names)
end

function CrossGambling:GetForeverRuleset()
    if not self:IsForeverClient() then
        return nil
    end

    if C_GameRules.IsGameRuleActive(Enum.GameRule.HardcoreRuleset) then
        return "Hardcore"
    elseif C_GameRules.IsGameRuleActive(Enum.GameRule.RPRuleset) then
        return "RP"
    elseif C_GameRules.IsGameRuleActive(Enum.GameRule.PvPRuleset) then
        return "PvP"
    end

    return "PvE"
end

function CrossGambling:ShortPlayerName(name)
    if not name then
        return nil
    end

    name = self:TrimInput(name)
    if self:IsForeverClient() then
        return name
    end
    return (strsplit("-", name, 2))
end

function CrossGambling:NormalizePlayerName(name, preserveRealm)
    if not name then
        return nil
    end

    name = strtrim(tostring(name))
    if name == "" then
        return nil
    end

    if not preserveRealm then
        name = self:ShortPlayerName(name)
        if not name or name == "" then
            return nil
        end
    end

    return strlower(name)
end

function CrossGambling:ClampInteger(value, low, high)
    local numericValue = tonumber(value)
    if not numericValue then
        return nil
    end

    numericValue = math.floor(numericValue)
    if numericValue < low then
        numericValue = low
    elseif numericValue > high then
        numericValue = high
    end

    return numericValue
end

function CrossGambling:addCommas(value)
    local text = tostring(value)
    local sign, digits = text:match("^(-?)(%d+)$")
    if not digits or #digits <= 3 then
        return text
    end

    local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    formatted = formatted:gsub("^,", "")
    return sign .. formatted
end

function CrossGambling:String(players)
    local names = {}
    for i = 1, #players do
        local entry = players[i]
        names[i] = type(entry) == "table" and entry.name or tostring(entry)
    end

    if #names == 0 then
        return ""
    elseif #names == 1 then
        return names[1]
    end

    return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

function CrossGambling:CountKeys(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end
