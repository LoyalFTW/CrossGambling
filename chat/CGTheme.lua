CGTheme = {}

CGTheme._frameColor  = {r = 0.27, g = 0.27, b = 0.27}
CGTheme._buttonColor = {r = 0.30, g = 0.30, b = 0.30}
CGTheme._sideColor   = {r = 0.20, g = 0.20, b = 0.20}
CGTheme._fontColor   = {r = 1.00, g = 0.82, b = 0.00}

CGTheme._btnFrames  = {}
CGTheme._sideFrames = {}
CGTheme._frameFrames = {}
CGTheme._fontStrings = {}
CGTheme._mainFrame  = nil

CGTheme.isSlick = false

local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"
local DEFAULT_FONT_FLAGS = ""

local function NormalizeFontFlags(flags)
    if flags == nil or flags == false then
        return DEFAULT_FONT_FLAGS
    end

    if type(flags) ~= "string" then
        return DEFAULT_FONT_FLAGS
    end

    local normalized = flags:upper():gsub("%s+", "")
    if normalized == "" or normalized == "NONE" then
        return ""
    end

    local tokens = {}
    for token in normalized:gmatch("[^,]+") do
        tokens[token] = true
    end

    local hasMono = tokens.MONOCHROME and true or false
    local hasThick = tokens.THICKOUTLINE and true or false
    local hasOutline = hasThick or tokens.OUTLINE

    if hasThick then
        return hasMono and "THICKOUTLINE, MONOCHROME" or "THICKOUTLINE"
    end
    if hasOutline then
        return hasMono and "OUTLINE, MONOCHROME" or "OUTLINE"
    end
    if hasMono then
        return "MONOCHROME"
    end

    return DEFAULT_FONT_FLAGS
end

function CGTheme:GetFontPath()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    local db = a and a.db and a.db.global
    if not db then return DEFAULT_FONT end

    if type(db.fontMediaPath) == "string" and db.fontMediaPath ~= "" then
        return db.fontMediaPath
    end

    local lsm = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if lsm and db.fontMedia then
        local path = lsm:Fetch(lsm.MediaType.FONT, db.fontMedia, true)
        if type(path) == "string" and path ~= "" then
            return path
        end
    end

    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end

    return DEFAULT_FONT
end

function CGTheme:GetFontSize()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    return (a and a.db and a.db.global and a.db.global.uiFontSize) or 12
end

function CGTheme:GetFontFlags()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    local flags = a and a.db and a.db.global and a.db.global.fontFlags
    return NormalizeFontFlags(flags)
end

function CGTheme:RegisterBtn(frame)
    table.insert(self._btnFrames, frame)
    if frame and frame.GetFontString then
        local fs = frame:GetFontString()
        if fs then
            self:RegisterFont(fs)
        end
    end
end

function CGTheme:RegisterSide(frame)
    table.insert(self._sideFrames, frame)
end

function CGTheme:RegisterFrame(frame)
    table.insert(self._frameFrames, frame)
end

function CGTheme:RegisterFont(fontString)
    table.insert(self._fontStrings, fontString)
    if fontString and fontString.SetTextColor then
        fontString:SetTextColor(self._fontColor.r, self._fontColor.g, self._fontColor.b)
        fontString:SetFont(self:GetFontPath(), self:GetFontSize(), self:GetFontFlags())
    end
end

function CGTheme:RegisterMain(frame)
    self._mainFrame = frame
end

function CGTheme:ClearRegistry()
    self._btnFrames  = {}
    self._sideFrames = {}
    self._frameFrames = {}
    self._fontStrings = {}
    self._mainFrame  = nil
end

function CGTheme:GetTheme()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    if a and a.db then return a.db.global.theme or "Slick" end
    return "Slick"
end

function CGTheme:Init()
    local theme = self:GetTheme()
    self.isSlick = (theme == "Slick")
    CGOptions:Build(self.isSlick) 
end

function CGTheme:Switch(name)
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    if not a or not a.db then return end

    a.db.global.theme = name
    self.isSlick = (name == "Slick")

    local framesToHide = {
        "CrossGamblingSlick",
        "CrossGamblingClassic",
        "CrossGamblingTheme",
        "CrossGamblingAuditLogFrame",
        "CGRightMenuChat",
        "CGRightMenu",
    }
    for _, fname in ipairs(framesToHide) do
        local f = _G[fname]
        if f and f.Hide then f:Hide() end
    end

    if a.auditFrame then
        a.auditFrame:Hide()
        a.auditFrame = nil
    end

    self:ClearRegistry()
    a.uiBuilt = false

    if name == "Slick" then
        a:DrawMainEvents()
    else
        a:DrawMainEvents2()
    end

    a.uiBuilt = true

    CGOptions:Rebuild(name == "Slick")

    self:LoadColors()

    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD100CrossGambling|r: Switched to " .. name .. " theme.")
end

function CGTheme:ApplyColors()
    if self._mainFrame then
        self._mainFrame:SetBackdropColor(self._frameColor.r, self._frameColor.g, self._frameColor.b)
    end
    for _, f in ipairs(self._frameFrames) do
        f:SetBackdropColor(self._frameColor.r, self._frameColor.g, self._frameColor.b)
    end
    for _, f in ipairs(self._btnFrames) do
        f:SetBackdropColor(self._buttonColor.r, self._buttonColor.g, self._buttonColor.b)
    end
    for _, f in ipairs(self._sideFrames) do
        f:SetBackdropColor(self._sideColor.r, self._sideColor.g, self._sideColor.b)
    end
    for _, fs in ipairs(self._fontStrings) do
        if fs and fs.SetTextColor then
            fs:SetTextColor(self._fontColor.r, self._fontColor.g, self._fontColor.b)
            fs:SetFont(self:GetFontPath(), self:GetFontSize(), self:GetFontFlags())
        end
    end
end

function CGTheme:LoadColors()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    if not a or not a.db or not a.db.global.colors then return end

    a.db.global.uiFontSize = a.db.global.uiFontSize or 12
    a.db.global.chatFontSize = a.db.global.chatFontSize or a.db.global.fontvalue or 12
    if a.db.global.fontvalue == 14 and a.db.global.chatFontSize == 14 then
        a.db.global.fontvalue = 12
        a.db.global.chatFontSize = 12
    end
    if a.db.global.uiFontSize == 14 then
        a.db.global.uiFontSize = 12
    end

    local c = a.db.global.colors
    c.chatFontColor = c.chatFontColor or {r = c.fontColor.r, g = c.fontColor.g, b = c.fontColor.b}
    if c.fontColor and c.fontColor.r == 1 and c.fontColor.g == 0 and c.fontColor.b == 0 then
        c.fontColor.r, c.fontColor.g, c.fontColor.b = 1, 0.82, 0
    end
    if c.chatFontColor and c.chatFontColor.r == 1 and c.chatFontColor.g == 0 and c.chatFontColor.b == 0 then
        c.chatFontColor.r, c.chatFontColor.g, c.chatFontColor.b = 1, 0.82, 0
    end
    self._frameColor.r,  self._frameColor.g,  self._frameColor.b  = c.frameColor.r,  c.frameColor.g,  c.frameColor.b
    self._buttonColor.r, self._buttonColor.g, self._buttonColor.b = c.buttonColor.r, c.buttonColor.g, c.buttonColor.b
    self._sideColor.r,   self._sideColor.g,   self._sideColor.b   = c.sideColor.r,   c.sideColor.g,   c.sideColor.b
    self._fontColor.r,   self._fontColor.g,   self._fontColor.b   = c.fontColor.r,   c.fontColor.g,   c.fontColor.b

    self:ApplyColors()
end

function CGTheme:SaveColors()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    if not a or not a.db then return end
    local c = a.db.global.colors
    c.chatFontColor = c.chatFontColor or {r = self._fontColor.r, g = self._fontColor.g, b = self._fontColor.b}
    c.frameColor.r,  c.frameColor.g,  c.frameColor.b  = self._frameColor.r,  self._frameColor.g,  self._frameColor.b
    c.buttonColor.r, c.buttonColor.g, c.buttonColor.b = self._buttonColor.r, self._buttonColor.g, self._buttonColor.b
    c.sideColor.r,   c.sideColor.g,   c.sideColor.b   = self._sideColor.r,   self._sideColor.g,   self._sideColor.b
    c.fontColor.r,   c.fontColor.g,   c.fontColor.b   = self._fontColor.r,   self._fontColor.g,   self._fontColor.b
end

function CGTheme:SetFontColor(r, g, b)
    self._fontColor.r, self._fontColor.g, self._fontColor.b = r, g, b
    self:ApplyFont()
end

function CGTheme:ApplyFont()
    for _, fs in ipairs(self._fontStrings) do
        if fs and fs.SetTextColor then
            fs:SetTextColor(self._fontColor.r, self._fontColor.g, self._fontColor.b)
            fs:SetFont(self:GetFontPath(), self:GetFontSize(), self:GetFontFlags())
        end
    end
end

function CGTheme:GetFontColor()
    return self._fontColor.r, self._fontColor.g, self._fontColor.b
end

local function OpenColorPicker(r, g, b, onAccept, onCancel)
    ColorPickerFrame:Hide()
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc  = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                onAccept(nr, ng, nb)
            end,
            cancelFunc  = function(prev)
                if prev then onCancel(prev.r, prev.g, prev.b) end
            end,
            hasOpacity  = false,
            r = r, g = g, b = b, opacity = 1,
        })
    else
        ColorPickerFrame.func = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            onAccept(nr, ng, nb)
        end
        ColorPickerFrame.cancelFunc = function()
            onCancel(r, g, b)
        end
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Show()
    end
end

function CGTheme:ChangeColor(element)
    if element == "resetColors" then
        self._frameColor.r,  self._frameColor.g,  self._frameColor.b  = 0.27, 0.27, 0.27
        self._buttonColor.r, self._buttonColor.g, self._buttonColor.b = 0.30, 0.30, 0.30
        self._sideColor.r,   self._sideColor.g,   self._sideColor.b   = 0.20, 0.20, 0.20
        self._fontColor.r,   self._fontColor.g,   self._fontColor.b   = 1.00, 0.82, 0.00
        local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
        if a and a.db and a.db.global and a.db.global.colors then
            a.db.global.colors.chatFontColor = {r = 1.00, g = 0.82, b = 0.00}
        end
        self:ApplyColors()
        self:SaveColors()
        return
    end

    local color
    if     element == "frame"     then color = self._frameColor
    elseif element == "buttons"   then color = self._buttonColor
    elseif element == "sidecolor" then color = self._sideColor
    elseif element == "fontcolor" then color = self._fontColor
    else return end

    OpenColorPicker(
        color.r, color.g, color.b,
        function(nr, ng, nb)
            color.r, color.g, color.b = nr, ng, nb
            self:ApplyColors()
            self:SaveColors()
        end,
        function(or2, og, ob)
            color.r, color.g, color.b = or2, og, ob
            self:ApplyColors()
        end
    )
end

function LoadColor()    CGTheme:LoadColors()  end
function SaveColor()    CGTheme:SaveColors()  end
