function CrossGambling:NormalizePlayerName(name, preserveRealm)
    if not name then
        return nil
    end

    name = strtrim(tostring(name))
    if name == "" then
        return nil
    end

    if not preserveRealm then
        name = strsplit("-", name, 2)
        if not name or name == "" then
            return nil
        end
    end

    return strlower(name)
end

function CrossGambling:NormalizeHouseCutValue(value)
    local numericValue = tonumber(value)
    if not numericValue then
        return nil
    end

    numericValue = math.floor(numericValue)
    if numericValue < 0 then
        numericValue = 0
    elseif numericValue > 100 then
        numericValue = 100
    end

    return numericValue
end

function CrossGambling:RebuildBanCache()
    self.banLookup = {}

    local bans = self.db and self.db.global and self.db.global.bans
    if not bans then
        return
    end

    for i = 1, #bans do
        local normalizedName = self:NormalizePlayerName(bans[i])
        if normalizedName then
            self.banLookup[normalizedName] = true
        end
    end
end

function CrossGambling:IsPlayerBanned(playerName)
    local normalizedPlayerName = self:NormalizePlayerName(playerName)
    if not normalizedPlayerName then
        return false
    end

    if not self.banLookup then
        self:RebuildBanCache()
    end

    return self.banLookup[normalizedPlayerName] == true
end

function CrossGambling:addCommas(value)
    return #tostring(value) > 3 and tostring(value):gsub("^(-?%d+)(%d%d%d)", "%1,%2"):gsub("(%d)(%d%d%d)", ",%1,%2") or tostring(value)
end
