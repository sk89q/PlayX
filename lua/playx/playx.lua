-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$
-- Version 2.8.23 by Science on 2017-05-26 04:55 PM (-06:00 UTC)


-- FCVAR_GAMEDLL makes cvar change detection work
CreateConVar("playx_jw_url", "http://ziondevelopers.github.io/playx/swf/jwplayer.flash.swf", {FCVAR_GAMEDLL})
CreateConVar("playx_host_url", "http://ziondevelopers.github.io/playx/host.html",        {FCVAR_GAMEDLL})
CreateConVar("playx_youtubehost_url", "http://ziondevelopers.github.io/playx/youtubehost.html",        {FCVAR_GAMEDLL})
CreateConVar("playx_jw_youtube", "1", {FCVAR_ARCHIVE})
CreateConVar("playx_admin_timeout", "120", {FCVAR_ARCHIVE})
CreateConVar("playx_expire", "-1", {FCVAR_ARCHIVE})
CreateConVar("playx_race_protection", "1", {FCVAR_ARCHIVE})
CreateConVar("playx_wire_input", "0", {FCVAR_ARCHIVE})
CreateConVar("playx_wire_input_delay", "2", {FCVAR_ARCHIVE})

-- Note: Not using cvar replication because this can start causing problems
-- if the server has been left online for a while.

PlayX = {}
util.AddNetworkString("PlayXBegin") -- Add to Pool
util.AddNetworkString("PlayXProvidersList") -- Add to Pool

--- Checks for Admin Mods and Flags to Allow PlayX Access
-- @return boolean
function PlayX.AccessManager(ply)
	-- Default is Deny
	local result = false
	
	-- Check if ULib is loaded
	if ULib ~= nil then
		result = ULib.ucl.query(ply, "PlayX Access")	
	end
	
	-- Check if exsto is loaded
	if exsto ~= nil then
		result = ply:IsAllowed("playxaccess")
	end
	
	-- Check if Evolve is Loaded
	if evolve ~= nil then
		result = ply:EV_HasPrivilege( "PlayX Access" )
	end
	
	if result == false then
		result = ply:IsAdmin()
	end
	
	return result
end

include("playxlib.lua")

-- Load providers
local p = file.Find("playx/providers/*.lua","LUA")
for _, file in pairs(p) do
    local status, err = pcall(function() include("playx/providers/" .. file) end)
    if not status then
        ErrorNoHalt("Failed to load provider(s) in " .. file .. ": " .. err)
    end
end

PlayX.CurrentMedia = nil
PlayX.AdminTimeoutTimerRunning = false
PlayX.LastOpenTime = 0


--- Checks if a player instance exists in the game.
-- @return Whether a player exists
function PlayX.PlayerExists()
    return table.Count(ents.FindByClass("gmod_playx")) > 0
end

--- Gets the player instance entity
-- @return Entity or nil
function PlayX.GetInstance()
    local props = ents.FindByClass("gmod_playx")
    if table.Count(props) >= 1 then
    	return props[1]
    else
    	return nil
    end
end

--- Checks whether the JW player is enabled.
-- @return Whether the JW player is enabled
function PlayX.IsUsingJW()
    return GetConVar("playx_jw_url"):GetString():Trim():gmatch("^https?://.+") and true or false
end

--- Gets the URL of the JW player.
-- @return
function PlayX.GetJWURL()
    return GetConVar("playx_jw_url"):GetString():Trim()
end

--- Returns whether the JW player supports YouTube.
-- @return
function PlayX.JWPlayerSupportsYouTube()
    return GetConVar("playx_jw_youtube"):GetBool()
end

--- Gets the URL of the host file.
-- @return
function PlayX.GetHostURL()
    return GetConVar("playx_host_url"):GetString():Trim()
end

--- Checks whether the host URL is valid.
-- @return Whether the host URL is valid
function PlayX.HasValidHost()
    return PlayX.GetHostURL():Trim():gmatch("^https?://.+") and true or false
end

--- Returns whether a player is permitted to use the player.
-- @param ply Player
-- @return
function PlayX.IsPermitted(ply)
    local result = false
    
    if game.SinglePlayer() then
        result = true
    else
	    result = PlayX.AccessManager(ply)
    end
    
    return result
end

--- Spawns the player at the location that a player is looking at. This
-- function will check whether there is already a player or not.
-- @param ply Player
-- @param model Model path
-- @param repeater Spawn repeater
-- @return Success, and error message
function PlayX.SpawnForPlayer(ply, model, repeater)
    if not repeater and PlayX.PlayerExists() then
        return false, "There is already a PlayX player somewhere on the map", nil
    end
    
    if not util.IsValidModel(model) then
        return false, "The server doesn't have the selected model", nil
    end
    
    local tr = ply.GetEyeTraceNoCursor and ply:GetEyeTraceNoCursor() or
        ply:GetEyeTrace()
        
    local cls = "gmod_playx" .. (repeater and "_repeater" or "")

	local ent = ents.Create(cls)
    ent:SetModel(model)
    
	local info = PlayXScreens[model:lower()]
    
	if not info or not info.IsProjector or 
	   not ((info.Up == 0 and info.Forward == 0) or
	        (info.Forward == 0 and info.Right == 0) or
	        (info.Right == 0 and info.Up == 0)) then
        ent:SetAngles(Angle(0, (ply:GetPos() - tr.HitPos):Angle().y, 0))
	    ent:SetPos(tr.HitPos - ent:OBBCenter() + 
	       ((ent:OBBMaxs().z - ent:OBBMins().z) + 10) * tr.HitNormal)
        ent:DropToFloor()
    else
        local ang = Angle(0, 0, 0)
        
        if info.Forward > 0 then
            ang = ang + Angle(180, 0, 180)
        elseif info.Forward < 0 then
            ang = ang + Angle(0, 0, 0)
        elseif info.Right > 0 then
            ang = ang + Angle(90, 0, 90)
        elseif info.Right < 0 then
            ang = ang + Angle(-90, 0, 90)
        elseif info.Up > 0 then
            ang = ang + Angle(-90, 0, 0)
        elseif info.Up < 0 then
            ang = ang + Angle(90, 0, 0)
        end
        
        local tryDist = math.min(ply:GetPos():Distance(tr.HitPos), 4000)
        local data = {}
        data.start = tr.HitPos + tr.HitNormal * (ent:OBBMaxs() - ent:OBBMins()):Length()
        data.endpos = tr.HitPos + tr.HitNormal * tryDist
        data.filter = player.GetAll()
        local dist = util.TraceLine(data).Fraction * tryDist - 
            (ent:OBBMaxs() - ent:OBBMins()):Length() / 2
        
        ent:SetAngles(ang + tr.HitNormal:Angle())
        ent:SetPos(tr.HitPos - ent:OBBCenter() + dist * tr.HitNormal)
    end
    
    ent:Spawn()
    ent:Activate()
    
    local phys = ent:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
        phys:Sleep()
    end
    
    if ply.AddCleanup then
        ply:AddCleanup(cls, ent)
	    
	    undo.Create("#" .. cls)
	    undo.AddEntity(ent)
	    undo.SetPlayer(ply)
	    undo.Finish()
    end
    
    return true, "" , ent
end

--- Resolves a provider.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @return Provider name (detected) or nil
-- @return Result or error message
function PlayX.ResolveProvider(provider, uri, useJW)
    local result = nil
    
    if provider ~= "" then -- Provider detected
        if not list.Get("PlayXProviders")[provider] then
            return nil, "Unknown provider specified"
        end
        
        local newURI = list.Get("PlayXProviders")[provider].Detect(uri)
        result = list.Get("PlayXProviders")[provider].GetPlayer(newURI and newURI or uri, useJW)
        
        if not result then
            return nil, "The provider did not recognize the media URI"
        end
    else -- Time to detect the provider
        for id, p in pairs(list.Get("PlayXProviders")) do
            local newURI = p.Detect(uri)
            
            if newURI then
                provider = id
                result = p.GetPlayer(newURI, useJW)
                break
            end
        end
        
        if not result then
            return nil, "No provider was auto-detected"
        end
    end
    
    return provider, result
end

--- Opens a media file to be played. Clients will be informed of the new
-- media. This is the typical function that you would call to play a
-- certain video.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param start Time to start the video at, in seconds
-- @param forceLowFramerate Force the client side players to play at 1 FPS
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @param ignoreLength True to not check the length of the video (for auto-close)
-- @return The result generated by a provider, or nil and the error message
function PlayX.OpenMedia(provider, uri, start, forceLowFramerate, useJW, ignoreLength)
    if not PlayX.PlayerExists() then
        return false, "There is no player spawned to play the media"
    end
    
    if start == nil then
        start = 0
    end
    
    if useJW == nil then
        useJW = true
    end
    local useJW = useJW and PlayX.IsUsingJW()
    
    if uri == "" then
        return false, "No URI provided"
    end
    
    local provider, result = PlayX.ResolveProvider(provider, uri, useJW)
    
    if provider == nil then
        return false, result    
    end
    
    local useLowFramerate = result.LowFramerate
    if forceLowFramerate then
        useLowFramerate = true
    end
    
    PlayX.BeginMedia(result.Handler, result.URI, start, result.ResumeSupported,
                     useLowFramerate, result.HandlerArgs)
    
    PlayX.UpdateMetadata({
        ["Provider"] = provider,
    })
    
    if result.MetadataFunc then
        Msg(Format("PlayX: Metadata function available via provider %s\n", provider))
        result.MetadataFunc(function(data)
            Msg(Format("PlayX: Received metadata via provider %s\n", provider)) 
            PlayX.UpdateMetadata(data)
        end, function(err)
            Msg(Format("PlayX: Metadata failed via provider %s: %s\n", provider, err))
        end)
    end
    
    return result
end

--- Stops playing.
function PlayX.CloseMedia()
    if PlayX.CurrentMedia then
        PlayX.EndMedia()
    end
end

--- Updates the current media metadata. This can be called even after the media
-- has begun playing. Calling this when there is no player spawned has
-- no effect or there is no media playing has no effect.
-- @param data Metadata structure
function PlayX.UpdateMetadata(data)
    if not PlayX.PlayerExists() or not PlayX.CurrentMedia then
        return
    end
    
    table.Merge(PlayX.CurrentMedia, data)
    PlayX:GetInstance():SetWireMetadata(PlayX.CurrentMedia)
    
    hook.Call("PlayXMetadataReceived", nil, {PlayX.CurrentMedia, data})
    
    -- Now handle the length
    if data.Length then
	    if GetConVar("playx_expire"):GetFloat() <= -1 then
	        timer.Stop("PlayXMediaExpire")
	    else
	        local length = data.Length + GetConVar("playx_expire"):GetFloat() -- Pad length
	         
	        PlayX.CurrentMedia.StopTime = PlayX.CurrentMedia.StartTime + length
	        
	        local timeLeft = PlayX.CurrentMedia.StopTime - PlayX.CurrentMedia.StartTime
	        
	        print("PlayX: Length of current media set to " .. tostring(length) ..
	              " (grace 10 seconds), time left: " .. tostring(timeLeft) .. " seconds")
	        
	        if timeLeft > 0 then
	            timer.Adjust("PlayXMediaExpire", timeLeft, 1)
	            timer.Start("PlayXMediaExpire")
	        else -- Looks like it ended already!
	            print("PlayX: Media has already expired")
	            PlayX.EndMedia()
	        end
	    end
    end
    
    -- Send off data information
    if data.Title then
        SendUserMessage("PlayXMetadata", nil, tostring(data.Title):sub(1, 200))
    end
end

--- Begins a piece of media and informs clients about it. This allows you
-- to skip the provider detection code and force a handler and URI.
-- @param handler
-- @param uri
-- @param start
-- @param resumeSupported
-- @param lowFramerate
-- @param length Length of the media in seconds, can be nil
-- @param handlerArgs Arguments for the handler, can be nil
-- @Param provider Used for wire outputs & metadata, optional
-- @Param identifier Identifies video URL/etc, used for wire outputs & metadata, optional
-- @Param title Used for wire outputs & metadata, optional
function PlayX.BeginMedia(handler, uri, start, resumeSupported, lowFramerate, handlerArgs)
    timer.Stop("PlayXMediaExpire")
    timer.Stop("PlayXAdminTimeout")
    PlayX.LastOpenTime = CurTime()
    
    print(string.format("PlayX: Beginning media %s with handler %s, start at %ss",
                        uri, handler, start))
    
    if not handlerArgs then
        handlerArgs = {}
    end
    
    PlayX.CurrentMedia = {
        ["Handler"] = handler,
        ["URI"] = uri,
        ["StartAt"] = start,
        ["StartTime"] = CurTime() - start,
        ["ResumeSupported"] = resumeSupported,
        ["LowFramerate"] = lowFramerate,
        ["StopTime"] = nil,
        ["CurrentPos"] = nil,
        ["HandlerArgs"] = handlerArgs,
        -- Filled by metadata functions
        ["Provider"] = nil,
        -- Filled by metadata functions from provider
        ["URL"] = nil,
        ["Title"] = nil,
        ["Description"] = nil,
        ["Length"] = nil,
        ["Tags"] = nil,
        ["DatePublished"] = nil,
        ["DateModified"] = nil,
        ["Submitter"] = nil,
        ["SubmitterURL"] = nil,
        ["SubmitterAvatar"] = nil,
        ["NumFaves"] = nil,
        ["NumViews"] = nil,
        ["NumComments"] = nil,
        ["RatingNorm"] = nil,
        ["NumRatings"] = nil,
        ["Thumbnail"] = nil,
        ["Width"] = nil,
        ["Height"] = nil,
        ["IsLive"] = nil,
        ["ViewerCount"] = nil,
    }
    
    hook.Call("PlayXMediaBegun", nil, {handler, uri, start, resumeSupported,
                                       lowFramerate, handlerArgs,
                                       PlayX.CurrentMedia})
    
    PlayX.SendBeginDStream()
end

--- Clears the current media information and inform clients of the change.
-- Unlike PlayX.CloseMedia(), this does not check if something is already
-- playing to begin with.
function PlayX.EndMedia()
    timer.Stop("PlayXMediaExpire")
    timer.Stop("PlayXAdminTimeout")
    
    local instance = PlayX.GetInstance()
    if instance ~= nil then
        PlayX.GetInstance():ClearWireOutputs()
    end
    
    PlayX.CurrentMedia = nil
    PlayX.AdminTimeoutTimerRunning = false
    
    hook.Call("PlayXMediaEnded", nil, {})
    
    PlayX.SendEndUMsg()
end

--- Send the PlayXBegin datastream to clients. You should not have much of
-- a reason to call this method. We're using datastreams here because
-- some providers (cough. Livestream cough.) send a little too much data.
-- @param ply Pass a player to filter the message to just that player
function PlayX.SendBeginDStream(ply)
    local filter = nil
    
    if IsValid(ply) then
        filter = ply
    else
        --filter = RecipientFilter()
        --filter:AddAllPlayers()
        
        -- PCMod is a piece of crap
        filter = player.GetHumans()
    end
    
    local strLength = string.len(PlayX.CurrentMedia.Handler) +
                      string.len(PlayX.CurrentMedia.URI)
    
    if next(PlayX.CurrentMedia.HandlerArgs) == nil and strLength <= 200 then
        umsg.Start("PlayXBegin", filter)
        umsg.String(PlayX.CurrentMedia.Handler)
        umsg.String(PlayX.CurrentMedia.URI)
        umsg.Long(CurTime() - PlayX.CurrentMedia.StartTime) -- To be safe
        umsg.Bool(PlayX.CurrentMedia.ResumeSupported)
        umsg.Bool(PlayX.CurrentMedia.LowFramerate)
        umsg.End()
    else
	    net.Start("PlayXBegin")
		net.WriteTable({
	        ["Handler"] = PlayX.CurrentMedia.Handler,
	        ["URI"] = PlayX.CurrentMedia.URI,
	        ["PlayAge"] = CurTime() - PlayX.CurrentMedia.StartTime,
	        ["ResumeSupported"] = PlayX.CurrentMedia.ResumeSupported,
	        ["LowFramerate"] = PlayX.CurrentMedia.LowFramerate,
	        ["HandlerArgs"] = PlayX.CurrentMedia.HandlerArgs,
	    })
		net.Broadcast()
	end
end

--- Send the PlayXEnd umsg to clients. You should not have much of a
-- a reason to call this method.
function PlayX.SendEndUMsg()
    local filter = RecipientFilter()
    filter:AddAllPlayers()
    
    umsg.Start("PlayXEnd", filter)
    umsg.End()
end

--- Send the PlayXEnd umsg to clients. You should not have much of a
-- a reason to call this method.
function PlayX.SendError(ply, err)
    umsg.Start("PlayXError", ply)
	umsg.String(err)
    umsg.End()
end

--- Send the PlayXSpawnDialog umsg to a client, telling the client to
-- open the spawn dialog.
-- @param ply Player to send to
-- @param forRepeater True if this is for the repeater
function PlayX.SendSpawnDialogUMsg(ply, forRepeater)
	if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        umsg.Start("PlayXSpawnDialog", ply)
        umsg.Bool(forRepeater)
        umsg.End()
    end
end

--- Send the PlayXUse umsg to clients.
function PlayX.Use(ply)
    umsg.Start("PlayXUse", ply)
    umsg.End()
end

local function JWURLCallback(cvar, old, new)
    -- Do our own cvar replication
    SendUserMessage("PlayXJWURL", nil, GetConVar("playx_jw_url"):GetString())
end

local function HostURLCallback(cvar, old, new)
    -- Do our own cvar replication
    SendUserMessage("PlayXHostURL", nil, GetConVar("playx_host_url"):GetString())
end

cvars.AddChangeCallback("playx_jw_url", JWURLCallback)
cvars.AddChangeCallback("playx_host_url", HostURLCallback)

--- Called for concmd playx_open.
local function ConCmdOpen(ply, cmd, args)
	if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    elseif not PlayX.PlayerExists() then
        PlayX.SendError(ply, "There is no player spawned! Go to the spawn menu > Entities")
    elseif not args[1] then
        ply:PrintMessage(HUD_PRINTCONSOLE, "playx_open requires a URI")
    elseif GetConVar("playx_race_protection"):GetFloat() > 0 and 
        (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
        PlayX.SendError(ply, "Another video/media selection was started too recently.")
    else
        local uri = args[1]:Trim()
        local provider = playxlib.CastToString(args[2], ""):Trim()
        local start = playxlib.ParseTimeString(args[3])
        local forceLowFramerate = playxlib.CastToBool(args[4], false)
        local useJW = playxlib.CastToBool(args[5], true)
        local ignoreLength = playxlib.CastToBool(args[6], false)
        
        if start == nil then
            PlayX.SendError(ply, "The time format you entered for \"Start At\" isn't understood")
        elseif start < 0 then
            PlayX.SendError(ply, "A non-negative start time is required")
        else
            PrintMessage(HUD_PRINTCONSOLE, ply:Nick().." started a video!")
            local result, err = PlayX.OpenMedia(provider, uri, start,
                                                forceLowFramerate, useJW,
                                                ignoreLength)
            
            if not result then
                PlayX.SendError(ply, err)
            end
        end
    end
end

--- Called for concmd playx_close.
function ConCmdClose(ply, cmd, args)
	if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        PlayX.EndMedia()
    end
end

--- Called for concmd playx_spawn.
function ConCmdSpawn(ply, cmd, args)
    if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        if not args[1] or args[1]:Trim() == "" then
            PlayX.SendError(ply, "No model specified")
        else
            local model = args[1]:Trim()
            local result, err = PlayX.SpawnForPlayer(ply, model, cmd == "playx_spawn_repeater")
        
            if not result then
                PlayX.SendError(ply, err)
            end
        end
    end
end

concommand.Add("playx_open", ConCmdOpen)
concommand.Add("playx_close", ConCmdClose)
concommand.Add("playx_spawn", ConCmdSpawn)
concommand.Add("playx_spawn_repeater", ConCmdSpawn)

--- Called on game mode hook PlayerInitialSpawn.
function PlayerInitialSpawn(ply)
    SendUserMessage("PlayXJWURL", ply, GetConVar("playx_jw_url"):GetString())
    SendUserMessage("PlayXHostURL", ply, GetConVar("playx_host_url"):GetString())
    
    -- Send providers list.
    net.Start("PlayXProvidersList")
		net.WriteTable({
			["List"] = list.Get("PlayXProvidersList"),
		})
	net.Send(ply)
   
    local origMedia = PlayX.CurrentMedia
    
    -- Tell the user the playing media in three seconds
    timer.Simple(3, function()
        local media = PlayX.CurrentMedia
        if not media or not media.ResumeSupported then return end
        if media ~= origMedia then return end -- In case the media changes
        
        if media.StopTime and media.StopTime < CurTime() then
            PlayX.EndMedia()
        else
            PlayX.SendBeginDStream(ply)
		    
            -- Send off metadata information
		    if media.Title then
		        SendUserMessage("PlayXMetadata", ply,
		            tostring(media.Title):sub(1, 200))
		    end
        end
    end)
end

--- Called on game mode hook PlayerAuthed.
function PlayerAuthed(ply, steamID, uniqueID)
    if PlayX.CurrentMedia and PlayX.AdminTimeoutTimerRunning then
        if PlayX.IsPermitted(ply) then
            print("PlayX: Allowed User authed (connecting); killing timeout")
            
            timer.Stop("PlayXAdminTimeout")
            PlayX.AdminTimeoutTimerRunning = false
        end
    end
end

--- Called on game mode hook PlayerDisconnected.
function PlayerDisconnected(ply)
    if not PlayX.CurrentMedia then return end
    if PlayX.AdminTimeoutTimerRunning then return end
    
    for _, v in pairs(player.GetAll()) do
        if v ~= ply and PlayX.IsPermitted(v) then return end
    end
    
    -- No timer, no admin, no soup for you
    local timeout = GetConVar("playx_admin_timeout"):GetFloat()
    
    if timeout > 0 then
        print(string.format("PlayX: No admin on server; setting timeout for %fs", timeout))
        
        timer.Adjust("PlayXAdminTimeout", timeout, 1)
        timer.Start("PlayXAdminTimeout")
        
        PlayX.AdminTimeoutTimerRunning = true
    end
end

hook.Add("PlayerInitialSpawn", "PlayXPlayerInitialSpawn", PlayerInitialSpawn)
hook.Add("PlayerAuthed", "PlayXPlayerPlayerAuthed", PlayerAuthed)
hook.Add("PlayerDisconnected", "PlayXPlayerDisconnected", PlayerDisconnected)

timer.Adjust("PlayXMediaExpire", 1, 1, function()
    print("PlayX: Media has expired")
    hook.Call("PlayXMediaExpired", nil, {})
    PlayX.EndMedia()
end)

timer.Adjust("PlayXAdminTimeout", 1, 1, function()
    print("PlayX: No administrators have been present for an extended period of time; timing out media")
    hook.Call("PlayXAdminTimeout", nil, {})
    PlayX.EndMedia()
end)
