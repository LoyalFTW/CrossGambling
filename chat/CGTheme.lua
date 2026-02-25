CGTheme = {}

CGTheme._frameColor  = {r = 0.27, g = 0.27, b = 0.27}
CGTheme._buttonColor = {r = 0.30, g = 0.30, b = 0.30}
CGTheme._sideColor   = {r = 0.20, g = 0.20, b = 0.20}
CGTheme._fontColor   = {r = 1.00, g = 0.00, b = 0.00}

CGTheme._btnFrames  = {}
CGTheme._sideFrames = {}
CGTheme._mainFrame  = nil

CGTheme.isSlick = false

function CGTheme:RegisterBtn(frame)
    table.insert(self._btnFrames, frame)
end

function CGTheme:RegisterSide(frame)
    table.insert(self._sideFrames, frame)
end

function CGTheme:RegisterMain(frame)
    self._mainFrame = frame
end

function CGTheme:ClearRegistry()
    self._btnFrames  = {}
    self._sideFrames = {}
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
    for _, f in ipairs(self._btnFrames) do
        f:SetBackdropColor(self._buttonColor.r, self._buttonColor.g, self._buttonColor.b)
    end
    for _, f in ipairs(self._sideFrames) do
        f:SetBackdropColor(self._sideColor.r, self._sideColor.g, self._sideColor.b)
    end
    self:SetFontColor(self._fontColor.r, self._fontColor.g, self._fontColor.b)
end

function CGTheme:LoadColors()
    local a = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
    if not a or not a.db or not a.db.global.colors then return end

    local c = a.db.global.colors
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
    c.frameColor.r,  c.frameColor.g,  c.frameColor.b  = self._frameColor.r,  self._frameColor.g,  self._frameColor.b
    c.buttonColor.r, c.buttonColor.g, c.buttonColor.b = self._buttonColor.r, self._buttonColor.g, self._buttonColor.b
    c.sideColor.r,   c.sideColor.g,   c.sideColor.b   = self._sideColor.r,   self._sideColor.g,   self._sideColor.b
    c.fontColor.r,   c.fontColor.g,   c.fontColor.b   = self._fontColor.r,   self._fontColor.g,   self._fontColor.b
end

function CGTheme:SetFontColor(r, g, b)
    self._fontColor.r, self._fontColor.g, self._fontColor.b = r, g, b
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
        self._fontColor.r,   self._fontColor.g,   self._fontColor.b   = 1.00, 0.00, 0.00
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
