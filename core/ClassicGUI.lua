local CGPlayers = {}
local CrossGamblingUI
function CrossGambling:toggleUi2()
if (CrossGamblingUI:IsVisible()) then
CrossGamblingUI:Hide()
else
CrossGamblingUI:Show()
end
end

function CrossGambling:ShowClassic(info)
    -- Show Inerface
	if (CrossGamblingUI:IsVisible() ~= true) then
        CrossGamblingUI:Show()
		LoadColor()
	else 
		CrossGamblingUI:Hide()
	end
end

function CrossGambling:HideClassic(info)
    -- Hide Interface
    if (CrossGamblingUI:IsVisible()) then
        CrossGamblingUI:Hide()
    end
end 

function CrossGambling:DrawMainEvents2()
--Create Main UI
CrossGamblingUI = CreateFrame("Frame", "CrossGamblingClassic", UIParent, "InsetFrameTemplate")
CrossGamblingUI:SetSize(320, 195) 
CrossGamblingUI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CrossGamblingUI:SetMovable(true)
CrossGamblingUI:EnableMouse(true)
CrossGamblingUI:SetUserPlaced(true)
CrossGamblingUI:SetResizable(true)
CrossGamblingUI:RegisterForDrag("LeftButton")
CrossGamblingUI:SetScript("OnDragStart", CrossGamblingUI.StartMoving)
CrossGamblingUI:SetScript("OnDragStop", CrossGamblingUI.StopMovingOrSizing)
CrossGamblingUI:SetClampedToScreen(true)
self.db.global.scale = self.db.global.scale
CrossGamblingUI:SetScale(self.db.global.scale)
CrossGamblingUI:Hide()
-- Header to hold options
local MainHeader = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
MainHeader:SetSize(CrossGamblingUI:GetSize(), 21)
MainHeader:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)

-- Main Button
local MainMenu = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
MainMenu:SetSize(CrossGamblingUI:GetSize(), 21)
MainMenu:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
--Options Button
local OptionsButton = CreateFrame("Frame", nil, CrossGamblingUI, "InsetFrameTemplate")
OptionsButton:SetSize(CrossGamblingUI:GetSize(), 21)
OptionsButton:SetPoint("TOPLEFT", CrossGamblingUI, 0, 0)
OptionsButton:Hide()
-- Main Menu
local CGMainMenu = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGMainMenu:SetSize(100, 21)
CGMainMenu:SetPoint("TOPLEFT", MainHeader, "TOPLEFT", 30, 0)
CGMainMenu:SetFrameStrata("MEDIUM")
CGMainMenu:SetText("Main")
CGMainMenu:SetNormalFontObject("GameFontNormal")
CGMainMenu:SetScript("OnMouseUp", function(self)
	if OptionsButton:IsShown() then
		OptionsButton:Hide()
		MainMenu:Show()
	end
	
end)
-- Footer
local MainFooter = CreateFrame("Button", nil, CrossGamblingUI, "InsetFrameTemplate")
MainFooter:SetSize(CrossGamblingUI:GetSize(), 15)
MainFooter:SetPoint("BOTTOMLEFT", CrossGamblingUI, 0, 0)
MainFooter:SetText("CrossGambling - Lay@Mal'Ganis")
MainFooter:SetNormalFontObject("GameFontNormal")
-- Options Menu
local CGOptions = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGOptions:SetSize(100, 21)
CGOptions:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", -25, 0)
CGOptions:SetFrameStrata("MEDIUM")
CGOptions:SetText("Options")
CGOptions:SetNormalFontObject("GameFontNormal")
CGOptions:SetScript("OnMouseUp", function(self)
	if MainMenu:IsShown() then
		MainMenu:Hide()
		OptionsButton:Show()
	end
end)

local GCchatMethod = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
GCchatMethod:SetSize(150, 30)
GCchatMethod:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
GCchatMethod:SetText(self.game.chatMethod)
GCchatMethod:SetNormalFontObject("GameFontNormal")
GCchatMethod:SetScript("OnClick", function() self:chatMethod() GCchatMethod:SetText(self.game.chatMethod) end)

local CGGameMode = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGGameMode:SetSize(150, 30)
CGGameMode:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -2)
CGGameMode:SetText(self.game.mode)
CGGameMode:SetNormalFontObject("GameFontNormal")
CGGameMode:SetScript("OnClick", function() self:changeGameMode() CGGameMode:SetText(self.game.mode) end)

local CGEditBox = CreateFrame("EditBox", nil, MainMenu, "InputBoxTemplate")
CGEditBox:SetSize(200, 30)
CGEditBox:SetSize(MainHeader:GetSize()-25, 25)
CGEditBox:SetPoint("TOPLEFT", GCchatMethod, 10, -30)
CGEditBox:SetAutoFocus(false)
CGEditBox:SetTextInsets(10, 10, 5, 5)
CGEditBox:SetMaxLetters(6)
CGEditBox:SetJustifyH("CENTER")
CGEditBox:SetText(self.db.global.wager)
-- Left Side Controls
local CGGuildPercent = CreateFrame("EditBox", nil, OptionsButton, "InputBoxTemplate")
CGGuildPercent:SetSize(140, 30)
CGGuildPercent:SetPoint("TOPLEFT", CGOptions, -22, -55)
CGGuildPercent:SetAutoFocus(false)
CGGuildPercent:SetMaxLetters(2)
CGGuildPercent:SetJustifyH("CENTER")
CGGuildPercent:SetText(self.db.global.houseCut)
CGGuildPercent:SetScript("OnEnterPressed", EditBoxOnEnterPressed)

local CGAcceptOnes = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGAcceptOnes:SetSize(150, 30)
CGAcceptOnes:SetPoint("TOPLEFT", GCchatMethod, "BOTTOMLEFT", -0, -25)
CGAcceptOnes:SetText("New Game")
CGAcceptOnes:SetNormalFontObject("GameFontNormal")

CGAcceptOnes:SetScript("OnClick", function()
	CGAcceptOnes:Disable()	-- Disable the button during processing

	if CGAcceptOnes:GetText() == "Host Game" then
		CGAcceptOnes:SetText("New Game")
	else
		self.game.state = "START"
		self:SendMsg("R_NewGame")

		-- Sets same roll for everyone.
		self:SendMsg("SET_WAGER", CGEditBox:GetText())

		-- Switches everyone to the same gamemode.
		self:SendMsg("GAME_MODE", CGGameMode:GetText())

		-- Switches everyone to the proper chat method.
		self:SendMsg("Chat_Method", GCchatMethod:GetText())

		self:SendMsg("SET_HOUSE", CGGuildPercent:GetText())
		
		self.game.host = true
		self:SendMsg("New_Game")

		-- Starts a new game but only if they're the host.
	end

	CGAcceptOnes:Enable()	-- Enable the button after processing
end)

local CGLastCall = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGLastCall:SetSize(150, 30)
CGLastCall:SetPoint("TOPLEFT", CGAcceptOnes, "BOTTOMLEFT", -0, -3)
CGLastCall:SetText("Last Call!")
CGLastCall:SetNormalFontObject("GameFontNormal")
CGLastCall:SetScript("OnClick", function()
self:SendMsg("LastCall")
end)

local CGStartRoll = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGStartRoll:SetSize(150, 30)
CGStartRoll:SetPoint("TOPLEFT", CGLastCall, "BOTTOMLEFT", -0, -3)
CGStartRoll:SetText("Start Rolling")
CGStartRoll:SetNormalFontObject("GameFontNormal")
CGStartRoll:SetScript("OnClick", function()
self:CGRolls()
CGStartRoll:SetText("Whos Left?")
end)
-- Right Side Controls 
local CGEnter = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGEnter:SetSize(150, 30)
CGEnter:SetPoint("TOPLEFT", CGGameMode, "BOTTOMLEFT", -0, -25)
CGEnter:SetText("Join Game")
CGEnter:SetNormalFontObject("GameFontNormal")
CGEnter:SetScript("OnClick", function()
	if (CGEnter:GetText() == "Join Game") then
         SendChatMessage("1" , self.game.chatMethod)
        CGEnter:SetText("Leave Game")
    elseif (CGEnter:GetText() == "Leave Game") then
		SendChatMessage("-1" , self.game.chatMethod)
        CGEnter:SetText("Join Game")
    end
end)


local CGRollMe = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGRollMe:SetSize(150, 30)
CGRollMe:SetPoint("TOPLEFT", CGEnter, "BOTTOMLEFT", -0, -3)
CGRollMe:SetText("Roll Me")
CGRollMe:SetNormalFontObject("GameFontNormal")
CGRollMe:SetScript("OnClick", function()
  rollMe()
end)

local CGCloseGame = CreateFrame("Button", nil, MainMenu, "UIPanelButtonTemplate")
CGCloseGame:SetSize(150, 30)
CGCloseGame:SetPoint("TOPLEFT", CGRollMe, "BOTTOMLEFT", -0, -3)
CGCloseGame:SetText("Close")
CGCloseGame:SetNormalFontObject("GameFontNormal")
CGCloseGame:SetScript("OnClick", function()
  CrossGamblingUI:Hide()
end)

-- Options Menu Buttons

-- Left Options
local CGFullStats = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGFullStats:SetSize(150, 30)
CGFullStats:SetPoint("TOPLEFT", MainHeader, "BOTTOMLEFT", 5, -2)
CGFullStats:SetText("Full Stats")
CGFullStats:SetNormalFontObject("GameFontNormal")
CGFullStats:SetScript("OnClick", function(full)
  self:reportStats(full)
end)

local CGGuildCut = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGGuildCut:SetSize(150, 30)
CGGuildCut:SetPoint("TOPLEFT", CGFullStats, "BOTTOMLEFT", -0, -3)
CGGuildCut:SetText("Guild Cut(OFF)")
CGGuildCut:SetNormalFontObject("GameFontNormal")
CGGuildCut:SetScript("OnClick", function()
  if (self.game.house == true) then
		self.game.house = false
		CGGuildCut:SetText("Guild Cut (OFF)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned off.")
	else
		self.game.house = true
		CGGuildCut:SetText("Guild Cut (ON)");
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Guild cut has been turned on.")
	end
end)

local CGReset = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGReset:SetSize(158, 30)
CGReset:SetPoint("TOPLEFT", CGGuildCut, "BOTTOMLEFT", -0, -3)
CGReset:SetText("Reset Stats!")
CGReset:SetScript("OnMouseDown", function()
self.game.host = false
for i = 1, #CGPlayers do
		CGPlayers[1].HasRolled = false
		CrossGambling:RemovePlayer(CGPlayers[1].Name)
	    
end
	CGEnter:SetText("Join Game")
    self.game.state = "START"
    self.game.players = {}
    self.game.result = nil
    self.db.global.stats = {}
	self.db.global.joinstats = {}
	self.db.global.housestats = 0
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00CG ALL STATS RESET!")
end)

-- Create a button to toggle the realm filter
local CGRealmFilter = CreateFrame("Button", "CGRealmFilter", OptionsButton, "UIPanelButtonTemplate")
CGRealmFilter:SetPoint("TOPLEFT", CGReset, "BOTTOMLEFT", -0, -3)
CGRealmFilter:SetSize(158, 30)
CGRealmFilter:SetText("Realm Filter(OFF)")
CGRealmFilter:Show()

-- Function to toggle the realm filter
local function ToggleRealmFilter()
  if(self.game.realmFilter == false) then
    CGRealmFilter:SetText("Realm Filter(ON)")
	self.game.realmFilter = true
  else
    CGRealmFilter:SetText("Realm Filter(OFF)")
	self.game.realmFilter = false
  end
end

-- Set the button's OnClick behavior to toggle the realm filter
CGRealmFilter:SetScript("OnClick", ToggleRealmFilter)


-- Right Options 
local CGFameShame = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGFameShame:SetSize(150, 30)
CGFameShame:SetPoint("TOPRIGHT", MainHeader, "BOTTOMRIGHT", -4, -3)
CGFameShame:SetText("Fame/Shame")
CGFameShame:SetNormalFontObject("GameFontNormal")
CGFameShame:SetScript("OnClick", function()
  self:reportStats()
end)

local CGTheme = CreateFrame("Button", nil, OptionsButton, "UIPanelButtonTemplate")
CGTheme:SetSize(150, 30)
CGTheme:SetPoint("TOPRIGHT", CGFameShame, "BOTTOMRIGHT", -0, -35)
CGTheme:SetText("Slick Theme")
CGTheme:SetNormalFontObject("GameFontNormal")
CGTheme:SetScript("OnClick", function()
  self.db.global.theme = "Slick"
	  ReloadUI()
end)

-- Right Side Menu
local CGRightMenu = CreateFrame("Frame", "CGRightMenu", CrossGamblingUI, "InsetFrameTemplate")
CGRightMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPRIGHT", 0, 0)
CGRightMenu:SetSize(220, 150)
CGRightMenu:Hide()

local function onUpdate(self,elapsed)
    local mainX, mainY = CrossGamblingUI:GetCenter()
    local leftX, leftY = CGRightMenu:GetCenter()
    local distance = math.sqrt((mainX - leftX)^2 + (mainY - leftY)^2)
    if distance < 260 then
        CGRightMenu:ClearAllPoints()
        CGRightMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPRIGHT", 0, 0)
end
end

CGRightMenu:SetScript("OnUpdate", onUpdate)
CGRightMenu:SetMovable(true)
CGRightMenu:EnableMouse(true)
CGRightMenu:SetUserPlaced(true)
CGRightMenu:SetClampedToScreen(true)

CGRightMenu:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving();
        self.isMoving = true;
    end
end)
CGRightMenu:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing();
        self.isMoving = false;
    end
end)

-- Create the text field frame within the right side menu frame
CGRightMenu.TextField = CreateFrame("ScrollingMessageFrame", nil, CGRightMenu)
CGRightMenu.TextField:SetPoint("CENTER", CGRightMenu, 2, -0)
CGRightMenu.TextField:SetSize(CGRightMenu:GetWidth()-8, -140)
CGRightMenu.TextField:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
CGRightMenu.TextField:SetFading(false)
CGRightMenu.TextField:SetJustifyH("LEFT")
CGRightMenu.TextField:SetMaxLines(50)
CGRightMenu.TextField:SetScript("OnMouseWheel", function(self, delta)
    if (delta == 1) then
        self:ScrollUp()
    else
        self:ScrollDown()
    end
end)


local function OnChatSubmit(CGChatBox)
    local message = CGChatBox:GetText()
    if message ~= "" and message ~= " " then
        local playerName = UnitName("player")
	local playerClass = select(2, UnitClass("player"))
	local messageWithPlayerInfo = string.format("%s:%s:%s", playerName, playerClass, message)
		self:SendMsg("CHAT_MSG", messageWithPlayerInfo)
    end
    CGChatBox:SetText("")
    CGChatBox:ClearFocus()
end

local CallFrame = CreateFrame("Frame")
CallFrame:RegisterEvent("CHAT_MSG_ADDON")
CallFrame:SetScript("OnEvent", function(self, event, prefix, msg)
	if prefix ~= "CrossGambling" then return end
		local event_type, arg1, arg2 = strsplit(":", msg)
	if CGCall[event_type] then
		CGCall[event_type](arg1, arg2)
	elseif event_type == "CHAT_MSG" then
	local name, class, message = strmatch(msg, "CHAT_MSG:(%S+):(%S+):(.+)")
	local formatted = string.format("[%s|r]: %s", name, message)
	CGRightMenu.TextField:AddMessage(formatted)
	end
end)

local CGChatBox = CreateFrame("EditBox", nil, CGRightMenu, "InputBoxTemplate")
CGChatBox:SetPoint("TOPLEFT", CGRightMenu, "BOTTOMLEFT", 5, -20)
CGChatBox:SetSize(CGRightMenu:GetWidth() - 10, -15)
CGChatBox:SetAutoFocus(false)
CGChatBox:SetTextInsets(10, 10, 5, 5)
CGChatBox:SetMaxLetters(55)
CGChatBox:SetText("Type Here...")
CGChatBox:SetScript("OnEnterPressed", OnChatSubmit)

local CGChatToggle = CreateFrame("Button", nil, MainHeader, "UIPanelButtonTemplate")
CGChatToggle:SetSize(20, 21) 
CGChatToggle:SetPoint("TOPRIGHT", MainHeader, "TOPRIGHT", 0, 0)
CGChatToggle:SetText(">")
CGChatToggle:SetNormalFontObject("GameFontNormal")
CGChatToggle:SetScript("OnMouseDown", function()
   if CGRightMenu:IsShown() then
		CGRightMenu:Hide()
		CGChatToggle:SetText(">")
		self.game.chatframeOption = true
	else
		CGRightMenu:Show()
		CGChatToggle:SetText("<")
		self.game.chatframeOption = false
	end
end)

local valuescale = function(val,valStep)
		 	self.db.global.scalevalue = val
    return floor(val/valStep)*valStep
  end
  
	--basic slider func
	local CreateBasicSlider = function(parent, name, title, minVal, maxVal, valStep)
	local slider = CreateFrame("Slider", name, CrossGamblingUI, "OptionsSliderTemplate")
	slider:SetSize(CrossGamblingUI:GetSize(), 21)
	slider:SetPoint("BOTTOM", CrossGamblingUI, "BOTTOM", 0, -20)
    local editbox = CreateFrame("EditBox", "$parentEditBox", slider, "InputBoxTemplate")
    slider:SetMinMaxValues(100, 250)
	self.db.global.scalevalue = self.db.global.scalevalue
	slider:SetValue(self.db.global.scalevalue)
    slider:SetValueStep(valStep)
	slider:SetFrameStrata("LOW")
    slider.text = _G[name.."Text"]
    slider.text:SetText(title)
    slider.textLow = _G[name.."Low"]
    slider.textHigh = _G[name.."High"]
    slider.textLow:SetText("")
    slider.textHigh:SetText("")
    slider.textLow:SetTextColor(0,0,0)
    slider.textHigh:SetTextColor(0.4,0.4,0.4)
    editbox:ClearAllPoints()
    editbox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    editbox:SetText(slider:GetValue())
    editbox:SetAutoFocus(false)
	
    slider:SetScript("OnValueChanged", function(self,value)
      self.editbox:SetText(valuescale (value,valStep))
    end)
    slider.editbox = editbox
    return slider
  end
  
 
    local slider = CreateBasicSlider(parent, "CGSlider", "", 0, 1, 0.001)
    slider:HookScript("OnMouseUp", function(self,value)
      --save value
	  CrossScale(self)
    end)

	function CrossScale()
		self.db.global.scale = slider:GetValue()/100
		CrossGamblingUI:SetScale(self.db.global.scale)
	end
	
-- Left Side Menu
local CGLeftMenu = CreateFrame("Frame", "CGLeftMenu", CrossGamblingUI, "InsetFrameTemplate")
CGLeftMenu:SetPoint("TOPLEFT", CrossGamblingUI, "TOPLEFT", -300, -20)
CGLeftMenu:SetSize(300, 180)
CGLeftMenu:Hide()

local function onUpdate(self,elapsed)
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
        self:StartMoving();
        self.isMoving = true;
    end
end)
CGLeftMenu:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing();
        self.isMoving = false;
    end
end)

local CGLeftMenuHeader = CreateFrame("Button", nil, CGLeftMenu, "UIPanelButtonTemplate")
CGLeftMenuHeader:SetSize(CGLeftMenu:GetSize(), 21) 
CGLeftMenuHeader:SetPoint("TOPLEFT", CGLeftMenu, "TOPLEFT", 0, 20)
CGLeftMenuHeader:SetFrameLevel(15)
CGLeftMenuHeader:SetText("Roll Tracker")
CGLeftMenuHeader:SetNormalFontObject("GameFontNormal")

local CGMenuToggle = CreateFrame("Button", nil, MainHeader,  "UIPanelButtonTemplate")
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

function CrossGambling:RemovePlayer(name)
    -- loop through the "CGPlayers" table
    for i, player in pairs(CGPlayers) do
        if player.name == name then
            -- remove the player from the "CGPlayers" table
            table.remove(CGPlayers, i)
            -- update the player list
            UpdatePlayerList()
            -- player found and removed, exit the function
            return
        end
    end
end


function CrossGambling:AddPlayer(playerName)
    -- First, check if the player already exists in the "CGPlayers" table
    for i, player in pairs(CGPlayers) do
        if player.name == playerName then
            -- player already exists, exit the function
            return
        end
    end
    -- create a new table to store the player's information
    local newPlayer = {
        name = playerName,
        total = 0,
    }
    -- insert the new player into the "CGPlayers" table
    table.insert(CGPlayers, newPlayer)

    -- sort the "CGPlayers" table by name
    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)
    UpdatePlayerList()
end

-- Create the main frame for the player list
local playerListFrame = CreateFrame("Frame", "PlayerListFrame", CGLeftMenu)
playerListFrame:SetSize(300, 150)
playerListFrame:SetPoint("CENTER")

-- Create a scroll frame to hold the player list
local scrollFrame = CreateFrame("ScrollFrame", "PlayerListScrollFrame", playerListFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(266, 170)
scrollFrame:SetPoint("TOPLEFT", 10, 15)

-- Enable scrolling with the mouse wheel
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
playerButtonsFrame:SetSize(280, 1)  -- Set the height to 1 for dynamic sizing
scrollFrame:SetScrollChild(playerButtonsFrame)

-- create a new table to store the player buttons
playerButtons = {}

function UpdatePlayerList()
    -- Sort CGPlayers table alphabetically by player name
    table.sort(CGPlayers, function(a, b)
        return a.name < b.name
    end)

    -- Remove all current player buttons
    for i, button in ipairs(playerButtons) do
        button:Hide()
        button:SetParent(nil)
    end

    for i, player in ipairs(CGPlayers) do
        local playerButton = CreateFrame("Button", "PlayerButton"..i, playerButtonsFrame, "InsetFrameTemplate")
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

	-- For testing
	--for i = 1, 40 do
  --  local randomName = "Player " .. math.random(1, 20)
   -- CrossGambling:AddPlayer(randomName)
--end
end



CGCall["PLAYER_ROLL"] = function(playerName, value)
    -- find the player in the "CGPlayers" table
    for i, player in pairs(CGPlayers) do
        if player.name == playerName then
            player.roll = value -- change roll to value
            break
        end
    end
    UpdatePlayerList()
end

CGCall["R_NewGame"] = function()
    for i = #CGPlayers, 1, -1 do
        CrossGambling:RemovePlayer(CGPlayers[i].name)
    end
CGEnter:SetText("Join Game")
CGEnter:Enable()
end



CGCall["DisableClient"] = function()
		CGAcceptOnes:Disable()
		CGLastCall:Disable()
		CGStartRoll:Disable()
		self.game.players = {}
		self.game.result = nil
	if(self.game.host) then
		CGAcceptOnes:Enable()
		CGLastCall:Enable()
		CGStartRoll:Enable()
	end
end

CGCall["Disable_Join"] = function()
CGEnter:Disable()
end

end

C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")
