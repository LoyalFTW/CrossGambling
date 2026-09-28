local _, ns = ...
local CrossGambling = ns.CG

local uiThemes = {
    "Classic",
    "Slick"
}

function CrossGambling:BuildUI()
    if self.uiBuilt then return end
    if self.db.global.themechoice == 1 then
        self:ShowThemePicker()
        return
    end
    self.uiBuilt = true
    if self.db.global.theme == uiThemes[2] then
        self:DrawMainEvents()
    elseif self.db.global.theme == uiThemes[1] then
        self:DrawMainEvents2()
    end
end

function CrossGambling:ShowThemePicker()
    if self.themePickerFrame then
        self.themePickerFrame:Show()
        return
    end

    local picker = CreateFrame("Frame", "CrossGamblingThemePicker", UIParent, "BasicFrameTemplateWithInset")
    picker:SetSize(1000, 320)
    picker:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    picker:SetMovable(true)
    picker:EnableMouse(true)
    picker:SetUserPlaced(true)
    picker:SetClampedToScreen(true)
    picker:RegisterForDrag("LeftButton")
    picker:SetScript("OnDragStart", picker.StartMoving)
    picker:SetScript("OnDragStop", picker.StopMovingOrSizing)
    self.themePickerFrame = picker

    local header = picker:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOP", picker, "TOP", 0, -2)
    header:SetText("CrossGambling")

    local subtext = picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtext:SetPoint("TOP", picker, "TOP", 0, -50)
    subtext:SetText("Choose between Classic or Slick style. Click Confirm to switch instantly.\nClosing this window will default to Slick.")

    local pickerSelected = "Slick"

    local classicThumb = picker:CreateTexture(nil, "ARTWORK")
    classicThumb:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", 0, 10)
    classicThumb:SetTexture("Interface\\AddOns\\CrossGambling\\media\\ClassicTheme.tga")

    local slickThumb = picker:CreateTexture(nil, "ARTWORK")
    slickThumb:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", 0, 10)
    slickThumb:SetTexture("Interface\\AddOns\\CrossGambling\\media\\NewTheme.tga")
    slickThumb:SetSize(608, 280)

    local function makeRadioBtn(parent, label, x, y)
        local btn = CreateFrame("CheckButton", nil, parent)
        btn:SetSize(26, 26)
        btn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
        btn:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        btn:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", btn, "RIGHT", 4, 0)
        lbl:SetText(label)
        return btn
    end

    local oldThemeBtn = makeRadioBtn(picker, "Old Theme", 220, 10)
    local newThemeBtn = makeRadioBtn(picker, "New Theme", 620, 10)
    newThemeBtn:SetChecked(true)

    oldThemeBtn:SetScript("OnClick", function()
        pickerSelected = "Classic"
        oldThemeBtn:SetChecked(true)
        newThemeBtn:SetChecked(false)
    end)

    newThemeBtn:SetScript("OnClick", function()
        pickerSelected = "Slick"
        newThemeBtn:SetChecked(true)
        oldThemeBtn:SetChecked(false)
    end)

    local function confirmChoice(theme)
        self.db.global.themechoice = 0
        self.db.global.theme = theme
        picker:Hide()
        self.uiBuilt = true
        CGTheme:ClearRegistry()
        if theme == uiThemes[2] then
            self:DrawMainEvents()
        else
            self:DrawMainEvents2()
        end
    end

    local confirmBtn = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
    confirmBtn:SetSize(100, 26)
    confirmBtn:SetPoint("BOTTOM", picker, "BOTTOM", 0, 10)
    confirmBtn:SetText("Confirm")
    confirmBtn:SetScript("OnClick", function()
        confirmChoice(pickerSelected)
    end)

    picker.CloseButton:SetScript("OnClick", function()
        confirmChoice("Slick")
    end)

    picker:Show()
end

function CrossGambling:ToggleGUI(info, isShowing)
    self:BuildUI()
    local method = isShowing and "Show" or "Hide"
    local theme = self.db.global.theme

    if theme == uiThemes[1] then
        CrossGambling[method .. "Classic"](CrossGambling)
    elseif theme == uiThemes[2] then
        CrossGambling[method .. "Slick"](CrossGambling)
    end
end
