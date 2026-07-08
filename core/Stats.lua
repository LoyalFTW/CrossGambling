local function getStoredName(statsTable, name)
    local normalized = CrossGambling:NormalizePlayerName(name, true)
    if not normalized then
        return nil
    end

    for existingName in pairs(statsTable or {}) do
        if CrossGambling:NormalizePlayerName(existingName, true) == normalized then
            return existingName
        end
    end

    return name
end

local function getKnownPlayerName(addon, name)
    return getStoredName(addon.db.global.stats, getStoredName(addon.db.global.deathrollStats, name))
end

local function combineStatsByMain(addon, statsTable)
    local combinedStats = {}

    for playerName, amount in pairs(statsTable or {}) do
        local mainName = addon:getMainName(playerName)
        combinedStats[mainName] = (combinedStats[mainName] or 0) + amount
    end

    return combinedStats
end

local FULL_STATS_BATCH_SIZE = 18
local FULL_STATS_BATCH_DELAY = 2
local STATS_EXPORT_VERSION = "CrossGamblingStatsExport;3"
local TRANSFER_BACKDROP = {
    bgFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    edgeFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = {left = 1, right = 1, top = 1, bottom = 1},
}

local function ensureBackdrop(frame)
    if frame and not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
end

local function isSlickTheme(addon)
    return addon and addon.db and addon.db.global and addon.db.global.theme == "Slick"
end

local function styleTransferFont(fontString)
    if not fontString then return end

    if CGTheme and CGTheme.GetFontColor then
        fontString:SetTextColor(CGTheme:GetFontColor())
    else
        fontString:SetTextColor(1, 1, 1)
    end
    if CGTheme and CGTheme.GetFontPath then
        fontString:SetFont(CGTheme:GetFontPath(), CGTheme:GetFontSize(), CGTheme:GetFontFlags())
    end
    if CGTheme and CGTheme.RegisterFont then
        CGTheme:RegisterFont(fontString)
    end
end

local function styleTransferButton(button)
    ensureBackdrop(button)
    button:SetBackdrop(TRANSFER_BACKDROP)
    button:SetBackdropBorderColor(0, 0, 0)

    local fontString = button:GetFontString()
    if not fontString then
        fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        button:SetFontString(fontString)
    end
    fontString:SetAllPoints(button)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")
    styleTransferFont(fontString)

    if CGTheme and CGTheme.RegisterBtn then
        CGTheme:RegisterBtn(button)
    end

    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints()
        highlight:Hide()
    end
    button:SetScript("OnEnter", function(self)
        local h = self:GetHighlightTexture()
        if h then h:Show() end
    end)
    button:SetScript("OnLeave", function(self)
        local h = self:GetHighlightTexture()
        if h then h:Hide() end
    end)
end

local function createTransferButton(parent, text, width, height, slick)
    local button = CreateFrame("Button", nil, parent, slick and "BackdropTemplate" or "UIPanelButtonTemplate")
    button:SetSize(width, height)
    if slick then
        styleTransferButton(button)
    end
    button:SetText(text)
    return button
end

local function sendChatLine(addon, message)
    if addon and type(addon.SendChat) == "function" then
        addon:SendChat(message)
    else
        SendChatMessage(message, addon.game.chatMethod)
    end
end

local function sendChatLinesInBatches(addon, lines, batchSize, batchDelay)
    batchSize = batchSize or FULL_STATS_BATCH_SIZE
    batchDelay = batchDelay or FULL_STATS_BATCH_DELAY

    if not lines or #lines == 0 then
        return
    end

    addon.statsReportToken = (addon.statsReportToken or 0) + 1
    local reportToken = addon.statsReportToken

    local function sendBatch(startIndex)
        if addon.statsReportToken ~= reportToken then
            return
        end

        local endIndex = math.min(startIndex + batchSize - 1, #lines)
        for i = startIndex, endIndex do
            sendChatLine(addon, lines[i])
        end

        if endIndex < #lines then
            C_Timer.After(batchDelay, function()
                sendBatch(endIndex + 1)
            end)
        end
    end

    sendBatch(1)
end

local function splitExportFields(line)
    local fields = {}
    local delimiter = line:find(";", 1, true) and ";"
        or line:find("|", 1, true) and "|"
        or "\t"
    local pattern = delimiter == ";" and "(.-);"
        or delimiter == "|" and "(.-)|"
        or "(.-)\t"
    for field in (line .. delimiter):gmatch(pattern) do
        table.insert(fields, field)
    end
    return fields
end

local function sortedKeys(source)
    local keys = {}
    for key in pairs(source or {}) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return tostring(a):lower() < tostring(b):lower()
    end)
    return keys
end

local function appendStatLines(lines, recordType, source)
    local count = 0
    for _, name in ipairs(sortedKeys(source)) do
        table.insert(lines, string.format("%s;%s;%s", recordType, name, tostring(source[name] or 0)))
        count = count + 1
    end
    return count
end

local function createStatsExport(addon, exportType)
    exportType = exportType or "all"
    local global = (addon.db and addon.db.global) or {}
    local lines = {
        STATS_EXPORT_VERSION,
    }

    if exportType == "deathroll" then
        table.insert(lines, "DATASET;DEATHROLL")
        if appendStatLines(lines, "DEATHROLL", global.deathrollStats) == 0 then
            table.insert(lines, "NOTE;No Deathroll stats to export")
        end
        return table.concat(lines, "\n")
    elseif exportType == "session" then
        table.insert(lines, "DATASET;SESSION")
        if appendStatLines(lines, "SESSION", addon.game and addon.game.sessionStats or {}) == 0 then
            table.insert(lines, "NOTE;No Session stats to export")
        end
        return table.concat(lines, "\n")
    end

    table.insert(lines, "DATASET;ALL_STATS")
    table.insert(lines, "HOUSE;" .. tostring(global.housestats or 0))
    if appendStatLines(lines, "STAT", global.stats) == 0 then
        table.insert(lines, "NOTE;No All Stats to export")
    end

    for _, altName in ipairs(sortedKeys(global.joinstats)) do
        table.insert(lines, string.format("JOIN;%s;%s", altName, tostring(global.joinstats[altName] or "")))
    end

    for _, altName in ipairs(sortedKeys(global.altStats)) do
        local altStats = global.altStats[altName] or {}
        table.insert(lines, string.format(
            "ALT;%s;%s;%s;%s",
            altName,
            tostring(altStats.displayName or ""),
            tostring(altStats.stats or 0),
            tostring(altStats.deathrollStats or 0)
        ))
    end

    return table.concat(lines, "\n")
end

local function parseStatsExport(text)
    local imported = {
        stats = {},
        deathrollStats = {},
        sessionStats = {},
        joinstats = {},
        altStats = {},
        housestats = 0,
        dataset = "FULL",
    }
    local counts = {
        stats = 0,
        deathrollStats = 0,
        sessionStats = 0,
        joinstats = 0,
        altStats = 0,
    }

    local sawVersion = false
    for line in (text or ""):gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local fields = splitExportFields(line)
            local recordType = fields[1]

            if recordType == "CrossGamblingStatsExport" then
                sawVersion = true
                if fields[2] ~= "1" and fields[2] ~= "2" and fields[2] ~= "3" then
                    return nil, "Unsupported export version."
                end
            elseif recordType == "DATASET" then
                imported.dataset = fields[2] or "FULL"
            elseif recordType == "NOTE" then
                -- Human-readable export note; ignored during import.
            elseif recordType == "HOUSE" then
                imported.housestats = tonumber(fields[2]) or 0
            elseif recordType == "STAT" or recordType == "DEATHROLL" or recordType == "SESSION" then
                local name = fields[2]
                local amount = tonumber(fields[3])
                if not name or name == "" or not amount then
                    return nil, "Invalid " .. recordType .. " line."
                end

                if recordType == "STAT" then
                    imported.stats[name] = amount
                    counts.stats = counts.stats + 1
                elseif recordType == "DEATHROLL" then
                    imported.deathrollStats[name] = amount
                    counts.deathrollStats = counts.deathrollStats + 1
                else
                    imported.sessionStats[name] = amount
                    counts.sessionStats = counts.sessionStats + 1
                end
            elseif recordType == "JOIN" then
                local altName, mainName = fields[2], fields[3]
                if not altName or altName == "" or not mainName or mainName == "" then
                    return nil, "Invalid JOIN line."
                end

                imported.joinstats[altName] = mainName
                counts.joinstats = counts.joinstats + 1
            elseif recordType == "ALT" then
                local altName = fields[2]
                local displayName = fields[3]
                local stats = tonumber(fields[4])
                local deathrollStats = tonumber(fields[5])
                if not altName or altName == "" or not stats or not deathrollStats then
                    return nil, "Invalid ALT line."
                end

                imported.altStats[altName] = {
                    displayName = displayName ~= "" and displayName or altName,
                    stats = stats,
                    deathrollStats = deathrollStats,
                }
                counts.altStats = counts.altStats + 1
            else
                return nil, "Unknown export line: " .. tostring(recordType)
            end
        end
    end

    if not sawVersion then
        return nil, "Missing CrossGambling export header."
    end

    return imported, nil, counts
end

local function ensureStatsImportDialog(addon)
    if StaticPopupDialogs["CG_IMPORT_STATS"] then
        return
    end

    StaticPopupDialogs["CG_IMPORT_STATS"] = {
        text = "Replace current stats with this import?",
        button1 = "Import",
        button2 = "Cancel",
        OnAccept = function()
            local pending = addon.pendingStatsImport
            if not pending then
                return
            end

            if pending.dataset == "DEATHROLL" then
                addon.db.global.deathrollStats = pending.deathrollStats
            elseif pending.dataset == "SESSION" then
                addon.game = addon.game or {}
                addon.game.sessionStats = pending.sessionStats
            elseif pending.dataset == "ALL_STATS" then
                addon.db.global.stats = pending.stats
                addon.db.global.joinstats = pending.joinstats
                addon.db.global.altStats = pending.altStats
                addon.db.global.housestats = pending.housestats
                if CrossGambling["stats"] then
                    CrossGambling["stats"] = addon.db.global.stats
                end
            else
                addon.db.global.stats = pending.stats
                addon.db.global.deathrollStats = pending.deathrollStats
                addon.db.global.joinstats = pending.joinstats
                addon.db.global.altStats = pending.altStats
                addon.db.global.housestats = pending.housestats
                if CrossGambling["stats"] then
                    CrossGambling["stats"] = addon.db.global.stats
                end
            end
            addon.pendingStatsImport = nil
            addon:Print("Stats import complete.")
        end,
        OnCancel = function()
            addon.pendingStatsImport = nil
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

function CrossGambling:joinStats(info, args)
    local mainname, altname = string.match(args, "^(%S+)%s+(%S+)$")
    if not mainname or not altname then
        DEFAULT_CHAT_FRAME:AddMessage("Invalid format. Use: <mainname> <altname>")
        return
    end

    self.db.global.altStats = self.db.global.altStats or {}

    local storedMainName = getKnownPlayerName(self, mainname)
    local storedAltName = getKnownPlayerName(self, altname)
    local normalizedMainName = self:NormalizePlayerName(storedMainName, true)
    local normalizedAltName = self:NormalizePlayerName(storedAltName, true)

    if normalizedMainName == normalizedAltName then
        DEFAULT_CHAT_FRAME:AddMessage("Main and alt cannot be the same character.")
        return
    end

    local altStats = {
        displayName = storedAltName,
        stats = self.db.global.stats[storedAltName] or 0,
        deathrollStats = self.db.global.deathrollStats[storedAltName] or 0,
    }
    self.db.global.altStats[normalizedAltName] = altStats

    self.db.global.stats[storedMainName] = self.db.global.stats[storedMainName] or 0
    self.db.global.deathrollStats[storedMainName] = self.db.global.deathrollStats[storedMainName] or 0

    self.db.global.stats[storedMainName] = self.db.global.stats[storedMainName] + altStats.stats
    self.db.global.deathrollStats[storedMainName] = self.db.global.deathrollStats[storedMainName] + altStats.deathrollStats

    self.db.global.joinstats = self.db.global.joinstats or {}
    self.db.global.joinstats[normalizedAltName] = storedMainName

    self.db.global.stats[storedAltName] = nil
    self.db.global.deathrollStats[storedAltName] = nil

    self.db.global.mergeAudit = self.db.global.mergeAudit or {}
    self.db.global.mergeAudit[normalizedAltName] = {
        mainname = storedMainName,
        statsAdded = altStats.stats,
        deathrollStatsAdded = altStats.deathrollStats,
        timestamp = time()
    }
	
    self:AddAuditEntry({
        action = "joinStats",
        mainname = storedMainName,
        altname = storedAltName,
        statsAdded = altStats.stats,
        deathrollStatsAdded = altStats.deathrollStats,
        timestamp = time()
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("Joined alt '%s' to main '%s'", storedAltName, storedMainName))
end


function CrossGambling:unjoinStats(info, altname)
    if not altname or altname == "" then
        for alt, main in pairs(self.db.global.joinstats or {}) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Currently joined: alt '%s' -> main '%s'", alt, main))
        end
        return
    end

    local normalizedAltName = self:NormalizePlayerName(altname, true)
    local mainname = self.db.global.joinstats[normalizedAltName]
    if not mainname then
        DEFAULT_CHAT_FRAME:AddMessage("Alt is not joined to any main.")
        return
    end

    local altStats = self.db.global.altStats and self.db.global.altStats[normalizedAltName]
    if not altStats then
        DEFAULT_CHAT_FRAME:AddMessage("No saved stats found for alt.")
        return
    end

    self.db.global.stats[mainname] = (self.db.global.stats[mainname] or 0) - altStats.stats
    self.db.global.deathrollStats[mainname] = (self.db.global.deathrollStats[mainname] or 0) - altStats.deathrollStats

    local restoredAltName = altStats.displayName or getKnownPlayerName(self, altname)
    self.db.global.stats[restoredAltName] = altStats.stats
    self.db.global.deathrollStats[restoredAltName] = altStats.deathrollStats

    self.db.global.joinstats[normalizedAltName] = nil
    self.db.global.altStats[normalizedAltName] = nil

    self.db.global.mergeAudit = self.db.global.mergeAudit or {}
    self.db.global.mergeAudit[normalizedAltName .. "_unmerged_" .. time()] = {
        action = "unmerge",
        mainname = mainname,
        statsRemoved = altStats.stats,
        deathrollStatsRemoved = altStats.deathrollStats,
        timestamp = time()
    }

    self:AddAuditEntry({
        action = "unjoinStats",
        mainname = mainname,
        altname = restoredAltName,
        pointsRemoved = altStats.stats,
        deathrollStatsRemoved = altStats.deathrollStats,
        timestamp = time()
    })

    DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s' from main '%s'", restoredAltName, mainname))
end

function CrossGambling:reportStats(full)
    local lines = {
        "-- CrossGambling All Time Stats --",
        string.format("The house has taken %s total.", (self.db.global.housestats or 0))
    }

    local combinedStats = combineStatsByMain(self, self.db.global.stats)

    if next(combinedStats) == nil then
        table.insert(lines, "No stats to report.")
        sendChatLinesInBatches(self, lines)
        return
    end

    local sortedStats = {}
    for mainName, totalAmount in pairs(combinedStats) do
        table.insert(sortedStats, {name = mainName, amount = totalAmount})
    end
    table.sort(sortedStats, function(a, b) return a.amount > b.amount end)

    local winners, losers = {}, {}
    for _, stat in ipairs(sortedStats) do
        if stat.amount > 0 then table.insert(winners, stat) else table.insert(losers, stat) end
    end

    if full then
        for k, v in ipairs(sortedStats) do
            local sortsign = v.amount < 0 and "lost" or "won"
            local statMessage = string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount))
            table.insert(lines, statMessage)
        end
        sendChatLinesInBatches(self, lines)
        return
    end

    sendChatLine(self, lines[1])
    sendChatLine(self, lines[2])
    SendChatMessage("-- Top 3 Winners --", self.game.chatMethod)
		for i = 1, math.min(3, #winners) do
			SendChatMessage(string.format("%d. %s won %d total", i, winners[i].name, math.abs(winners[i].amount)), self.game.chatMethod)
		end

		table.sort(losers, function(a, b)
			return a.amount < b.amount
		end)

		SendChatMessage("-- Top 3 Losers --", self.game.chatMethod)
		for i = 1, math.min(3, #losers) do
			SendChatMessage(string.format("%d. %s lost %d total", i, losers[i].name, math.abs(losers[i].amount)), self.game.chatMethod)
		end

end

function CrossGambling:ExportStatsText(exportType)
    return createStatsExport(self, exportType)
end

function CrossGambling:ImportStatsText(text)
    local imported, errorMessage, counts = parseStatsExport(text)
    if not imported then
        self:Print("Stats import failed: " .. (errorMessage or "Invalid export text."))
        return false
    end

    self.pendingStatsImport = imported
    ensureStatsImportDialog(self)
    StaticPopup_Show("CG_IMPORT_STATS")

    if counts then
        self:Print(string.format(
            "Ready to import %s: %d stats, %d deathroll stats, %d session stats, %d joined alts, and %d saved alt records.",
            imported.dataset or "FULL",
            counts.stats or 0,
            counts.deathrollStats or 0,
            counts.sessionStats or 0,
            counts.joinstats or 0,
            counts.altStats or 0
        ))
    end

    return true
end

function CrossGambling:ShowStatsTransferFrame(mode)
    mode = mode == "import" and "import" or "export"
    local slick = isSlickTheme(self)

    if self.statsTransferFrame and self.statsTransferFrame.isSlick ~= slick then
        self.statsTransferFrame:Hide()
        self.statsTransferFrame = nil
    end

    if not self.statsTransferFrame then
        local frame = CreateFrame("Frame", "CrossGamblingStatsTransferFrame", UIParent, slick and "BackdropTemplate" or "BasicFrameTemplateWithInset")
        frame:SetSize(620, 430)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetUserPlaced(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame.addon = self
        frame.exportType = "all"
        frame.isSlick = slick

        if slick then
            ensureBackdrop(frame)
            frame:SetBackdrop(TRANSFER_BACKDROP)
            frame:SetBackdropBorderColor(0, 0, 0)
            if CGTheme and CGTheme._frameColor then
                frame:SetBackdropColor(CGTheme._frameColor.r, CGTheme._frameColor.g, CGTheme._frameColor.b)
            end
            if CGTheme and CGTheme.RegisterFrame then
                CGTheme:RegisterFrame(frame)
            end
        end

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", frame, "TOP", 0, -7)
        if slick then
            styleTransferFont(title)
        end
        frame.title = title

        function frame:RefreshExportText()
            local exportTitle = self.exportType == "deathroll" and "Deathrolls"
                or self.exportType == "session" and "Session Stats"
                or "All Stats"
            local exportText = self.addon:ExportStatsText(self.exportType)
            self.title:SetText("CrossGambling Export Stats - " .. exportTitle)
            self.editBox:SetText(exportText)
            self.editBox:SetCursorPosition(0)
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        end

        local allStatsButton = createTransferButton(frame, "All Stats", 110, 24, slick)
        allStatsButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -34)
        allStatsButton:SetScript("OnClick", function()
            frame.exportType = "all"
            frame.mode = "export"
            frame:RefreshExportText()
        end)

        local deathrollButton = createTransferButton(frame, "Deathrolls", 110, 24, slick)
        deathrollButton:SetPoint("LEFT", allStatsButton, "RIGHT", 8, 0)
        deathrollButton:SetScript("OnClick", function()
            frame.exportType = "deathroll"
            frame.mode = "export"
            frame:RefreshExportText()
        end)

        local sessionButton = createTransferButton(frame, "Session Stats", 110, 24, slick)
        sessionButton:SetPoint("LEFT", deathrollButton, "RIGHT", 8, 0)
        sessionButton:SetScript("OnClick", function()
            frame.exportType = "session"
            frame.mode = "export"
            frame:RefreshExportText()
        end)

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -66)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 52)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetSize(540, 320)
        editBox:SetTextInsets(4, 4, 4, 4)
        if slick then
            styleTransferFont(editBox)
        end
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        editBox:SetScript("OnTextChanged", function(self)
            local parent = self:GetParent()
            if parent and parent.UpdateScrollChildRect then
                parent:UpdateScrollChildRect()
            end
        end)
        scrollFrame:SetScrollChild(editBox)
        frame.editBox = editBox

        local exportButton = createTransferButton(frame, "Export", 110, 24, slick)
        exportButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 16)
        exportButton:SetScript("OnClick", function()
            frame.mode = "export"
            frame:RefreshExportText()
        end)

        local importButton = createTransferButton(frame, "Import", 110, 24, slick)
        importButton:SetPoint("LEFT", exportButton, "RIGHT", 8, 0)
        importButton:SetScript("OnClick", function()
            frame.addon:ImportStatsText(frame.editBox:GetText())
        end)

        local closeButton = createTransferButton(frame, "Close", 110, 24, slick)
        closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 16)
        closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        self.statsTransferFrame = frame
    end

    local frame = self.statsTransferFrame
    frame.mode = mode
    frame.exportType = frame.exportType or "all"

    if mode == "export" then
        frame:RefreshExportText()
    else
        frame.title:SetText("CrossGambling Import Stats")
        frame.editBox:SetText("")
        frame.editBox:SetFocus()
    end

    frame:Show()
end

function CrossGambling:getMainName(playerName)
    local normalizedPlayerName = self:NormalizePlayerName(playerName, true)
    local mainName = self.db.global.joinstats[normalizedPlayerName] or playerName
    return getKnownPlayerName(self, mainName)
end

function CrossGambling:reportSessionStats()
    SendChatMessage("-- Current Session Stats --", self.game.chatMethod)

    local sessionSortlist = self:sortStats(self.game.sessionStats or {})
    if #sessionSortlist == 0 then
        SendChatMessage("No stats available for the current session.", self.game.chatMethod)
    else
        self:reportSortedStats(sessionSortlist, "Current Session")
    end
end

function CrossGambling:reportSortedStats(sortlist, title)
    for k, v in ipairs(sortlist) do
        local sortsign = v.amount < 0 and "lost" or "won"
        SendChatMessage(string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount)), self.game.chatMethod)
    end
end

function CrossGambling:sortStats(stats)
    local sortedStats = {}
    for name, amount in pairs(stats or {}) do
        table.insert(sortedStats, {name = name, amount = amount})
    end
    table.sort(sortedStats, function(a, b) return a.amount > b.amount end)
    return sortedStats
end

function CrossGambling:updatePlayerStat(playerName, amount, isDeathroll)
    local storedPlayerName = getKnownPlayerName(self, playerName)
    self.game.sessionStats[storedPlayerName] = (self.game.sessionStats[storedPlayerName] or 0) + amount
    self.db.global.stats[storedPlayerName] = (self.db.global.stats[storedPlayerName] or 0) + amount
    if isDeathroll then
        local storedDeathrollName = getKnownPlayerName(self, storedPlayerName)
        self.db.global.deathrollStats[storedDeathrollName] = (self.db.global.deathrollStats[storedDeathrollName] or 0) + amount
    end
end

function CrossGambling:reportDeathrollStats()
    SendChatMessage("-- Deathroll Stats --", self.game.chatMethod)
    local deathrollSortlist = self:sortStats(combineStatsByMain(self, self.db.global.deathrollStats))
    if #deathrollSortlist == 0 then
        SendChatMessage("No stats available for Deathrolls.", self.game.chatMethod)
    else
        self:reportSortedStats(deathrollSortlist, "Deathrolls")
    end
end

function CrossGambling:listAlts(info)
    for altname, mainname in pairs(self.db.global.joinstats or {}) do
        local altStats = self.db.global.altStats and self.db.global.altStats[altname]
        local displayAltName = (altStats and altStats.displayName) or altname
        self:Print("[main] " .. mainname .. " is merged with [alt] " .. displayAltName)
    end
end

function CrossGambling:updateStat(info, args)
    local player, amountStr = strsplit(" ", args)
    local amount = tonumber(amountStr)

    if player and amount then
        local storedPlayerName = getKnownPlayerName(self, player)
        local oldAmount = self.db.global.stats[storedPlayerName] or 0
        self:updatePlayerStat(storedPlayerName, amount)
        local newAmount = self.db.global.stats[storedPlayerName] or 0
		
        self:AddAuditEntry({
            action = "updateStat",
            player = storedPlayerName,
            oldAmount = oldAmount,
            addedAmount = amount,
            newAmount = newAmount,
            timestamp = time()
        })

        self:Print(string.format("Successfully updated stats for %s (%d -> %d), added %d", storedPlayerName, oldAmount, newAmount, amount))
    else
        self:Print("Invalid input for updating stats.")
    end
end


function CrossGambling:deleteStat(info, player)
    local storedStatName = getKnownPlayerName(self, player)
    local storedDeathrollName = getKnownPlayerName(self, player)
    local oldStats = self.db.global.stats[storedStatName] or 0
    local oldDeathrollStats = self.db.global.deathrollStats[storedDeathrollName] or 0
    self.db.global.stats[storedStatName] = nil
    self.db.global.deathrollStats[storedDeathrollName] = nil
    self.db.global.joinstats[self:NormalizePlayerName(player, true)] = nil
    if self.db.global.altStats then
        self.db.global.altStats[self:NormalizePlayerName(player, true)] = nil
    end
    self:AddAuditEntry({
        action = "deleteStat",
        player = storedStatName,
        oldAmount = oldStats,
        oldDeathrollAmount = oldDeathrollStats,
        timestamp = time()
    })
    self:Print("Successfully removed stats for " .. storedStatName .. ".")
end

function CrossGambling:resetStats(info)
    local statsCount = 0
    local deathrollCount = 0
    local linkedAltCount = 0
    for _ in pairs(self.db.global.stats or {}) do statsCount = statsCount + 1 end
    for _ in pairs(self.db.global.deathrollStats or {}) do deathrollCount = deathrollCount + 1 end
    for _ in pairs(self.db.global.joinstats or {}) do linkedAltCount = linkedAltCount + 1 end

    self.db.global.stats = {}
    self.db.global.joinstats = {}
    self.db.global.deathrollStats = {}
    self.db.global.altStats = {}
    self.db.global.mergeAudit = {}
    self.game.sessionStats = {}
    self:AddAuditEntry({
        action = "resetStats",
        statsCount = statsCount,
        deathrollCount = deathrollCount,
        linkedAltCount = linkedAltCount,
        timestamp = time()
    })
    self:Print("All stats have been reset.")
end
