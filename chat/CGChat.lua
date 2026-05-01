CGChat = {} 

local function GetFontSize()
    if CrossGambling and CrossGambling.db and CrossGambling.db.global then
        return CrossGambling.db.global.chatFontSize or CrossGambling.db.global.fontvalue or 12
    end
    return 12
end

local function GetFontColor()
    if CrossGambling and CrossGambling.db and CrossGambling.db.global and CrossGambling.db.global.colors then
        local fc = CrossGambling.db.global.colors.chatFontColor or CrossGambling.db.global.colors.fontColor
        return fc.r, fc.g, fc.b
    end
    return 1, 1, 1
end

function CGChat:BuildChatPanel(parentFrame, game, backdropApplyFn, sideColorApplyFn)
    local addon = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")

    local CGRightMenu = CreateFrame("Frame", "CGRightMenuChat", parentFrame, "BackdropTemplate")
    CGRightMenu:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 0, 0)
    CGRightMenu:SetSize(220, 200)
    if sideColorApplyFn then sideColorApplyFn(CGRightMenu) end
    CGRightMenu:Hide()

    local function onUpdate(self, elapsed)
        local mainX, mainY = parentFrame:GetCenter()
        local selfX, selfY = self:GetCenter()
        if math.sqrt((mainX-selfX)^2 + (mainY-selfY)^2) < 220 then
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 0, 0)
            self:SetScript("OnUpdate", nil)
        end
    end
    CGRightMenu:SetMovable(true)
    CGRightMenu:EnableMouse(true)
    CGRightMenu:SetUserPlaced(true)
    CGRightMenu:SetClampedToScreen(true)
    CGRightMenu:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
            self:StartMoving()
            self.isMoving = true
            self:SetScript("OnUpdate", onUpdate)
        end
    end)
    CGRightMenu:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
            self:SetScript("OnUpdate", onUpdate)
        end
    end)
    CGRightMenu:SetScript("OnHide", function(self)
        if self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
        end
        self:SetScript("OnUpdate", nil)
    end)

    local textField = CreateFrame("ScrollingMessageFrame", nil, CGRightMenu)
    textField:SetPoint("TOPLEFT",     CGRightMenu, "TOPLEFT",  4,  -4)
    textField:SetPoint("BOTTOMRIGHT", CGRightMenu, "BOTTOMRIGHT", -4, 30)
    textField:SetFont("Fonts\\FRIZQT__.TTF", GetFontSize(), "")
    textField:SetFading(false)
    textField:SetJustifyH("LEFT")
    textField:SetMaxLines(50)
    textField:SetScript("OnMouseWheel", function(self, delta)
        if delta == 1 then self:ScrollUp() else self:ScrollDown() end
    end)
    CGRightMenu.TextField = textField

    local PLACEHOLDER = "Type Here..."

    local CGChatBox = CreateFrame("EditBox", "CGChatBoxFrame", CGRightMenu, "InputBoxTemplate")
    CGChatBox:SetPoint("BOTTOMLEFT",  CGRightMenu, "BOTTOMLEFT",  5, 6)
    CGChatBox:SetPoint("BOTTOMRIGHT", CGRightMenu, "BOTTOMRIGHT", -5, 6)
    CGChatBox:SetHeight(22)
    CGChatBox:SetAutoFocus(false)
    CGChatBox:SetTextInsets(4, 4, 0, 0)
    CGChatBox:SetMaxLetters(55)
    CGChatBox:SetText(PLACEHOLDER)

    CGChatBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == PLACEHOLDER then self:SetText("") end
    end)
    CGChatBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then self:SetText(PLACEHOLDER) end
    end)
    CGChatBox:SetScript("OnEscapePressed", function(self)
        self:SetText(PLACEHOLDER)
        self:ClearFocus()
    end)
    CGChatBox:SetScript("OnEnterPressed", function(self)
        local message = self:GetText()
        if message ~= "" and message ~= PLACEHOLDER then
            local playerName     = UnitName("player")
            local playerColor    = "|c" .. RAID_CLASS_COLORS[select(2, UnitClass("player"))].colorStr
            local r, g, b        = GetFontColor()
            local formatted      = string.format("[%s]|r: |cFF%02x%02x%02x%s", playerName, math.floor(r*255), math.floor(g*255), math.floor(b*255), message)
            local withPlayerInfo = string.format("%s:%s", playerColor .. playerName, formatted)
            addon:SendMsg("CHAT_MSG", withPlayerInfo)
            self:SetText("")
            self:ClearFocus()
        end
    end)

    CGRightMenu.ChatBox = CGChatBox

    local callFrame = CreateFrame("Frame")
    callFrame:SetScript("OnEvent", function(self, event, prefix, msg)
        if prefix ~= "CrossGambling" then return end
        local event_type, arg1, arg2 = strsplit(":", msg)
        if CGCall[event_type] then
            CGCall[event_type](arg1, arg2)
        elseif event_type == "CHAT_MSG" then
            local name, class, message = strmatch(msg, "CHAT_MSG:(%S+):(%S+):(.+)")
            if name and message then
                textField:AddMessage(string.format("[%s|r]: %s", name, message))
            end
        end
    end)

    function CGChat:StartListening()
        callFrame:RegisterEvent("CHAT_MSG_ADDON")
    end

    function CGChat:StopListening()
        callFrame:UnregisterEvent("CHAT_MSG_ADDON")
    end

    CGChat.RightMenu = CGRightMenu
    CGChat.TextField = textField
    CGChat.ChatBox   = CGChatBox
    CrossGambling.CGRightMenu = CGRightMenu

    return CGRightMenu
end

function CGChat:RefreshFont()
    if self.TextField then
        self.TextField:SetFont("Fonts\\FRIZQT__.TTF", GetFontSize(), "")
    end
end

function CGChat:SetFontSize(value)
    if CrossGambling and CrossGambling.db and CrossGambling.db.global then
        CrossGambling.db.global.chatFontSize = value
        CrossGambling.db.global.fontvalue = value
    end
    self:RefreshFont()
end

function CGChat:BuildToggleButton(headerFrame, backdropApplyFn, game)
    local btn = CreateFrame("Button", nil, headerFrame, "BackdropTemplate")
    btn:SetSize(20, 21)
    btn:SetPoint("TOPRIGHT", headerFrame, "TOPRIGHT", 0, 0)
    btn:SetFrameLevel(15)
    btn:SetText(">")
    btn:SetNormalFontObject("GameFontNormal")
    if backdropApplyFn then backdropApplyFn(btn) end

    btn:SetScript("OnMouseDown", function()
        local menu = CGChat.RightMenu
        if not menu then return end
        if menu:IsShown() then
            menu:Hide()
            btn:SetText(">")
            if game then game.chatframeOption = true end
        else
            menu:Show()
            btn:SetText("<")
            if game then game.chatframeOption = false end
        end
    end)

    CGChat.ToggleButton = btn
    return btn
end
