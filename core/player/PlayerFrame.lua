local CGPlayers     = {}
local playerButtons = {}
local UpdatePlayerList

function CrossGambling:AddPlayer(playerName)
    for _, player in pairs(CGPlayers) do
        if player.name == playerName then return end
    end
    table.insert(CGPlayers, { name = playerName, total = 0 })
    table.sort(CGPlayers, function(a, b) return a.name < b.name end)
    if UpdatePlayerList then UpdatePlayerList() end
end

function CrossGambling:RemovePlayer(name)
    for i, player in pairs(CGPlayers) do
        if player.name == name then
            table.remove(CGPlayers, i)
            if UpdatePlayerList then UpdatePlayerList() end
            return
        end
    end
end

function CrossGambling:DrawPlayerFrame(CrossGamblingUI, MainHeader, ButtonColors, SideColor)
    local CGLeftMenu = CreateFrame("Frame", "CGLeftMenu", CrossGamblingUI, "BackdropTemplate")
    CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
    CGLeftMenu:SetSize(300, 180)
    SideColor(CGLeftMenu)

    local function onUpdate(self, elapsed)
        local mainX, mainY = CrossGamblingUI:GetCenter()
        local leftX, leftY = CGLeftMenu:GetCenter()
        local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
        if distance < 260 then
            CGLeftMenu:ClearAllPoints()
            CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
        end
    end

    CGLeftMenu:SetScript("OnUpdate", onUpdate)
    CGLeftMenu:SetMovable(true)
    CGLeftMenu:EnableMouse(true)
    CGLeftMenu:SetUserPlaced(true)
    CGLeftMenu:SetClampedToScreen(true)
    CGLeftMenu:Hide()

    CGLeftMenu:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
            self:StartMoving()
            self.isMoving = true
        end
    end)
    CGLeftMenu:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
        end
    end)

    local CGLeftMenuHeader = CreateFrame("Button", nil, CGLeftMenu, "BackdropTemplate")
    CGLeftMenuHeader:SetSize(CGLeftMenu:GetSize(), 21)
    CGLeftMenuHeader:SetPoint("TOPLEFT", CGLeftMenu, "TOPLEFT", 0, 20)
    CGLeftMenuHeader:SetFrameLevel(15)
    CGLeftMenuHeader:SetText("Roll Tracker")
    CGLeftMenuHeader:SetNormalFontObject("GameFontNormal")
    ButtonColors(CGLeftMenuHeader)

    local CGMenuToggle = CreateFrame("Button", nil, MainHeader, "BackdropTemplate")
    CGMenuToggle:SetSize(20, 21)
    CGMenuToggle:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 0, 0)
    CGMenuToggle:SetFrameLevel(15)
    CGMenuToggle:SetText("<")
    CGMenuToggle:SetNormalFontObject("GameFontNormal")
    ButtonColors(CGMenuToggle)
    CGMenuToggle:SetScript("OnMouseDown", function(self)
        if CGLeftMenu:IsShown() then
            CGLeftMenu:Hide()
            CGMenuToggle:SetText("<")
        else
            CGLeftMenu:Show()
            CGMenuToggle:SetText(">")
        end
    end)

    local playerListFrame = CreateFrame("Frame", "PlayerListFrame", CGLeftMenu)
    playerListFrame:SetSize(300, 150)
    playerListFrame:SetPoint("CENTER")

    local scrollFrame = CreateFrame("ScrollFrame", "PlayerListScrollFrame", playerListFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(266, 170)
    scrollFrame:SetPoint("TOPLEFT", 10, 10)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentValue = scrollFrame:GetVerticalScroll()
        local rowHeight = 30
        local numRows = #CGPlayers
        local maxRows = math.max(numRows * rowHeight - scrollFrame:GetHeight(), 0)
        local newValue = math.max(0, math.min(currentValue - delta * rowHeight, maxRows))
        scrollFrame:SetVerticalScroll(newValue)
    end)

    local playerButtonsFrame = CreateFrame("Frame", "PlayerButtonsFrame", scrollFrame)
    playerButtonsFrame:SetSize(280, 1)
    scrollFrame:SetScrollChild(playerButtonsFrame)

    UpdatePlayerList = function()
        for i, button in ipairs(playerButtons) do
            button:Hide()
            button:SetParent(nil)
        end
        playerButtons = {}

        table.sort(CGPlayers, function(a, b) return a.name < b.name end)

        local row = 0
        for i, player in ipairs(CGPlayers) do
            local playerButton = CreateFrame("Button", "PlayerButton" .. i, playerButtonsFrame, "BackdropTemplate")
            playerButton:SetSize(250, 30)
            playerButton:SetPoint("TOPLEFT", 0, -row * 30)
            ButtonColors(playerButton)
            CrossGambling:ColorsApplyAll()

            local buttonText = playerButton:CreateFontString(nil, "OVERLAY")
            buttonText:SetFont("Fonts\\FRIZQT__.TTF", 20)
            buttonText:SetPoint("LEFT", 5, 0)
            playerButton.text = buttonText

            local _, class = UnitClass(player.name)
            local classColor = class and RAID_CLASS_COLORS[class]

            if classColor and classColor.colorStr then
                local nameColor = "|c" .. classColor.colorStr
                if player.roll then
                    buttonText:SetText(nameColor .. player.name .. "|r : |cFF000000" .. player.roll .. "|r")
                else
                    buttonText:SetText(nameColor .. player.name .. "|r")
                end
            else
                if player.roll then
                    buttonText:SetText("|cffffffff" .. player.name .. "|r : |cFF000000" .. player.roll .. "|r")
                else
                    buttonText:SetText("|cffffffff" .. player.name .. "|r")
                end
            end

            table.insert(playerButtons, playerButton)
            row = row + 1
        end

        playerButtonsFrame:SetHeight(math.max(row * 30, 1))
    end

    CrossGambling:RegisterPlayerCGCalls()
    return CGLeftMenu, CGMenuToggle
end

function CrossGambling:DrawClassicPlayerFrame(CrossGamblingUI, MainHeader)
    local CGLeftMenu = CreateFrame("Frame", "CGLeftMenu", CrossGamblingUI, "InsetFrameTemplate")
    CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
    CGLeftMenu:SetSize(300, 180)
    CGLeftMenu:Hide()

    local function onUpdate(self, elapsed)
        local mainX, mainY = CrossGamblingUI:GetCenter()
        local leftX, leftY = CGLeftMenu:GetCenter()
        local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
        if distance < 300 then
            CGLeftMenu:ClearAllPoints()
            CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
        end
    end

    CGLeftMenu:SetScript("OnUpdate", onUpdate)
    CGLeftMenu:SetMovable(true)
    CGLeftMenu:EnableMouse(true)
    CGLeftMenu:SetUserPlaced(true)
    CGLeftMenu:SetClampedToScreen(true)

    CGLeftMenu:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
            self:StartMoving()
            self.isMoving = true
        end
    end)
    CGLeftMenu:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing()
            self.isMoving = false
        end
    end)

    local CGLeftMenuHeader = CreateFrame("Button", nil, CGLeftMenu, "UIPanelButtonTemplate")
    CGLeftMenuHeader:SetSize(CGLeftMenu:GetSize(), 21)
    CGLeftMenuHeader:SetPoint("TOPLEFT", CGLeftMenu, "TOPLEFT", 0, 20)
    CGLeftMenuHeader:SetFrameLevel(15)
    CGLeftMenuHeader:SetText("Roll Tracker")
    CGLeftMenuHeader:SetNormalFontObject("GameFontNormal")

    local CGMenuToggle = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
    CGMenuToggle:SetSize(20, 21)
    CGMenuToggle:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 0, 0)
    CGMenuToggle:SetFrameLevel(15)
    CGMenuToggle:SetText("<")
    CGMenuToggle:SetNormalFontObject("GameFontNormal")
    CGMenuToggle:SetScript("OnMouseDown", function(self)
        if CGLeftMenu:IsShown() then
            CGLeftMenu:Hide()
            CGMenuToggle:SetText("<")
        else
            CGLeftMenu:Show()
            CGMenuToggle:SetText(">")
        end
    end)

    local playerListFrame = CreateFrame("Frame", "PlayerListFrame", CGLeftMenu)
    playerListFrame:SetSize(300, 150)
    playerListFrame:SetPoint("CENTER")

    local scrollFrame = CreateFrame("ScrollFrame", "PlayerListScrollFrame", playerListFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(266, 170)
    scrollFrame:SetPoint("TOPLEFT", 10, 15)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentValue = scrollFrame:GetVerticalScroll()
        local rowHeight = 30
        local numRows = #CGPlayers
        local maxRows = math.max(numRows * rowHeight - scrollFrame:GetHeight(), 0)
        local newValue = math.max(0, math.min(currentValue - delta * rowHeight, maxRows))
        scrollFrame:SetVerticalScroll(newValue)
    end)

    local playerButtonsFrame = CreateFrame("Frame", "PlayerButtonsFrame", scrollFrame)
    playerButtonsFrame:SetSize(280, 1)
    scrollFrame:SetScrollChild(playerButtonsFrame)

    UpdatePlayerList = function()
        table.sort(CGPlayers, function(a, b) return a.name < b.name end)

        for i, button in ipairs(playerButtons) do
            button:Hide()
            button:SetParent(nil)
        end
        playerButtons = {}

        for i, player in ipairs(CGPlayers) do
            local playerButton = CreateFrame("Button", "PlayerButton" .. i, playerButtonsFrame, "InsetFrameTemplate")
            playerButton:SetSize(260, 20)
            playerButton:SetPoint("TOPLEFT", playerButtonsFrame, 0, -i * 20)
            playerButton:SetNormalFontObject("GameFontNormal")
            playerButton:SetHighlightFontObject("GameFontHighlight")

            if player.roll ~= nil then
                playerButton:SetText(player.name .. " : " .. player.roll)
            else
                playerButton:SetText(player.name)
            end

            table.insert(playerButtons, playerButton)
        end
    end

    CrossGambling:RegisterPlayerCGCalls()
    return CGLeftMenu, CGMenuToggle
end

function CrossGambling:RegisterPlayerCGCalls()
    CGCall["PLAYER_ROLL"] = function(playerName, value)
        for i, player in pairs(CGPlayers) do
            if player.name == playerName then
                player.roll = value
                break
            end
        end
        if UpdatePlayerList then UpdatePlayerList() end
    end

    CGCall["R_NewGame"] = function()
        for i = #CGPlayers, 1, -1 do
            CrossGambling:RemovePlayer(CGPlayers[i].name)
        end
        local ui = CrossGambling.UI or CrossGambling.ClassicUI
        if ui then
            if ui.CGEnter then ui.CGEnter:SetText("Join Game"); ui.CGEnter:Enable() end
            if ui.CGStartRoll then ui.CGStartRoll:SetText("Start Rolling") end
        end
    end

    CGCall["DisableClient"] = function()
        local ui = CrossGambling.UI or CrossGambling.ClassicUI
        if not ui then return end
        ui.CGAcceptOnes:Disable()
        ui.CGLastCall:Disable()
        ui.CGStartRoll:Disable()
        CrossGambling.game.players = {}
        CrossGambling.game.result  = nil
        if CrossGambling.game.host then
            ui.CGAcceptOnes:Enable()
            ui.CGLastCall:Enable()
            ui.CGStartRoll:Enable()
        end
    end

    CGCall["Disable_Join"] = function()
        local ui = CrossGambling.UI or CrossGambling.ClassicUI
        if ui and ui.CGEnter then ui.CGEnter:Disable() end
    end
end
