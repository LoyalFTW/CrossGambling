CrossGambling = LibStub("AceAddon-3.0"):NewAddon("CrossGambling", "AceConsole-3.0", "AceEvent-3.0")
local CrossGambling = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")

local gameStates = {
    "START",
    "REGISTER",
    "ROLL"
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
            func = function()
                CrossGambling:reportStats(true)
            end
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
        exportstats = {
            name = "Export Stats",
            desc = "Open the stats export window",
            type = "execute",
            func = function()
                CrossGambling:ShowStatsTransferFrame("export")
            end
        },
        importstats = {
            name = "Import Stats",
            desc = "Open the stats import window",
            type = "execute",
            func = function()
                CrossGambling:ShowStatsTransferFrame("import")
            end
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
        testing = {
            name = "Testing Mode",
            desc = "[on|off] - Enable to unlock /cg testbots and debug chat echoes. Off by default.",
            type = "input",
            set = "SetTestingMode"
        },
        testbots = {
            name = "Test Bots",
            desc = "[count] - Start a local bot-only test game in the current mode. Requires /cg testing on first.",
            type = "input",
            set = "StartBotTest"
        },
        stoptest = {
            name = "Stop Bot Test",
            desc = "Stops/resets an in-progress bot test game",
            type = "execute",
            func = "StopBotTest"
        },
    }
}

local function trimInput(text)
	if not text then
		return ""
	end

	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeHouseCutValue(value)
	local numericValue = tonumber(value)
	if not numericValue then
		return nil
	end

	numericValue = math.floor(numericValue)
	if numericValue < 0 then
		numericValue = 0
	elseif numericValue > 100 then
		numericValue = 100
	end

	return numericValue
end

local function normalizePlayerName(name)
	if not name then
		return nil
	end

	name = strtrim(tostring(name))
	name = strsplit("-", name, 2)
	if name == "" then
		return nil
	end

	return strlower(name)
end

local function isPlayerBanned(addon, playerName)
	local normalizedPlayerName = normalizePlayerName(playerName)
	if not normalizedPlayerName then
		return false
	end

	for _, bannedPlayer in ipairs((addon and addon.db and addon.db.global and addon.db.global.bans) or {}) do
		if normalizePlayerName(bannedPlayer) == normalizedPlayerName then
			return true
		end
	end

	return false
end

function CrossGambling:NormalizePlayerName(name, preserveRealm)
	if not name then
		return nil
	end

	name = strtrim(tostring(name))
	if name == "" then
		return nil
	end

	if not preserveRealm then
		name = strsplit("-", name, 2)
		if not name or name == "" then
			return nil
		end
	end

	return strlower(name)
end

function CrossGambling:RebuildBanCache()
	self.banLookup = {}

	local bans = self.db and self.db.global and self.db.global.bans
	if not bans then
		return
	end

	for i = 1, #bans do
		local normalizedName = self:NormalizePlayerName(bans[i])
		if normalizedName then
			self.banLookup[normalizedName] = true
		end
	end
end

function CrossGambling:IsPlayerBanned(playerName)
	local normalizedPlayerName = self:NormalizePlayerName(playerName)
	if not normalizedPlayerName then
		return false
	end

	if not self.banLookup then
		self:RebuildBanCache()
	end

	return self.banLookup[normalizedPlayerName] == true
end

function CrossGambling:PrintCommandHelp()
	self:Print("Commands: show, hide, minimap, allstats, stats, joinstats, unjoinstats, listalts, updatestat, deletestat, resetstats, exportstats, importstats, ban, unban, listbans, audit, testing, testbots, stoptest")
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
				method(self, nil, remainder)
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
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
	self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
	self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")
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

-- The saved variable used to be called "CrossGambling", the same name as the addon table.
-- WoW loads saved variables after the addon files, so every login the global addon table
-- was replaced by last session's serialized copy (functions are not saved), and anything
-- calling CrossGambling:Method() at runtime blew up with "attempt to call method (a nil
-- value)". Saved data lives in CrossGamblingDB now; take the global back and carry any
-- legacy data over the first time an upgraded client logs in. The TOCs still list the old
-- CrossGambling saved variable so that data can be read once - drop it from the TOCs (and
-- delete this) in a later release, once players have had a version with the migration.
local legacyDBKeys = {
	"global", "profiles", "profileKeys", "namespaces",
	"char", "realm", "class", "race", "faction", "factionrealm", "factionrealmregion", "locale",
}

local function reclaimGlobal()
	local saved = _G.CrossGambling
	_G.CrossGambling = CrossGambling

	if saved == CrossGambling or type(saved) ~= "table" then
		return
	end

	local current = _G.CrossGamblingDB
	if type(current) == "table" and next(current) ~= nil then
		return
	end

	local migrated = {}
	for _, key in ipairs(legacyDBKeys) do
		if type(saved[key]) == "table" then
			migrated[key] = saved[key]
		end
	end

	if next(migrated) ~= nil then
		_G.CrossGamblingDB = migrated
	end
end

function CrossGambling:InitDB()
	reclaimGlobal()

    local defaults = {
        global = {
            minimap = {
                hide = false,
            },
            wager = 1000,
            minWager = 1,
            maxWager = 1000000,
            testingMode = false,
            houseCut = 10,
			colors = { frameColor = {r = 0.27, g = 0.27, b = 0.27}, buttonColor = {r = 0.30, g = 0.30, b = 0.30}, sideColor = {r = 0.20, g = 0.20, b = 0.20}, fontColor = {r = 1, g = 0, b = 0} },
            themechoice = 1,
            theme = uiThemes[2],
            stats = {},
			deathrollStats = {},
			modeStats = {},
            housestats = 0,
            joinstats = {},
            altStats = {},
            scale = 1,
            scalevalue = 1,
			fontvalue = 14, 
            bans = {},
            auditLog = {},
            auditRetention = 30,
            auditMaxEntries = 500,
            suspendChatEventsInCombat = true,
},
}

        local defaultMode = (self.modeListOrder and self.modeListOrder[1]) or "Classic"

		self.game = {
				chatMethod = chatMethods[1],
				mode = defaultMode,
				state = gameStates[1],
				chatframeOption = true,
				realmFilter = false,
				house = false,
				host = false,
				hostName = nil,
				players = {},
				PlayerName = UnitName("player"),
				PlayerClass = select(2, UnitClass("player")),
				result = nil,
				sessionStats = {},
			}

	CGCall = {}
	self.db = LibStub("AceDB-3.0"):New("CrossGamblingDB", defaults, true)
	if(CrossGambling["stats"]) then CrossGambling["stats"] = self.db.global.stats end
	self:RebuildBanCache()
	
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
            local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
            local version = getAddOnMetadata and getAddOnMetadata("CrossGambling", "Version") or nil
            version = version or "Dev"
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

function CrossGambling:GetWagerLimits()
	local global = self.db and self.db.global
	return (global and global.minWager) or 1, (global and global.maxWager) or 1000000
end

function CrossGambling:ValidateWager(value)
	local numericValue = tonumber(value)
	if not numericValue then
		return nil
	end

	local minWager, maxWager = self:GetWagerLimits()
	numericValue = math.floor(numericValue)
	if numericValue < minWager then
		numericValue = minWager
	elseif numericValue > maxWager then
		numericValue = maxWager
	end

	return numericValue
end

function CrossGambling:SetWager(value)
	if not self.db or not self.db.global then
		return
	end

	local normalizedValue = self:ValidateWager(value)
	if not normalizedValue then
		normalizedValue = self.db.global.wager or 1000
	end

	self.db.global.wager = normalizedValue

	if self.wagerInput then
		self.wagerInput:SetText(tostring(normalizedValue))
	end
end

function CrossGambling:SetHouseCut(value)
	if not self.db or not self.db.global then
		return
	end

	local normalizedValue = normalizeHouseCutValue(value)
	if not normalizedValue then
		normalizedValue = self.db.global.houseCut or 10
	end

	self.db.global.houseCut = normalizedValue

	if self.guildPercentInput then
		self.guildPercentInput:SetText(tostring(normalizedValue))
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

function CrossGambling:SetTestingMode(info, args)
	local value = strtrim(tostring(args or "")):lower()
	local isOn = self.db and self.db.global and self.db.global.testingMode

	if value == "on" then
		self.db.global.testingMode = true
	elseif value == "off" then
		self.db.global.testingMode = false
	else
		self:Print("Usage: /cg testing on|off (currently " .. (isOn and "ON" or "OFF") .. ")")
		return
	end

	self:Print("CrossGambling: Testing mode is now " .. (self.db.global.testingMode and "ON" or "OFF") .. ".")
end

function CrossGambling:SendChat(msg, method)
  if self.db and self.db.global and self.db.global.testingMode then
    self:Print("|cff888888[" .. (method or self.game.chatMethod or "Chat") .. "]|r " .. msg)
  end
  pcall(SendChatMessage, msg, method or self.game.chatMethod)
end

function CrossGambling:ShouldSuspendChatEventsInCombat()
	return self.db
		and self.db.global
		and self.db.global.suspendChatEventsInCombat ~= false
		and InCombatLockdown()
		and self:IsHighImpactCombatContext()
end

function CrossGambling:IsHighImpactCombatContext()
	if self.bossEncounterActive then
		return true
	end

	local _, instanceType = IsInInstance()
	return instanceType == "arena" or instanceType == "pvp"
end

function CrossGambling:SuspendRegistrationChatEvents()
	if self.game.state ~= gameStates[2] then
		return
	end

	self.chatEventsSuspendedForCombat = true
	self:UnRegisterChatEvents()
end

function CrossGambling:ResumeRegistrationChatEvents()
	if not self.chatEventsSuspendedForCombat then
		return
	end

	local mode = self:GetCurrentMode()
	local pickPhaseActive = self.game.state == gameStates[3] and mode and mode.usesChatPick

	if self.game.state == gameStates[2] or pickPhaseActive then
		self:RegisterChatEvents()
	end
end

function CrossGambling:RegisterChatEvents()
	if self:ShouldSuspendChatEventsInCombat() then
		self:SuspendRegistrationChatEvents()
		return
	end

	self.chatEventsSuspendedForCombat = false

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

function CrossGambling:OnCombatStart()
	if self:ShouldSuspendChatEventsInCombat() then
		self:SuspendRegistrationChatEvents()
	end
end

function CrossGambling:OnCombatEnd()
	self:ResumeRegistrationChatEvents()
end

function CrossGambling:OnEncounterStart()
	self.bossEncounterActive = true

	if self:ShouldSuspendChatEventsInCombat() then
		self:SuspendRegistrationChatEvents()
	end
end

function CrossGambling:OnEncounterEnd()
	self.bossEncounterActive = false

	if not self:ShouldSuspendChatEventsInCombat() then
		self:ResumeRegistrationChatEvents()
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
	if self:ShouldSuspendChatEventsInCombat() then
		self.chatEventsSuspendedForCombat = true
		self:UnRegisterChatEvents()
		return
	end

    if (self.game.state == gameStates[2]) then
        local playerName = strsplit("-", playerName, 2)
        self:RegisterGame(text, playerName)
    elseif (self.game.state == gameStates[3]) then
        local playerName = strsplit("-", playerName, 2)
        self:DispatchModeHook("OnChatText", playerName, text)
    end
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
        if normalizePlayerName(bannedPlayer) == normalizePlayerName(playerName) then
            self:Print(playerName .. " Unable to add to ban list - user already banned.")
            return
        end
    end

    table.insert(self.db.global.bans, playerName)
    self:RebuildBanCache()
    self:RemovePlayer(playerName)
    self:unregisterPlayer(playerName)
    self:Print(playerName .. " has been added to the ban list.")
end


function CrossGambling:unbanPlayer(info, playerName)
    if not playerName or playerName == "" then
        self:Print("Error: No name provided.")
        return
    end

    local playerIndex = nil
    for i = 1, #self.db.global.bans do
        if normalizePlayerName(self.db.global.bans[i]) == normalizePlayerName(playerName) then
            playerIndex = i
            break
        end
    end

    if playerIndex then
        table.remove(self.db.global.bans, playerIndex)
        self:RebuildBanCache()
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


function CrossGambling:PromptNextRoll()
    local currentPlayer = self.game.players[self.currentPlayerIndex]
    if currentPlayer then
        self:SendChat(format("%s, it's your turn! Type /roll %d", currentPlayer.name, self.currentRoll))
      else
        self:SendChat("Error: Current player is nil during prompt.")
    end
end


function CrossGambling:getPlayerByName(name)
    local players = self.game.players
    local indexByName = self.game.playerIndexByName

    if not indexByName then
        indexByName = {}
        for i = 1, #players do
            indexByName[players[i].name] = i
        end
        self.game.playerIndexByName = indexByName
    end

    local playerIndex = indexByName[name]
    return playerIndex and players[playerIndex] or nil
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
        local mode = self:GetCurrentMode()
        local minPlayers = (mode and mode.minPlayers) or 2

        if (#self.game.players >= minPlayers) then
            if not (mode and mode.usesChatPick) then
                self:UnRegisterChatEvents()
            end
            self:RegisterEvent("CHAT_MSG_SYSTEM", "handleSystemMessage")
            self.game.state = gameStates[3]
            CGCall["START_ROLLS"]()
        else
			self:SendChat("Not enough Players! This mode needs at least " .. minPlayers .. ".")
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
    local players = self.game.players
    local indexByName = self.game.playerIndexByName

    if not indexByName then
        indexByName = {}
        self.game.playerIndexByName = indexByName
        for i = 1, #players do
            indexByName[players[i].name] = i
        end
    end

    if indexByName[playerName] then
        return
    end

    if self:IsPlayerBanned(playerName) then
		if(self.game.chatframeOption == false and self.game.host == true) then
			local RollNotification = "Sorry " .. playerName .. ", you're banned."
			self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
		else
			self:SendChat("Sorry " .. playerName .. ", you're banned." )
		end
        return
    end

    local newRegister = {
        name = playerName,
        roll = playerRoll
    }
	
    local newIndex = #players + 1
    players[newIndex] = newRegister
    indexByName[playerName] = newIndex
end

function CrossGambling:unregisterPlayer(playerName)
    local players = self.game.players
    local indexByName = self.game.playerIndexByName
    local playerIndex = indexByName and indexByName[playerName]
    if not playerIndex then
        return
    end

    tremove(players, playerIndex)
    indexByName[playerName] = nil

    for i = playerIndex, #players do
        indexByName[players[i].name] = i
    end
end



function CrossGambling:UnRegisterChatEvents()
        self.chatEventsRegistered = false
        self:UnregisterEvent("CHAT_MSG_PARTY")
        self:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
        self:UnregisterEvent("CHAT_MSG_RAID")
        self:UnregisterEvent("CHAT_MSG_RAID_LEADER")
		self:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT")
        self:UnregisterEvent("CHAT_MSG_GUILD")
end
