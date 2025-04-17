function CrossGambling:Copy_Table(src, dest)
	--Adding the old stats to the new table.
	for index, value in pairs(CrossGambling["stats"]) do
		if type(value) == "table" then
			dest[index] = {}
			self:Copy_Table(value, dest[index])
		else
			dest[index] = value
		end
	end
end

function CrossGambling:reportStats(full)
	-- Post the stats to the chat channel
	SendChatMessage("-- CrossGambling All Time Stats --", self.game.chatMethod)
	SendChatMessage(string.format("The house has taken %s total.", (self.db.global.housestats)), self.game.chatMethod)

	local sortlistname = {}
	local sortlistamount = {}
	local n = 0

	-- Allows for the old stats to be removed and updated to the new table.
	if CrossGambling["stats"] then
		self:Copy_Table(dt, self.db.global.stats)
		CrossGambling["stats"] = nil
	end

	for i, j in pairs(self.db.global.stats) do
		local name = i
		if self.db.global.joinstats[strlower(i)] ~= nil then
			name = self.db.global.joinstats[strlower(i)]:gsub("^%l", string.upper)
		end

		-- Find the appropriate position to insert or update
		local found = false
		for k = 1, n do
			if strlower(name) == strlower(sortlistname[k]) then
				sortlistamount[k] = (sortlistamount[k] or 0) + j
				found = true
				break
			end
		end

		if not found then
			n = n + 1
			sortlistname[n] = name
			sortlistamount[n] = j
		end
	end

	-- Define a comparator function for sorting in descending order
	local function compare(i, j)
		return sortlistamount[i] > sortlistamount[j]
	end

	-- Create an index table to keep track of original indices
	local indices = {}
	for i = 1, n do
		indices[i] = i
	end

	-- Sort indices based on the comparator function
	table.sort(indices, compare)

	-- Rearrange sortlistamount and sortlistname based on sorted indices
	local sortedAmounts = {}
	local sortedNames = {}
	for i, idx in ipairs(indices) do
		sortedAmounts[i] = sortlistamount[idx]
		sortedNames[i] = sortlistname[idx]
	end

	-- Update the original lists
	sortlistamount = sortedAmounts
	sortlistname = sortedNames

	if full then
		for i = 1, n do
			local sortsign = "won"
			if sortlistamount[i] < 0 then sortsign = "lost" end
			SendChatMessage(string.format("%d. %s %s %d total", i, sortlistname[i], sortsign, math.abs(sortlistamount[i])), self.game.chatMethod)
		end
		return
	end

	-- Top 3 Winners
	local x1 = math.min(3, n)
	if x1 > 0 then
		SendChatMessage("-- Top 3 Winners --", self.game.chatMethod)
		for i = 1, x1 do
			local sortsign = "won"
			if sortlistamount[i] < 0 then sortsign = "lost" end
			SendChatMessage(string.format("%d. %s %s %d total", i, sortlistname[i], sortsign, math.abs(sortlistamount[i])), self.game.chatMethod)
		end
	end

	-- Top 3 Losers
	local x2 = math.min(3, n)
	if x2 > 0 then
		SendChatMessage("-- Top 3 Losers --", self.game.chatMethod)
		for i = 1, x2 do
			local sortsign = "won"
			if sortlistamount[n - i + 1] < 0 then sortsign = "lost" end
			SendChatMessage(string.format("%d. %s %s %d total", i, sortlistname[n - i + 1], sortsign, math.abs(sortlistamount[n - i + 1])), self.game.chatMethod)
		end
	end
end


function CrossGambling:updatePlayerStat(playerName, amount)
	-- Update a given player's stats by adding the given amount.
	if (self.db.global.stats[playerName] == nil) then
		self.db.global.stats[playerName] = 0
	end

	self.db.global.stats[playerName] = self.db.global.stats[playerName] + amount
end

function CrossGambling:joinStats(info, args)
  local i = string.find(args, " ")
	if((not i) or i == -1 or string.find(args, "[", 1, true) or string.find(args, "]", 1, true)) then
		DEFAULT_CHAT_FRAME:AddMessage("")
		return
	end
	local mainname = string.sub(args, 1, i-1)
	local altname = string.sub(args, i+1)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname))
	self.db.global.joinstats [altname] = mainname;
end

function CrossGambling:unjoinStats(info, altname)
 if(altname ~= nil and altname ~= "") then
		DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname))
		self.db.global.joinstats [altname] = nil
	else
		local i, e
		for i, e in pairs(self.db.global.joinstats ) do
			DEFAULT_CHAT_FRAME:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e))
		end
	end
end


function CrossGambling:listAlts(info, mainname, altname)
	-- Alt List
	for mainname, altname in pairs(self.db.global.joinstats) do
		local nameString = altname
		self:Print("[main] " .. mainname .. " is merged with [alt] " .. nameString)
	end
end

function CrossGambling:updateStat(info, args)
	local player, amount = string.match(args, "^(%S+)%s+(%-?%d+)$")
	amount = tonumber(amount)

	if player and amount then
		local oldAmount = self.db.global.stats[player] or 0
		self:updatePlayerStat(player, amount)
		self:Print(string.format("Successfully updated stats for %s (%d -> %d)", player, oldAmount, self.db.global.stats[player]))
	else
		self:Print(string.format("Could not add given amount (%s) to %s's stats due to invalid input.", tostring(amount), tostring(player)))
	end
end

function CrossGambling:deleteStat(info, player)
	if (self.db.global.stats[player] ~= nil) then
		self.db.global.stats[player] = nil
	end
	self:Print("Successfully removed stats for " .. player .. ".")
end

function CrossGambling:resetStats(info)
   self.db.global.stats = { }
   self.db.global.joinstats = { }
end
