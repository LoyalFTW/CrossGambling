local function MakeBackdrop()
    local CG_TEX = "Interface\\AddOns\\CrossGambling\\media\\CG.tga"
    return {
        bgFile   = CG_TEX,
        edgeFile = CG_TEX,
        tile     = false, tileSize = 0, edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    }
end

local function MakeButton(parent, w, h, text, isClassic)
    local btn
    if isClassic then
        btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    else
        btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        if btn.SetBackdrop then
            btn:SetBackdrop(MakeBackdrop())
            btn:SetBackdropBorderColor(0, 0, 0)
            btn:SetBackdropColor(0.28, 0.28, 0.28)
        end
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        local hl = btn:GetHighlightTexture()
        hl:SetBlendMode("ADD")
        hl:SetAllPoints()
    end
    btn:SetSize(w, h)
    btn:SetText(text)
    btn:SetNormalFontObject("GameFontNormal")
    return btn
end

local function MakeLabel(parent, text, fontObj)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObj or "GameFontNormalSmall")
    fs:SetText(text)
    return fs
end

local function MakeSep(parent, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetSize(width or 260, 1)
    line:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    return line
end

local function MakeSectionHeader(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetText(text)
    fs:SetTextColor(1, 0.82, 0)
    return fs
end

local function MakeRow(parent, width, yOff, isClassic)
    local ROW_H = 28
    local row = CreateFrame("Frame", nil, parent, isClassic and nil or "BackdropTemplate")
    row:SetSize(width, ROW_H)
    row:SetPoint("TOPLEFT", parent, 8, yOff)
    if not isClassic and row.SetBackdrop then
        row:SetBackdrop(MakeBackdrop())
        row:SetBackdropColor(0.20, 0.20, 0.20)
        row:SetBackdropBorderColor(0.35, 0.35, 0.35)
    end
    return row, ROW_H
end

local function MakeColorSwatch(parent, label, getColor, onChanged, isClassic)
    local w = isClassic and 120 or 110
    local btn = MakeButton(parent, w, 26, label, isClassic)
    btn:SetScript("OnClick", function()
        local r, g, b = getColor()
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                hasOpacity = false,
                swatchFunc  = function() onChanged(ColorPickerFrame:GetColorRGB()) end,
                cancelFunc  = function(prev) onChanged(prev.r, prev.g, prev.b) end,
                previousValues = { r = r, g = g, b = b },
            })
        else
            ColorPickerFrame.hasOpacity     = false
            ColorPickerFrame.previousValues = { r = r, g = g, b = b }
            ColorPickerFrame.func           = function() onChanged(ColorPickerFrame:GetColorRGB()) end
            ColorPickerFrame.cancelFunc     = function(prev) onChanged(prev.r, prev.g, prev.b) end
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end)
    return btn
end

function CrossGambling:BuildOptionsMenu()
    if CrossGambling.OptionsMenuFrame then return end

    local isClassic = self:IsClassicTheme()

    local PANEL_W    = 320
    local PANEL_H    = 460
    local TAB_H      = 26
    local HEADER_H   = 22
    local CONTENT_TOP = -(HEADER_H + TAB_H + 6)
    local ROW_W      = PANEL_W - 18
    local PAD        = 8

    local panel
    if isClassic then
        panel = CreateFrame("Frame", "CGOptionsMenuFrame", UIParent, "BasicFrameTemplateWithInset")
        panel:SetSize(PANEL_W, PANEL_H)
        panel.TitleText:SetText("CrossGambling Options")
    else
        panel = CreateFrame("Frame", "CGOptionsMenuFrame", UIParent, "BackdropTemplate")
        panel:SetSize(PANEL_W, PANEL_H)
        if panel.SetBackdrop then
            panel:SetBackdrop(MakeBackdrop())
            panel:SetBackdropBorderColor(0, 0, 0)
            panel:SetBackdropColor(0.13, 0.13, 0.13)
        end

        local titleBar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        titleBar:SetSize(PANEL_W, HEADER_H)
        titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
        if titleBar.SetBackdrop then
            titleBar:SetBackdrop(MakeBackdrop())
            titleBar:SetBackdropColor(0.20, 0.20, 0.20)
            titleBar:SetBackdropBorderColor(0, 0, 0)
        end
        local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("CENTER")
        titleText:SetText("CrossGambling — Options")

        local closeBtn = CreateFrame("Button", nil, panel)
        closeBtn:SetSize(18, 18)
        closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
        closeBtn:SetScript("OnClick", function() panel:Hide() end)
    end

    panel:SetPoint("CENTER", UIParent, "CENTER", 80, 0)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetUserPlaced(true)
    panel:SetClampedToScreen(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
    panel:Hide()

    local TABS        = { "Game", "Theme", "Colors", "History" }
    local tabButtons  = {}
    local tabContents = {}
    local activeTab   = 1

    local function ShowTab(idx)
        activeTab = idx
        for i, content in ipairs(tabContents) do
            content:SetShown(i == idx)
        end
        for i, btn in ipairs(tabButtons) do
            if isClassic then
                btn:SetNormalFontObject(i == idx and "GameFontHighlight" or "GameFontNormal")
            else
                local r = (i == idx) and 0.40 or 0.22
                if btn.SetBackdropColor then btn:SetBackdropColor(r, r, r) end
                if btn.SetBackdropBorderColor then
                    btn:SetBackdropBorderColor(i == idx and 0.6 or 0.30, i == idx and 0.50 or 0.30, 0)
                end
            end
        end
    end

    local tabW = math.floor(PANEL_W / #TABS)
    for i, name in ipairs(TABS) do
        local btn = MakeButton(panel, tabW, TAB_H, name, isClassic)
        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", (i - 1) * tabW, -HEADER_H)
        btn:SetScript("OnClick", function() ShowTab(i) end)
        tabButtons[i] = btn

        local pane = CreateFrame("Frame", nil, panel)
        pane:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0, CONTENT_TOP)
        pane:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 4)
        pane:Hide()
        tabContents[i] = pane
    end

    do
        local g    = tabContents[1]
        local FULL = ROW_W
        local HALF = math.floor((FULL - 6) / 2)
        local yOff = -8

        local hdr1 = MakeSectionHeader(g, "STATISTICS")
        hdr1:SetPoint("TOPLEFT", g, PAD + 2, yOff)
        yOff = yOff - 18

        local fullStats = MakeButton(g, HALF, 26, "Full Stats", isClassic)
        fullStats:SetPoint("TOPLEFT", g, PAD, yOff)
        fullStats:SetScript("OnClick", function() CrossGambling:reportStats() end)

        local deathStats = MakeButton(g, HALF, 26, "DeathRoll Stats", isClassic)
        deathStats:SetPoint("TOPLEFT", g, PAD + HALF + 6, yOff)
        deathStats:SetScript("OnClick", function() CrossGambling:reportDeathrollStats() end)
        yOff = yOff - 32

        local fameShame = MakeButton(g, HALF, 26, "Fame / Shame", isClassic)
        fameShame:SetPoint("TOPLEFT", g, PAD, yOff)
        fameShame:SetScript("OnClick", function() CrossGambling:reportStats() end)

        local sessionStats = MakeButton(g, HALF, 26, "Session Stats", isClassic)
        sessionStats:SetPoint("TOPLEFT", g, PAD + HALF + 6, yOff)
        sessionStats:SetScript("OnClick", function() CrossGambling:reportSessionStats() end)
        yOff = yOff - 38

        MakeSep(g, FULL):SetPoint("TOPLEFT", g, PAD, yOff)
        yOff = yOff - 10
        local hdr2 = MakeSectionHeader(g, "GAME SETTINGS")
        hdr2:SetPoint("TOPLEFT", g, PAD + 2, yOff)
        yOff = yOff - 18

        local guildRow, guildRowH = MakeRow(g, FULL, yOff, isClassic)
        local guildLbl = MakeLabel(guildRow, "Guild Cut", "GameFontNormalSmall")
        guildLbl:SetPoint("LEFT", guildRow, "LEFT", 10, 0)
        guildLbl:SetTextColor(0.85, 0.85, 0.85)
        local guildToggle = MakeButton(guildRow, 70, 20, "OFF", isClassic)
        guildToggle:SetPoint("RIGHT", guildRow, "RIGHT", -6, 0)
        guildToggle:SetScript("OnClick", function()
            CrossGambling.game.house = not CrossGambling.game.house
            local on = CrossGambling.game.house
            guildToggle:SetText(on and "ON" or "OFF")
            if not isClassic and guildToggle.SetBackdropColor then
                guildToggle:SetBackdropColor(on and 0.15 or 0.28, on and 0.32 or 0.28, on and 0.15 or 0.28)
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00CrossGambling:|r Guild cut " .. (on and "ON" or "OFF") .. ".")
        end)
        yOff = yOff - guildRowH - 4

        local houseRow, houseRowH = MakeRow(g, FULL, yOff, isClassic)
        local houseLbl = MakeLabel(houseRow, "House Cut %", "GameFontNormalSmall")
        houseLbl:SetPoint("LEFT", houseRow, "LEFT", 10, 0)
        houseLbl:SetTextColor(0.85, 0.85, 0.85)
        local houseBox = CreateFrame("EditBox", nil, houseRow, "InputBoxTemplate")
        houseBox:SetSize(60, 20)
        houseBox:SetPoint("RIGHT", houseRow, "RIGHT", -8, 0)
        houseBox:SetAutoFocus(false)
        houseBox:SetMaxLetters(4)
        houseBox:SetJustifyH("CENTER")
        houseBox:SetText(tostring(CrossGambling.db and CrossGambling.db.global.houseCut or 10))
        houseBox:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v and CrossGambling.db then CrossGambling.db.global.houseCut = v end
            self:ClearFocus()
        end)
        yOff = yOff - houseRowH - 4

        local realmRow, realmRowH = MakeRow(g, FULL, yOff, isClassic)
        local realmLbl = MakeLabel(realmRow, "Realm Filter", "GameFontNormalSmall")
        realmLbl:SetPoint("LEFT", realmRow, "LEFT", 10, 0)
        realmLbl:SetTextColor(0.85, 0.85, 0.85)
        local realmToggle = MakeButton(realmRow, 70, 20, "OFF", isClassic)
        realmToggle:SetPoint("RIGHT", realmRow, "RIGHT", -6, 0)
        realmToggle:SetScript("OnClick", function()
            CrossGambling.game.realmFilter = not CrossGambling.game.realmFilter
            local on = CrossGambling.game.realmFilter
            realmToggle:SetText(on and "ON" or "OFF")
            if not isClassic and realmToggle.SetBackdropColor then
                realmToggle:SetBackdropColor(on and 0.15 or 0.28, on and 0.32 or 0.28, on and 0.15 or 0.28)
            end
        end)
        yOff = yOff - realmRowH - 4

        local joinRow, joinRowH = MakeRow(g, FULL, yOff, isClassic)
        local joinLbl = MakeLabel(joinRow, "Join Word", "GameFontNormalSmall")
        joinLbl:SetPoint("LEFT", joinRow, "LEFT", 10, 0)
        joinLbl:SetTextColor(0.85, 0.85, 0.85)
        local joinSubLbl = MakeLabel(joinRow, "players type this to enter", "GameFontNormalSmall")
        joinSubLbl:SetPoint("LEFT", joinLbl, "RIGHT", 8, 0)
        joinSubLbl:SetTextColor(0.45, 0.45, 0.45)
        local joinBox = CreateFrame("EditBox", nil, joinRow, "InputBoxTemplate")
        joinBox:SetSize(70, 20)
        joinBox:SetPoint("RIGHT", joinRow, "RIGHT", -8, 0)
        joinBox:SetAutoFocus(false)
        joinBox:SetMaxLetters(20)
        joinBox:SetJustifyH("CENTER")
        joinBox:SetText(CrossGambling.db and CrossGambling.db.global.joinWord or "1")
        joinBox:SetScript("OnEnterPressed", function(self)
            local word = self:GetText():match("^%s*(.-)%s*$")
            if word ~= "" and CrossGambling.db then
                CrossGambling.db.global.joinWord = word
            end
            self:ClearFocus()
        end)
        joinBox:SetScript("OnEditFocusLost", function(self)
            local word = self:GetText():match("^%s*(.-)%s*$")
            if word ~= "" and CrossGambling.db then
                CrossGambling.db.global.joinWord = word
            end
        end)
        yOff = yOff - joinRowH - 4

        local leaveRow, leaveRowH = MakeRow(g, FULL, yOff, isClassic)
        local leaveLbl = MakeLabel(leaveRow, "Leave Word", "GameFontNormalSmall")
        leaveLbl:SetPoint("LEFT", leaveRow, "LEFT", 10, 0)
        leaveLbl:SetTextColor(0.85, 0.85, 0.85)
        local leaveSubLbl = MakeLabel(leaveRow, "players type this to withdraw", "GameFontNormalSmall")
        leaveSubLbl:SetPoint("LEFT", leaveLbl, "RIGHT", 8, 0)
        leaveSubLbl:SetTextColor(0.45, 0.45, 0.45)
        local leaveBox = CreateFrame("EditBox", nil, leaveRow, "InputBoxTemplate")
        leaveBox:SetSize(70, 20)
        leaveBox:SetPoint("RIGHT", leaveRow, "RIGHT", -8, 0)
        leaveBox:SetAutoFocus(false)
        leaveBox:SetMaxLetters(20)
        leaveBox:SetJustifyH("CENTER")
        leaveBox:SetText(CrossGambling.db and CrossGambling.db.global.leaveWord or "-1")
        leaveBox:SetScript("OnEnterPressed", function(self)
            local word = self:GetText():match("^%s*(.-)%s*$")
            if word ~= "" and CrossGambling.db then
                CrossGambling.db.global.leaveWord = word
            end
            self:ClearFocus()
        end)
        leaveBox:SetScript("OnEditFocusLost", function(self)
            local word = self:GetText():match("^%s*(.-)%s*$")
            if word ~= "" and CrossGambling.db then
                CrossGambling.db.global.leaveWord = word
            end
        end)
        yOff = yOff - leaveRowH - 10

        MakeSep(g, FULL):SetPoint("TOPLEFT", g, PAD, yOff)
        yOff = yOff - 10
        local hdr3 = MakeLabel(g, "DANGER ZONE", "GameFontNormalSmall")
        hdr3:SetPoint("TOPLEFT", g, PAD + 2, yOff)
        hdr3:SetTextColor(0.85, 0.25, 0.25)
        yOff = yOff - 18

        local resetBtn = MakeButton(g, FULL, 26, "Reset All Stats", isClassic)
        resetBtn:SetPoint("TOPLEFT", g, PAD, yOff)
        if not isClassic and resetBtn.SetBackdropColor then
            resetBtn:SetBackdropColor(0.30, 0.12, 0.12)
            resetBtn:SetBackdropBorderColor(0.5, 0.1, 0.1)
        end
        resetBtn:SetScript("OnClick", function()
            CrossGambling.game.host    = false
            CrossGambling.game.state   = "START"
            CrossGambling.game.players = {}
            CrossGambling.game.result  = nil
            CrossGambling:resetStats()
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444CrossGambling:|r Stats have been reset.")
        end)
    end

    do
        local g    = tabContents[2]
        local FULL = ROW_W
        local yOff = -8

        local hdr = MakeLabel(g, "Choose Your Theme", "GameFontNormal")
        hdr:SetPoint("TOP", g, "TOP", 0, yOff)
        hdr:SetTextColor(1, 0.82, 0)
        yOff = yOff - 20

        local subTxt = MakeLabel(g, "Your UI will reload after confirming.", "GameFontNormalSmall")
        subTxt:SetPoint("TOP", g, "TOP", 0, yOff)
        subTxt:SetTextColor(0.55, 0.55, 0.55)
        yOff = yOff - 22

        local PREVIEW_W = 134
        local PREVIEW_H = 86
        local GAP       = math.floor((FULL - PREVIEW_W * 2) / 3)
        local selectedThemeKey = CrossGambling.db and CrossGambling.db.global.theme or "Slick"
        local selectionIndicators = {}

        for idx, themeData in ipairs(CrossGambling_Themes) do
            local xBase = PAD + (idx - 1) * (PREVIEW_W + GAP + 2)

            local previewBox = CreateFrame("Frame", nil, g, "BackdropTemplate")
            previewBox:SetSize(PREVIEW_W, PREVIEW_H + 22)
            previewBox:SetPoint("TOPLEFT", g, xBase, yOff)
            if not isClassic and previewBox.SetBackdrop then
                previewBox:SetBackdrop(MakeBackdrop())
                previewBox:SetBackdropColor(0.18, 0.18, 0.18)
                previewBox:SetBackdropBorderColor(0.38, 0.38, 0.38)
            end

            local tex = previewBox:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT",     previewBox, 2, -2)
            tex:SetPoint("BOTTOMRIGHT", previewBox, -2, 22)
            tex:SetTexture(themeData.previewTex)

            local nameLabel = MakeLabel(previewBox, themeData.label, "GameFontNormalSmall")
            nameLabel:SetPoint("BOTTOM", previewBox, "BOTTOM", 0, 5)

            local selBorder = previewBox:CreateTexture(nil, "OVERLAY")
            selBorder:SetAllPoints(previewBox)
            selBorder:SetColorTexture(1, 0.82, 0, 0.30)
            selBorder:Hide()
            selectionIndicators[themeData.dbKey] = selBorder

            previewBox:EnableMouse(true)
            previewBox:SetScript("OnMouseDown", function()
                selectedThemeKey = themeData.dbKey
                for key, ind in pairs(selectionIndicators) do
                    ind:SetShown(key == selectedThemeKey)
                end
            end)
        end

        if selectionIndicators[selectedThemeKey] then
            selectionIndicators[selectedThemeKey]:Show()
        end

        yOff = yOff - (PREVIEW_H + 30)

        local confirmBtn = MakeButton(g, 160, 28, "Confirm & Reload", isClassic)
        confirmBtn:SetPoint("TOP", g, "TOP", 0, yOff)
        confirmBtn:SetScript("OnClick", function()
            CrossGambling:SetTheme(selectedThemeKey)
        end)
        yOff = yOff - 38

        local infoTxt = MakeLabel(g,
            "Classic: native WoW window frames.\nSlick: custom dark UI with customisable colours.",
            "GameFontNormalSmall")
        infoTxt:SetPoint("TOP", g, "TOP", 0, yOff)
        infoTxt:SetTextColor(0.55, 0.55, 0.55)
        infoTxt:SetJustifyH("CENTER")
        infoTxt:SetWidth(FULL)
    end

    do
        local g    = tabContents[3]
        local FULL = ROW_W
        local HALF = math.floor((FULL - 6) / 2)
        local yOff = -8

        if isClassic then
            local notice = MakeLabel(g,
                "Colour customisation is only\navailable in the Slick theme.\n\nSwitch themes on the Theme tab.",
                "GameFontNormal")
            notice:SetPoint("CENTER", g, "CENTER", 0, 0)
            notice:SetJustifyH("CENTER")
            notice:SetTextColor(0.65, 0.65, 0.65)
        else
            local hdr = MakeLabel(g, "Slick Theme Colours", "GameFontNormal")
            hdr:SetPoint("TOP", g, "TOP", 0, yOff)
            hdr:SetTextColor(1, 0.82, 0)
            yOff = yOff - 26

            local BtnClrFrames  = {}
            local SideClrFrames = {}

            local function ApplyLive()
                local c = CrossGambling.db.global.colors
                for _, f in ipairs(BtnClrFrames) do
                    if f.SetBackdropColor then f:SetBackdropColor(c.buttonColor.r, c.buttonColor.g, c.buttonColor.b) end
                end
                for _, f in ipairs(SideClrFrames) do
                    if f.SetBackdropColor then f:SetBackdropColor(c.sideColor.r, c.sideColor.g, c.sideColor.b) end
                end
                if CrossGamblingSlick and CrossGamblingSlick.SetBackdropColor then
                    CrossGamblingSlick:SetBackdropColor(c.frameColor.r, c.frameColor.g, c.frameColor.b)
                end
            end

            local frameSwatch = MakeColorSwatch(g, "Frame Color",
                function()
                    local c = CrossGambling.db.global.colors.frameColor
                    return c.r, c.g, c.b
                end,
                function(r, g2, b)
                    CrossGambling:SaveThemeColors({r=r,g=g2,b=b}, nil, nil, nil)
                    ApplyLive()
                end, isClassic)
            frameSwatch:SetPoint("TOPLEFT", g, PAD, yOff)

            local btnSwatch = MakeColorSwatch(g, "Button Color",
                function()
                    local c = CrossGambling.db.global.colors.buttonColor
                    return c.r, c.g, c.b
                end,
                function(r, g2, b)
                    CrossGambling:SaveThemeColors(nil, {r=r,g=g2,b=b}, nil, nil)
                    ApplyLive()
                end, isClassic)
            btnSwatch:SetPoint("TOPLEFT", g, PAD + HALF + 6, yOff)
            yOff = yOff - 34

            local sideSwatch = MakeColorSwatch(g, "Side Color",
                function()
                    local c = CrossGambling.db.global.colors.sideColor
                    return c.r, c.g, c.b
                end,
                function(r, g2, b)
                    CrossGambling:SaveThemeColors(nil, nil, {r=r,g=g2,b=b}, nil)
                    ApplyLive()
                end, isClassic)
            sideSwatch:SetPoint("TOPLEFT", g, PAD, yOff)

            local fontSwatch = MakeColorSwatch(g, "Font Color",
                function()
                    local c = CrossGambling.db.global.colors.fontColor
                    return c.r, c.g, c.b
                end,
                function(r, g2, b)
                    CrossGambling:SaveThemeColors(nil, nil, nil, {r=r,g=g2,b=b})
                    if CrossGambling.ChatTextField then
                        CrossGambling.ChatTextField:SetTextColor(r, g2, b)
                    end
                end, isClassic)
            fontSwatch:SetPoint("TOPLEFT", g, PAD + HALF + 6, yOff)
            yOff = yOff - 38

            MakeSep(g, FULL):SetPoint("TOPLEFT", g, PAD, yOff)
            yOff = yOff - 14

            local fsLabel = MakeLabel(g, "Chat Font Size:", "GameFontNormalSmall")
            fsLabel:SetPoint("TOPLEFT", g, PAD, yOff)
            fsLabel:SetTextColor(0.85, 0.85, 0.85)
            yOff = yOff - 20

            local fontSlider = CreateFrame("Slider", "CGOptionsFontSlider", g, "OptionsSliderTemplate")
            fontSlider:SetSize(FULL - 34, 16)
            fontSlider:SetPoint("TOPLEFT", g, PAD, yOff)
            fontSlider:SetMinMaxValues(8, 24)
            fontSlider:SetValueStep(1)
            fontSlider:SetObeyStepOnDrag(true)
            local fv = (CrossGambling.db and CrossGambling.db.global.fontvalue) or 14
            fontSlider:SetValue(fv)
            CGOptionsFontSliderLow:SetText("8")
            CGOptionsFontSliderHigh:SetText("24")
            CGOptionsFontSliderText:SetText("Font Size")

            local fvDisplay = g:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fvDisplay:SetPoint("LEFT", fontSlider, "RIGHT", 6, 0)
            fvDisplay:SetText(fv)

            fontSlider:SetScript("OnValueChanged", function(self, val)
                val = math.floor(val + 0.5)
                if CrossGambling.db then CrossGambling.db.global.fontvalue = val end
                fvDisplay:SetText(val)
                if CrossGambling.ChatTextField then
                    CrossGambling.ChatTextField:SetFont("Fonts\\FRIZQT__.TTF", val, "")
                end
            end)
            yOff = yOff - 38

            MakeSep(g, FULL):SetPoint("TOPLEFT", g, PAD, yOff)
            yOff = yOff - 14

            local resetColBtn = MakeButton(g, FULL, 26, "Reset to Default Colors", isClassic)
            resetColBtn:SetPoint("TOPLEFT", g, PAD, yOff)
            resetColBtn:SetScript("OnClick", function()
                CrossGambling:ResetThemeColors({}, {}, nil)
                ApplyLive()
                DEFAULT_CHAT_FRAME:AddMessage("|cffffff00CrossGambling:|r Colours reset to defaults.")
            end)
        end
    end

    do
        local g    = tabContents[4]
        local FULL = ROW_W
        local HALF = math.floor((FULL - 6) / 2)
        local yOff = -8

        local hdr = MakeLabel(g, "Audit History Log", "GameFontNormal")
        hdr:SetPoint("TOP", g, "TOP", 0, yOff)
        hdr:SetTextColor(1, 0.82, 0)
        yOff = yOff - 20

        local desc = MakeLabel(g,
            "Review past game results and stat changes.\nSearch, filter by date, and manage old entries.",
            "GameFontNormalSmall")
        desc:SetPoint("TOP", g, "TOP", 0, yOff)
        desc:SetJustifyH("CENTER")
        desc:SetTextColor(0.50, 0.50, 0.50)
        desc:SetWidth(FULL)
        yOff = yOff - 40

        local openLogBtn = MakeButton(g, FULL, 28, "Open History Log", isClassic)
        openLogBtn:SetPoint("TOPLEFT", g, PAD, yOff)
        openLogBtn:SetScript("OnClick", function()
            local af = CrossGambling.auditFrame
            if not af then return end
            if af:IsShown() then
                af:Hide()
                openLogBtn:SetText("Open History Log")
            else
                CrossGambling:PurgeOldAuditEntries()
                af:Show()
                if af.UpdateLayout then af:UpdateLayout() end
                CrossGambling:UpdateAuditLogText(af.searchBox and af.searchBox:GetText() or "")
                openLogBtn:SetText("Close History Log")
            end
        end)
        yOff = yOff - 38

        MakeSep(g, FULL):SetPoint("TOPLEFT", g, PAD, yOff)
        yOff = yOff - 10

        local retHeader = MakeSectionHeader(g, "LOG RETENTION")
        retHeader:SetPoint("TOPLEFT", g, PAD + 2, yOff)
        yOff = yOff - 16

        local retDesc = MakeLabel(g, "Auto-purge entries older than:", "GameFontNormalSmall")
        retDesc:SetPoint("TOPLEFT", g, PAD + 2, yOff)
        retDesc:SetTextColor(0.55, 0.55, 0.55)
        yOff = yOff - 28

        local retentionDays = {5, 10, 30, "Never"}
        local retCBs = {}
        local CB_SLOT_W = math.floor(FULL / #retentionDays)

        local function OnRetChanged(self2)
            for _, cb in pairs(retCBs) do cb:SetChecked(false) end
            self2:SetChecked(true)
            if CrossGambling.db then
                CrossGambling.db.global.auditRetention = self2.days
            end
        end

        for i, val in ipairs(retentionDays) do
            local cb = CreateFrame("CheckButton", nil, g, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            local xPos = PAD + (i - 1) * CB_SLOT_W + math.floor((CB_SLOT_W - 20) / 2)
            cb:SetPoint("TOPLEFT", g, xPos, yOff)
            if cb.Text then cb.Text:Hide() end

            local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("BOTTOM", cb, "TOP", 0, 2)
            lbl:SetText(type(val) == "number" and (val .. "d") or "Never")
            lbl:SetTextColor(0.80, 0.80, 0.80)

            cb.days = val
            cb:SetScript("OnClick", OnRetChanged)
            retCBs[i] = cb
        end

        C_Timer.After(0.15, function()
            if not CrossGambling.db then return end
            for _, cb in pairs(retCBs) do
                if CrossGambling.db.global.auditRetention == cb.days then
                    cb:SetChecked(true)
                end
            end
        end)
        yOff = yOff - 38

        local purgeBtn = MakeButton(g, FULL, 26, "Purge Log Now", isClassic)
        purgeBtn:SetPoint("TOPLEFT", g, PAD, yOff)
        if not isClassic and purgeBtn.SetBackdropColor then
            purgeBtn:SetBackdropColor(0.28, 0.12, 0.12)
            purgeBtn:SetBackdropBorderColor(0.5, 0.1, 0.1)
        end
        purgeBtn:SetScript("OnClick", function()
            if CrossGambling.db and CrossGambling.db.global then
                CrossGambling.db.global.auditLog = {}
            end
            local af = CrossGambling.auditFrame
            if af and af.searchBox then
                CrossGambling:UpdateAuditLogText(af.searchBox:GetText())
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00CrossGambling:|r History log purged.")
        end)
        yOff = yOff - 38

        MakeSep(g, FULL):SetPoint("TOPLEFT", g, PAD, yOff)
        yOff = yOff - 10

        local exportHeader = MakeSectionHeader(g, "EXPORT / IMPORT STATS")
        exportHeader:SetPoint("TOPLEFT", g, PAD + 2, yOff)
        yOff = yOff - 18

        local exportRowFrame = CreateFrame("Frame", nil, g, isClassic and nil or "BackdropTemplate")
        exportRowFrame:SetSize(FULL, 26)
        exportRowFrame:SetPoint("TOPLEFT", g, PAD, yOff)
        if not isClassic and exportRowFrame.SetBackdrop then
            exportRowFrame:SetBackdrop(MakeBackdrop())
            exportRowFrame:SetBackdropColor(0.12, 0.12, 0.12)
            exportRowFrame:SetBackdropBorderColor(0.35, 0.35, 0.35)
        end

        local exportBox = CreateFrame("EditBox", nil, exportRowFrame, "InputBoxTemplate")
        exportBox:SetSize(FULL - 10, 20)
        exportBox:SetPoint("CENTER", exportRowFrame, "CENTER", 0, 0)
        exportBox:SetAutoFocus(false)
        exportBox:SetMaxLetters(0)
        exportBox:SetText("Click Export to generate a share string...")
        exportBox:SetTextColor(0.45, 0.45, 0.45)
        exportBox:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == "Click Export to generate a share string..." then
                self:SetText("")
                self:SetTextColor(0.9, 0.9, 0.9)
            end
        end)
        yOff = yOff - 32

        local exportBtn = MakeButton(g, HALF, 26, "Export Stats", isClassic)
        exportBtn:SetPoint("TOPLEFT", g, PAD, yOff)
        exportBtn:SetScript("OnClick", function()
            local str = CrossGambling:exportStats()
            exportBox:SetText(str)
            exportBox:SetTextColor(0.9, 0.9, 0.9)
            exportBox:SetFocus()
            exportBox:HighlightText()
        end)

        local importBtn = MakeButton(g, HALF, 26, "Import Stats", isClassic)
        importBtn:SetPoint("TOPLEFT", g, PAD + HALF + 6, yOff)
        importBtn:SetScript("OnClick", function()
            local str = exportBox:GetText()
            CrossGambling:importStats(str)
            exportBox:SetText("Click Export to generate a share string...")
            exportBox:SetTextColor(0.45, 0.45, 0.45)
            exportBox:ClearFocus()
        end)
    end

    ShowTab(1)

    CrossGambling.OptionsMenuFrame = panel

    function CrossGambling:ToggleOptionsMenu()
        if panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
        end
    end
end
