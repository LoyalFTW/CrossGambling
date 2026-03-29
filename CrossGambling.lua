CrossGambling = LibStub("AceAddon-3.0"):NewAddon("CrossGambling", "AceConsole-3.0", "AceEvent-3.0")
local CrossGambling = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")

local gameStates = {
    "START",
    "REGISTER",
    "ROLL"
}

local gameModes = {
    "Classic",
	"1v1DeathRoll",
    "BigTwo",
}
local chatMethods = {
    "PARTY",
    "RAID",
    "GUILD"
}

local uiThemes = {
    "Classic",
	"Slick"
}

local options = {
    name = "CrossGambling",
    handler = CrossGambling,
    type = 'group',
    args = {
		show = {
			name = "Show",
			desc = "Show Game",
			type = "execute",
			func = function()
				CrossGambling:ToggleGUI(info, true)
			end
		},

		hide = {
			name = "Hide",
			desc = "Hide Game",
			type = "execute",
			func = function()
				CrossGambling:ToggleGUI(info, false)
			end
		},
        minimap = {
            name = "Minimap",
            desc = "Show/Hide Minimap Icon",
            type = "execute",
            func = "ToggleMinimap"
		}, 
        allstats = {
            name = "All Stats",
            desc = "Shows all Stats(Out of Order in Guild)",
            type = "execute",
            func = "reportStats"
        },
        stats = {
            name = "Fame/Shame",
            desc = "Shows Top 3 Winners/Losers(Out of Order in Guild)",
            type = "execute",
            func = "reportStats"
        },
        joinstats = {
            name = "Join Stats",
            desc = "[main] [alt] - Join the two character's win/loss amounts on stat tracker",
            type = "input",
            set = "joinStats"
        },
        unjoinstats = {
            name = "Unjoin Stats",
            desc = "[alt] - Unjoins the Alt from whomever it's attached to",
            type = "input",
            set = "unjoinStats"
        },
        listalts = {
            name = "List Alts",
            desc = "See everyone whos used joinstats",
            type = "execute",
            func = "listAlts"
        },
        updatestat = {
            name = "Update Stat",
            desc = "[player] [amount] - Add [amount] to [player]'s stats (use negative numbers to subtract)",
            type = "input",
            set = "updateStat"
        },
        deletestat = {
            name = "Delete Stat",
            desc = "[player] - Permanently delete stats",
            type = "input",
            set = "deleteStat"
        },
        resetstats = {
            name = "Reset Stats",
            desc = "Deletes All Stats",
            type = "execute",
            func = "resetStats"
        },
        ban = {
            name = "Ban Player",
            desc = "[player] -  Ban players from joining",
            type = "input",
            set = "banPlayer"
        },
        unban = {
            name = "Unban Player",
            desc = "[player] - Unbans a previously banned player",
            type = "input",
            set = "unbanPlayer"
        },
        listbans = {
            name = "List Bans",
            desc = "See banned players",
            type = "execute",
            func = "listBans"
        },
		audit = { 
			name = "List Merges",
			desc = "See all merged players or changes",
			type = "execute",
			func = "auditMerges" 
		},
    }
}

local function trimInput(text)
	if not text then
		return ""
	end

	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

function CrossGambling:PrintCommandHelp()
	self:Print("Commands: show, hide, minimap, allstats, stats, joinstats, unjoinstats, listalts, updatestat, deletestat, resetstats, ban, unban, listbans, audit")
	self:Print("Usage: /cg <command> [value]")
end

function CrossGambling:HandleSlashCommand(input)
	local trimmed = trimInput(input)
	if trimmed == "" then
		self:PrintCommandHelp()
		return
	end

	local command, remainder = trimmed:match("^(%S+)%s*(.-)$")
	command = command and command:lower() or ""
	remainder = trimInput(remainder)

	local option = options.args[command]
	if not option then
		self:Print(("Unknown command: %s"):format(command))
		self:PrintCommandHelp()
		return
	end

	if option.type == "execute" then
		if type(option.func) == "string" then
			local method = self[option.func]
			if type(method) == "function" then
				method(self)
				return
			end
		elseif type(option.func) == "function" then
			option.func()
			return
		end
	elseif option.type == "input" then
		if remainder == "" then
			self:Print(("Usage: /cg %s %s"):format(command, option.desc or "<value>"))
			return
		end

		if type(option.set) == "string" then
			local method = self[option.set]
			if type(method) == "function" then
				method(self, remainder)
				return
			end
		elseif type(option.set) == "function" then
			option.set(nil, remainder)
			return
		end
	end

	self:Print(("Command '%s' is not available right now."):format(command))
end


function CrossGambling:OnInitialize()
	self:InitDB()
	self:InitMinimap()
	self:DrawSecondEvents()
	self:RegisterChatCommand("CrossGambling", "HandleSlashCommand")
	self:RegisterChatCommand("cg", "HandleSlashCommand")
	self.uiBuilt = false
end

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

function CrossGambling:InitDB()
    local defaults = {
        global = {
            minimap = {
                hide = false,
            },
            wager = 1000,
            houseCut = 10,
			colors = { frameColor = {r = 0.27, g = 0.27, b = 0.27}, buttonColor = {r = 0.30, g = 0.30, b = 0.30}, sideColor = {r = 0.20, g = 0.20, b = 0.20}, fontColor = {r = 1, g = 0, b = 0} },
            themechoice = 1,
            theme = uiThemes[2],
            stats = {},
			deathrollStats = {},
            housestats = 0,
            joinstats = {},
            scale = 1,
            scalevalue = 1,
			fontvalue = 14, 
            bans = {},
            auditLog = {},
            auditRetention = 30,
            auditMaxEntries = 500,
},
}

		self.game = {
				chatMethod = chatMethods[1],
				mode = gameModes[1],
				state = gameStates[1],
				chatframeOption = true,
				realmFilter = false,
				house = false,
				host = false, 
				players = {},
				PlayerName = UnitName("player"),
				PlayerClass = select(2, UnitClass("player")),
				result = nil,
				sessionStats = {},
			}

    CGCall = {}
	self.db = LibStub("AceDB-3.0"):New("CrossGambling", defaults, true)
	if(CrossGambling["stats"]) then CrossGambling["stats"] = self.db.global.stats end
	
end

function CrossGambling:InitMinimap()
	local minimapIcon = LibStub("LibDBIcon-1.0")
	local minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("CrossGamblingIcon", {
	type = "data source",
	text = "CrossGambling",
	icon = "Interface\\AddOns\\CrossGambling\\media\\icon",
	OnClick = function()
	CrossGambling:BuildUI()
	if (self.db.global.theme == uiThemes[1]) then
		self:toggleUi2()
	elseif (self.db.global.theme == uiThemes[2]) then
		self:toggleUi()
	end
end,
	OnTooltipShow = function(tooltip)
            local version = "v12.0.09"
            if version:find("project-version", 1, true) then 
                version = "Dev" 
            end
            tooltip:AddDoubleLine("Cross Gambling", "|cFFAAAAAA" .. version .. "|r", 1, 0.82, 0, 1, 1, 1)
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine("|cFF00BBFFLeft-Click|r", "|cFFFFFFFFToggle CrossGambling Window|r")
        end,
})
minimapIcon:Register("CrossGamblingIcon", minimapLDB, self.db.global.minimap)

function CrossGambling:ToggleMinimap()
	if (self.db.global.minimap.hide == false) then
		minimapIcon:Hide("CrossGamblingIcon")
		self.db.global.minimap.hide = true
	else
		minimapIcon:Show("CrossGamblingIcon")
		self.db.global.minimap.hide = false
	end
end
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

function CrossGambling:SendMsg(event, arg1)
  local msg = event
  if arg1 then msg = msg .. ":" .. tostring(arg1) end
  if self.game.chatMethod then
    pcall(ChatThrottleLib.SendAddonMessage, ChatThrottleLib, "BULK", "CrossGambling", msg, self.game.chatMethod)
  end
end

function CrossGambling:SendChat(msg, method)
  pcall(SendChatMessage, msg, method or self.game.chatMethod)
end

function CrossGambling:RegisterChatEvents()
    if self.game.chatMethod == chatMethods[1] then
        self:RegisterEvent("CHAT_MSG_PARTY", "handleChatMsg")
        self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "handleChatMsg")
    elseif self.game.chatMethod == chatMethods[2] then
        self:RegisterEvent("CHAT_MSG_RAID", "handleChatMsg")
        self:RegisterEvent("CHAT_MSG_RAID_LEADER", "handleChatMsg")
        self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT", "handleChatMsg") 
    else
        self:RegisterEvent("CHAT_MSG_GUILD", "handleChatMsg")
    end
end

function CrossGambling:chatMethod()
    local channelNum
    for i = 1, #chatMethods do
        if (self.game.chatMethod == chatMethods[i]) then
            channelNum = i
        end
    end

    if (channelNum ~= nil) then
            if (channelNum == #chatMethods) then
                self.game.chatMethod = chatMethods[1]
            else
                self.game.chatMethod = chatMethods[channelNum + 1]
            end
    else
        self.game.chatMethod = chatMethods[1]
    end
	
end

function CrossGambling:addCommas(value)
    return #tostring(value) > 3 and tostring(value):gsub("^(-?%d+)(%d%d%d)", "%1,%2"):gsub("(%d)(%d%d%d)", ",%1,%2") or tostring(value)
end


function CrossGambling:handleChatMsg(_, text, playerName)
    if (self.game.state == gameStates[2]) then
        local playerName = strsplit("-", playerName, 2)
        self:RegisterGame(text, playerName)
    end
end

function CrossGambling:TrimAuditLog()
    if not self.db or not self.db.global then return end

    local log = self.db.global.auditLog or {}
    local retention = self.db.global.auditRetention
    local maxEntries = tonumber(self.db.global.auditMaxEntries) or 500

    if retention ~= nil and retention ~= -1 and retention ~= "Never" then
        local cutoff = time() - (tonumber(retention) * 86400)
        local prunedLog = {}

        for _, entry in ipairs(log) do
            if tonumber(entry.timestamp) and tonumber(entry.timestamp) > cutoff then
                table.insert(prunedLog, entry)
            end
        end

        log = prunedLog
    end

    if maxEntries > 0 and #log > maxEntries then
        local startIndex = #log - maxEntries + 1
        local cappedLog = {}

        for i = startIndex, #log do
            cappedLog[#cappedLog + 1] = log[i]
        end

        log = cappedLog
    end

    self.db.global.auditLog = log
end

function CrossGambling:AddAuditEntry(entry)
    if not self.db or not self.db.global or type(entry) ~= "table" then return end

    self.db.global.auditLog = self.db.global.auditLog or {}
    table.insert(self.db.global.auditLog, entry)
    self:TrimAuditLog()
end

function CrossGambling:handleSystemMessage(_, text)
    if self.game.state ~= gameStates[3] then
        return
    end

    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")

    if not playerName or not actualRoll or not minRoll or not maxRoll then
        return
    end

    minRoll, maxRoll = tonumber(minRoll), tonumber(maxRoll)
    actualRoll = tonumber(actualRoll)

    self:DispatchModeHook("OnRollReceived", playerName, actualRoll, minRoll, maxRoll)
end

function CrossGambling:banPlayer(info, playerName)
    if not playerName or playerName == "" then
        self:Print("Error: No name provided.")
        return
    end

    for i, bannedPlayer in ipairs(self.db.global.bans) do
        if bannedPlayer == playerName then
            self:Print(playerName .. " Unable to add to ban list - user already banned.")
            return
        end
    end

    table.insert(self.db.global.bans, playerName)
    self:Print(playerName .. " has been added to the ban list.")
end


function CrossGambling:unbanPlayer(info, playerName)
    if not playerName or playerName == "" then
        self:Print("Error: No name provided.")
        return
    end

    local playerIndex = nil
    for i = 1, #self.db.global.bans do
        if (self.db.global.bans[i] == playerName) then
            playerIndex = i
            break
        end
    end

    if playerIndex then
        table.remove(self.db.global.bans, playerIndex)
        self:Print(playerName .. " has been removed from the ban list.")
    else
        self:Print(playerName .. " is not currently banned!")
    end
end


function CrossGambling:listBans(info)
    local bans = self.db.global.bans
    if #bans == 0 then
        self:Print("There are no bans currently.")
    else
        for i, ban in ipairs(bans) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s", "...", tostring(ban)))
        end
        self:Print("The Current Bans, to unban use /cg unban [PlayerName]")
    end
end


function CrossGambling:changeGameMode()
	local gameNum
	for i = 1, #gameModes do
        if (self.game.mode == gameModes[i]) then
            gameNum = i
        end
    end

    if (gameNum ~= nil) then
            if (gameNum == #gameModes) then
                self.game.mode = gameModes[1]
            else
                self.game.mode = gameModes[gameNum + 1]
            end
    else
        self.game.mode = gameModes[1]
    end
end

function CrossGambling:PromptNextRoll()
    local currentPlayer = self.game.players[self.currentPlayerIndex]
    if currentPlayer then
        self:SendChat(format("%s, it's your turn! Type /roll %d", currentPlayer.name, self.currentRoll))
      else
        self:SendChat("Error: Current player is nil during prompt.")
    end
end


function CrossGambling:getPlayerByName(name)
    for i = 1, #self.game.players do
        if self.game.players[i].name == name then
            return self.game.players[i]
        end
    end
    return nil
end

function CrossGambling:hasPendingRolls()
    for i = 1, #self.game.players do
        if not self.game.players[i].roll then
            return true
        end
    end
    return false
end

function CrossGambling:CGRolls()
    if (self.game.state == gameStates[2]) then
        if (#self.game.players > 1) then
            self:UnRegisterChatEvents()
            self:RegisterEvent("CHAT_MSG_SYSTEM", "handleSystemMessage")
            self.game.state = gameStates[3]
            CGCall["START_ROLLS"]()
        else
			self:SendChat("Not enough Players!")
        end
    elseif (self.game.state == gameStates[3]) then
        local playersRoll = self:CheckRolls()
        if #playersRoll > 0 then
            local message = table.concat(playersRoll, ", ") .. " still needs to roll!"
			self:SendChat(message)
        end
    end
end

function CrossGambling:CheckRolls(playerName)
    local playersRoll = {}
    for i = 1, #self.game.players do
        if (self.game.players[i].roll == nil) then
            table.insert(playersRoll, self.game.players[i].name)
        end
    end
    return playersRoll
end

function CrossGambling:CGResults()
    local result = {}
	result = self:CResult()

    if  (self.game.result == nil) then
        self.game.result = result
    else 
        if (#self.game.result.winners > 1) then
            if (#result.winners > 0) then
                self.game.result.winners = result.winners
            else
                self.game.result.winners = result.losers
            end
        elseif (#self.game.result.losers > 1) then
            if (#result.losers > 0) then
                self.game.result.losers = result.losers
            else
                self.game.result.losers = result.winners
            end
        end
    end

    self:detectTie()
end




function CrossGambling:registerPlayer(playerName, playerRoll)
    for i = 1, #self.game.players do
        if (self.game.players[i].name == playerName) then
            return
        end
    end

    for i = 1, #self.db.global.bans do
        if (self.db.global.bans[i] == playerName) then
		    if(self.game.chatframeOption == false and self.game.host == true) then
				local RollNotification = "Sorry " .. playerName .. ", you're banned."
				self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
			else
				self:SendChat("Sorry " .. playerName .. ", you're banned." )
			end
            return
        end
    end

    local newRegister = {
        name = playerName,
        roll = playerRoll
    }
	
    tinsert(self.game.players, newRegister)
end

function CrossGambling:unregisterPlayer(playerName)
    for i = 1, #self.game.players do
        if (self.game.players[i].name == playerName) then         
		   tremove(self.game.players, i)
            return
        end
    end
end



function CrossGambling:UnRegisterChatEvents()
        self:UnregisterEvent("CHAT_MSG_PARTY")
        self:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
        self:UnregisterEvent("CHAT_MSG_RAID")
        self:UnregisterEvent("CHAT_MSG_RAID_LEADER")
		self:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT")
        self:UnregisterEvent("CHAT_MSG_GUILD")
end
