local PlayerCard = {
    modeRows = {},
}

local CARD_BACKDROP = {
    bgFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    edgeFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local PANEL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function styleFont(fontString, small)
    if not fontString then return end
    if CGTheme and CGTheme.GetFontPath then
        local size = small and math.max(10, CGTheme:GetFontSize() - 2) or CGTheme:GetFontSize()
        fontString:SetFont(CGTheme:GetFontPath(), size, CGTheme:GetFontFlags())
    end
    if CGTheme and CGTheme.RegisterFont then CGTheme:RegisterFont(fontString) end
end

local function coloredName(name)
    local _, class = UnitClass(name)
    local color = class and RAID_CLASS_COLORS[class]
    return color and color.colorStr and "|c" .. color.colorStr .. name .. "|r" or "|cffffffff" .. name .. "|r"
end

local function signedGold(addon, amount)
    amount = tonumber(amount) or 0
    local color = amount > 0 and "|cff45d66b" or amount < 0 and "|cffff6262" or "|cffb7b7b7"
    local sign = amount > 0 and "+" or amount < 0 and "-" or ""
    return color .. sign .. addon:addCommas(math.abs(amount)) .. "g|r"
end

local function streakText(streak)
    streak = tonumber(streak) or 0
    if streak > 0 then return "|cff45d66bW" .. streak .. "|r" end
    if streak < 0 then return "|cffff6262L" .. math.abs(streak) .. "|r" end
    return "|cffb7b7b7None|r"
end

local function setPanelColor(panel, r, g, b, a)
    panel:SetBackdrop(PANEL_BACKDROP)
    panel:SetBackdropColor(r, g, b, a)
    panel:SetBackdropBorderColor(0, 0, 0, 0.9)
end

local function createMetric(parent, label, width)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(width, 60)
    setPanelColor(panel, 0.06, 0.06, 0.08, 0.88)

    panel.label = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.label:SetPoint("TOP", panel, "TOP", 0, -8)
    panel.label:SetText(label)
    styleFont(panel.label, true)

    panel.value = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.value:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
    styleFont(panel.value)
    return panel
end

function PlayerCard:Ensure(addon)
    if self.frame then return self.frame end
    local slick = addon.db and addon.db.global and addon.db.global.theme == "Slick"
    local frame = CreateFrame("Frame", "CrossGamblingPlayerCardFrame", UIParent, slick and "BackdropTemplate" or "BasicFrameTemplateWithInset")
    frame:SetSize(420, 470)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    if slick then
        frame:SetBackdrop(CARD_BACKDROP)
        frame:SetBackdropBorderColor(0, 0, 0)
        local color = CGTheme and CGTheme._frameColor or { r = 0.12, g = 0.12, b = 0.14 }
        frame:SetBackdropColor(color.r, color.g, color.b, 0.98)
        if CGTheme and CGTheme.RegisterFrame then CGTheme:RegisterFrame(frame) end
    end

    local close = frame.CloseButton or CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    if not frame.CloseButton then close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2) end

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetHeight(20)
    if slick then
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
        frame.title:SetPoint("RIGHT", close, "LEFT", -6, 0)
        frame.title:SetJustifyH("LEFT")
    else
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 34, -2)
        frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -2)
        frame.title:SetJustifyH("CENTER")
    end
    styleFont(frame.title)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -31)
    frame.subtitle:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    frame.subtitle:SetJustifyH("LEFT")
    styleFont(frame.subtitle, true)

    frame.session = createMetric(frame, "SESSION RESULT", 184)
    frame.session:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -67)
    frame.lifetime = createMetric(frame, "LIFETIME RESULT", 184)
    frame.lifetime:SetPoint("LEFT", frame.session, "RIGHT", 16, 0)

    frame.games = createMetric(frame, "TRACKED GAMES", 117)
    frame.games:SetPoint("TOPLEFT", frame.session, "BOTTOMLEFT", 0, -10)
    frame.record = createMetric(frame, "RECORD", 117)
    frame.record:SetPoint("LEFT", frame.games, "RIGHT", 10, 0)
    frame.streak = createMetric(frame, "CURRENT STREAK", 130)
    frame.streak:SetPoint("LEFT", frame.record, "RIGHT", 10, 0)

    frame.modeTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.modeTitle:SetPoint("TOPLEFT", frame.games, "BOTTOMLEFT", 0, -18)
    frame.modeTitle:SetText("Mode Performance")
    styleFont(frame.modeTitle)

    frame.modeHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.modeHint:SetPoint("LEFT", frame.modeTitle, "RIGHT", 8, 0)
    frame.modeHint:SetText("Lifetime gold  |  Tracked record")
    styleFont(frame.modeHint, true)

    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", frame.modeTitle, "BOTTOMLEFT", 0, -9)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 47)
    frame.scroll:EnableMouseWheel(true)
    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.content:SetSize(370, 1)
    frame.scroll:SetScrollChild(frame.content)
    frame.scroll:SetScript("OnMouseWheel", function(scroll, delta)
        local maximum = math.max(0, frame.content:GetHeight() - scroll:GetHeight())
        scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll() - delta * 32, maximum)))
    end)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
    frame.footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
    frame.footer:SetJustifyH("LEFT")
    styleFont(frame.footer, true)

    self.frame = frame
    self.addon = addon
    frame:Hide()
    return frame
end

function PlayerCard:AcquireModeRow(index)
    local row = self.modeRows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, self.frame.content, "BackdropTemplate")
    row:SetSize(370, 30)
    setPanelColor(row, 0.07, 0.07, 0.09, index % 2 == 0 and 0.78 or 0.58)

    row.mode = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.mode:SetPoint("LEFT", row, "LEFT", 9, 0)
    row.mode:SetWidth(125)
    row.mode:SetJustifyH("LEFT")
    styleFont(row.mode, true)

    row.gold = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.gold:SetPoint("LEFT", row.mode, "RIGHT", 4, 0)
    row.gold:SetWidth(92)
    row.gold:SetJustifyH("RIGHT")
    styleFont(row.gold, true)

    row.record = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.record:SetPoint("RIGHT", row, "RIGHT", -9, 0)
    row.record:SetWidth(125)
    row.record:SetJustifyH("RIGHT")
    styleFont(row.record, true)

    self.modeRows[index] = row
    return row
end

function PlayerCard:Refresh()
    if not self.frame or not self.frame:IsShown() or not self.playerName then return end
    local data = self.addon:GetPlayerCardData(self.playerName)
    self.frame.title:SetText(coloredName(data.name) .. "  |  Player Card")
    if data.requestedName ~= data.name then
        self.frame.subtitle:SetText(data.requestedName .. " is linked to this main profile")
    else
        self.frame.subtitle:SetText("CrossGambling performance overview")
    end
    self.frame.session.value:SetText(signedGold(self.addon, data.session))
    self.frame.lifetime.value:SetText(signedGold(self.addon, data.lifetime))
    self.frame.games.value:SetText(tostring(data.games))
    local record = string.format("%dW - %dL", data.wins, data.losses)
    if data.pushes > 0 then record = record .. " - " .. data.pushes .. "P" end
    self.frame.record.value:SetText(record)
    self.frame.streak.value:SetText(streakText(data.streak))

    table.sort(data.modes, function(a, b)
        local aActive = a.games > 0 or a.amount ~= 0
        local bActive = b.games > 0 or b.amount ~= 0
        if aActive ~= bActive then return aActive end
        if a.games ~= b.games then return a.games > b.games end
        return a.name < b.name
    end)

    for _, row in ipairs(self.modeRows) do row:Hide() end
    for i, mode in ipairs(data.modes) do
        local row = self:AcquireModeRow(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -(i - 1) * 32)
        row.mode:SetText(mode.name)
        row.gold:SetText(signedGold(self.addon, mode.amount))
        local modeRecord = string.format("%dW-%dL  |  %d", mode.wins, mode.losses, mode.games)
        if mode.pushes > 0 then modeRecord = string.format("%dW-%dL-%dP  |  %d", mode.wins, mode.losses, mode.pushes, mode.games) end
        row.record:SetText(modeRecord)
        row:Show()
    end
    self.frame.content:SetHeight(math.max(1, #data.modes * 32))

    if data.lastPlayed then
        self.frame.footer:SetText("Last tracked: " .. date("%Y-%m-%d %H:%M", data.lastPlayed) .. "  |  Best: W" .. data.bestWinStreak .. " / L" .. data.bestLossStreak)
    else
        self.frame.footer:SetText("Game records and streaks begin tracking with Player Cards; existing gold totals are preserved.")
    end
end

function PlayerCard:Show(addon, playerName, anchor)
    local frame = self:Ensure(addon)
    self.playerName = playerName
    frame:ClearAllPoints()
    if anchor then
        frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 12, 10)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    frame:Show()
    self:Refresh()
end

function PlayerCard:Toggle(addon, playerName, anchor)
    local frame = self:Ensure(addon)
    if frame:IsShown() and self.playerName == playerName then
        frame:Hide()
        return
    end
    self:Show(addon, playerName, anchor)
end

CrossGamblingPlayerCard = PlayerCard

CrossGamblingGameBoard:SetPlayerClickHandler(function(addon, playerName, row)
    PlayerCard:Toggle(addon, playerName, row)
end)
