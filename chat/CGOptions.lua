CGOptions = {}
local _buildCount = 0

local function GetAddon()
    return LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
end

local function MakeButton(parent, text, w, h)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w or 120, h or 26)
    btn:SetText(text)
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
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w or 80, h or 22)
    btn._state = false
    function btn:Refresh(val)
        self._state = val
        self:SetText(val and "|cff00ff00ON|r" or "|cffff4444OFF|r")
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

function CGOptions:Build(isSlick)

    local TABS = isSlick
        and {"Game", "Theme", "Colors", "History"}
        or  {"Game", "Theme", "History"}

    local tabW = math.floor(260 / #TABS)

    _buildCount = _buildCount + 1
    local frameName = "CGOptionsFrame" .. _buildCount
    local win = CreateFrame("Frame", frameName, UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(320, 370)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetUserPlaced(true)
    win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop",  win.StopMovingOrSizing)
    win:Hide()

    local titleText = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", win, "TOP", 0, -5)
    titleText:SetText("CrossGambling \226\128\148 Options")

    win.CloseButton:SetScript("OnClick", function() win:Hide() end)

    local tabBtns   = {}
    local tabPanels = {}

    local tabBar = CreateFrame("Frame", nil, win)
    tabBar:SetHeight(26)
    tabBar:SetPoint("TOPLEFT",  win, "TOPLEFT",  10, -28)
    tabBar:SetPoint("TOPRIGHT", win, "TOPRIGHT", -10, -28)

    for i, name in ipairs(TABS) do
        local tb = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
        tb:SetSize(tabW, 24)
        tb:SetText(name)
        tb:SetPoint("TOPLEFT", tabBar, "TOPLEFT", (i-1)*(tabW+2), 0)
        tabBtns[i] = tb

        local panel = CreateFrame("Frame", nil, win)
        panel:SetPoint("TOPLEFT",     win, "TOPLEFT",  10, -62)
        panel:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -10, 10)
        panel:Hide()
        tabPanels[i] = panel
    end

    local function ShowTab(idx)
        for i, p in ipairs(tabPanels) do
            if i == idx then p:Show() else p:Hide() end
        end
        for i, b in ipairs(tabBtns) do
            b:SetText(i == idx and ("|cffFFD100"..TABS[i].."|r") or TABS[i])
        end
    end

    for i, tb in ipairs(tabBtns) do
        local idx = i
        tb:SetScript("OnClick", function() ShowTab(idx) end)
    end

    local gamePanel = tabPanels[1]
    local ROW_H  = 32
    local LBL_X  = 10
    local VAL_X  = 195
    local START_Y = -10

    local function RowLabel(panel, y, txt)
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", LBL_X, y)
        fs:SetText(txt)
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
        if v then GetAddon().db.global.houseCut = v end
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

    local fullStatsBtn = MakeButton(gamePanel, "Full Stats", BW, BH)
    fullStatsBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", 0, statY)
    fullStatsBtn:SetScript("OnClick", function() GetAddon():reportStats(nil, true) end)

    local deathStatsBtn = MakeButton(gamePanel, "DeathRoll Stats", BW, BH)
    deathStatsBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", BW + 4, statY)
    deathStatsBtn:SetScript("OnClick", function() GetAddon():reportDeathrollStats() end)

    local fameBtn = MakeButton(gamePanel, "Fame / Shame", BW, BH)
    fameBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", 0, statY - BH - 4)
    fameBtn:SetScript("OnClick", function() GetAddon():reportStats() end)

    local sessionBtn = MakeButton(gamePanel, "Session Stats", BW, BH)
    sessionBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", BW + 4, statY - BH - 4)
    sessionBtn:SetScript("OnClick", function() GetAddon():reportSessionStats() end)

    local resetBtn = MakeButton(gamePanel, "Reset All Stats", BW*2 + 4, BH)
    resetBtn:SetPoint("TOPLEFT", gamePanel, "TOPLEFT", 0, statY - (BH+4)*2)
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

    local themeSub = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeSub:SetPoint("TOP", themeHdr, "BOTTOM", 0, -4)
    themeSub:SetText("UI will reload after confirming.")

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

    local slickBox = CreateFrame("Button", nil, themePanel, "BackdropTemplate")
    slickBox:SetSize(prevW, prevH)
    slickBox:SetPoint("TOPRIGHT", themePanel, "TOPRIGHT", -8, -52)
    slickBox:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\ChatFrame\\ChatFrameBackground",edgeSize=2})
    local st = slickBox:CreateTexture(nil,"ARTWORK") st:SetAllPoints()
    st:SetTexture("Interface\\AddOns\\CrossGambling\\media\\NewTheme.tga")
    local slickLbl = themePanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    slickLbl:SetPoint("TOP", slickBox, "BOTTOM", 0, -5)
    slickLbl:SetText("Slick")

    local function UpdateThemeSel()
        if selectedTheme == "Classic" then
            classicBox:SetBackdropBorderColor(1,0.82,0) slickBox:SetBackdropBorderColor(0.2,0.2,0.2)
            classicLbl:SetTextColor(1,0.82,0)          slickLbl:SetTextColor(1,1,1)
        else
            slickBox:SetBackdropBorderColor(1,0.82,0)  classicBox:SetBackdropBorderColor(0.2,0.2,0.2)
            slickLbl:SetTextColor(1,0.82,0)            classicLbl:SetTextColor(1,1,1)
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

    local histPanel = isSlick and tabPanels[4] or tabPanels[3]

    local openLogBtn = MakeButton(histPanel, "Open History Log", 280, 28)
    openLogBtn:SetPoint("TOP", histPanel, "TOP", 0, -10)
    openLogBtn:SetScript("OnClick", function()
        local a  = GetAddon()
        local af = a and a.auditFrame
        if not af then return end
        if af:IsShown() then af:Hide()
        else
            a:PurgeOldAuditEntries()
            af:Show() af:UpdateLayout()
            a:UpdateAuditLogText(af.searchBox and af.searchBox:GetText() or "")
        end
    end)

    local purgeLbl = histPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    purgeLbl:SetPoint("TOPLEFT", histPanel, "TOPLEFT", 10, -52)
    purgeLbl:SetText("Auto-purge entries older than:")

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
        colHdr:SetTextColor(1, 0.82, 0)
        colHdr:SetText("Slick Theme Colours")

        local colSub = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        colSub:SetPoint("TOP", colHdr, "BOTTOM", 0, -2)
        colSub:SetTextColor(0.7, 0.7, 0.7)
        colSub:SetText("Click a colour swatch to change it")

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
        fontSizeLbl:SetText("Chat Font Size:")

        local fontSizeSlider = CreateFrame("Slider", "CGFontSizeSlider", colPanel, "OptionsSliderTemplate")
        fontSizeSlider:SetPoint("TOPLEFT",  colPanel, "TOPLEFT",  BAR_LEFT + 10, sliderBaseY - 20)
        fontSizeSlider:SetPoint("TOPRIGHT", colPanel, "TOPRIGHT", BAR_RIGHT - 30, sliderBaseY - 20)
        fontSizeSlider:SetMinMaxValues(8, 24)
        fontSizeSlider:SetValueStep(1)
        fontSizeSlider:SetObeyStepOnDrag(true)

        local sliderTitle = _G["CGFontSizeSliderText"]
        if sliderTitle then sliderTitle:SetText("Font Size") end
        local sliderLow = _G["CGFontSizeSliderLow"]
        if sliderLow then sliderLow:SetText("8") end
        local sliderHigh = _G["CGFontSizeSliderHigh"]
        if sliderHigh then sliderHigh:SetText("24") end

        local sliderValLbl = colPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sliderValLbl:SetPoint("LEFT", fontSizeSlider, "RIGHT", 6, 0)

        fontSizeSlider:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val + 0.5)
            sliderValLbl:SetText(tostring(val))
            local a = GetAddon()
            if a and a.db then
                a.db.global.chatFontSize = val
                if CGChat and CGChat.SetFontSize then CGChat:SetFontSize(val) end
            end
        end)

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
        resetLbl:SetTextColor(1, 0.82, 0)
        resetLbl:SetText("Reset to Default Colors")

        resetColBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 0.92, 0.3)
            resetLbl:SetTextColor(1, 0.95, 0.4)
        end)
        resetColBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.78, 0.61, 0.12)
            resetLbl:SetTextColor(1, 0.82, 0)
        end)
        resetColBtn:SetScript("OnClick", function()
            local a = GetAddon()
            if a and a.db then
                a.db.global.colors = {
                    frameColor  = {r=0.27, g=0.27, b=0.27},
                    buttonColor = {r=0.30, g=0.30, b=0.30},
                    sideColor   = {r=0.20, g=0.20, b=0.20},
                    fontColor   = {r=1,    g=0,    b=0   },
                }
            end
            CGTheme:ChangeColor("resetColors")
            for _, sw in ipairs(swatches) do sw:Refresh() end
            DEFAULT_CHAT_FRAME:AddMessage("CrossGambling: Colors reset to defaults.")
        end)

        colPanel:SetScript("OnShow", function()
            for _, sw in ipairs(swatches) do sw:Refresh() end
            local a = GetAddon()
            local fsVal = (a and a.db and a.db.global.chatFontSize) or 12
            fontSizeSlider:SetValue(fsVal)
            sliderValLbl:SetText(tostring(math.floor(fsVal + 0.5)))
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
    local map = {Game=1, Theme=2, Colors=3, History=4}
    if tabName and map[tabName] and self.ShowTab then self.ShowTab(map[tabName]) end
end
