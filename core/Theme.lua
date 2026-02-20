local CG = CrossGambling  -- forward-ref; populated after addon load

CrossGambling_Themes = {
    {
        label          = "Classic",
        dbKey          = "Classic",
        previewTex     = "Interface\\AddOns\\CrossGambling\\media\\ClassicTheme.tga",
        frameTemplate  = "InsetFrameTemplate",
        buttonTemplate = "UIPanelButtonTemplate",
    },
    {
        label          = "Slick",
        dbKey          = "Slick",
        previewTex     = "Interface\\AddOns\\CrossGambling\\media\\NewTheme.tga",
        frameTemplate  = "BackdropTemplate",
        buttonTemplate = "BackdropTemplate",
    },
}

CrossGambling_DefaultColors = {
    frameColor  = { r = 0.27, g = 0.27, b = 0.27 },
    buttonColor = { r = 0.30, g = 0.30, b = 0.30 },
    sideColor   = { r = 0.20, g = 0.20, b = 0.20 },
    fontColor   = { r = 1.00, g = 1.00, b = 1.00 },
}

function CrossGambling:GetCurrentTheme()
    local key = (self.db and self.db.global.theme) or "Slick"
    for _, t in ipairs(CrossGambling_Themes) do
        if t.dbKey == key then return t end
    end
    return CrossGambling_Themes[2]  
end

function CrossGambling:IsClassicTheme()
    return self:GetCurrentTheme().dbKey == "Classic"
end

function CrossGambling:ApplyThemeColors(btnFrames, sideFrames, mainFrame)
    if self:IsClassicTheme() then return end

    local c = self.db.global.colors

    if mainFrame and mainFrame.SetBackdropColor then
        mainFrame:SetBackdropColor(c.frameColor.r, c.frameColor.g, c.frameColor.b)
    end

    for _, f in ipairs(btnFrames or {}) do
        if f.SetBackdropColor then
            f:SetBackdropColor(c.buttonColor.r, c.buttonColor.g, c.buttonColor.b)
        end
    end

    for _, f in ipairs(sideFrames or {}) do
        if f.SetBackdropColor then
            f:SetBackdropColor(c.sideColor.r, c.sideColor.g, c.sideColor.b)
        end
    end
end

function CrossGambling:SaveThemeColors(frameColor, buttonColor, sideColor, fontColor)
    local c = self.db.global.colors
    if frameColor  then c.frameColor.r,  c.frameColor.g,  c.frameColor.b  = frameColor.r,  frameColor.g,  frameColor.b  end
    if buttonColor then c.buttonColor.r, c.buttonColor.g, c.buttonColor.b = buttonColor.r, buttonColor.g, buttonColor.b end
    if sideColor   then c.sideColor.r,   c.sideColor.g,   c.sideColor.b   = sideColor.r,   sideColor.g,   sideColor.b   end
    if fontColor   then c.fontColor.r,   c.fontColor.g,   c.fontColor.b   = fontColor.r,   fontColor.g,   fontColor.b   end
end

function CrossGambling:ResetThemeColors(btnFrames, sideFrames, mainFrame)
    local d = CrossGambling_DefaultColors
    self:SaveThemeColors(
        { r=d.frameColor.r,  g=d.frameColor.g,  b=d.frameColor.b  },
        { r=d.buttonColor.r, g=d.buttonColor.g, b=d.buttonColor.b },
        { r=d.sideColor.r,   g=d.sideColor.g,   b=d.sideColor.b   },
        { r=d.fontColor.r,   g=d.fontColor.g,   b=d.fontColor.b   }
    )
    self:ApplyThemeColors(btnFrames, sideFrames, mainFrame)
end

function CrossGambling:SetTheme(dbKey)
    for _, t in ipairs(CrossGambling_Themes) do
        if t.dbKey == dbKey then
            self.db.global.theme = dbKey
            ReloadUI()
            return
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000CrossGambling:|r Unknown theme: " .. tostring(dbKey))
end
