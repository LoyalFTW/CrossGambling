CGOptions = {}
local _buildCount = 0
local OPTION_BACKDROP = {
    bgFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    edgeFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = {left = 1, right = 1, top = 1, bottom = 1},
}

local function GetAddon()
    return LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
end

local function EnsureBackdrop(frame)
    if frame and not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
end

local function StyleSlickFont(fontString)
    if not fontString then return fontString end

    if CGTheme and CGTheme.GetFontColor then
        fontString:SetTextColor(CGTheme:GetFontColor())
    else
        fontString:SetTextColor(1, 1, 1)
    end
    if CGTheme and CGTheme.RegisterFont then
        CGTheme:RegisterFont(fontString)
    end
    if CGTheme and CGTheme.GetFontPath then
        fontString:SetFont(CGTheme:GetFontPath(), CGTheme:GetFontSize(), CGTheme:GetFontFlags())
    end

    return fontString
end

local function SetSlickButtonText(btn, text)
    if btn and btn._cgLabel then
        btn._cgLabel:SetText(text or "")
    end
    btn:SetText(text or "")
end

local function StyleSlickButton(btn)
    if not btn then return btn end

    EnsureBackdrop(btn)
    btn:SetBackdrop(OPTION_BACKDROP)
    btn:SetBackdropBorderColor(0, 0, 0)

    local currentText = btn:GetText()
    local fontString = btn:GetFontString()
    if not fontString then
        fontString = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn:SetFontString(fontString)
    end
    btn._cgLabel = fontString
    fontString:SetAllPoints(btn)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")
    StyleSlickFont(fontString)
    if currentText then
        SetSlickButtonText(btn, currentText)
    end

    if CGTheme and CGTheme.RegisterBtn then
        CGTheme:RegisterBtn(btn)
    end

    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    local highlight = btn:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints()
        highlight:Hide()
    end
    btn:SetScript("OnEnter", function(self)
        local h = self:GetHighlightTexture()
        if h then h:Show() end
    end)
    btn:SetScript("OnLeave", function(self)
        local h = self:GetHighlightTexture()
        if h then h:Hide() end
    end)

    return btn
end

local function MakeButton(parent, text, w, h)
    local btn = CreateFrame("Button", nil, parent, CGOptions._isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
    btn:SetSize(w or 120, h or 26)
    if CGOptions._isSlick then
        StyleSlickButton(btn)
    end
    if CGOptions._isSlick then
        SetSlickButtonText(btn, text)
    else
        btn:SetText(text)
    end
    return btn
end

local function MakeEditBox(parent, w, h, maxLetters)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(w or 80, h or 22)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxLetters or 10)
    eb:SetJustifyH("CENTER")
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnEditFocusLost",   function(self) self:HighlightText(0,0) end)
    eb:SetScript("OnEscapePressed",   function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed",    function(self) self:ClearFocus() end)
    return eb
end

local function MakeToggleBtn(parent, w, h)
    local btn = CreateFrame("Button", nil, parent, CGOptions._isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
    btn:SetSize(w or 80, h or 22)
    btn._state = false
    function btn:Refresh(val)
        self._state = val
        if CGOptions._isSlick then
            SetSlickButtonText(self, val and "ON" or "OFF")
        else
            self:SetText(val and "ON" or "OFF")
        end
    end
    if CGOptions._isSlick then
        StyleSlickButton(btn)
    end
    btn:Refresh(false)
    return btn
end

local function ColorSwatch(parent, getColorFn, setColorFn)
    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(26, 26)
    swatch:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4)

    function swatch:Refresh()
        local r, g, b = getColorFn()
        if r then self:SetBackdropColor(r, g, b) end
    end

    swatch:SetScript("OnClick", function(self)
        local r, g, b = getColorFn()
        if not r then return end
        local origR, origG, origB = r, g, b
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    swatch:SetBackdropColor(nr, ng, nb)
                    setColorFn(nr, ng, nb)
                end,
                cancelFunc = function(prev)
                    if prev then
                        swatch:SetBackdropColor(prev.r, prev.g, prev.b)
                        setColorFn(prev.r, prev.g, prev.b)
                    end
                end,
                hasOpacity = false,
                r = r, g = g, b = b, opacity = 1,
            })
        else
            ColorPickerFrame.func = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                swatch:SetBackdropColor(nr, ng, nb)
                setColorFn(nr, ng, nb)
            end
            ColorPickerFrame.cancelFunc = function()
                swatch:SetBackdropColor(origR, origG, origB)
                setColorFn(origR, origG, origB)
            end
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end)

    return swatch
end

local function GetFontChoices()
    local choices = {
        { label = "Default", value = nil, path = nil },
        { label = "Friz Quadrata", value = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
        { label = "Arial Narrow", value = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
        { label = "Morpheus", value = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
        { label = "Skurri", value = "Skurri", path = "Fonts\\SKURRI.TTF" },
    }

    local lsm = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if lsm then
        for _, name in ipairs(lsm:List(lsm.MediaType.FONT) or {}) do
            table.insert(choices, {
                label = name,
                value = name,
                path = lsm:Fetch(lsm.MediaType.FONT, name, true),
            })
        end
    end

    return choices
end

local FONT_STYLE_CHOICES = {
    { label = "None", value = "" },
    { label = "Outline", value = "OUTLINE" },
    { label = "Thick Outline", value = "THICKOUTLINE" },
    { label = "Monochrome", value = "MONOCHROME" },
    { label = "Monochrome Outline", value = "OUTLINE, MONOCHROME" },
    { label = "Monochrome Thick", value = "THICKOUTLINE, MONOCHROME" },
}

local function MakeDropdown(parent, name, choices, width, getValue, setValue)
    local function LabelFor(value)
        for _, choice in ipairs(choices) do
            if choice.value == value then return choice.label end
        end
        return choices[1] and choices[1].label or ""
    end

    if CGOptions._isSlick then
        local dd = CreateFrame("Button", name, parent, "BackdropTemplate")
        dd:SetSize(width or 150, 22)
        dd:SetBackdrop(OPTION_BACKDROP)
        dd:SetBackdropColor(CGTheme._buttonColor.r, CGTheme._buttonColor.g, CGTheme._buttonColor.b)
        dd:SetBackdropBorderColor(0, 0, 0)
        if CGTheme and CGTheme.RegisterBtn then CGTheme:RegisterBtn(dd) end

        local valueText = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valueText:SetPoint("LEFT", dd, "LEFT", 8, 0)
        valueText:SetPoint("RIGHT", dd, "RIGHT", -22, 0)
        valueText:SetJustifyH("LEFT")
        valueText:SetWordWrap(false)
        StyleSlickFont(valueText)

        local caret = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        caret:SetPoint("RIGHT", dd, "RIGHT", -7, 0)
        caret:SetText("v")
        StyleSlickFont(caret)

        local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(50)
        popup:SetBackdrop(OPTION_BACKDROP)
        popup:SetBackdropColor(CGTheme._frameColor.r, CGTheme._frameColor.g, CGTheme._frameColor.b)
        popup:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
        if CGTheme and CGTheme.RegisterFrame then CGTheme:RegisterFrame(popup) end
        popup:Hide()
        popup.buttons = {}

        local dismiss = CreateFrame("Frame", nil, UIParent)
        dismiss:SetAllPoints(UIParent)
        dismiss:SetFrameStrata("DIALOG")
        dismiss:SetFrameLevel(49)
        dismiss:EnableMouse(true)
        dismiss:Hide()
        dismiss:SetScript("OnMouseDown", function()
            popup:Hide()
            dismiss:Hide()
        end)

        local function CurrentIndex()
            local value = getValue()
            for index, choice in ipairs(choices) do
                if choice.value == value then return index end
            end
            return 1
        end

        local function Refresh()
            valueText:SetText(LabelFor(getValue()))
        end

        local function RefreshPopup()
            local rowH, gap = 20, 2
            popup:SetSize(dd:GetWidth(), math.max(#choices * (rowH + gap) + 6, 26))
            local activeIndex = CurrentIndex()

            for index, choice in ipairs(choices) do
                local btn = popup.buttons[index]
                if not btn then
                    btn = CreateFrame("Button", nil, popup, "BackdropTemplate")
                    btn:SetBackdrop(OPTION_BACKDROP)
                    btn._label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn._label:SetPoint("LEFT", btn, "LEFT", 8, 0)
                    btn._label:SetPoint("RIGHT", btn, "RIGHT", -22, 0)
                    btn._label:SetJustifyH("LEFT")
                    StyleSlickFont(btn._label)
                    btn._check = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn._check:SetPoint("RIGHT", btn, "RIGHT", -7, 0)
                    StyleSlickFont(btn._check)
                    popup.buttons[index] = btn
                end

                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3 - (index - 1) * (rowH + gap))
                btn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -3, -3 - (index - 1) * (rowH + gap))
                btn:SetHeight(rowH)
                btn._label:SetText(choice.label)
                btn._check:SetText(index == activeIndex and "v" or "")
                btn._checked = index == activeIndex
                btn:SetBackdropColor(btn._checked and 0.12 or 0.06, btn._checked and 0.12 or 0.06, btn._checked and 0.12 or 0.06, 1)
                btn:SetBackdropBorderColor(btn._checked and 1 or 0.18, btn._checked and 0.82 or 0.18, btn._checked and 0 or 0.18, 1)
                btn:SetScript("OnEnter", function(self)
                    self:SetBackdropBorderColor(1, 0.82, 0, 1)
                end)
                btn:SetScript("OnLeave", function(self)
                    self:SetBackdropBorderColor(self._checked and 1 or 0.18, self._checked and 0.82 or 0.18, self._checked and 0 or 0.18, 1)
                end)
                btn:SetScript("OnClick", function()
                    setValue(choice.value, choice.path)
                    Refresh()
                    popup:Hide()
                    dismiss:Hide()
                end)
                btn:Show()
            end

            for index = #choices + 1, #popup.buttons do
                popup.buttons[index]:Hide()
            end
        end

        dd:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 0.82, 0) end)
        dd:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0) end)
        dd:SetScript("OnClick", function(self)
            if popup:IsShown() then
                popup:Hide()
                dismiss:Hide()
                return
            end
            RefreshPopup()
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
            dismiss:Show()
            popup:Show()
        end)

        dd.Refresh = Refresh
        Refresh()
        return dd
    end

    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 150)

    local function Refresh()
        UIDropDownMenu_SetText(dd, LabelFor(getValue()))
    end

    UIDropDownMenu_Initialize(dd, function(self, level)
        for _, choice in ipairs(choices) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = choice.label
            info.checked = getValue() == choice.value
            info.func = function()
                setValue(choice.value, choice.path)
                Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    dd.Refresh = Refresh
    Refresh()
    return dd
end

function CGOptions:Build(isSlick)
    self._isSlick = isSlick and true or false

    local function AnchorToMainFrame(frame)
        if not frame then return end

        local mainFrame = isSlick and _G.CrossGamblingSlick or _G.CrossGamblingClassic
        frame:ClearAllPoints()

        if mainFrame then
            frame:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 10, 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    local TABS = isSlick
        and {"Game", "Theme", "Colors", "Chat", "History"}
        or  {"Game", "Theme", "History"}

    local tabW = math.floor((isSlick and 300 or 260) / #TABS)

    _buildCount = _buildCount + 1
    local frameName = "CGOptionsFrame" .. _buildCount
    local win = CreateFrame("Frame", frameName, UIParent, isSlick and "BackdropTemplate" or "BasicFrameTemplateWithInset")
    win:SetSize(isSlick and 340 or 320, 370)
    if isSlick then
        EnsureBackdrop(win)
        win:SetBackdrop(OPTION_BACKDROP)
        win:SetBackdropBorderColor(0, 0, 0)
        win:SetBackdropColor(CGTheme._frameColor.r, CGTheme._frameColor.g, CGTheme._frameColor.b)
        if CGTheme and CGTheme.RegisterFrame then
            CGTheme:RegisterFrame(win)
        end
    end
    AnchorToMainFrame(win)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetUserPlaced(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop",  win.StopMovingOrSizing)
    win:SetScript("OnShow", function(self)
        AnchorToMainFrame(self)
    end)
    win:Hide()

    local titleText = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", win, "TOP", 0, -5)
    titleText:SetText("CrossGambling \226\128\148 Options")
    if isSlick then
        StyleSlickFont(titleText)
        local closeBtn = MakeButton(win, "X", 22, 20)
        closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() win:Hide() end)
        win.CloseButton = closeBtn
    elseif win.CloseButton then
        win.CloseButton:SetScript("OnClick", function() win:Hide() end)
    end

    local tabBtns   = {}
    local tabPanels = {}

    local tabBar = CreateFrame("Frame", nil, win)
    tabBar:SetHeight(26)
    tabBar:SetPoint("TOPLEFT",  win, "TOPLEFT",  10, -28)
    tabBar:SetPoint("TOPRIGHT", win, "TOPRIGHT", -10, -28)

    for i, name in ipairs(TABS) do
        local tb = CreateFrame("Button", nil, tabBar, isSlick and "BackdropTemplate" or "UIPanelButtonTemplate")
        tb:SetSize(tabW, 24)
        tb:SetPoint("TOPLEFT", tabBar, "TOPLEFT", (i-1)*(tabW+2), 0)
        if isSlick then
            StyleSlickButton(tb)
        end
        if isSlick then
            SetSlickButtonText(tb, name)
        else
            tb:SetText(name)
        end
        tabBtns[i] = tb

        local panel = CreateFrame("Frame", nil, win, isSlick and "BackdropTemplate" or nil)
        panel:SetPoint("TOPLEFT",     win, "TOPLEFT",  10, -62)
        panel:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -10, 10)
        if isSlick then
            panel:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeSize = 1,
            })
            panel:SetBackdropColor(CGTheme._frameColor.r, CGTheme._frameColor.g, CGTheme._frameColor.b)
            panel:SetBackdropBorderColor(0.18, 0.18, 0.18, 0.9)
            if CGTheme and CGTheme.RegisterFrame then
                CGTheme:RegisterFrame(panel)
            end
        end
        panel:Hide()
        tabPanels[i] = panel
    end

    local function ShowTab(idx)
        for i, p in ipairs(tabPanels) do
            if i == idx then p:Show() else p:Hide() end
        end
        for i, b in ipairs(tabBtns) do
            if isSlick then
                SetSlickButtonText(b, TABS[i])
            else
                b:SetText(TABS[i])
            end
            if isSlick and b.SetBackdropBorderColor then
                if i == idx then
                    b:SetBackdropBorderColor(1, 0.82, 0)
                else
                    b:SetBackdropBorderColor(0, 0, 0)
                end
            end
        end
    end

    for i, tb in ipairs(tabBtns) do
        local idx = i
        tb:SetScript("OnClick", function() ShowTab(idx) end)
    end

    local gamePanel = tabPanels[1]
    local ROW_H  = 32
    local LBL_X  = isSlick and 54 or 10
    local VAL_X  = isSlick and 182 or 195
    local START_Y = -10

    local function RowLabel(panel, y, txt)
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", LBL_X, y)
        fs:SetText(txt)
        if isSlick then StyleSlickFont(fs) end
        return fs
    end

    local function Divider(panel, y)
        local t = panel:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        t:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, y)
        t:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
        t:SetColorTexture(0.4, 0.4, 0.4, 0.5)
        return t
    end

    RowLabel(gamePanel, START_Y, "Guild Cut:")
    local guildCutBtn = MakeToggleBtn(gamePanel, 85, 22)
    guildCutBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", VAL_X, START_Y + 4)
    guildCutBtn:SetScript("OnClick", function(self)
        local a = GetAddon()
        self._state = not self._state
        a.game.house = self._state
        self:Refresh(self._state)
        DEFAULT_CHAT_FRAME:AddMessage("CrossGambling: Guild cut " .. (self._state and "ON" or "OFF") .. ".")
    end)

    RowLabel(gamePanel, START_Y - ROW_H, "House Cut %:")
    local houseCutEB = MakeEditBox(gamePanel, 85, 22, 3)
    houseCutEB:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", VAL_X, START_Y - ROW_H + 4)
    houseCutEB:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0,0)
        local v = tonumber(self:GetText())
        if v then GetAddon():SetHouseCut(v) end
    end)

    RowLabel(gamePanel, START_Y - ROW_H*2, "Realm Filter:")
    local realmBtn = MakeToggleBtn(gamePanel, 85, 22)
    realmBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", VAL_X, START_Y - ROW_H*2 + 4)
    realmBtn:SetScript("OnClick", function(self)
        local a = GetAddon()
        self._state = not self._state
        a.game.realmFilter = self._state
        self:Refresh(self._state)
    end)

    RowLabel(gamePanel, START_Y - ROW_H*3, "Join Word:")
    local joinEB = MakeEditBox(gamePanel, 85, 22, 10)
    joinEB:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", VAL_X, START_Y - ROW_H*3 + 4)
    joinEB:SetText("1")
    joinEB:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0,0)
        local v = self:GetText()
        if v and v ~= "" then GetAddon().db.global.joinWord = v end
    end)
    joinEB:SetScript("OnEnterPressed", function(self)
        local v = self:GetText()
        if v and v ~= "" then GetAddon().db.global.joinWord = v end
        self:ClearFocus()
    end)

    RowLabel(gamePanel, START_Y - ROW_H*4, "Leave Word:")
    local leaveEB = MakeEditBox(gamePanel, 85, 22, 10)
    leaveEB:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", VAL_X, START_Y - ROW_H*4 + 4)
    leaveEB:SetText("-1")
    leaveEB:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0,0)
        local v = self:GetText()
        if v and v ~= "" then GetAddon().db.global.leaveWord = v end
    end)
    leaveEB:SetScript("OnEnterPressed", function(self)
        local v = self:GetText()
        if v and v ~= "" then GetAddon().db.global.leaveWord = v end
        self:ClearFocus()
    end)

    Divider(gamePanel, START_Y - ROW_H*5 - 4)

    local statY = START_Y - ROW_H*5 - 12
    local BW, BH = 138, 26
    local statsX = isSlick and 21 or 0

    local fullStatsBtn = MakeButton(gamePanel, "Full Stats", BW, BH)
    fullStatsBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", statsX, statY)
    fullStatsBtn:SetScript("OnClick", function() GetAddon():reportStats(true) end)

    local deathStatsBtn = MakeButton(gamePanel, "DeathRoll Stats", BW, BH)
    deathStatsBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", statsX + BW + 4, statY)
    deathStatsBtn:SetScript("OnClick", function() GetAddon():reportDeathrollStats() end)

    local fameBtn = MakeButton(gamePanel, "Fame / Shame", BW, BH)
    fameBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", statsX, statY - BH - 4)
    fameBtn:SetScript("OnClick", function() GetAddon():reportStats() end)

    local sessionBtn = MakeButton(gamePanel, "Session Stats", BW, BH)
    sessionBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", statsX + BW + 4, statY - BH - 4)
    sessionBtn:SetScript("OnClick", function() GetAddon():reportSessionStats() end)

    local resetBtn = MakeButton(gamePanel, "Reset All Stats", BW*2 + 4, BH)
    resetBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", statsX, statY - (BH+4)*2)
    resetBtn:SetScript("OnClick", function()
        if not StaticPopupDialogs["CG_RESET_STATS"] then
            StaticPopupDialogs["CG_RESET_STATS"] = {
                text         = "Reset ALL stats? This cannot be undone.",
                button1      = "Yes", button2 = "No",
                OnAccept     = function() GetAddon():resetStats(nil) end,
                timeout      = 0, whileDead = true, hideOnEscape = true,
            }
        end
        StaticPopup_Show("CG_RESET_STATS")
    end)

    gamePanel:SetScript("OnShow", function()
        local a = GetAddon()
        if not a or not a.game then return end
        guildCutBtn:Refresh(a.game.house)
        realmBtn:Refresh(a.game.realmFilter)
        houseCutEB:SetText(tostring(a.db.global.houseCut or 10))
        joinEB:SetText(a.db.global.joinWord or "1")
        leaveEB:SetText(a.db.global.leaveWord or "-1")
    end)

    local themePanel = tabPanels[2]

    local themeHdr = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    themeHdr:SetPoint("TOP", themePanel, "TOP", 0, -6)
    themeHdr:SetText("Choose Your Theme")
    if isSlick then StyleSlickFont(themeHdr) end

    local themeSub = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeSub:SetPoint("TOP", themeHdr, "BOTTOM", 0, -4)
    themeSub:SetText("Theme switches instantly — no reload needed.")
    if isSlick then StyleSlickFont(themeSub) end

    local selectedTheme = "Slick"
    local prevW, prevH  = 118, 90

    local classicBox = CreateFrame("Button", nil, themePanel, "BackdropTemplate")
    classicBox:SetSize(prevW, prevH)
    classicBox:SetPoint("TOPLEFT", themePanel, "TOPLEFT", 8, -52)
    classicBox:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\ChatFrame\\ChatFrameBackground",edgeSize=2})
    local ct = classicBox:CreateTexture(nil,"ARTWORK") ct:SetAllPoints()
    ct:SetTexture("Interface\\AddOns\\CrossGambling\\media\\ClassicTheme.tga")
    local classicLbl = themePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    classicLbl:SetPoint("TOP", classicBox, "BOTTOM", 0, -5)
    classicLbl:SetText("Classic")
    if isSlick then StyleSlickFont(classicLbl) end

    local slickBox = CreateFrame("Button", nil, themePanel, "BackdropTemplate")
    slickBox:SetSize(prevW, prevH)
    slickBox:SetPoint("TOPRIGHT", themePanel, "TOPRIGHT", -8, -52)
    slickBox:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\ChatFrame\\ChatFrameBackground",edgeSize=2})
    local st = slickBox:CreateTexture(nil,"ARTWORK") st:SetAllPoints()
    st:SetTexture("Interface\\AddOns\\CrossGambling\\media\\NewTheme.tga")
    local slickLbl = themePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    slickLbl:SetPoint("TOP", slickBox, "BOTTOM", 0, -5)
    slickLbl:SetText("Slick")
    if isSlick then StyleSlickFont(slickLbl) end

    local function UpdateThemeSel()
        if selectedTheme == "Classic" then
            classicBox:SetBackdropBorderColor(1,0.82,0) slickBox:SetBackdropBorderColor(0.2,0.2,0.2)
        else
            slickBox:SetBackdropBorderColor(1,0.82,0)  classicBox:SetBackdropBorderColor(0.2,0.2,0.2)
        end
    end

    classicBox:SetScript("OnClick", function() selectedTheme="Classic" UpdateThemeSel() end)
    slickBox:SetScript("OnClick",   function() selectedTheme="Slick"   UpdateThemeSel() end)

    local confirmBtn = MakeButton(themePanel, "Apply Theme", 280, 28)
    confirmBtn:SetPoint("BOTTOM", themePanel, "BOTTOM", 0, 10)
    confirmBtn:SetScript("OnClick", function()
        local current = GetAddon().db.global.theme or "Slick"
        if selectedTheme == current then
            DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100CrossGambling|r: Already using " .. selectedTheme .. " theme.")
            return
        end
        CGOptions:Toggle()
        CGTheme:Switch(selectedTheme)
    end)

    themePanel:SetScript("OnShow", function()
        local a = GetAddon()
        if a and a.db then selectedTheme = a.db.global.theme or "Slick" end
        UpdateThemeSel()
    end)

    local histPanel = isSlick and tabPanels[5] or tabPanels[3]

    local openLogBtn = MakeButton(histPanel, "Open History Log", 280, 28)
    openLogBtn:SetPoint("TOP", histPanel, "TOP", 0, -10)
    openLogBtn:SetScript("OnClick", function()
        local a  = GetAddon()
        local af = a and a.auditFrame
        if not af then return end
        if af:IsShown() then af:Hide()
        else
            if a and type(a.TrimAuditLog) == "function" then
                a:TrimAuditLog()
            end
            local mainFrame = CGOptions._isSlick and _G.CrossGamblingSlick or _G.CrossGamblingClassic
            if mainFrame then
                af:ClearAllPoints()
                af:SetPoint("TOP", mainFrame, "BOTTOM", 0, -12)
            end
            af:Show() af:UpdateLayout()
            if a and type(a.UpdateAuditLogText) == "function" then
                a:UpdateAuditLogText(af.searchBox and af.searchBox:GetText() or "")
            end
        end
    end)

    local purgeLbl = histPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    purgeLbl:SetPoint("TOPLEFT", histPanel, "TOPLEFT", 10, -52)
    purgeLbl:SetText("Auto-purge entries older than:")
    if isSlick then StyleSlickFont(purgeLbl) end

    local retDays = {5, 10, 30, "Never"}
    local retCBs  = {}
    local CBW     = 60

    for i, val in ipairs(retDays) do
        local cb = CreateFrame("CheckButton", nil, histPanel, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", histPanel, "TOPLEFT", 10 + (i-1)*CBW, -74)
        if cb.Text then cb.Text:Hide() end
        local lbl2 = cb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        lbl2:SetPoint("TOP", cb, "BOTTOM", 0, -2)
        lbl2:SetText(type(val)=="number" and (val.."d") or "Never")
        if isSlick then StyleSlickFont(lbl2) end
        cb.days = val
        cb:SetScript("OnClick", function(self)
            for _, c in pairs(retCBs) do c:SetChecked(false) end
            self:SetChecked(true)
            GetAddon().db.global.auditRetention = self.days
        end)
        retCBs[i] = cb
    end

    local purgeNowBtn = MakeButton(histPanel, "Purge Log Now", 280, 28)
    purgeNowBtn:SetPoint("TOP", histPanel, "TOP", 0, -115)
    purgeNowBtn:SetScript("OnClick", function()
        local a = GetAddon()
        a.db.global.auditLog = {}
        local af = a.auditFrame
        if af then a:UpdateAuditLogText(af.searchBox and af.searchBox:GetText() or "") end
        DEFAULT_CHAT_FRAME:AddMessage("CrossGambling: History log purged.")
    end)

    histPanel:SetScript("OnShow", function()
        local a = GetAddon()
        if not a or not a.db then return end
        for _, cb in pairs(retCBs) do
            cb:SetChecked(a.db.global.auditRetention == cb.days)
        end
    end)

    if isSlick then
        local colPanel = tabPanels[3]

        local colHdr = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        colHdr:SetPoint("TOP", colPanel, "TOP", 0, -6)
        colHdr:SetText("Slick Theme Colours")
        StyleSlickFont(colHdr)

        local colSub = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        colSub:SetPoint("TOP", colHdr, "BOTTOM", 0, -2)
        colSub:SetText("Click a colour swatch to change it")
        StyleSlickFont(colSub)

        local ROW_BAR_H = 26
        local ROW_GAP   = 6
        local BAR_LEFT  = 10
        local BAR_RIGHT = -10
        local LABEL_W   = 110

        local colItems = {
            {
                label = "Frame Color",
                get   = function() return CGTheme._frameColor.r,  CGTheme._frameColor.g,  CGTheme._frameColor.b  end,
                set   = function(r,g,b) CGTheme._frameColor.r,CGTheme._frameColor.g,CGTheme._frameColor.b=r,g,b; CGTheme:ApplyColors(); CGTheme:SaveColors() end,
            },
            {
                label = "Button Color",
                get   = function() return CGTheme._buttonColor.r, CGTheme._buttonColor.g, CGTheme._buttonColor.b end,
                set   = function(r,g,b) CGTheme._buttonColor.r,CGTheme._buttonColor.g,CGTheme._buttonColor.b=r,g,b; CGTheme:ApplyColors(); CGTheme:SaveColors() end,
            },
            {
                label = "Side Color",
                get   = function() return CGTheme._sideColor.r,   CGTheme._sideColor.g,   CGTheme._sideColor.b   end,
                set   = function(r,g,b) CGTheme._sideColor.r,CGTheme._sideColor.g,CGTheme._sideColor.b=r,g,b; CGTheme:ApplyColors(); CGTheme:SaveColors() end,
            },
            {
                label = "Font Color",
                get   = function() return CGTheme._fontColor.r,   CGTheme._fontColor.g,   CGTheme._fontColor.b   end,
                set   = function(r,g,b) CGTheme:SetFontColor(r,g,b); CGTheme:SaveColors() end,
            },
        }

        local swatches  = {}
        local firstRowY = -36

        for i, item in ipairs(colItems) do
            local rowY = firstRowY - (i - 1) * (ROW_BAR_H + ROW_GAP)

            local rowBg = CreateFrame("Frame", nil, colPanel, "BackdropTemplate")
            rowBg:SetHeight(ROW_BAR_H)
            rowBg:SetPoint("TOPLEFT",  colPanel, "TOPLEFT",  BAR_LEFT,  rowY)
            rowBg:SetPoint("TOPRIGHT", colPanel, "TOPRIGHT", BAR_RIGHT, rowY)
            rowBg:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeSize = 1,
            })
            rowBg:SetBackdropColor(0.08, 0.08, 0.08)
            rowBg:SetBackdropBorderColor(0.25, 0.25, 0.25)

            local lbl = rowBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", rowBg, "LEFT", 8, 0)
            lbl:SetText(item.label)
            StyleSlickFont(lbl)

            local sw = CreateFrame("Button", nil, rowBg, "BackdropTemplate")
            sw:SetHeight(ROW_BAR_H - 4)
            sw:SetPoint("LEFT",  rowBg, "LEFT",  LABEL_W, 2)
            sw:SetPoint("RIGHT", rowBg, "RIGHT", -2,      2)
            sw:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeSize = 1,
            })
            sw:SetBackdropBorderColor(0, 0, 0)

            function sw:Refresh()
                local r, g, b = item.get()
                if r then self:SetBackdropColor(r, g, b) end
            end

            sw:SetScript("OnClick", function(self)
                local r, g, b = item.get()
                if not r then return end
                local origR, origG, origB = r, g, b
                if ColorPickerFrame.SetupColorPickerAndShow then
                    ColorPickerFrame:SetupColorPickerAndShow({
                        swatchFunc = function()
                            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                            self:SetBackdropColor(nr, ng, nb)
                            item.set(nr, ng, nb)
                        end,
                        cancelFunc = function(prev)
                            if prev then
                                self:SetBackdropColor(prev.r, prev.g, prev.b)
                                item.set(prev.r, prev.g, prev.b)
                            end
                        end,
                        hasOpacity = false,
                        r = r, g = g, b = b, opacity = 1,
                    })
                else
                    ColorPickerFrame.func = function()
                        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                        self:SetBackdropColor(nr, ng, nb)
                        item.set(nr, ng, nb)
                    end
                    ColorPickerFrame.cancelFunc = function()
                        self:SetBackdropColor(origR, origG, origB)
                        item.set(origR, origG, origB)
                    end
                    ColorPickerFrame.hasOpacity = false
                    ColorPickerFrame:SetColorRGB(r, g, b)
                    ColorPickerFrame:Hide()
                    ColorPickerFrame:Show()
                end
            end)

            sw:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 0.82, 0) end)
            sw:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0) end)

            table.insert(swatches, sw)
        end

        local sliderBaseY = firstRowY - #colItems * (ROW_BAR_H + ROW_GAP) - 10

        local fontSizeLbl = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontSizeLbl:SetPoint("TOPLEFT", colPanel, "TOPLEFT", BAR_LEFT, sliderBaseY)
        fontSizeLbl:SetText("Font Size:")
        StyleSlickFont(fontSizeLbl)

        local fontSizeSlider = CreateFrame("Slider", "CGUIFontSizeSlider", colPanel, "OptionsSliderTemplate")
        fontSizeSlider:SetPoint("TOPLEFT",  colPanel, "TOPLEFT",  BAR_LEFT + 10, sliderBaseY - 20)
        fontSizeSlider:SetPoint("TOPRIGHT", colPanel, "TOPRIGHT", BAR_RIGHT - 30, sliderBaseY - 20)
        fontSizeSlider:SetMinMaxValues(8, 24)
        fontSizeSlider:SetValueStep(1)
        fontSizeSlider:SetObeyStepOnDrag(true)

        local sliderTitle = _G["CGUIFontSizeSliderText"]
        if sliderTitle then sliderTitle:SetText("Font Size"); StyleSlickFont(sliderTitle) end
        local sliderLow = _G["CGUIFontSizeSliderLow"]
        if sliderLow then sliderLow:SetText("8"); StyleSlickFont(sliderLow) end
        local sliderHigh = _G["CGUIFontSizeSliderHigh"]
        if sliderHigh then sliderHigh:SetText("24"); StyleSlickFont(sliderHigh) end

        local sliderValLbl = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sliderValLbl:SetPoint("LEFT", fontSizeSlider, "RIGHT", 6, 0)
        StyleSlickFont(sliderValLbl)

        fontSizeSlider:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val + 0.5)
            sliderValLbl:SetText(tostring(val))
            local a = GetAddon()
            if a and a.db then
                a.db.global.uiFontSize = val
                CGTheme:ApplyFont()
            end
        end)

        local fontLbl = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontLbl:SetPoint("TOPLEFT", colPanel, "TOPLEFT", BAR_LEFT, sliderBaseY - 58)
        fontLbl:SetText("Font:")
        StyleSlickFont(fontLbl)

        local fontDropdown = MakeDropdown(colPanel, "CGUIFontDropdown", GetFontChoices(), 180,
            function()
                local a = GetAddon()
                return a and a.db and a.db.global.fontMedia
            end,
            function(value, path)
                local a = GetAddon()
                if a and a.db then
                    a.db.global.fontMedia = value
                    a.db.global.fontMediaPath = path
                    CGTheme:ApplyFont()
                end
            end)
        fontDropdown:SetPoint("TOPLEFT", colPanel, "TOPLEFT", BAR_LEFT + 0, sliderBaseY - 54)

        local outlineLbl = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        outlineLbl:SetPoint("TOPLEFT", colPanel, "TOPLEFT", BAR_LEFT, sliderBaseY - 92)
        outlineLbl:SetText("Outline:")
        StyleSlickFont(outlineLbl)

        local outlineDropdown = MakeDropdown(colPanel, "CGUIFontOutlineDropdown", FONT_STYLE_CHOICES, 100,
            function()
                local a = GetAddon()
                return (a and a.db and a.db.global.fontFlags) or ""
            end,
            function(value)
                local a = GetAddon()
                if a and a.db then
                    a.db.global.fontFlags = value or ""
                    CGTheme:ApplyFont()
                end
            end)
        outlineDropdown:SetPoint("TOPLEFT", colPanel, "TOPLEFT", BAR_LEFT + 190, sliderBaseY - 54)

        local resetColBtn = CreateFrame("Button", nil, colPanel, "BackdropTemplate")
        resetColBtn:SetHeight(28)
        resetColBtn:SetPoint("BOTTOMLEFT",  colPanel, "BOTTOMLEFT",  BAR_LEFT,  12)
        resetColBtn:SetPoint("BOTTOMRIGHT", colPanel, "BOTTOMRIGHT", BAR_RIGHT, 12)
        resetColBtn:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeSize = 1,
        })
        resetColBtn:SetBackdropColor(0.10, 0.08, 0.02)
        resetColBtn:SetBackdropBorderColor(0.78, 0.61, 0.12)

        local resetLbl = resetColBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        resetLbl:SetAllPoints()
        resetLbl:SetJustifyH("CENTER")
        resetLbl:SetText("Reset to Default Colors")
        StyleSlickFont(resetLbl)

        resetColBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 0.92, 0.3)
        end)
        resetColBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.78, 0.61, 0.12)
        end)
        resetColBtn:SetScript("OnClick", function()
            local a = GetAddon()
            if a and a.db then
                a.db.global.colors = {
                    frameColor  = {r=0.27, g=0.27, b=0.27},
                    buttonColor = {r=0.30, g=0.30, b=0.30},
                    sideColor   = {r=0.20, g=0.20, b=0.20},
                    fontColor   = {r=1,    g=0.82, b=0   },
                    chatFontColor = {r=1,  g=0.82, b=0   },
                }
            end
            CGTheme:ChangeColor("resetColors")
            for _, sw in ipairs(swatches) do sw:Refresh() end
            DEFAULT_CHAT_FRAME:AddMessage("CrossGambling: Colors reset to defaults.")
        end)

        colPanel:SetScript("OnShow", function()
            for _, sw in ipairs(swatches) do sw:Refresh() end
            local a = GetAddon()
            local fsVal = (a and a.db and a.db.global.uiFontSize) or 12
            fontSizeSlider:SetValue(fsVal)
            sliderValLbl:SetText(tostring(math.floor(fsVal + 0.5)))
            fontDropdown.Refresh()
            outlineDropdown.Refresh()
        end)

        local chatPanel = tabPanels[4]

        local chatHdr = chatPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        chatHdr:SetPoint("TOP", chatPanel, "TOP", 0, -6)
        chatHdr:SetText("Chat Settings")
        StyleSlickFont(chatHdr)

        local chatRows = {}
        local chatRowY = -74

        local function ChatRow(label)
            local rowBg = CreateFrame("Frame", nil, chatPanel, "BackdropTemplate")
            rowBg:SetHeight(ROW_BAR_H)
            rowBg:SetPoint("TOPLEFT",  chatPanel, "TOPLEFT",  BAR_LEFT,  chatRowY)
            rowBg:SetPoint("TOPRIGHT", chatPanel, "TOPRIGHT", BAR_RIGHT, chatRowY)
            rowBg:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeSize = 1,
            })
            rowBg:SetBackdropColor(0.08, 0.08, 0.08)
            rowBg:SetBackdropBorderColor(0.25, 0.25, 0.25)

            local lbl = rowBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", rowBg, "LEFT", 8, 0)
            lbl:SetText(label)
            StyleSlickFont(lbl)

            chatRowY = chatRowY - (ROW_BAR_H + ROW_GAP)
            table.insert(chatRows, rowBg)
            return rowBg
        end

        local chatSizeRow = ChatRow("Chat Font Size")

        local chatFontSizeSlider = CreateFrame("Slider", "CGChatFontSizeSlider", chatPanel, "OptionsSliderTemplate")
        chatFontSizeSlider:SetPoint("LEFT",  chatSizeRow, "LEFT",  LABEL_W + 8, 0)
        chatFontSizeSlider:SetPoint("RIGHT", chatSizeRow, "RIGHT", -40, 0)
        chatFontSizeSlider:SetMinMaxValues(8, 24)
        chatFontSizeSlider:SetValueStep(1)
        chatFontSizeSlider:SetObeyStepOnDrag(true)

        local chatSliderTitle = _G["CGChatFontSizeSliderText"]
        if chatSliderTitle then chatSliderTitle:SetText("Font Size"); StyleSlickFont(chatSliderTitle) end
        local chatSliderLow = _G["CGChatFontSizeSliderLow"]
        if chatSliderLow then chatSliderLow:SetText("8"); StyleSlickFont(chatSliderLow) end
        local chatSliderHigh = _G["CGChatFontSizeSliderHigh"]
        if chatSliderHigh then chatSliderHigh:SetText("24"); StyleSlickFont(chatSliderHigh) end

        local chatSliderValLbl = chatPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chatSliderValLbl:SetPoint("LEFT", chatFontSizeSlider, "RIGHT", 6, 0)
        StyleSlickFont(chatSliderValLbl)

        chatFontSizeSlider:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val + 0.5)
            chatSliderValLbl:SetText(tostring(val))
            local a = GetAddon()
            if a and a.db then
                a.db.global.chatFontSize = val
                a.db.global.fontvalue = val
                if CGChat and CGChat.SetFontSize then CGChat:SetFontSize(val) end
            end
        end)

        chatRowY = -42
        local chatColorRow = ChatRow("Chat Font Color")

        local chatColorSwatch = CreateFrame("Button", nil, chatColorRow, "BackdropTemplate")
        chatColorSwatch:SetHeight(ROW_BAR_H - 4)
        chatColorSwatch:SetPoint("LEFT",  chatColorRow, "LEFT",  LABEL_W, 2)
        chatColorSwatch:SetPoint("RIGHT", chatColorRow, "RIGHT", -2,      2)
        chatColorSwatch:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeSize = 1,
        })
        chatColorSwatch:SetBackdropBorderColor(0, 0, 0)

        function chatColorSwatch:Refresh()
            local a = GetAddon()
            local c = a and a.db and a.db.global.colors
            local color = c and (c.chatFontColor or c.fontColor)
            if color then self:SetBackdropColor(color.r, color.g, color.b) end
        end

        chatColorSwatch:SetScript("OnClick", function(self)
            local a = GetAddon()
            local c = a and a.db and a.db.global.colors
            local color = c and (c.chatFontColor or c.fontColor)
            if not color then return end
            local origR, origG, origB = color.r, color.g, color.b
            local function applyColor(r, g, b)
                c.chatFontColor = c.chatFontColor or {}
                c.chatFontColor.r, c.chatFontColor.g, c.chatFontColor.b = r, g, b
                self:SetBackdropColor(r, g, b)
                if CGChat and CGChat.RefreshFont then CGChat:RefreshFont() end
            end

            if ColorPickerFrame.SetupColorPickerAndShow then
                ColorPickerFrame:SetupColorPickerAndShow({
                    swatchFunc = function()
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        applyColor(r, g, b)
                    end,
                    cancelFunc = function(prev)
                        if prev then applyColor(prev.r, prev.g, prev.b) end
                    end,
                    hasOpacity = false,
                    r = color.r, g = color.g, b = color.b, opacity = 1,
                })
            else
                ColorPickerFrame.func = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    applyColor(r, g, b)
                end
                ColorPickerFrame.cancelFunc = function()
                    applyColor(origR, origG, origB)
                end
                ColorPickerFrame.hasOpacity = false
                ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
                ColorPickerFrame:Hide()
                ColorPickerFrame:Show()
            end
        end)
        chatColorSwatch:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 0.82, 0) end)
        chatColorSwatch:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0) end)

        chatPanel:SetScript("OnShow", function()
            local a = GetAddon()
            local fsVal = (a and a.db and a.db.global.chatFontSize) or (a and a.db and a.db.global.fontvalue) or 12
            chatFontSizeSlider:SetValue(fsVal)
            chatSliderValLbl:SetText(tostring(math.floor(fsVal + 0.5)))
            chatColorSwatch:Refresh()
        end)
    end

    ShowTab(1)
    CGOptions.frame   = win
    CGOptions.ShowTab = ShowTab
    return win
end

function CGOptions:Rebuild(isSlick)
    if self.frame then
        self.frame:Hide()
        self.frame:SetParent(nil)
        self.frame = nil
        self.ShowTab = nil
    end
    self:Build(isSlick)
end

function CGOptions:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

function CGOptions:Open(tabName)
    if not self.frame then return end
    self.frame:Show()
    local map = self._isSlick
        and {Game=1, Theme=2, Colors=3, Chat=4, ["Chat Settings"]=4, History=5}
        or  {Game=1, Theme=2, History=3}
    if tabName and map[tabName] and self.ShowTab then self.ShowTab(map[tabName]) end
end
