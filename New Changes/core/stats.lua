function CrossGambling:reportStats(full)
    -- Post the stats to the chat channel
    SendChatMessage("-- CrossGambling All Time Stats --", self.db.global.gamble.chatMethod)
    SendChatMessage("The house has taken " .. self:formatInt(CrossGambling["stats"]) .. " gold!", self.db.global.gamble.chatMethod)

	local sortlistname = {};
	local sortlistamount = {};
	local n = 0;
	local i, j, k;

	for i, j in pairs(CrossGambling["stats"]) do
		local name = i;
		if(CrossGambling["joinstats"][strlower(i)] ~= nil) then
			name = CrossGambling["joinstats"][strlower(i)]:gsub("^%l", string.upper);
		end
		for k=0,n do
			if(k == n) then
				sortlistname[n] = name;
				sortlistamount[n] = j;
				n = n + 1;
				break;
			elseif(strlower(name) == strlower(sortlistname[k])) then
				sortlistamount[k] = (sortlistamount[k] or 0) + j;
				break;
			end
		end
	end

	for i = 0, n-1 do
		for j = i+1, n-1 do
			if(sortlistamount[j] > sortlistamount[i]) then
				sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i];
				sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i];
			end
		end
	end
	
	if full then
		for k = 0,  #sortlistamount do
			local sortsign = "won";
			if(sortlistamount[k] < 0) then sortsign = "lost"; end
			SendChatMessage(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), self.db.global.gamble.chatMethod);
		end

		return
	end

	local x1 = 3-1;
	local x2 = n-3;
	if(x1 >= n) then x1 = n-1; end
	if(x2 <= x1) then x2 = x1+1; end

	for i = 0, x1 do
		sortsign = "won";
		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		SendChatMessage(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), self.db.global.gamble.chatMethod);
	end

	if(x1+1 < x2) then
		SendChatMessage("...", self.db.global.gamble.chatMethod);
	end

	for i = x2, n-1 do
		sortsign = "won";

		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		SendChatMessage(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), self.db.global.gamble.chatMethod);
		
	end
end

function CrossGambling:updateStats(playerName, amount)
    -- Update a given player's stats by adding the given amount
    if (CrossGambling["stats"][playerName] == nil) then
        CrossGambling["stats"][playerName] = 0
    end

    CrossGambling["stats"][playerName] = CrossGambling["stats"][playerName] + amount
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
	CrossGambling["joinstats"][altname] = mainname;
end

function CrossGambling:unjoinStats(info, altname)
 if(altname ~= nil and altname ~= "") then
		DEFAULT_CHAT_FRAME:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname))
		CrossGambling["joinstats"][altname] = nil
	else
		local i, e
		for i, e in pairs(CrossGambling["joinstats"]) do
			DEFAULT_CHAT_FRAME:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e))
		end
	end
end

function CrossGambling:updateStats(info, args)
    local player, amount = strsplit(" ", args)
    amount = tonumber(amount)

    if (player ~= nil and amount ~= nil) then
        local oldAmount = CrossGambling["stats"][player]

        if (oldAmount == nil) then
            oldAmount = 0
        end

        self:updatePlayerStat(player, amount)
        self:Print("Successfully updated stats for " .. player .. " (" .. oldAmount .. " -> " .. CrossGambling["stats"][player] .. ")")
    else
        self:Print("Could not add given amount (" .. tostring(amount) .. ") to " .. tostring(player) .. "'s stats due to invalid input.")
    end
end

function CrossGambling:deleteStats(info, player)
    if (CrossGambling["stats"][player] ~= nil) then
        CrossGambling["stats"][player] = nil
    end
    self:Print("Successfully removed stats for " .. player .. ".")
end

function CrossGambling:resetStats(info)
   CrossGambling["stats"] = { }
   CrossGambling["joinstats"] = { }
end