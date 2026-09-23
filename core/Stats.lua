local function normalizePlayerNameLocal(addon, name, preserveRealm)
    return addon:NormalizePlayerName(name, preserveRealm)
end

local function getStoredName(statsTable, name)
    local normalized = normalizePlayerNameLocal(CrossGambling, name, true)
    if not normalized then
        return nil
    end

    for existingName in pairs(statsTable or {}) do
        if normalizePlayerNameLocal(CrossGambling, existingName, true) == normalized then
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
local STATS_EXPORT_VERSION = "CrossGamblingStatsExport;6"
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

local function refreshHistoryProfileOption()
    if CGOptions and type(CGOptions.RefreshHistoryProfile) == "function" then
        CGOptions:RefreshHistoryProfile()
    end
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

local function styleTransferButton(button, smallFont)
    ensureBackdrop(button)
    button:SetBackdrop(TRANSFER_BACKDROP)
    button:SetBackdropBorderColor(0, 0, 0)
    if CGTheme and CGTheme._buttonColor then
        button:SetBackdropColor(CGTheme._buttonColor.r, CGTheme._buttonColor.g, CGTheme._buttonColor.b)
    end

    local fontString = button:GetFontString()
    if not fontString then
        fontString = button:CreateFontString(nil, "OVERLAY", smallFont and "GameFontNormalSmall" or "GameFontNormal")
        button:SetFontString(fontString)
    end
    fontString:SetAllPoints(button)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")

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

local function createTransferButton(parent, text, width, height, slick, smallFont)
    local button = CreateFrame("Button", nil, parent, slick and "BackdropTemplate" or "UIPanelButtonTemplate")
    button:SetSize(width, height)
    if slick then
        styleTransferButton(button, smallFont)
    else
        button:SetNormalFontObject("GameFontNormal")
        if smallFont then
            local fontString = button:GetFontString()
            if fontString then
                local path, _, flags = fontString:GetFont()
                fontString:SetFont(path, 10, flags)
            end
        end
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

local function appendModeStatLines(lines, modeStats)
    local count = 0
    for _, modeName in ipairs(sortedKeys(modeStats)) do
        for _, playerName in ipairs(sortedKeys(modeStats[modeName])) do
            table.insert(lines, string.format("MODESTAT;%s;%s;%s", modeName, playerName, tostring(modeStats[modeName][playerName] or 0)))
            count = count + 1
        end
    end
    return count
end

local function copyStats(source)
    local destination = {}
    for name, amount in pairs(source or {}) do
        destination[name] = amount
    end
    return destination
end

local function copyModeStats(source)
    local destination = {}
    for modeName, stats in pairs(source or {}) do
        destination[modeName] = copyStats(stats)
    end
    return destination
end

local function appendPlayerCardLines(lines, playerCardStats)
    for _, playerName in ipairs(sortedKeys(playerCardStats)) do
        local record = playerCardStats[playerName] or {}
        table.insert(lines, string.format(
            "CARD;%s;%s;%s;%s;%s;%s;%s;%s;%s",
            playerName,
            tostring(record.games or 0),
            tostring(record.wins or 0),
            tostring(record.losses or 0),
            tostring(record.pushes or 0),
            tostring(record.streak or 0),
            tostring(record.bestWinStreak or 0),
            tostring(record.bestLossStreak or 0),
            tostring(record.lastPlayed or 0)
        ))
        for _, modeName in ipairs(sortedKeys(record.modes)) do
            local mode = record.modes[modeName] or {}
            table.insert(lines, string.format(
                "CARDMODE;%s;%s;%s;%s;%s;%s",
                playerName,
                modeName,
                tostring(mode.games or 0),
                tostring(mode.wins or 0),
                tostring(mode.losses or 0),
                tostring(mode.pushes or 0)
            ))
        end
    end
end

local function appendProfileLines(lines, profiles, activeName)
    if activeName then
        table.insert(lines, "ACTIVEPROFILE;" .. activeName)
    end

    for _, profileName in ipairs(sortedKeys(profiles)) do
        local profile = profiles[profileName] or {}
        table.insert(lines, string.format(
            "PROFILE;%s;%s;%s;%s",
            profileName,
            tostring(profile.createdAt or 0),
            tostring(profile.updatedAt or 0),
            tostring(profile.housestats or 0)
        ))
        for _, playerName in ipairs(sortedKeys(profile.stats)) do
            table.insert(lines, string.format("PROFILESTAT;%s;%s;%s", profileName, playerName, tostring(profile.stats[playerName] or 0)))
        end
        for _, playerName in ipairs(sortedKeys(profile.deathrollStats)) do
            table.insert(lines, string.format("PROFILEDEATH;%s;%s;%s", profileName, playerName, tostring(profile.deathrollStats[playerName] or 0)))
        end
        for _, modeName in ipairs(sortedKeys(profile.modeStats)) do
            for _, playerName in ipairs(sortedKeys(profile.modeStats[modeName])) do
                table.insert(lines, string.format("PROFILEMODE;%s;%s;%s;%s", profileName, modeName, playerName, tostring(profile.modeStats[modeName][playerName] or 0)))
            end
        end
    end
end

local function createStatsExport(addon, exportType)
    exportType = exportType or "all"
    local global = (addon.db and addon.db.global) or {}
    local lines = {
        STATS_EXPORT_VERSION,
    }

    local modeKey = exportType:match("^mode:(.+)$")

    if modeKey then
        table.insert(lines, "DATASET;MODE:" .. modeKey)
        local modeData = (global.modeStats and global.modeStats[modeKey]) or {}
        local count = 0
        for _, playerName in ipairs(sortedKeys(modeData)) do
            table.insert(lines, string.format("MODESTAT;%s;%s;%s", modeKey, playerName, tostring(modeData[playerName] or 0)))
            count = count + 1
        end
        if count == 0 then
            table.insert(lines, "NOTE;No stats to export for " .. modeKey)
        end
        return table.concat(lines, "\n")
    elseif exportType == "deathroll" then
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

    appendModeStatLines(lines, global.modeStats or {})
    appendPlayerCardLines(lines, global.playerCardStats or {})
    appendProfileLines(lines, global.statProfiles or {}, global.activeStatProfile)

    return table.concat(lines, "\n")
end

local function parseStatsExport(text)
    local imported = {
        stats = {},
        deathrollStats = {},
        sessionStats = {},
        joinstats = {},
        altStats = {},
        modeStats = {},
        playerCardStats = {},
        statProfiles = nil,
        activeStatProfile = nil,
        housestats = 0,
        dataset = "FULL",
    }
    local counts = {
        stats = 0,
        deathrollStats = 0,
        sessionStats = 0,
        joinstats = 0,
        altStats = 0,
        modeStats = 0,
        playerCardStats = 0,
        statProfiles = 0,
    }

    local sawVersion = false
    for line in (text or ""):gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local fields = splitExportFields(line)
            local recordType = fields[1]

            if recordType == "CrossGamblingStatsExport" then
                sawVersion = true
                if fields[2] ~= "1" and fields[2] ~= "2" and fields[2] ~= "3" and fields[2] ~= "4" and fields[2] ~= "5" and fields[2] ~= "6" then
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
            elseif recordType == "MODESTAT" then
                local modeName = fields[2]
                local playerName = fields[3]
                local amount = tonumber(fields[4])
                if not modeName or modeName == "" or not playerName or playerName == "" or not amount then
                    return nil, "Invalid MODESTAT line."
                end

                imported.modeStats[modeName] = imported.modeStats[modeName] or {}
                imported.modeStats[modeName][playerName] = amount
                counts.modeStats = counts.modeStats + 1
            elseif recordType == "CARD" then
                local playerName = fields[2]
                local games = tonumber(fields[3])
                local wins = tonumber(fields[4])
                local losses = tonumber(fields[5])
                local pushes = tonumber(fields[6])
                local streak = tonumber(fields[7])
                local bestWinStreak = tonumber(fields[8])
                local bestLossStreak = tonumber(fields[9])
                local lastPlayed = tonumber(fields[10])
                if not playerName or playerName == "" or not games or not wins or not losses or not pushes or not streak or not bestWinStreak or not bestLossStreak or not lastPlayed then
                    return nil, "Invalid CARD line."
                end
                imported.playerCardStats[playerName] = {
                    games = games,
                    wins = wins,
                    losses = losses,
                    pushes = pushes,
                    streak = streak,
                    bestWinStreak = bestWinStreak,
                    bestLossStreak = bestLossStreak,
                    lastPlayed = lastPlayed > 0 and lastPlayed or nil,
                    modes = {},
                }
                counts.playerCardStats = counts.playerCardStats + 1
            elseif recordType == "CARDMODE" then
                local playerName = fields[2]
                local modeName = fields[3]
                local games = tonumber(fields[4])
                local wins = tonumber(fields[5])
                local losses = tonumber(fields[6])
                local pushes = tonumber(fields[7])
                if not playerName or playerName == "" or not modeName or modeName == "" or not games or not wins or not losses or not pushes then
                    return nil, "Invalid CARDMODE line."
                end
                imported.playerCardStats[playerName] = imported.playerCardStats[playerName] or { modes = {} }
                imported.playerCardStats[playerName].modes = imported.playerCardStats[playerName].modes or {}
                imported.playerCardStats[playerName].modes[modeName] = {
                    games = games,
                    wins = wins,
                    losses = losses,
                    pushes = pushes,
                }
            elseif recordType == "ACTIVEPROFILE" then
                if not fields[2] or fields[2] == "" then
                    return nil, "Invalid ACTIVEPROFILE line."
                end
                imported.activeStatProfile = fields[2]
            elseif recordType == "PROFILE" then
                local profileName = fields[2]
                if not profileName or profileName == "" then
                    return nil, "Invalid PROFILE line."
                end
                imported.statProfiles = imported.statProfiles or {}
                imported.statProfiles[profileName] = imported.statProfiles[profileName] or {
                    stats = {}, deathrollStats = {}, modeStats = {},
                }
                local profile = imported.statProfiles[profileName]
                profile.createdAt = tonumber(fields[3]) or 0
                profile.updatedAt = tonumber(fields[4]) or 0
                profile.housestats = tonumber(fields[5]) or 0
                counts.statProfiles = counts.statProfiles + 1
            elseif recordType == "PROFILESTAT" or recordType == "PROFILEDEATH" then
                local profileName, playerName = fields[2], fields[3]
                local amount = tonumber(fields[4])
                if not profileName or profileName == "" or not playerName or playerName == "" or not amount then
                    return nil, "Invalid " .. recordType .. " line."
                end
                imported.statProfiles = imported.statProfiles or {}
                imported.statProfiles[profileName] = imported.statProfiles[profileName] or { stats = {}, deathrollStats = {}, modeStats = {} }
                local destination = recordType == "PROFILESTAT" and imported.statProfiles[profileName].stats or imported.statProfiles[profileName].deathrollStats
                destination[playerName] = amount
            elseif recordType == "PROFILEMODE" then
                local profileName, modeName, playerName = fields[2], fields[3], fields[4]
                local amount = tonumber(fields[5])
                if not profileName or profileName == "" or not modeName or modeName == "" or not playerName or playerName == "" or not amount then
                    return nil, "Invalid PROFILEMODE line."
                end
                imported.statProfiles = imported.statProfiles or {}
                imported.statProfiles[profileName] = imported.statProfiles[profileName] or { stats = {}, deathrollStats = {}, modeStats = {} }
                local profile = imported.statProfiles[profileName]
                profile.modeStats[modeName] = profile.modeStats[modeName] or {}
                profile.modeStats[modeName][playerName] = amount
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

            local modeKey = pending.dataset and pending.dataset:match("^MODE:(.+)$")

            if modeKey then
                addon.db.global.modeStats = addon.db.global.modeStats or {}
                addon.db.global.modeStats[modeKey] = (pending.modeStats and pending.modeStats[modeKey]) or {}
            elseif pending.dataset == "DEATHROLL" then
                addon.db.global.deathrollStats = pending.deathrollStats
            elseif pending.dataset == "SESSION" then
                addon.game = addon.game or {}
                addon.game.sessionStats = pending.sessionStats
            elseif pending.dataset == "ALL_STATS" then
                addon.db.global.stats = pending.stats
                addon.db.global.joinstats = pending.joinstats
                addon.db.global.altStats = pending.altStats
                addon.db.global.housestats = pending.housestats
                addon.db.global.modeStats = pending.modeStats
                addon.db.global.playerCardStats = pending.playerCardStats
                if pending.statProfiles then
                    addon.db.global.statProfiles = pending.statProfiles
                    addon.db.global.activeStatProfile = pending.activeStatProfile
                    addon.db.global.statProfilesInitialized = true
                end
            else
                addon.db.global.stats = pending.stats
                addon.db.global.deathrollStats = pending.deathrollStats
                addon.db.global.joinstats = pending.joinstats
                addon.db.global.altStats = pending.altStats
                addon.db.global.housestats = pending.housestats
                addon.db.global.modeStats = pending.modeStats
                addon.db.global.playerCardStats = pending.playerCardStats
                if pending.statProfiles then
                    addon.db.global.statProfiles = pending.statProfiles
                    addon.db.global.activeStatProfile = pending.activeStatProfile
                    addon.db.global.statProfilesInitialized = true
                end
            end
            addon:EnsureStatProfiles()
            refreshHistoryProfileOption()
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
    local normalizedMainName = normalizePlayerNameLocal(self, storedMainName, true)
    local normalizedAltName = normalizePlayerNameLocal(self, storedAltName, true)

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

    local normalizedAltName = normalizePlayerNameLocal(self, altname, true)
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
    sendChatLine(self, "-- Top 3 Winners --")
		for i = 1, math.min(3, #winners) do
			sendChatLine(self, string.format("%d. %s won %d total", i, winners[i].name, math.abs(winners[i].amount)))
		end

		table.sort(losers, function(a, b)
			return a.amount < b.amount
		end)

		sendChatLine(self, "-- Top 3 Losers --")
		for i = 1, math.min(3, #losers) do
			sendChatLine(self, string.format("%d. %s lost %d total", i, losers[i].name, math.abs(losers[i].amount)))
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
            "Ready to import %s: %d stats, %d deathroll stats, %d session stats, %d mode stats, %d joined alts, %d saved alt records, %d player cards, and %d history profiles.",
            imported.dataset or "FULL",
            counts.stats or 0,
            counts.deathrollStats or 0,
            counts.sessionStats or 0,
            counts.modeStats or 0,
            counts.joinstats or 0,
            counts.altStats or 0,
            counts.playerCardStats or 0,
            counts.statProfiles or 0
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
        frame:SetSize(700, 480)
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
        frame.datasetButtons = {}

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

        local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        modeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -62)
        modeLabel:SetText("By Game Mode:")
        if slick then
            styleTransferFont(modeLabel)
        end

        function frame:RefreshExportText()
            local exportTitle
            local modeKey = self.exportType:match("^mode:(.+)$")
            if modeKey then
                exportTitle = modeKey
            elseif self.exportType == "deathroll" then
                exportTitle = "Deathrolls"
            elseif self.exportType == "session" then
                exportTitle = "Session Stats"
            else
                exportTitle = "All Stats"
            end

            local exportText = self.addon:ExportStatsText(self.exportType)
            self.title:SetText("CrossGambling Export Stats - " .. exportTitle)
            self.editBox:SetText(exportText)
            self.editBox:SetCursorPosition(0)
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        end

        function frame:SetActiveDatasetButton(activeBtn)
            for _, btn in ipairs(self.datasetButtons) do
                if btn == activeBtn then
                    btn:LockHighlight()
                else
                    btn:UnlockHighlight()
                end
            end
        end

        local function addDatasetButton(label, exportType, width, height, setPoint, smallFont)
            local btn = createTransferButton(frame, label, width, height, slick, smallFont)
            setPoint(btn)
            btn:SetScript("OnClick", function()
                frame.exportType = exportType
                frame.mode = "export"
                frame:RefreshExportText()
                frame:SetActiveDatasetButton(btn)
            end)
            table.insert(frame.datasetButtons, btn)
            return btn
        end

        local allStatsButton = addDatasetButton("All Stats", "all", 110, 24, function(btn)
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -34)
        end)
        local deathrollButton = addDatasetButton("Deathrolls", "deathroll", 110, 24, function(btn)
            btn:SetPoint("LEFT", allStatsButton, "RIGHT", 8, 0)
        end)
        addDatasetButton("Session Stats", "session", 110, 24, function(btn)
            btn:SetPoint("LEFT", deathrollButton, "RIGHT", 8, 0)
        end)

        local previousModeButton
        for _, modeName in ipairs(self.modeListOrder or {}) do
            local anchor = previousModeButton
            previousModeButton = addDatasetButton(modeName, "mode:" .. modeName, 100, 22, function(btn)
                if anchor then
                    btn:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
                else
                    btn:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -6)
                end
            end, true)
        end

        frame:SetActiveDatasetButton(allStatsButton)

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -114)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 52)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetSize(620, 320)
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

function CrossGambling:NormalizeStatProfileName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if name == "" then
        return nil, "Enter a profile name."
    end
    if #name > 32 then
        return nil, "Profile names can be up to 32 characters."
    end
    if name:find("[;|\r\n\t]") or name:find("[%c]") then
        return nil, "Profile names cannot contain separators or control characters."
    end
    return name
end

function CrossGambling:EnsureStatProfiles()
    if not self.db or not self.db.global then
        return
    end

    local global = self.db.global
    global.statProfiles = type(global.statProfiles) == "table" and global.statProfiles or {}

    for profileName, profile in pairs(global.statProfiles) do
        if type(profileName) ~= "string" or type(profile) ~= "table" then
            global.statProfiles[profileName] = nil
        else
            profile.stats = type(profile.stats) == "table" and profile.stats or {}
            profile.deathrollStats = type(profile.deathrollStats) == "table" and profile.deathrollStats or {}
            profile.modeStats = type(profile.modeStats) == "table" and profile.modeStats or {}
            profile.housestats = tonumber(profile.housestats) or 0
            profile.createdAt = tonumber(profile.createdAt) or time()
            profile.updatedAt = tonumber(profile.updatedAt) or profile.createdAt
        end
    end

    if next(global.statProfiles) == nil then
        local now = time()
        local migrateExisting = global.statProfilesInitialized ~= true
        global.statProfiles.General = {
            stats = migrateExisting and copyStats(global.stats) or {},
            deathrollStats = migrateExisting and copyStats(global.deathrollStats) or {},
            modeStats = migrateExisting and copyModeStats(global.modeStats) or {},
            housestats = migrateExisting and (tonumber(global.housestats) or 0) or 0,
            createdAt = now,
            updatedAt = now,
        }
    end
    global.statProfilesInitialized = true

    local activeName = global.activeStatProfile
    if not activeName or not global.statProfiles[activeName] then
        activeName = global.statProfiles.General and "General" or next(global.statProfiles)
        global.activeStatProfile = activeName
    end
end

function CrossGambling:FindStatProfileName(name)
    self:EnsureStatProfiles()
    local normalized = self:NormalizeStatProfileName(name)
    if not normalized then
        return nil
    end
    local target = normalized:lower()
    for profileName in pairs(self.db.global.statProfiles) do
        if profileName:lower() == target then
            return profileName
        end
    end
end

function CrossGambling:GetActiveStatProfile()
    self:EnsureStatProfiles()
    local name = self.db.global.activeStatProfile
    return name, self.db.global.statProfiles[name]
end

function CrossGambling:CreateStatProfile(name)
    local normalized, errorMessage = self:NormalizeStatProfileName(name)
    if not normalized then
        self:Print(errorMessage)
        return false
    end

    self:EnsureStatProfiles()
    local existingName = self:FindStatProfileName(normalized)
    if existingName then
        self.db.global.activeStatProfile = existingName
        refreshHistoryProfileOption()
        self:Print("History profile selected: " .. existingName .. ".")
        return true
    end

    local now = time()
    self.db.global.statProfiles[normalized] = { stats = {}, deathrollStats = {}, modeStats = {}, housestats = 0, createdAt = now, updatedAt = now }
    self.db.global.activeStatProfile = normalized
    refreshHistoryProfileOption()
    self:Print("History profile created and selected: " .. normalized .. ".")
    return true
end

function CrossGambling:SetActiveStatProfile(name)
    local existingName = self:FindStatProfileName(name)
    if not existingName then
        self:Print("History profile not found: " .. tostring(name) .. ".")
        return false
    end
    self.db.global.activeStatProfile = existingName
    refreshHistoryProfileOption()
    self:Print("History profile selected: " .. existingName .. ".")
    return true
end

function CrossGambling:ResetStatProfile(name)
    local existingName = self:FindStatProfileName(name)
    if not existingName then
        return false
    end
    local profile = self.db.global.statProfiles[existingName]
    profile.stats = {}
    profile.deathrollStats = {}
    profile.modeStats = {}
    profile.housestats = 0
    profile.updatedAt = time()
    self:Print("History profile reset: " .. existingName .. ".")
    return true
end

function CrossGambling:DeleteStatProfile(name)
    local existingName = self:FindStatProfileName(name)
    if not existingName then
        return false
    end
    self.db.global.statProfiles[existingName] = nil
    self.db.global.activeStatProfile = nil
    self:EnsureStatProfiles()
    refreshHistoryProfileOption()
    self:Print("History profile deleted: " .. existingName .. ". Active profile: " .. self.db.global.activeStatProfile .. ".")
    return true
end

function CrossGambling:UpdateActiveStatProfile(playerName, amount, modeName)
    local _, profile = self:GetActiveStatProfile()
    profile.stats[playerName] = (profile.stats[playerName] or 0) + amount
    if modeName == "1v1DeathRoll" then
        profile.deathrollStats[playerName] = (profile.deathrollStats[playerName] or 0) + amount
    end
    if modeName then
        profile.modeStats[modeName] = profile.modeStats[modeName] or {}
        profile.modeStats[modeName][playerName] = (profile.modeStats[modeName][playerName] or 0) + amount
    end
    profile.updatedAt = time()
end

function CrossGambling:reportStatProfile(name)
    local existingName = name and self:FindStatProfileName(name) or self.db.global.activeStatProfile
    if not existingName then
        self:Print("History profile not found.")
        return
    end
    local profile = self.db.global.statProfiles[existingName]
    sendChatLine(self, "-- History Profile: " .. existingName .. " --")
    sendChatLine(self, string.format("The house has taken %s total.", self:addCommas(profile.housestats or 0)))
    local sorted = self:sortStats(combineStatsByMain(self, profile.stats))
    if #sorted == 0 then
        sendChatLine(self, "No stats available for this profile.")
    else
        self:reportSortedStats(sorted, existingName)
    end
end

function CrossGambling:ShowStatProfilesFrame()
    local slick = isSlickTheme(self)
    if self.statProfilesFrame and self.statProfilesFrame.isSlick ~= slick then
        self.statProfilesFrame:Hide()
        self.statProfilesFrame:SetParent(nil)
        self.statProfilesFrame = nil
    end

    if not self.statProfilesFrame then
        local frame = CreateFrame("Frame", "CrossGamblingStatProfilesFrame", UIParent, slick and "BackdropTemplate" or "BasicFrameTemplateWithInset")
        frame:SetSize(430, 430)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetUserPlaced(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame.addon = self
        frame.isSlick = slick
        frame.page = 1
        frame.rows = {}

        if slick then
            ensureBackdrop(frame)
            frame:SetBackdrop(TRANSFER_BACKDROP)
            frame:SetBackdropBorderColor(0, 0, 0)
            frame:SetBackdropColor(CGTheme._frameColor.r, CGTheme._frameColor.g, CGTheme._frameColor.b)
            if CGTheme and CGTheme.RegisterFrame then CGTheme:RegisterFrame(frame) end
        end

        local title = frame:CreateFontString(nil, "OVERLAY", slick and "GameFontNormal" or "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, slick and 4 or -2)
        title:SetText("History Profiles")
        if slick then styleTransferFont(title) end

        if slick then
            local closeButton = createTransferButton(frame, "X", 22, 20, true, true)
            closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
            closeButton:SetScript("OnClick", function() frame:Hide() end)

            local headerLine = frame:CreateTexture(nil, "ARTWORK")
            headerLine:SetHeight(2)
            headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, -24)
            headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -24)
            headerLine:SetColorTexture(1, 0.82, 0, 0.62)
        end

        local activeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        activeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -42)
        if slick then styleTransferFont(activeLabel) end
        frame.activeLabel = activeLabel

        local help = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        help:SetPoint("TOPLEFT", activeLabel, "BOTTOMLEFT", 0, -6)
        help:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
        help:SetJustifyH("LEFT")
        help:SetText("New results are saved to the selected profile as well as Session and All-Time Stats.")
        if slick then styleTransferFont(help) end

        for index = 1, 8 do
            local row = createTransferButton(frame, "", 394, 24, slick, true)
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -86 - (index - 1) * 27)
            row:SetScript("OnClick", function(self)
                if self.profileName then
                    frame.addon:SetActiveStatProfile(self.profileName)
                    frame:Refresh()
                end
            end)
            frame.rows[index] = row
        end

        local previous = createTransferButton(frame, "Previous", 90, 22, slick, true)
        previous:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -306)
        previous:SetScript("OnClick", function()
            frame.page = math.max(1, frame.page - 1)
            frame:Refresh()
        end)
        frame.previous = previous

        local pageLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pageLabel:SetPoint("LEFT", previous, "RIGHT", 16, 0)
        if slick then styleTransferFont(pageLabel) end
        frame.pageLabel = pageLabel

        local nextButton = createTransferButton(frame, "Next", 90, 22, slick, true)
        nextButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -306)
        nextButton:SetScript("OnClick", function()
            frame.page = frame.page + 1
            frame:Refresh()
        end)
        frame.next = nextButton

        local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        input:SetSize(266, 24)
        input:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -340)
        input:SetAutoFocus(false)
        input:SetMaxLetters(32)
        input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        frame.input = input

        local createButton = createTransferButton(frame, "Create & Use", 116, 24, slick, true)
        createButton:SetPoint("LEFT", input, "RIGHT", 8, 0)
        createButton:SetScript("OnClick", function()
            if frame.addon:CreateStatProfile(input:GetText()) then
                input:SetText("")
                input:ClearFocus()
                frame.page = 1
                frame:Refresh()
            end
        end)
        input:SetScript("OnEnterPressed", function()
            createButton:Click()
        end)

        local reportButton = createTransferButton(frame, "Report", 92, 24, slick, true)
        reportButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
        reportButton:SetScript("OnClick", function() frame.addon:reportStatProfile() end)

        local resetButton = createTransferButton(frame, "Reset", 92, 24, slick, true)
        resetButton:SetPoint("LEFT", reportButton, "RIGHT", 8, 0)
        resetButton:SetScript("OnClick", function()
            frame.addon.pendingStatProfileReset = frame.addon.db.global.activeStatProfile
            StaticPopup_Show("CG_RESET_STAT_PROFILE", frame.addon.pendingStatProfileReset)
        end)

        local deleteButton = createTransferButton(frame, "Delete", 92, 24, slick, true)
        deleteButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
        deleteButton:SetScript("OnClick", function()
            frame.addon.pendingStatProfileDelete = frame.addon.db.global.activeStatProfile
            StaticPopup_Show("CG_DELETE_STAT_PROFILE", frame.addon.pendingStatProfileDelete)
        end)

        local closeButton = createTransferButton(frame, "Close", 92, 24, slick, true)
        closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
        closeButton:SetScript("OnClick", function() frame:Hide() end)

        function frame:Refresh()
            self.addon:EnsureStatProfiles()
            local names = sortedKeys(self.addon.db.global.statProfiles)
            local pages = math.max(1, math.ceil(#names / 8))
            self.page = math.min(math.max(1, self.page), pages)
            local activeName = self.addon.db.global.activeStatProfile
            self.activeLabel:SetText("Active: " .. activeName)
            self.pageLabel:SetText(string.format("Page %d of %d", self.page, pages))
            self.previous:SetEnabled(self.page > 1)
            self.next:SetEnabled(self.page < pages)
            local startIndex = (self.page - 1) * 8 + 1
            for rowIndex, row in ipairs(self.rows) do
                local profileName = names[startIndex + rowIndex - 1]
                row.profileName = profileName
                if profileName then
                    local profile = self.addon.db.global.statProfiles[profileName]
                    local playerCount = 0
                    for _ in pairs(profile.stats) do playerCount = playerCount + 1 end
                    row:SetText(string.format("%s%s  |  %d players", profileName == activeName and "> " or "", profileName, playerCount))
                    row:Show()
                    if profileName == activeName then row:LockHighlight() else row:UnlockHighlight() end
                else
                    row:Hide()
                end
            end
        end

        frame:SetScript("OnShow", function(self) self:Refresh() end)
        self.statProfilesFrame = frame
    end

    if not StaticPopupDialogs["CG_RESET_STAT_PROFILE"] then
        StaticPopupDialogs["CG_RESET_STAT_PROFILE"] = {
            text = "Reset all saved stats in history profile '%s'?",
            button1 = "Reset", button2 = "Cancel",
            OnAccept = function()
                local name = self.pendingStatProfileReset
                self.pendingStatProfileReset = nil
                if name then self:ResetStatProfile(name) end
                if self.statProfilesFrame then self.statProfilesFrame:Refresh() end
            end,
            OnCancel = function() self.pendingStatProfileReset = nil end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
    end
    if not StaticPopupDialogs["CG_DELETE_STAT_PROFILE"] then
        StaticPopupDialogs["CG_DELETE_STAT_PROFILE"] = {
            text = "Delete history profile '%s'? This cannot be undone.",
            button1 = "Delete", button2 = "Cancel",
            OnAccept = function()
                local name = self.pendingStatProfileDelete
                self.pendingStatProfileDelete = nil
                if name then self:DeleteStatProfile(name) end
                if self.statProfilesFrame then self.statProfilesFrame.page = 1; self.statProfilesFrame:Refresh() end
            end,
            OnCancel = function() self.pendingStatProfileDelete = nil end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
    end

    self.statProfilesFrame:Refresh()
    self.statProfilesFrame:Show()
    self.statProfilesFrame:Raise()
end

function CrossGambling:getMainName(playerName)
    local normalizedPlayerName = normalizePlayerNameLocal(self, playerName, true)
    local mainName = self.db.global.joinstats[normalizedPlayerName] or playerName
    return getKnownPlayerName(self, mainName)
end

function CrossGambling:reportSessionStats()
    sendChatLine(self, "-- Current Session Stats --")

    local sessionSortlist = self:sortStats(self.game.sessionStats or {})
    if #sessionSortlist == 0 then
        sendChatLine(self, "No stats available for the current session.")
    else
        self:reportSortedStats(sessionSortlist, "Current Session")
    end
end

function CrossGambling:reportSortedStats(sortlist, title)
    for k, v in ipairs(sortlist) do
        local sortsign = v.amount < 0 and "lost" or "won"
        sendChatLine(self, string.format("%d. %s %s %d total", k, v.name, sortsign, math.abs(v.amount)))
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

function CrossGambling:updatePlayerStat(playerName, amount, modeName)
    local storedPlayerName = getKnownPlayerName(self, playerName)
    self.game.sessionStats[storedPlayerName] = (self.game.sessionStats[storedPlayerName] or 0) + amount
    self.db.global.stats[storedPlayerName] = (self.db.global.stats[storedPlayerName] or 0) + amount

    if modeName == true then
        modeName = "1v1DeathRoll"
    end

    self:UpdateActiveStatProfile(storedPlayerName, amount, modeName)

    if modeName then
        if modeName == "1v1DeathRoll" then
            local storedDeathrollName = getKnownPlayerName(self, storedPlayerName)
            self.db.global.deathrollStats[storedDeathrollName] = (self.db.global.deathrollStats[storedDeathrollName] or 0) + amount
        end

        self.db.global.modeStats = self.db.global.modeStats or {}
        self.db.global.modeStats[modeName] = self.db.global.modeStats[modeName] or {}
        self.db.global.modeStats[modeName][storedPlayerName] = (self.db.global.modeStats[modeName][storedPlayerName] or 0) + amount
    end
end

function CrossGambling:reportDeathrollStats()
    sendChatLine(self, "-- Deathroll Stats --")
    local deathrollSortlist = self:sortStats(combineStatsByMain(self, self.db.global.deathrollStats))
    if #deathrollSortlist == 0 then
        sendChatLine(self, "No stats available for Deathrolls.")
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
    if self.db.global.playerCardStats then
        self.db.global.playerCardStats[storedStatName] = nil
    end
    self.db.global.joinstats[normalizePlayerNameLocal(self, player, true)] = nil
    if self.db.global.altStats then
        self.db.global.altStats[normalizePlayerNameLocal(self, player, true)] = nil
    end
    self:EnsureStatProfiles()
    for _, profile in pairs(self.db.global.statProfiles) do
        profile.stats[storedStatName] = nil
        profile.deathrollStats[storedDeathrollName] = nil
        for _, modeStats in pairs(profile.modeStats) do
            modeStats[storedStatName] = nil
        end
        profile.updatedAt = time()
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
    self.db.global.modeStats = {}
    self.db.global.playerCardStats = {}
    self.db.global.altStats = {}
    self.db.global.mergeAudit = {}
    self.game.sessionStats = {}
    self.db.global.statProfiles = {}
    self.db.global.activeStatProfile = "General"
    self.db.global.statProfilesInitialized = true
    self:EnsureStatProfiles()
    refreshHistoryProfileOption()
    self:AddAuditEntry({
        action = "resetStats",
        statsCount = statsCount,
        deathrollCount = deathrollCount,
        linkedAltCount = linkedAltCount,
        timestamp = time()
    })
    self:Print("All stats have been reset.")
end
