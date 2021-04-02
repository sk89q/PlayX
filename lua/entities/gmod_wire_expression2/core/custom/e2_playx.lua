E2Lib.RegisterExtension("playx", true, "Allows E2 chips to connect with the PlayX camera","Everyone can play songs")
--// check if the player has permission to use PlayX and if there is a valid player on the map
local function canUsePlayX(ply)
	if ply == nil then return false end
	if !PlayX.IsPermitted(ply) then
		return false
	end
	if !PlayX.PlayerExists() then
		return false
	end
	return true
end
---------------------------------------------// MEDIA CONTOLLER FUNCTIONS \\---------------------------------------------
--open the given link and play the song
--@param string url
--@param string provider e.g. "YouTube"
--@param number starttime -in seconds
--@param number forceLowFramerate
--@param number useJW
--@param number ignoreLength -does this even work? PlayX.OpenMedia(...) never uses the variable
e2function void pxOpenMedia(string url)
	if !canUsePlayX(self.player) then return end
	if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
	    return
	end
	PlayX.OpenMedia("", url,0,nil,nil,nil)
end

e2function void pxOpenMedia(string url,string provider)
	if !canUsePlayX(self.player) then return end
	if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
	    return
	end
	PlayX.OpenMedia( provider, url,0,nil,nil,nil)
end

e2function void pxOpenMedia(string url,string provider,number starttime)
	if !canUsePlayX(self.player) then return end
	if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
	    return
	end
	PlayX.OpenMedia( provider, url,starttime,nil,nil,nil)
end

e2function void pxOpenMedia(string url,string provider,number starttime,number forceLowFramerate)
	if !canUsePlayX(self.player) then return end
	if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
	    return
	end
	PlayX.OpenMedia( provider, url,starttime,(forceLowFramerate!=0),nil,nil)
end

e2function void pxOpenMedia(string url,string provider,number starttime,number forceLowFramerate,number useJW)
	if !canUsePlayX(self.player) then return end
	if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
	    return
	end
	PlayX.OpenMedia( provider, url,starttime,(forceLowFramerate!=0),(useJW!=0),nil)
end

e2function void pxOpenMedia(string url,string provider,number starttime,number forceLowFramerate,number useJW,number ignoreLength)
	if !canUsePlayX(self.player) then return end
	if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
	    return
	end
	PlayX.OpenMedia( provider, url,starttime,(forceLowFramerate!=0),(useJW!=0),(ignoreLength!=0))
end



e2function number pxCanQuery()
	if PlayX.PlayerExists() then
		if GetConVar("playx_race_protection"):GetFloat() > 0 and (CurTime() - PlayX.LastOpenTime) > GetConVar("playx_race_protection"):GetFloat() then
		    return 1
		end
	end
	return 0
end

---Stops the media
e2function void pxStopMedia()
	if !canUsePlayX(self.player) then return end
	PlayX.CloseMedia()
end
---------------------------------------------\\ MEDIA CONTOLLER FUNCTIONS //---------------------------------------------

---------------------------------------------// EASY ACCESS FUNCTIONS \\---------------------------------------------
--Check if a media player is already spawned
--@return number 1 if there is a playX player on the map
e2function number pxExists()
	if PlayX.PlayerExists() then
		return 1
	end
	return 0
end

--Finds the PlayX player on the map
--@return entity or nil
e2function entity pxInstance()
	return PlayX.GetInstance()
end

--Finds all playX repeater on the map
--@return array 
e2function array pxRepeaters()
	return ents.FindByClass("gmod_playx_repeater")
end

--Servertime when the media started playing
--@return number
e2function number pxStartTime()
	if !PlayX.CurrentMedia then return 0 end
	return PlayX.CurrentMedia.StartTime
end

--Length of the media currently playing in seconds
--@return number 
e2function number pxLength()
	if !PlayX.CurrentMedia then return 0 end
	return PlayX.CurrentMedia.Length
end

--Checks whether the PlayX is currently playing
--@return number
e2function number pxIsPlaying()
	if PlayX.CurrentMedia then return 1 end
	return 0
end

--Checks whether the playX is using JW
--@return number
e2function number pxUsingJW()
	if PlayX.IsUsingJW() then
		return 1
	end
	return 0
end

--Gets the media URI 
--@return string
e2function string pxURI()
	if !PlayX.CurrentMedia then return "" end
	return PlayX.CurrentMedia.URI
end

--Gets the media URL
--@return string
e2function string pxURL()
	if !PlayX.CurrentMedia then return "" end
	return PlayX.CurrentMedia.URL
end


--Gets the JWURL
--@return string
e2function string pxJWURL()
	return PlayX.GetJWURL()
end

--Gets the HostURL
--@return string
e2function string pxHostURL()
	return PlayX.GetHostURL()
end

--Checks wheter a player is permitted to use PlayX
--@return number
e2function number pxIsPermitted(entity player)
	if player~= nil and PlayX.IsPermitted(player) then
		return 1
	end
	return 0
end

--shitty way of getting the current time position of the video. Doesn't work correctly when pausing the game in singleplayer
--returns time in seconds
--@return number
e2function number pxCurrentTime() --TODO: better way to calculate this
	if !PlayX.CurrentMedia then return 0 end
	return CurTime() - PlayX.CurrentMedia.StartTime
end
---------------------------------------------\\ EASY ACCESS FUNCTIONS //---------------------------------------------

---------------------------------------------// SPAWNING FUNCTIONS \\---------------------------------------------
--Spawns a PlayX player or PlayX repeater with default cam model "models/dav0r/camera.mdl". Returns the playX entity
--@return entity
e2function entity pxSpawn()
	if self.player == nil or !PlayX.IsPermitted(self.player) then return end
	local success, errorMsg, ent =  PlayX.SpawnForPlayer(self.player, "models/dav0r/camera.mdl" , false)
	if success then
		local instance = ent
		self.data.spawnedProps[ instance ] = true
		return instance
	end
	return nil
end

--Spawns a PlayX player or PlayX repeater with default cam model "models/dav0r/camera.mdl". Returns the playX entity
--@param number isRepeater
--@return entity
e2function entity pxSpawn(number isRepeater)
	if self.player == nil or !PlayX.IsPermitted(self.player) then return end
	local success, errorMsg, ent =  PlayX.SpawnForPlayer(self.player, "models/dav0r/camera.mdl" , isRepeater ~= 0)
	if success then
		local instance = ent
		self.data.spawnedProps[ instance ] = true
		return instance
	end
	return nil
end

--Spawns a PlayX player or PlayX repeater with a seleced model. Returns the playX entity
--@param string model
--@param number isRepeater
--@return entity
e2function entity pxSpawn(string model,number isRepeater)
	if self.player == nil or !PlayX.IsPermitted(self.player) then return end
	local success, errorMsg, ent =  PlayX.SpawnForPlayer(self.player, model , isRepeater ~= 0)
	if success then
		local instance = ent
		self.data.spawnedProps[ instance ] = true
		return instance
	end
	return nil
end
---------------------------------------------\\ SPAWNING FUNCTIONS //---------------------------------------------

---------------------------------------------// MEDIA DATA FUNCTIONS \\---------------------------------------------
--converts a lua table into a E2 table
--@param lua-table data
--@return e2-table
local function tableToE2Table(data)
	local e2table = {n={},ntypes={},s={},stypes={},size=0}
	local size = 0

	for k,v in pairs( data ) do
		size = size + 1
		local vtype = type(v)
		if vtype == "boolean" then
			e2table.stypes[k] = "n"
			e2table.s[k] = v and 1 or 0
		elseif vtype == "table" then
			e2table.stypes[k] = "t"
			e2table.s[k] = tableToE2Table(v)
		elseif type(k) == "number" then
			e2table.ntypes[k] = "n"
			e2table.n[k] = v
		elseif type(k) == "string" then
			e2table.ntypes[k] = "s"
			e2table.n[k] = v
		else
			ErrorNoHalt("Unknown type detected key:"..vtype.." value"..v)
		end
	end
	e2table.size = size
	return e2table
end

--Returns the data of the media currently playing
--@return e2-table
e2function table pxCurrentMedia()
	if !PlayX.CurrentMedia then return {n={},ntypes={},s={},stypes={},size=0} end
	local data = table.Copy(PlayX.CurrentMedia)
	return tableToE2Table(data)
end
---------------------------------------------\\ MEDIA DATA FUNCTIONS //---------------------------------------------


local registered_chips = {}
local mediastart = 0
local mediastop = 0

hook.Add("PlayXMetadataReceived","PlayX.TriggerE2.StartMedia",function()
//hook.Add("PlayXMediaBegun","PlayX.TriggerE2",function()
	local ents = {}
	local i = 1
	for entity,_ in pairs(registered_chips) do
		if entity:IsValid() then 
			ents[i] = entity
			i = i + 1
		end
	end

	mediastart = 1
	for _,entity in ipairs(ents) do
		entity:Execute()
	end
	mediastart = 0
end)

hook.Add("PlayXMediaEnded","PlayX.TriggerE2.StopMedia",function()
	local ents = {}
	local i = 1
	for entity,_ in pairs(registered_chips) do
		if entity:IsValid() then 
			ents[i] = entity
			i = i + 1
		end
	end

	mediastop = 1
	for _,entity in ipairs(ents) do
		entity:Execute()
	end
	mediastop = 0
end)

--Executes the e2 when a media begins to play
e2function void runOnPlayX(number active)
    if active ~= 0 then
        registered_chips[self.entity] = true
    else
		registered_chips[self.entity] = nil
    end

end

--Returns 1 if a media just started playing
--@return number
e2function number pxClk()
	return mediastart
end

--Returns 1 if a media stopped playing
--@return number
e2function number pxClkStop()
	return mediastop
end






