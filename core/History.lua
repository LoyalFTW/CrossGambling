local auditRetentionOptions = {5, 10, 30, "Never"}

local function emitHistoryLine(addon, message)
    local method = addon and addon.game and addon.game.chatMethod
    if method == "PARTY" then
        if IsInGroup(LE_PARTY_CATEGORY_HOME) and not IsInRaid() then
            addon:SendChat(message, method)
            return
        end
    elseif method == "RAID" then
        if IsInRaid(LE_PARTY_CATEGORY_HOME) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            addon:SendChat(message, method)
            return
        end
    elseif method == "GUILD" then
        if IsInGuild() then
            addon:SendChat(message, method)
            return
        end
    end

    addon:Print(message)
end

function CrossGambling:TrimAuditLog()
    if not self.db or not self.db.global then return end

    local log = self.db.global.auditLog or {}
    local retention = self:GetAuditRetentionValue()
    local maxEntries = tonumber(self.db.global.auditMaxEntries) or 500

    if retention ~= nil and retention ~= -1 and retention ~= "Never" then
        local cutoff = time() - (tonumber(retention) * 86400)
        local prunedLog = {}

        for _, entry in ipairs(log) do
            if tonumber(entry.timestamp) and tonumber(entry.timestamp) > cutoff then
                table.insert(prunedLog, entry)
            end
        end

        log = prunedLog
    end

    if maxEntries > 0 and #log > maxEntries then
        local startIndex = #log - maxEntries + 1
        local cappedLog = {}

        for i = startIndex, #log do
            cappedLog[#cappedLog + 1] = log[i]
        end

        log = cappedLog
    end

    self.db.global.auditLog = log
end

function CrossGambling:GetAuditRetentionOptions()
    return auditRetentionOptions
end

function CrossGambling:GetAuditRetentionValue()
    if not self.db or not self.db.global then
        return 30
    end

    local retention = self.db.global.auditRetention
    if retention == nil then
        return 30
    end
    if retention == -1 then
        retention = "Never"
    end

    local normalized = tonumber(retention) or retention
    for _, option in ipairs(auditRetentionOptions) do
        if option == normalized then
            return option
        end
    end

    return 30
end

function CrossGambling:SetAuditRetention(retention)
    if not self.db or not self.db.global then
        return
    end

    if retention == -1 then
        retention = "Never"
    end

    local normalized = tonumber(retention) or retention
    for _, option in ipairs(auditRetentionOptions) do
        if option == normalized then
            self.db.global.auditRetention = option
            self:TrimAuditLog()
            return
        end
    end

    self.db.global.auditRetention = 30
    self:TrimAuditLog()
end

function CrossGambling:AddAuditEntry(entry)
    if not self.db or not self.db.global or type(entry) ~= "table" then return end

    self.db.global.auditLog = self.db.global.auditLog or {}
    entry.timestamp = tonumber(entry.timestamp) or time()
    table.insert(self.db.global.auditLog, entry)
    self:TrimAuditLog()
    if self.auditFrame and self.auditFrame:IsShown() and type(self.RefreshAuditFrame) == "function" then
        self:RefreshAuditFrame(self.auditFrame.searchBox and self.auditFrame.searchBox:GetText() or "")
    end
end

function CrossGambling:FormatAuditTimestamp(timestamp, compact)
    local ts = tonumber(timestamp) or 0
    if ts <= 0 then
        return compact and "Unknown" or "Unknown time"
    end

    local t = date("*t", ts)
    if compact then
        return string.format("%02d/%02d %02d:%02d", t.month, t.day, t.hour, t.min)
    end

    return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function CrossGambling:GetAuditSummary()
    local log = self.db and self.db.global and self.db.global.auditLog or {}
    local counts = { total = 0, debt = 0, updateStat = 0, joinStats = 0, unjoinStats = 0, deleteStat = 0, resetStats = 0, unknown = 0 }

    for _, entry in ipairs(log) do
        if type(entry) == "table" then
            counts.total = counts.total + 1
            if counts[entry.action] ~= nil then
                counts[entry.action] = counts[entry.action] + 1
            else
                counts.unknown = counts.unknown + 1
            end
        end
    end

    return counts
end

function CrossGambling:BuildAuditSearchText(entry, displayText)
    local parts = { displayText or "" }
    if type(entry) == "table" then
        for key, value in pairs(entry) do
            parts[#parts + 1] = tostring(key)
            parts[#parts + 1] = tostring(value)
        end
    end
    return strlower(table.concat(parts, " "))
end

function CrossGambling:AuditEntryMatches(entry, displayText, filter)
    filter = filter and tostring(filter) or ""
    if strtrim(filter) == "" then
        return true
    end

    local haystack = self:BuildAuditSearchText(entry, displayText)
    for token in string.gmatch(strlower(filter), "%S+") do
        if not haystack:find(token, 1, true) then
            return false
        end
    end

    return true
end

function CrossGambling:FormatAuditEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local ts = self:FormatAuditTimestamp(entry.timestamp, true)
    local dim = "|cff888888"
    local gold = "|cffffd100"
    local name = "|cffffff00"
    local green = "|cff44ff44"
    local red = "|cffff5555"
    local orange = "|cffffaa33"
    local reset = "|r"

    if entry.action == "updateStat" then
        local delta = tonumber(entry.addedAmount) or 0
        local deltaColor = delta >= 0 and green or red
        return string.format(
            "%s[%s]%s %sStats%s  %s%s%s\n%sBefore:%s %s  %sChange:%s %s%+d%s  %sAfter:%s %s",
            dim, ts, reset, gold, reset, name, entry.player or "?", reset,
            dim, reset, self:addCommas(entry.oldAmount or 0), dim, reset, deltaColor, delta, reset, dim, reset, self:addCommas(entry.newAmount or 0)
        )
    elseif entry.action == "joinStats" then
        return string.format(
            "%s[%s]%s %sLinked Alt%s  %s%s%s -> %s%s%s\n%sStats:%s +%s  %sDeathroll:%s +%s",
            dim, ts, reset, gold, reset, name, entry.altname or "?", reset, name, entry.mainname or "?", reset,
            dim, reset, self:addCommas(entry.statsAdded or 0), dim, reset, self:addCommas(entry.deathrollStatsAdded or 0)
        )
    elseif entry.action == "unjoinStats" then
        return string.format(
            "%s[%s]%s %sUnlinked Alt%s  %s%s%s from %s%s%s\n%sStats:%s -%s  %sDeathroll:%s -%s",
            dim, ts, reset, orange, reset, name, entry.altname or "?", reset, name, entry.mainname or "?", reset,
            dim, reset, self:addCommas(entry.pointsRemoved or 0), dim, reset, self:addCommas(entry.deathrollStatsRemoved or 0)
        )
    elseif entry.action == "debt" then
        return string.format(
            "%s[%s]%s %sRound Result%s  %s%s%s owes %s%s%s %s%sg%s",
            dim, ts, reset, gold, reset, name, entry.loser or "?", reset, name, entry.winner or "?", reset,
            red, self:addCommas(entry.amount or 0), reset
        )
    elseif entry.action == "deleteStat" then
        return string.format(
            "%s[%s]%s %sDeleted Stats%s  %s%s%s\n%sStats:%s %s  %sDeathroll:%s %s",
            dim, ts, reset, red, reset, name, entry.player or "?", reset,
            dim, reset, self:addCommas(entry.oldAmount or 0), dim, reset, self:addCommas(entry.oldDeathrollAmount or 0)
        )
    elseif entry.action == "resetStats" then
        return string.format(
            "%s[%s]%s %sReset Stats%s\n%sCleared:%s %d players, %d deathroll players, %d linked alts",
            dim, ts, reset, red, reset, dim, reset,
            tonumber(entry.statsCount) or 0, tonumber(entry.deathrollCount) or 0, tonumber(entry.linkedAltCount) or 0
        )
    end

    local extra = {}
    for key, value in pairs(entry) do
        extra[#extra + 1] = key .. "=" .. tostring(value)
    end
    table.sort(extra)
    return string.format("%s[%s]%s %sUnknown%s\n%s", dim, ts, reset, orange, reset, table.concat(extra, ", "))
end

function CrossGambling:RefreshAuditFrame(filter)
    if not self.auditFrame or not self.auditFrame.scrollFrame then
        return
    end

    local scrollFrame = self.auditFrame.scrollFrame
    local content = self.auditFrame.content
    if not content then
        content = CreateFrame("Frame", nil, scrollFrame)
        content:SetPoint("TOPLEFT")
        content:SetPoint("RIGHT")
        scrollFrame:SetScrollChild(content)
        self.auditFrame.content = content
    end

    content._fontPool = content._fontPool or {}
    local pool = content._fontPool
    for i = 1, #pool do
        pool[i]:SetText("")
        pool[i]:Hide()
    end

    local log = self.db and self.db.global and self.db.global.auditLog or {}
    local summary = self:GetAuditSummary()
    if self.auditFrame.summaryText then
        self.auditFrame.summaryText:SetText(string.format("%d entries  |  %d rounds  |  %d edits  |  %d links",
            summary.total, summary.debt, summary.updateStat + summary.deleteStat + summary.resetStats, summary.joinStats + summary.unjoinStats))
    end

    filter = filter and tostring(filter) or ""
    local loweredFilter = strtrim(filter) ~= "" and filter or nil
    local width = math.max(180, (scrollFrame:GetWidth() or 260) - 14)
    local yOffset = -8
    local spacing = 12
    local poolIdx = 0
    local matched = 0

    for i = #log, 1, -1 do
        local entry = log[i]
        local textLine = self:FormatAuditEntry(entry)
        if textLine and self:AuditEntryMatches(entry, textLine, loweredFilter) then
            matched = matched + 1
            poolIdx = poolIdx + 1
            local fs = pool[poolIdx]
            if not fs then
                fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                pool[poolIdx] = fs
            end
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
            fs:SetWidth(width)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            fs:SetText(textLine)
            fs:Show()
            yOffset = yOffset - fs:GetStringHeight() - spacing
        end
    end

    if matched == 0 then
        poolIdx = 1
        local fs = pool[1]
        if not fs then
            fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            pool[1] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
        fs:SetWidth(width)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        fs:SetText(#log == 0 and "No history yet. Completed rounds and stat changes will show here." or "No history matches your search.")
        fs:Show()
        yOffset = -36
    end

    content._fontUsed = poolIdx
    content:SetWidth(width)
    content:SetHeight(math.max(30, -yOffset + spacing))
    scrollFrame:SetVerticalScroll(0)
end

function CrossGambling:PurgeOldAuditEntries()
    self:TrimAuditLog()
end

function CrossGambling:UpdateAuditLogText(filter)
    self:RefreshAuditFrame(filter)
end

function CrossGambling:auditMerges()
    if not self.db.global.auditLog or #self.db.global.auditLog == 0 then
        emitHistoryLine(self, "No audit log entries found.")
        return
    end

    emitHistoryLine(self, "-- Audit Log --")
    for i, entry in ipairs(self.db.global.auditLog) do
        if entry.action == "updateStat" then
            emitHistoryLine(self, string.format(
                "%d. [%s] Updated stats for %s: old=%d, added=%d, new=%d",
                i, entry.timestamp, entry.player, entry.oldAmount, entry.addedAmount, entry.newAmount
            ))
        elseif entry.action == "joinStats" then
            emitHistoryLine(self, string.format(
                "%d. [%s] Joined alt '%s' to main '%s' with %d stats and %d deathroll stats",
                i, entry.timestamp, entry.altname, entry.mainname, entry.statsAdded or 0, entry.deathrollStatsAdded or 0
            ))
        elseif entry.action == "unjoinStats" then
            emitHistoryLine(self, string.format(
                "%d. [%s] Unjoined alt '%s' from main '%s', points subtracted: %d, deathroll: %d",
                i, entry.timestamp, entry.altname, entry.mainname, entry.pointsRemoved or 0, entry.deathrollStatsRemoved or 0
            ))
        elseif entry.action == "debt" then
            emitHistoryLine(self, string.format(
                "%d. [%s] %s owes %s %dg",
                i, entry.timestamp, entry.loser or "?", entry.winner or "?", entry.amount or 0
            ))
        elseif entry.action == "deleteStat" then
            emitHistoryLine(self, string.format(
                "%d. [%s] Deleted stats for %s: stats=%d, deathroll=%d",
                i, entry.timestamp, entry.player or "?", entry.oldAmount or 0, entry.oldDeathrollAmount or 0
            ))
        elseif entry.action == "resetStats" then
            emitHistoryLine(self, string.format(
                "%d. [%s] Reset stats: cleared %d players, %d deathroll players, %d linked alts",
                i, entry.timestamp, entry.statsCount or 0, entry.deathrollCount or 0, entry.linkedAltCount or 0
            ))
        else
            local extra = {}
            for key, value in pairs(entry) do
                table.insert(extra, key .. "=" .. tostring(value))
            end
            table.sort(extra)
            emitHistoryLine(self, string.format(
                "%d. [%s] %s",
                i,
                entry.timestamp or "?",
                next(extra) and table.concat(extra, ", ") or "Unknown audit entry"
            ))
        end
    end
end
