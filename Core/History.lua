local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG

local auditRetentionOptions = {5, 10, 30, "Never"}

function CrossGambling:CreateAuditExpandButton(frame, slick)
    local button = CreateFrame("Button", nil, frame, slick and "BackdropTemplate" or "UIPanelButtonTemplate")
    button:SetSize(20, 18)
    button:SetPoint("TOPLEFT", 8, -7)
    button:SetNormalFontObject("GameFontNormalSmall")
    button:SetText("+")
    local function restoreLayout()
        local restore = frame.auditRestoreLayout
        if not restore then return end
        frame:StopMovingOrSizing()
        frame.isSizing = false
        frame.auditRestoreLayout = nil
        frame:SetFrameStrata(restore.strata)
        frame:ClearAllPoints()
        frame:SetSize(restore.width, restore.height)
        for _, point in ipairs(restore.points) do
            frame:SetPoint(unpack(point))
        end
        button:SetText("+")
    end
    button:SetScript("OnClick", function()
        frame:StopMovingOrSizing()
        frame.isSizing = false
        GameTooltip:Hide()
        if frame.auditRestoreLayout then
            restoreLayout()
        else
            local width, height = frame:GetSize()
            local points = {}
            for i = 1, frame:GetNumPoints() do
                points[i] = { frame:GetPoint(i) }
            end
            frame.auditRestoreLayout = { width = width, height = height, points = points, strata = frame:GetFrameStrata() }
            frame:SetFrameStrata("DIALOG")
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            frame:SetSize(math.min(math.max(width, 800), UIParent:GetWidth() - 40),
                math.min(math.max(height, 650), UIParent:GetHeight() - 40))
            button:SetText("-")
        end
        frame:UpdateLayout()
    end)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(frame.auditRestoreLayout and L["History_RestoreHistoryWindow"] or L["History_ExpandHistoryWindow"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:HookScript("OnHide", function()
        restoreLayout()
        GameTooltip:Hide()
    end)
    frame.expandButton = button
    return button
end

function CrossGambling:AnnounceOrPrint(message)
    local method = self.game and self.game.chatMethod
    if self:CanSendToChannel(method) then
        self:SendChat(message, method)
        return
    end

    self:Print(message)
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
    if self:IsBotTest() then return end
    if not self.db or not self.db.global or type(entry) ~= "table" then return end

    self.db.global.auditLog = self.db.global.auditLog or {}
    if not entry.profile and type(self.GetActiveStatProfile) == "function" then
        entry.profile = self:GetActiveStatProfile()
    end
    entry.timestamp = tonumber(entry.timestamp) or time()
    table.insert(self.db.global.auditLog, entry)
    self:TrimAuditLog()
    if self.auditFrame and self.auditFrame:IsShown() and type(self.RefreshAuditFrame) == "function" then
        self:RefreshAuditFrame(self.auditFrame.searchBox and self.auditFrame.searchBox:GetText() or "")
    end
end

function CrossGambling:PurgeAuditLogNow()
    local count = (self.db and self.db.global and self.db.global.auditLog and #self.db.global.auditLog) or 0

    if self.db and self.db.global then
        self.db.global.auditLog = {}
    end

    if self.auditFrame and type(self.RefreshAuditFrame) == "function" then
        self:RefreshAuditFrame(self.auditFrame.searchBox and self.auditFrame.searchBox:GetText() or "")
    end

    self:Print(string.format(count == 1 and L["History_PurgedOne"] or L["History_PurgedMany"], count))
end

function CrossGambling:ConfirmPurgeAuditLog()
    if not StaticPopupDialogs["CG_PURGE_HISTORY"] then
        StaticPopupDialogs["CG_PURGE_HISTORY"] = {
            text         = L["History_PurgeTheEntireHistoryLogThisCannot"],
            button1      = L["History_Yes"],
            button2      = L["History_No"],
            OnAccept     = function() self:PurgeAuditLogNow() end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end
    StaticPopup_Show("CG_PURGE_HISTORY")
end

function CrossGambling:FormatAuditTimestamp(timestamp, compact)
    local ts = tonumber(timestamp) or 0
    if ts <= 0 then
        return compact and L["Common_Unknown"] or L["History_UnknownTime"]
    end

    local t = date("*t", ts)
    if compact then
        return string.format("%02d/%02d %02d:%02d", t.month, t.day, t.hour, t.min)
    end

    return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function CrossGambling:GetAuditSummary()
    local log = self.db and self.db.global and self.db.global.auditLog or {}
    local counts = { total = 0, debt = 0, payment = 0, paymentUndo = 0, doubleOrNothing = 0, updateStat = 0, joinStats = 0, unjoinStats = 0, deleteStat = 0, resetStats = 0, unknown = 0 }

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
    if entry.profile then
        ts = ts .. " · " .. tostring(entry.profile)
    end
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
            L["History_StatsBeforeChangeAfter"],
            dim, ts, reset, gold, reset, name, entry.player or "?", reset,
            dim, reset, self:addCommas(entry.oldAmount or 0), dim, reset, deltaColor, delta, reset, dim, reset, self:addCommas(entry.newAmount or 0)
        )
    elseif entry.action == "joinStats" then
        return string.format(
            L["History_LinkedAltStatsDeathroll"],
            dim, ts, reset, gold, reset, name, entry.altname or "?", reset, name, entry.mainname or "?", reset,
            dim, reset, self:addCommas(entry.statsAdded or 0), dim, reset, self:addCommas(entry.deathrollStatsAdded or 0)
        )
    elseif entry.action == "unjoinStats" then
        return string.format(
            L["History_UnlinkedAltFromStatsDeathroll"],
            dim, ts, reset, orange, reset, name, entry.altname or "?", reset, name, entry.mainname or "?", reset,
            dim, reset, self:addCommas(entry.pointsRemoved or 0), dim, reset, self:addCommas(entry.deathrollStatsRemoved or 0)
        )
    elseif entry.action == "debt" then
        local text = string.format(
            L["History_RoundResultOwesG"],
            dim, ts, reset, gold, reset, name, entry.loser or "?", reset, name, entry.winner or "?", reset,
            red, self:addCommas(entry.winnerAmount or entry.amount or 0), reset
        )
        if (tonumber(entry.guildAmount) or 0) > 0 then
            text = text .. L["History_Plus"] .. self:addCommas(entry.guildAmount) .. L["Game_GToTheGuild"]
        end
        if entry.ledgerId then text = text .. "  " .. dim .. L["History_Debt"] .. entry.ledgerId .. "]" .. reset end
        return text
    elseif entry.action == "payment" or entry.action == "paymentUndo" then
        return string.format(L["History_GDebt"], dim, ts, reset,
            entry.action == "payment" and green or orange, entry.action == "payment" and L["History_PaymentRecorded"] or L["History_PaymentUndone"], reset,
            entry.player or "?", entry.recipient or "?", self:addCommas(entry.amount or 0), tostring(entry.ledgerId or "?"))
    elseif entry.action == "doubleOrNothing" then
        local outcome = entry.outcome or "unknown"
        local outcomeText
        local outcomeColor = orange
        if outcome == "doubled" then
            outcomeText = L["History_DOUBLEDTo"] .. self:addCommas(entry.finalAmount or 0) .. L["Common_GoldSuffix"]
            outcomeColor = red
        elseif outcome == "cleared" then
            outcomeText = L["History_CLEAREDNothingOwed"]
            outcomeColor = green
        elseif outcome == "cancelled" then
            outcomeText = L["History_CANCELLEDOriginalResultKept"]
        else
            outcomeText = outcome == "unknown" and L["History_UnknownOutcomeUpper"] or strupper(tostring(outcome))
        end
        local rollText = entry.rolledOne and ("  " .. entry.rolledOne .. L["History_Rolled1"]) or ""
        return string.format(
            L["History_DoubleOrNothingVsOriginalGOutcome"],
            dim, ts, reset, gold, reset, name, entry.loser or "?", reset, name, entry.winner or "?", reset,
            dim, reset, self:addCommas(entry.originalAmount or 0), dim, reset, outcomeColor, outcomeText, reset, rollText
        )
    elseif entry.action == "deleteStat" then
        return string.format(
            L["History_DeletedStatsStatsDeathroll"],
            dim, ts, reset, red, reset, name, entry.player or "?", reset,
            dim, reset, self:addCommas(entry.oldAmount or 0), dim, reset, self:addCommas(entry.oldDeathrollAmount or 0)
        )
    elseif entry.action == "resetStats" then
        return string.format(
            L["History_ResetStatsClearedPlayersDeathrollPlayersLinked"],
            dim, ts, reset, red, reset, dim, reset,
            tonumber(entry.statsCount) or 0, tonumber(entry.deathrollCount) or 0, tonumber(entry.linkedAltCount) or 0
        )
    end

    local extra = {}
    for key, value in pairs(entry) do
        extra[#extra + 1] = key .. "=" .. tostring(value)
    end
    table.sort(extra)
    return string.format(L["History_Unknown"], dim, ts, reset, orange, reset, table.concat(extra, ", "))
end

function CrossGambling:QueueAuditSearchRefresh(searchBox, userInput)
    searchBox.auditSearchRevision = (searchBox.auditSearchRevision or 0) + 1
    if not userInput then return end

    local revision = searchBox.auditSearchRevision
    C_Timer.After(0.15, function()
        if searchBox.auditSearchRevision ~= revision then return end
        local frame = self.auditFrame
        if not frame or frame.searchBox ~= searchBox or not frame:IsShown() then return end
        self:RefreshAuditFrame(searchBox:GetText())
    end)
end

function CrossGambling:RefreshAuditFrame(filter)
    if not self.auditFrame or not self.auditFrame.scrollFrame then
        return
    end

    local searchBox = self.auditFrame.searchBox
    if searchBox then
        searchBox.auditSearchRevision = (searchBox.auditSearchRevision or 0) + 1
    end

    local scrollFrame = self.auditFrame.scrollFrame
    filter = filter and tostring(filter) or ""
    local scrollPosition = scrollFrame:GetVerticalScroll() or 0
    local searchChanged = self.auditFrame.auditSearchFilter ~= filter
    local anchorEntry, anchorOffset
    if not searchChanged and scrollPosition > 0 then
        for _, row in ipairs(self.auditFrame.auditScrollEntries or {}) do
            if row.offset > scrollPosition then break end
            anchorEntry = row.entry
            anchorOffset = scrollPosition - row.offset
        end
    end
    local scrollEntries = {}
    local restoredPosition = searchChanged and 0 or scrollPosition
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
        self.auditFrame.summaryText:SetText(string.format(L["History_EntriesRoundsDNEditsLinks"],
            summary.total, summary.debt, summary.doubleOrNothing, summary.updateStat + summary.deleteStat + summary.resetStats, summary.joinStats + summary.unjoinStats))
    end

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
            local offset = -yOffset
            scrollEntries[#scrollEntries + 1] = { entry = entry, offset = offset }
            if entry == anchorEntry then
                restoredPosition = offset + anchorOffset
            end
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
        fs:SetText(#log == 0 and L["History_NoHistoryYetCompletedRoundsAndStat"] or L["History_NoHistoryMatchesYourSearch"])
        fs:Show()
        yOffset = -36
    end

    content._fontUsed = poolIdx
    content:SetWidth(width)
    content:SetHeight(math.max(30, -yOffset + spacing))
    self.auditFrame.auditSearchFilter = filter
    self.auditFrame.auditScrollEntries = scrollEntries
    local maxScroll = math.max(0, content:GetHeight() - scrollFrame:GetHeight())
    scrollFrame:SetVerticalScroll(math.max(0, math.min(restoredPosition, maxScroll)))
end

function CrossGambling:PurgeOldAuditEntries()
    self:TrimAuditLog()
end

function CrossGambling:UpdateAuditLogText(filter)
    self:RefreshAuditFrame(filter)
end

local outcomeLabels = {
    unknown = L["History_UnknownOutcome"],
    doubled = L["History_DoubledOutcome"],
    cleared = L["History_ClearedOutcome"],
    cancelled = L["History_CancelledOutcome"],
}

function CrossGambling:auditMerges()
    if not self.db.global.auditLog or #self.db.global.auditLog == 0 then
        self:AnnounceOrPrint(L["History_NoAuditLogEntriesFound"])
        return
    end

    self:AnnounceOrPrint(L["History_AuditLog"])
    for i, entry in ipairs(self.db.global.auditLog) do
        if entry.action == "updateStat" then
            self:AnnounceOrPrint(string.format(
                L["History_UpdatedStatsForOldAddedNew"],
                i, entry.timestamp, entry.player, entry.oldAmount, entry.addedAmount, entry.newAmount
            ))
        elseif entry.action == "joinStats" then
            self:AnnounceOrPrint(string.format(
                L["History_JoinedAltToMainWithStatsAnd"],
                i, entry.timestamp, entry.altname, entry.mainname, entry.statsAdded or 0, entry.deathrollStatsAdded or 0
            ))
        elseif entry.action == "unjoinStats" then
            self:AnnounceOrPrint(string.format(
                L["History_UnjoinedAltFromMainPointsSubtractedDeathroll"],
                i, entry.timestamp, entry.altname, entry.mainname, entry.pointsRemoved or 0, entry.deathrollStatsRemoved or 0
            ))
        elseif entry.action == "debt" then
            self:AnnounceOrPrint(string.format(
                L["History_OwesG"],
                i, entry.timestamp, entry.loser or "?", entry.winner or "?", entry.winnerAmount or entry.amount or 0
            ))
            if (tonumber(entry.guildAmount) or 0) > 0 then
                self:AnnounceOrPrint(string.format(L["History_PlusGToTheGuild"], entry.guildAmount))
            end
        elseif entry.action == "payment" or entry.action == "paymentUndo" then
            self:AnnounceOrPrint(string.format(L["History_GDebt2"], i, entry.timestamp,
                entry.action == "payment" and L["History_PaymentRecorded2"] or L["History_PaymentUndone2"], entry.player or "?", entry.recipient or "?",
                entry.amount or 0, tostring(entry.ledgerId or "?")))
        elseif entry.action == "doubleOrNothing" then
            self:AnnounceOrPrint(string.format(
                L["History_DoubleOrNothingVsOriginalGOutcome2"],
                i, entry.timestamp, entry.loser or "?", entry.winner or "?", entry.originalAmount or 0,
                outcomeLabels[entry.outcome or "unknown"] or entry.outcome, entry.finalAmount or 0,
                entry.rolledOne and (", " .. entry.rolledOne .. L["History_Rolled1"]) or ""
            ))
        elseif entry.action == "deleteStat" then
            self:AnnounceOrPrint(string.format(
                L["History_DeletedStatsForStatsDeathroll"],
                i, entry.timestamp, entry.player or "?", entry.oldAmount or 0, entry.oldDeathrollAmount or 0
            ))
        elseif entry.action == "resetStats" then
            self:AnnounceOrPrint(string.format(
                L["History_ResetStatsClearedPlayersDeathrollPlayersLinked2"],
                i, entry.timestamp, entry.statsCount or 0, entry.deathrollCount or 0, entry.linkedAltCount or 0
            ))
        else
            local extra = {}
            for key, value in pairs(entry) do
                table.insert(extra, key .. "=" .. tostring(value))
            end
            table.sort(extra)
            self:AnnounceOrPrint(string.format(
                "%d. [%s] %s",
                i,
                entry.timestamp or "?",
                next(extra) and table.concat(extra, ", ") or L["History_UnknownAuditEntry"]
            ))
        end
    end
end
