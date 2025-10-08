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


function CrossGambling:OnInitialize()
	self:InitDB()
	self:InitMinimap()
	self:DrawSecondEvents()
		
	if (self.db.global.theme == uiThemes[2]) then
		self:DrawMainEvents()
	elseif (self.db.global.theme == uiThemes[1]) then
		self:DrawMainEvents2()
	end
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
			auditRetention = -1,
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
	LibStub("AceConfig-3.0"):RegisterOptionsTable("CrossGambling", options, {"CrossGambling", "cg"})
	if(CrossGambling["stats"]) then CrossGambling["stats"] = self.db.global.stats end
	
end

function CrossGambling:InitMinimap()
	local minimapIcon = LibStub("LibDBIcon-1.0")
	local minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("CrossGamblingIcon", {
	type = "data source",
	text = "CrossGambling",
	icon = "Interface\\AddOns\\CrossGambling\\media\\icon",
	OnClick = function()
	if (self.db.global.theme == uiThemes[1]) then
		self:toggleUi2()
	elseif (self.db.global.theme == uiThemes[2]) then
		self:toggleUi()
	end
end,
	OnTooltipShow = function(tooltip)
	tooltip:AddLine("CrossGambling", 1, 1, 1)
	tooltip:AddLine(" ", 1, 1, 1)
	tooltip:AddLine("Toggle CrossGambling.", 1, 229 / 255, 153/ 255)
	tooltip:Show()
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
	local method = isShowing and "Show" or "Hide"
	local theme = self.db.global.theme

	if theme == uiThemes[1] then
		CrossGambling[method .. "Classic"](info)
	elseif theme == uiThemes[2] then
		CrossGambling[method .. "Slick"](info)
	end
end

function CrossGambling:SendMsg(event, arg1)
  local msg = event
  if arg1 then msg = msg .. ":" .. tostring(arg1) end
  if self.game.chatMethod then
    ChatThrottleLib:SendAddonMessage("BULK", "CrossGambling", msg, self.game.chatMethod)
  end
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

function add_commas(value) 
return #tostring(value) > 3 and tostring(value):gsub("^(-?%d+)(%d%d%d)", "%1,%2"):gsub("(%d)(%d%d%d)", ",%1,%2") or tostring(value) 
end


function CrossGambling:handleChatMsg(_, text, playerName)
    if (self.game.state == gameStates[2]) then
        local playerName = strsplit("-", playerName, 2)
        self:RegisterGame(text, playerName)
    end
end

function CrossGambling:handleSystemMessage(_, text)
    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")

    if not playerName or not actualRoll or not minRoll or not maxRoll then
        return
    end

    minRoll, maxRoll = tonumber(minRoll), tonumber(maxRoll)
    actualRoll = tonumber(actualRoll)

    if self.game.mode == "1v1DeathRoll" then
        if minRoll ~= 1 or maxRoll ~= self.currentRoll then
            SendChatMessage("Error: Roll does not match expected range.", self.game.chatMethod)
            return
        end

        local currentPlayer = self.game.players[self.currentPlayerIndex]
        if not currentPlayer then
            SendChatMessage("Error: Current player is nil.", self.game.chatMethod)
            return
        end

        if playerName ~= currentPlayer.name then
            SendChatMessage(format("%s, it's not your turn! It's %s's turn.", playerName, currentPlayer.name), self.game.chatMethod)
            return
        end

        CGCall["PLAYER_ROLL"](playerName, actualRoll)

        if actualRoll == 1 then
            local loser = currentPlayer
            local winner = self.game.players[3 - self.currentPlayerIndex]  
            SendChatMessage(format("%s rolls a 1 and loses! %s owes %s %s", loser.name, loser.name, winner.name, self.db.global.wager), self.game.chatMethod)

            self:updatePlayerStat(loser.name, -self.db.global.wager, true) 
            self:updatePlayerStat(winner.name, self.db.global.wager, true) 
            return
        else
            self.currentRoll = actualRoll
            self.currentPlayerIndex = 3 - self.currentPlayerIndex
            self:PromptNextRoll()
        end
    else
        if minRoll == 1 and maxRoll == self.db.global.wager then
            for i = 1, #self.game.players do
                if self.game.players[i].name == playerName and self.game.players[i].roll == nil then
                    self.game.players[i].roll = actualRoll
                    self:SendMsg("PLAYER_ROLL", playerName .. ":" .. tostring(actualRoll))
                end
            end
        end

        if #self:CheckRolls() == 0 then
            self:CGResults()
        end
    end
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
        SendChatMessage(format("%s, it's your turn! Type /roll %d", currentPlayer.name, self.currentRoll), self.game.chatMethod)
      else
        SendChatMessage("Error: Current player is nil during prompt.", self.game.chatMethod)
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
            self:SendMsg("START_ROLLS")
        else
			SendChatMessage("Not enough Players!", self.game.chatMethod)
        end
    elseif (self.game.state == gameStates[3]) then
        local playersRoll = self:CheckRolls()
        if #playersRoll > 0 then
            local message = table.concat(playersRoll, ", ") .. " still needs to roll!"
			SendChatMessage(message, self.game.chatMethod)
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

function CrossGambling:CloseGame()
    if (self.game.result ~= nil) then
        if (#self.game.result.losers > 0 and #self.game.result.winners > 0) then
            local houseAmount = 0

            if (self.game.house == true) then
                houseAmount = math.floor(self.game.result.amountOwed * (self.db.global.houseCut / 100))
                self.game.result.amountOwed = self.game.result.amountOwed - houseAmount
            end

            for i = 1, #self.game.result.losers do
                local RollNotification = ""
                if (self.game.house == false) then
                    RollNotification = self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. add_commas(self.game.result.amountOwed) .. " gold!"
                elseif (self.game.house == true) then
                    RollNotification = self.game.result.losers[i].name .. " owes " .. self.game.result.winners[i].name .. " " .. add_commas(self.game.result.amountOwed) .. " gold!" .. " plus " .. add_commas(houseAmount) .. " to the guild"
                    self:updatePlayerStat("guild", houseAmount) 
                end

                if (self.game.chatframeOption == false and self.game.host == true) then
                    self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
                else
                    SendChatMessage(RollNotification, self.game.chatMethod)
                end

                self:updatePlayerStat(self.game.result.losers[i].name, self.game.result.amountOwed * -1)
                self:updatePlayerStat(self.game.result.winners[i].name, self.game.result.amountOwed * #self.game.result.losers)


                local loserName = self.game.result.losers[i].name
                local winnerName = self.game.result.winners[i].name
                local amountOwed = self.game.result.amountOwed

                table.insert(self.db.global.auditLog, {
                    timestamp = time(),
                    action = "debt",
                    loser = loserName,
                    winner = winnerName,
                    amount = amountOwed,
                })
            end

        else
            if (self.game.chatframeOption == false and self.game.host == true) then
                local RollNotification = "No winners this round!"
                self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
            else
                SendChatMessage("No winners this round!", self.game.chatMethod)
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

    for i = 1, #self.db.global.bans do
        if (self.db.global.bans[i] == playerName) then
		    if(self.game.chatframeOption == false and self.game.host == true) then
				local RollNotification = "Sorry " .. playerName .. ", you're banned."
				self:SendMsg(format("CHAT_MSG:%s:%s:%s", self.game.PlayerName, self.game.PlayerClass, RollNotification))
			else
				SendChatMessage("Sorry " .. playerName .. ", you're banned." , self.game.chatMethod)
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