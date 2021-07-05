CrossGambling = LibStub("AceAddon-3.0"):NewAddon("CrossGambling", "AceConsole-3.0", "AceEvent-3.0")
local CrossGambling = LibStub("AceAddon-3.0"):GetAddon("CrossGambling")
-- GLOBALS
local gameStates = {
    "START",
    "REGISTER",
    "ROLL"
}

local gameModes = {
    "Classic",
    "BigTwo",
    "501"
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
            func = "ShowGUI"
        },
        hide = {
            name = "Hide",
            desc = "Hide Game",
            type = "execute",
            func = "HideGUI"
		},
        minimap = {
            name = "Minimap",
            desc = "Show/Hide Minimap Icon",
            type = "execute",
            func = "minimap"
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
            func = "fameshame"
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
    }
}

-- Initialization --
function CrossGambling:OnInitialize()
    -- Defaults for the DB
	local defaults = {
		global = {
			minimap = {
            hide = false,
        },
		    wager = 1000,
			houseCut = 10,
			themechoice = 1,
			theme = uiThemes[2],
			stats = {},
			housestats = 0,
			joinstats = {},
			scale = 1,
			scalevalue = 1,
			bans = {},
		},
	}
	
	self.game = {
				chatMethod = chatMethods[1],
				mode = gameModes[1],
				state = gameStates[1],
				chatframeOption = true,
				house = false,
				host = false, 
				players = {},
				PlayerName = UnitName("player"),
				PlayerClass = select(2, UnitClass("player")),
				result = nil,
			}
			CGEvents = {}
    self.db = LibStub("AceDB-3.0"):New("CrossGambling", defaults, true)
	if(CrossGambling["stats"]) then CrossGambling["stats"] = self.db.global.stats end
    LibStub("AceConfig-3.0"):RegisterOptionsTable("CrossGambling", options, {"CrossGambling", "cg"})
    self.game.chatframeOption = true
    -- Sets up the minimap icon
    local minimapIcon = LibStub("LibDBIcon-1.0")
    local minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("CrossGamblingIcon", {
        type = "data source",
        text = "CrossGambling",
        icon = "Interface\\AddOns\\CrossGambling\\media\\icon",
        OnClick = function() 
		if (self.db.global.theme == uiThemes[1]) then
			self:toggleUi2()
        elseif (self.db.global.theme == uiThemes[2]) then
			self:toggleUi() end end,
        OnTooltipShow = function(tooltip)
		    tooltip:AddLine("CrossGambling", 1, 1, 1)
            tooltip:AddLine(" ", 1, 1, 1)
            tooltip:AddLine("Toggle CrossGambling.", 1, 229 / 255, 153 / 255)
		    tooltip:Show()

		end,
    })
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Cross Gambling> loaded /cg to use");
    minimapIcon:Register("CrossGamblingIcon", minimapLDB, self.db.global.minimap)
	if (self.db.global.theme == uiThemes[2]) then
		self:ConstructUI()
	elseif (self.db.global.theme == uiThemes[1]) then
		self:ConstructUI2()
	end
	function CrossGambling:minimap(info)
		if self.db.global.minimap.hide == false then 
			minimapIcon:Hide("CrossGamblingIcon")
			self.db.global.minimap.hide = true
		elseif self.db.global.minimap.hide == true then
			minimapIcon:Show("CrossGamblingIcon")
			self.db.global.minimap.hide = false
		end
	end
    
	self:drawEvents()
end


function CrossGambling:ShowGUI(info)
	if (self.db.global.theme == uiThemes[1]) then
		CrossGambling:ShowClassic(info)
    elseif (self.db.global.theme == uiThemes[2]) then
		CrossGambling:ShowSlick(info)
	end
end

function CrossGambling:HideGUI(info)
	if (self.db.global.theme == uiThemes[1]) then
		CrossGambling:HideClassic(info)
    elseif (self.db.global.theme == uiThemes[2]) then
		CrossGambling:HideSlick(info)
	end
end

function CrossGambling:SendEvent(event, arg1)
	-- Sends the game to proper chat channels for clients. 
	if self.game.chatMethod then
		local Event = event .. ":" .. tostring(arg1)

		C_ChatInfo.SendAddonMessage("CrossGambling", Event, self.game.chatMethod)
    --print("DEBUG | Event: ", event, " // Channel: ", Channel)
	end
end

function CrossGambling:RegisterChatEvents()
		if (self.game.chatMethod == chatMethods[1]) then
            self:RegisterEvent("CHAT_MSG_PARTY", "handleChatMsg")
            self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "handleChatMsg")
        elseif (self.game.chatMethod == chatMethods[2]) then
            self:RegisterEvent("CHAT_MSG_RAID", "handleChatMsg")
            self:RegisterEvent("CHAT_MSG_RAID_LEADER", "handleChatMsg")
        else
            self:RegisterEvent("CHAT_MSG_GUILD", "handleChatMsg")
        end
end

--ChatMethods
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

function CrossGambling:handleChatMsg(_, text, playerName)
    -- Record Player Registration
    if (self.game.state == gameStates[2]) then
        local playerName = strsplit("-", playerName, 2)
        self:RegisterGame(text, playerName)
    end
end

function CrossGambling:handleSystemMessage(_, text)
    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")

    -- records player rolls
	if (tonumber(minRoll) == 1 and tonumber(maxRoll) == self.db.global.wager) then
        for i = 1, #self.game.players do
            if (self.game.players[i].name == playerName and self.game.players[i].roll == nil) then
                self.game.players[i].roll = tonumber(actualRoll)
				self:SendEvent("PLAYER_ROLL", playerName..":"..tostring(actualRoll))
            end
        end
    end

    if (#self:CheckRolls() == 0) then
        self:CGResults()
    end
end

function CrossGambling:banPlayer(info, playerName)
	-- Adds players to ban list
	if (playerName ~= nil or playerName ~= "") then
		for i=1, #self.db.global.bans do
			if (playerName == self.db.global.bans[i]) then
				self:Print(playerName .. " Unable to add to ban list - user already banned.")
				return
			end
		end
			tinsert(self.db.global.bans, playerName)
			self:Print(playerName .. " has been added to the ban list.")
	else
		self:Print(playerName .. "|cffffff00Error: No name provided.")
	end
end

function CrossGambling:unbanPlayer(info, playerName)
    -- Removes from ban list
	if (playerName ~= nil or playerName ~= "") then
		for i = 1, #self.db.global.bans do
			if (playerName == self.db.global.bans[i]) then
				tremove(self.db.global.bans, i)
				self:Print(playerName .. " has been removed from the ban list.")
				return
			end
		end
		self:Print(playerName .. " is not currently banned!")
	else
		self:Print(playerName .. "|cffffff00Error: No name provided.")
	end
end

function CrossGambling:listBans(info)
	for i=1, table.getn(self.db.global.bans) do
		DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", "...", tostring(self.db.global.bans[i])))
	end
		self:Print("|cffffff00The Current Bans, to unban use /cg unban [PlayerName]@")
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

function CrossGambling:CGRolls()
    if (self.game.state == gameStates[2]) then
        -- Need at least two or more players to play. 
        if (#self.game.players > 1) then
            -- Stop listening to chat messages
            self:UnRegisterChatEvents()
            -- Listens to System Msgs
            self:RegisterEvent("CHAT_MSG_SYSTEM", "handleSystemMessage")
            self.game.state = gameStates[3]

            -- Starts the rolling Phase
            self:SendEvent("START_ROLLS")
        else
			if(self.game.chatframeOption == false and self.game.host == true) then
				local RollNotification = "Not enough Players!"
				self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
			else
				SendChatMessage("Not enough Players!" , self.game.chatMethod)
			end
        end
		-- Sets the game into Roll State 
    elseif (self.game.state == gameStates[3]) then
        -- Shows who hasn't rolled yet. 
        local playersRoll = self:CheckRolls(self.game.players)

        for i = 1, #playersRoll do
			if(self.game.chatframeOption == false) then
				local RollNotification = playersRoll[i] .. " still needs to roll!"
				self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
			else
				 SendChatMessage(playersRoll[i] .. " still needs to roll!" , self.game.chatMethod)
			end
        end
    end
end

function CrossGambling:CGResults()
    -- Results for winners/losers.
    local result = {}
	result = self:CResult()

    if  (self.game.result == nil) then
        self.game.result = result
    else
        -- If theres a tie breaker. 
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

function CrossGambling:CloseGame()
    if (self.game.result ~= nil) then
        if (#self.game.result.losers > 0 and #self.game.result.winners > 0) then
            local houseAmount = 0

            -- Check and make sure housecut is turned on.
            if (self.game.house == true) then
                houseAmount = math.floor(self.game.result.amountOwed * (self.db.global.houseCut / 100))
                self.game.result.amountOwed = self.game.result.amountOwed - houseAmount
            end
            -- Update players house/stats
            for i = 1, #self.game.result.losers do
			 if (self.game.house == false) then
			    local RollNotification = (self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. self:Comma(self.game.result.amountOwed) .. " gold!")
				if(self.game.chatframeOption == false and self.game.host == true) then	
					self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
				else
					SendChatMessage(self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. self:Comma(self.game.result.amountOwed) .. " gold!" , self.game.chatMethod)
                end               
			   self:updatePlayerStat(self.game.result.losers[i].name, self.game.result.amountOwed * -1)
			elseif(self.game.house == true) then
                if(self.game.chatframeOption == false and self.game.host == true) then
					local RollNotification = self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. self:Comma(self.game.result.amountOwed) .. " gold!" .. " plus " .. self:Comma(houseAmount) .. " to the guild"
					self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
				else
					SendChatMessage(self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. self:Comma(self.game.result.amountOwed) .. " gold!" .. " plus " .. self:Comma(houseAmount) .. " to the guild" , self.game.chatMethod)
				end
					self:updatePlayerStat(self.game.result.losers[i].name, self.game.result.amountOwed * -1)
					self.db.global.housestats = self.db.global.housestats + houseAmount
                end
            end
            
            for i = 1, #self.game.result.winners do
                self:updatePlayerStat(self.game.result.winners[i].name, self.game.result.amountOwed * #self.game.result.losers)
            end
        else
			if(self.game.chatframeOption == false and self.game.host == true) then
				local RollNotification = "No winners this round!"
				self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
			else
				SendChatMessage("No winners this round!" , self.game.chatMethod)
			end
        end
    end

	self:UnRegisterChatEvents()
    self:UnregisterEvent("CHAT_MSG_SYSTEM")
    self.game.state = gameStates[1]
    self.game.players = {}
    self.game.result = nil
end

function CrossGambling:registerPlayer(playerName, playerRoll)
    for i = 1, #self.game.players do
        if (self.game.players[i].name == playerName) then
            return
        end
    end
	
	    -- Check Ban List
    for i = 1, #self.db.global.bans do
        if (self.db.global.bans[i] == playerName) then
		    if(self.game.chatframeOption == false and self.game.host == true) then
				local RollNotification = "Sorry " .. playerName .. ", you're banned."
				self:SendEvent(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
			else
				SendChatMessage("Sorry " .. playerName .. ", you're banned." , self.game.chatMethod)
			end
            return
        end
    end

    -- Register a new player.
    local newRegister = {
        name = playerName,
        roll = playerRoll
    }
	
    tinsert(self.game.players, newRegister)
end

function CrossGambling:unregisterPlayer(playerName)
    -- Unregisters the player.
    for i = 1, #self.game.players do
        if (self.game.players[i].name == playerName) then         
		   tremove(self.game.players, i)
            return
        end
    end
end

function CrossGambling:CheckRolls(playerName)
    -- Shows who hasn't rolled.
	    local playersRoll = {}

    for i = 1, #self.game.players do
        if (self.game.players[i].roll == nil) then
            tinsert(playersRoll, self.game.players[i].name)
        end
    end

    return playersRoll
end

function CrossGambling:UnRegisterChatEvents()
        self:UnregisterEvent("CHAT_MSG_PARTY")
        self:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
        self:UnregisterEvent("CHAT_MSG_RAID")
        self:UnregisterEvent("CHAT_MSG_RAID_LEADER")
        self:UnregisterEvent("CHAT_MSG_GUILD")
end