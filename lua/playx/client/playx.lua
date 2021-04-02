-- PlayX
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
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
-- Version 2.8.23 by Science on 26-05-2017 06:00 PM

CreateClientConVar("playx_enabled", 1, true, false)
CreateClientConVar("playx_fps", 14, true, false)
CreateClientConVar("playx_volume", 80, true, false)
CreateClientConVar("playx_provider", "", false, false)
CreateClientConVar("playx_uri", "", false, false)
CreateClientConVar("playx_start_time", "0:00", false, false)
CreateClientConVar("playx_force_low_framerate", 0, false, false)
CreateClientConVar("playx_use_jw", 1, false, false)
CreateClientConVar("playx_ignore_length", 0, false, false)
CreateClientConVar("playx_use_chrome", 1, true, false)
CreateClientConVar("playx_error_windows", 1, true, false)
CreateClientConVar("playx_video_range_enabled", 1, true, false)
CreateClientConVar("playx_video_range_hints_enabled", 1, true, false)
CreateClientConVar("playx_video_radius", 1000, true, false)
CreateClientConVar("playx_debug", 0, true, false, "Enable Error Messages From Playx In Console")

surface.CreateFont( "HUDNumber",{
	font="Trebuchet MS",
	size = 40,
	weight = 900,
	antialias = true,
	additive = false
})

surface.CreateFont( "MenuLarge",{
	font="Verdana",
	size = 16,
	weight = 600,
	antialias = true,
	additive = false
})

PlayX = {}

include("playxlib.lua")
include("playx/client/bookmarks.lua")
include("playx/client/vgui/playx_browser.lua")

-- Load handlers
local p = file.Find("playx/client/handlers/*.lua","LUA")
for _, file in pairs(p) do
    local status, err = pcall(function() include("playx/client/handlers/" .. file) end)
    if not status then
        ErrorNoHalt("Failed to load handler(s) in " .. file .. ": " .. err)
    end
end

include("playx/client/panel.lua")

PlayX.Enabled = true
PlayX.Playing = false
PlayX.CurrentMedia = nil
PlayX.SeenNotice = false
PlayX.JWPlayerURL = GetConVarString("playx_jw_url")
PlayX.HostURL = GetConVarString("playx_host_url")
PlayX.ShowRadioHUD = true
PlayX.HasChrome = chrome ~= nil and chrome.NewBrowser ~= nil
PlayX.SupportsChrome = chrome ~= nil and chrome.NewBrowser ~= nil
PlayX.Providers = {}
PlayX._NavigatorWindow = nil
PlayX.CrashDetected = file.Read("_playx_crash_detection.txt","DATA") == "BEGIN"
PlayX.VideoRangeStatus = 1
PlayX.HintDelay = 1
PlayX.Pause = 0
PlayX.StartPaused = 0
PlayX.NavigatorCapturedURL = ""

local spawnWindow = nil

--- Internal function to update the FPS of the current player instance.
local function DoFPSChange()
    hook.Call("PlayXFPSChanged", nil, {PlayX:GetPlayerFPS()})
    
    if PlayX.PlayerExists() then
        PlayX.GetInstance():SetFPS(PlayX:GetPlayerFPS())
    end
end

--- Begins play of media on the instance.
local function BeginPlay()
    DoFPSChange()
    
    PlayX.GetInstance().LowFramerateMode = PlayX.CurrentMedia.LowFramerate
    PlayX.GetInstance():Play(PlayX.CurrentMedia.Handler, PlayX.CurrentMedia.URI,
                             CurTime() - PlayX.CurrentMedia.StartTime,
                             PlayX.GetPlayerVolume(), PlayX.CurrentMedia.HandlerArgs)
    
    hook.Call("PlayXPlayBegun", nil, {PlayX.CurrentMedia.Handler, PlayX.CurrentMedia.URI,
                                      CurTime() - PlayX.CurrentMedia.StartTime,
                                      PlayX.GetPlayerVolume(), PlayX.CurrentMedia.HandlerArgs})
    
    if not PlayX.SeenNotice then
        PlayX.ShowHint("Want to stop what's playing? Go to the Q menu > Options > PlayX")
        PlayX.SeenNotice = true
    end
    
    PlayX.Playing = true
    
    PlayX.UpdatePanels()
end

--- Ends play on the instance.
local function EndPlay()
    PlayX.GetInstance():Stop()
    PlayX.Playing = false
    
    hook.Call("PlayXPlayEnded", nil, {})
    
    PlayX.UpdatePanels()
end

--- Enables the player.
local function DoEnable()
    if PlayX.Enabled then return end
    
    if PlayX.CrashDetected then
        file.Write("_playx_crash_detection.txt", "CLEAR")
        PlayX.CrashDetected = false
    end
    
    PlayX.Enabled = true
    
    hook.Call("PlayXEnabled", nil, {true})
    
    if PlayX.PlayerExists() then
        if PlayX.CurrentMedia and PlayX.CurrentMedia.ResumeSupported then
            BeginPlay()
        end
    end
end

--- Disables the player.
local function DoDisable()
    if not PlayX.Enabled then return end
    
    PlayX.Enabled = false
    
    hook.Call("PlayXEnabled", nil, {false})
    
    if PlayX.PlayerExists() then
        if PlayX.CurrentMedia and PlayX.Playing then
            EndPlay()
        end
    end
end

--- Checks whether the player is spawned.
-- @return
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

--- Checks whether the host URL is valid.
-- @return Whether the host URL is valid
function PlayX.HasValidHostURL()
    return PlayX.HostURL:Trim():gmatch("^https?://.+") and true or false
end

--- Used to get the HTML, namely for debugging purposes.
function PlayX.GetHTML()
    if PlayX.PlayerExists() and PlayX.GetInstance().Browser ~= nil then
        PlayX.GetInstance().Browser:Exec("console.getHTML(document.documentElement.outerHTML)");
    end
end

--- Enables the player.
function PlayX.Enable()
    RunConsoleCommand("playx_enabled", "1")
end

--- Disables the player.
function PlayX.Disable()
    RunConsoleCommand("playx_enabled", "0")
end

--- Gets the player FPS.
-- @return
function PlayX.GetPlayerFPS()
    return math.Clamp(GetConVar("playx_fps"):GetInt(), 1, 30)
end

--- Sets the player FPS
-- @param fps
function PlayX.SetPlayerFPS(fps)
    RunConsoleCommand("playx_fps", fps)
end

--- Gets the player volume.
-- @return
function PlayX.GetPlayerVolume()
    return math.Clamp(GetConVar("playx_volume"):GetInt(), 0, 100)
end

--- Sets the player volume.
-- @return
function PlayX.SetPlayerVolume(vol)
    RunConsoleCommand("playx_volume", vol)
end

--- Checks to see if the user enabled gm_chrome. It does not check to see
-- whether it is supported, however. Use PlayX.SupportsChrome for that.
-- @return
function PlayX.ChromeEnabled()
    return GetConVar("playx_use_chrome"):GetBool()
end

--- Resume playing if it is not already playing. Error messages will 
-- be printed to console. 
function PlayX.ResumePlay()
    if not PlayX.PlayerExists() then
        Msg("There is no PlayX player spawned!\n")
    elseif not PlayX.CurrentMedia then
        Msg("No media is queued to play!\n")
    elseif not PlayX.CurrentMedia.ResumeSupported then
        Msg("The current media cannot be resumed.\n")
    elseif PlayX.Enabled then
        BeginPlay()
    end
end

--- Hides the player and stops it. Error messages will be printed to
-- console. 
function PlayX.HidePlayer()
    if not PlayX.PlayerExists() then
        Msg("There is no PlayX player spawned!\n")
    elseif not PlayX.CurrentMedia then
        Msg("No media is queued to play!\n")
    elseif PlayX.Enabled then
        EndPlay()
    end
end

--- Reset the render bounds of the project screen. Error messages will be
-- printed to console.
function PlayX.ResetRenderBounds()
    if not PlayX.PlayerExists() then
        Msg("There is no PlayX player spawned!\n")
    elseif not PlayX.GetInstance().IsProjector then
        Msg("The player is not a projector.\n")
    else
        PlayX.GetInstance():ResetRenderBounds()
    end
end

--- Puts in a request to open media. A request will be sent to the
-- server for processing.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param start Time to start the video at, in seconds
-- @param forceLowFramerate Force the client side players to play at 1 FPS
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @param ignoreLength True to not check the length of the video (for auto-close)
-- @return The result generated by a provider, or nil and the error message
function PlayX.RequestOpenMedia(provider, uri, start, forceLowFramerate, useJW, ignoreLength)
    if useJW == nil then useJW = true end
    RunConsoleCommand("playx_open", uri, provider, start,
                      forceLowFramerate and 1 or 0, useJW and 1 or 0,
                      ignoreLength and 1 or 0)
end

--- Puts in a request to close media. A request will be sent to the server
-- for processing.
function PlayX.RequestCloseMedia()
    RunConsoleCommand("playx_close")
end

--- Opens the dialog for choosing a model to spawn the player with.
-- @param forRepeater
function PlayX.OpenSpawnDialog(forRepeater)
    if spawnWindow and spawnWindow:IsValid() then
        return
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetDeleteOnClose(true)
    frame:SetTitle("Select Model for PlayX " .. (forRepeater and "Repeater" or "Player"))
    frame:SetSize(275, 400)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    spawnWindow = frame
    
    local modelList = vgui.Create("DPanelList", frame)
    modelList:EnableHorizontal(true)
    modelList:SetPadding(5)
    
    for model, info in pairs(PlayXScreens) do
        if not forRepeater or not info.NoScreen then
	        local spawnIcon = vgui.Create("SpawnIcon", modelList)
	        
	        spawnIcon:SetModel(model)
	        spawnIcon.Model = model
	        spawnIcon.DoClick = function()
	            surface.PlaySound("ui/buttonclickrelease.wav")
	            RunConsoleCommand("playx_spawn" .. (forRepeater and "_repeater" or ""), spawnIcon.Model)
	            frame:Close()
	        end
	        
	        modelList:AddItem(spawnIcon)
        end
    end
    
    local cancelButton = vgui.Create("DButton", frame)
    cancelButton:SetText("Cancel")
    cancelButton:SetWide(80)
    cancelButton.DoClick = function()
        frame:Close()
    end
    
    local customModelButton = vgui.Create("DButton", frame)
    customModelButton:SetText("Custom...")
    customModelButton:SetWide(80)
    customModelButton:SetTooltip("Try PlayX's \"best attempt\" at using an arbitrary model")
    customModelButton.DoClick = function()
        Derma_StringRequest("Custom Model", "Enter a model path (i.e. models/props_lab/blastdoor001c.mdl)", "",
            function(text)
                local text = text:Trim()
                if text ~= "" then
                    RunConsoleCommand("playx_spawn" .. (forRepeater and "_repeater" or ""), text)
                    frame:Close()
                else
                    Derma_Message("You didn't enter a model path.", "Error", "OK")
                end
            end)
    end
    
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        modelList:StretchToParent(5, 25, 5, 35)
	    cancelButton:SetPos(frame:GetWide() - cancelButton:GetWide() - 5,
	                        frame:GetTall() - cancelButton:GetTall() - 5)
	    customModelButton:SetPos(frame:GetWide() - cancelButton:GetWide() - customModelButton:GetWide() - 8,
	                        frame:GetTall() - customModelButton:GetTall() - 5)
    end
    
    frame:InvalidateLayout(true, true)
end

--- Opens the navigator window.
local navWindow
function PlayX.OpenNavigatorWindow()
    if navWindow then
        navWindow:SetVisible(true)
        navWindow:MakePopup()
        navWindow:InvalidateLayout(true, true)
        return
    end
    
    local frame = vgui.Create("DFrame")
    PlayX._NavigatorWindow = frame
    frame:SetTitle("PlayX Navigator")
    frame:SetDeleteOnClose(false)
    frame:SetScreenLock(true)
    frame:SetSize(ScrW() * 0.8, ScrH() * 0.9)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    
    local browser = vgui.Create("PlayXBrowser", frame)
    
    browser.OpeningVideo = function() 
        frame:Close()
    end

    -- Layout
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        browser:StretchToParent(5, 26, 5, 5)
    end
    
    frame:InvalidateLayout(true, true)
    
    navWindow = frame
end

--- Begins media.
-- @param handler
-- @param uri
-- @param playAge
-- @param resumeSupported
-- @param lowFramerate
-- @param handlerArgs
function PlayX.BeginMedia(handler, uri, playAge, resumeSupported, lowFramerate, handlerArgs)
    if not PlayX.PlayerExists() then -- This should not happen
        ErrorNoHalt("Undefined state DS_BEGIN_NO_PLAYER; please report error")
        return
    end
    
    PlayX.Playing = true
    PlayX.CurrentMedia = nil
    
    if list.Get("PlayXHandlers")[handler] then
        if uri:len() > 325 then
            print(string.format("PlayX: Playing %s using handler %s", uri, handler))
        else
            Msg(string.format("PlayX: Playing %s using handler %s\n", uri, handler))
        end
        
        PlayX.CurrentMedia = {
            ["Handler"] = handler,
            ["URI"] = uri,
            ["StartTime"] = CurTime() - playAge,
            ["ResumeSupported"] = resumeSupported,
            ["LowFramerate"] = lowFramerate,
            ["HandlerArgs"] = handlerArgs,
        }
		
		-- Disable PlayX!
		if PlayX.CrashDetected and PlayX.Enabled then
		    PlayX.TriggerCrashProtection()
		    
            -- Panels will be updated because the enabled cvar was changed
		elseif PlayX.Enabled then
            BeginPlay()
        else
            -- This matters for the admin, as the "End Media"
            -- button needs to be updated
            PlayX.UpdatePanels()
            
            if resumeSupported then
                LocalPlayer():ChatPrint(
                    "PlayX: A video or something just started playing! Enable " ..
                    "the player to see it."
                ) 
            else
                LocalPlayer():ChatPrint(
                    "PlayX: A video or something just started playing! Enable " ..
                    "the player to see the next thing that gets played."
                ) 
            end
        end
    else
        Msg(string.format("PlayX: No such handler named %s, can't play %s\n", handler, uri))
    end
end

--- Starts the window of crash detection. Called right when something is being
-- played by the entity.
function PlayX.CrashDetectionBegin()
    file.Write("_playx_crash_detection.txt", "BEGIN")
    
    timer.Destroy("PlayXCrashDetection")
    timer.Create("PlayXCrashDetection", 8, 1, PlayX.CrashDetectionEnd)
end

--- Ends the window of crash detection. Called by the entity after it has been
-- stopped or after a timeout after something had started playing.
function PlayX.CrashDetectionEnd()
    timer.Destroy("PlayXCrashDetection")
    file.Write("_playx_crash_detection.txt", "OK")
end

--- Called when a crash was detected and PlayX now needs to be disabled. A
-- message to the user will be printed to the console.
function PlayX.TriggerCrashProtection()
    chat.AddText(
        Color(255, 255, 0, 255),
        "PlayX has disabled itself following a detection of a crash in a previous " ..
        "session. Re-enable PlayX via your tool menu under the \"Options\" tab."
    )
    
    RunConsoleCommand("playx_enabled", "0")
end

--- Shows a hint.
-- @param msg
function PlayX.ShowHint(msg)
    if GAMEMODE and GAMEMODE.AddNotify then
	    GAMEMODE:AddNotify(msg, NOTIFY_GENERIC, 10);
	    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end
end

--- Shows an error message.
-- @param err
function PlayX.ShowError(err)
    if GetConVar("playx_error_windows"):GetBool() then
        Derma_Message(err, "Error", "OK")
        gui.EnableScreenClicker(true)
        gui.EnableScreenClicker(false)
    else
	    GAMEMODE:AddNotify("PlayX error: " .. tostring(err), NOTIFY_ERROR, 7);
	    surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end
end

--- Called on playx_enabled change.
local function EnabledCallback(cvar, old, new)
    if GetConVar("playx_enabled"):GetBool() then
        DoEnable()
    else
        DoDisable()
    end
    
    PlayX.UpdatePanels()
end

--- Called on playx_fps change.
local function FPSChangeCallback(cvar, old, new)
    DoFPSChange()
end

--- Called on playx_volume change.
local function VolumeChangeCallback(cvar, old, new)
    hook.Call("PlayXVolumeChanged", nil, {PlayX.GetPlayerVolume()})
    
    if PlayX.PlayerExists() and PlayX.CurrentMedia then
        PlayX.GetInstance():ChangeVolume(PlayX.GetPlayerVolume())
    end
end

cvars.AddChangeCallback("playx_enabled", EnabledCallback)
cvars.AddChangeCallback("playx_fps", FPSChangeCallback)
cvars.AddChangeCallback("playx_volume", VolumeChangeCallback)

PlayX.Enabled = GetConVar("playx_enabled"):GetBool()

--- Called on PlayXBegin datastream.
local function DSBegin(len)
	local decoded = net.ReadTable()
    local handler = decoded.Handler
    local uri = decoded.URI
    local playAge = decoded.PlayAge
    local resumeSupported = decoded.ResumeSupported
    local lowFramerate = decoded.LowFramerate
    local handlerArgs = decoded.HandlerArgs
    
	PlayX.BeginMedia(handler, uri, playAge, resumeSupported, lowFramerate, handlerArgs)
end

--- Called on PlayXBegin usermessage.
local function UMsgBegin(um)
    local handler = um:ReadString()
    local uri = um:ReadString()
    local playAge = um:ReadLong()
    local resumeSupported = um:ReadBool()
    local lowFramerate = um:ReadBool()
    
	PlayX.BeginMedia(handler, uri, playAge, resumeSupported, lowFramerate, {})
end

--- Called on PlayXProvidersList user message.
local function DSProvidersList(len)
	local decoded = net.ReadTable()
    Msg("PlayX: Providers list received\n")
    
    local list = decoded.List
    
    PlayX.Providers = {}
    
    for k, v in pairs(list) do
        PlayX.Providers[k] = v[1]
    end
    
    PlayX.UpdatePanels()
end

--- Called on PlayXEnd user message.
local function UMsgEnd(um)
    PlayX.CurrentMedia = nil
    
    if PlayX.PlayerExists() and PlayX.Playing and PlayX.Enabled then
        EndPlay()
    else
        PlayX.UpdatePanels() -- To make sure
    end
end

--- Called on PlayXSpawnDialog user message.
local function UMsgSpawnDialog(um)
    PlayX.OpenSpawnDialog(um:ReadBool())
end

--- Called on PlayXJWURL user message.
local function UMsgJWURL(um)
    Msg("PlayX: JW URL set\n")
    
    PlayX.JWPlayerURL = um:ReadString()
    
    PlayX.UpdatePanels()
end

--- Called on PlayXHostURL user message.
local function UMsgHostURL(um)
    Msg("PlayX: Host URL set\n")
    
    PlayX.HostURL = um:ReadString()
    
    PlayX.UpdatePanels()
end

--- Called on PlayXError user message.
local function UMsgError(um)
    local err = um:ReadString()
    
    PlayX.ShowError(err)
end

--- Called on PlayXMetadata user message, which gets sent on standard metadata
-- information (title).
local function UMsgMetadata(um)
    Msg("PlayX: Metadata received\n")
    
    local title = um:ReadString()
    
    if PlayX.CurrentMedia then
        PlayX.CurrentMedia.Title = title
    end 
end

--- Called on PlayXUse user message.
local function UMsgUse(um)
    if not GetConVar("playx_enabled"):GetBool() then
        RunConsoleCommand("playx_enabled", "1")
    else
        RunConsoleCommand("playx_enabled", "0")
    end
end

-- Called on PlayX Video Range Check
local function PlayXRangeCheck() 
	local enabled = GetConVarNumber("playx_video_range_enabled")
    local radius = GetConVarNumber("playx_video_radius")
	local showHints = GetConVarNumber("playx_video_range_hints_enabled")
	local distance = 0
	local ent = nil
	local entities = {}
	local ply = LocalPlayer()
		
	if enabled == 1 then
		if PlayX.PlayerExists() then
			ent = PlayX.GetInstance()
		end
		
		if ply:IsValid() then   
			if ent ~= nil then
				if ent:IsValid() then					
					distance = ply:GetPos():Distance(ent:GetPos())
					if distance > radius and PlayX.VideoRangeStatus == 1 then    
						PlayX.VideoRangeStatus = 0
						
						if ent.Browser ~= nil then
							if ent.CurrentPage.GetPauseJS() == nil then
								ent.Browser:RunJavascript('document.body.innerHTML = ""')
							else
								ent.Browser:RunJavascript(ent.CurrentPage.GetPauseJS());
								PlayX.Pause = 1								
							end
							
							if showHints == 1 and PlayX.HintDelay == 0 then
								PlayX.ShowHint("PlayX: You are now out of Range from Video Player!")
								PlayX.HintDelay = 1
							end		
						end
					elseif distance < radius and PlayX.VideoRangeStatus == 0 then
						PlayX.VideoRangeStatus = 1
						
						if ent.Browser ~= nil then
							if ent.CurrentPage.GetPlayJS() == nil or PlayX.StartPaused == 1 then
								ent.Browser:RunJavascript("window.location.reload();");
								PlayX.StartPaused = 0
							else
								if PlayX.Pause == 1 then
									ent.Browser:RunJavascript(ent.CurrentPage.GetPlayJS());
									PlayX.Pause = 0
								end
							end
							if showHints == 1 and PlayX.HintDelay == 0 then
								PlayX.ShowHint("PlayX: You are now in Range of Video Player!")
								PlayX.HintDelay = 1
							end		
						end
					end
				end
			end
		end
	elseif (PlayX.VideoRangeStatus == 0 and enabled == 0) then
		if PlayX.PlayerExists() then
			ent = PlayX.GetInstance()
		end
		
		if ent.Browser ~= nil then
			ent.Browser:RunJavascript('window.location.reload()')
			PlayX.VideoRangeStatus = 1
		end
	end	
end

net.Receive("PlayXBegin", DSBegin)
net.Receive("PlayXProvidersList", DSProvidersList)
usermessage.Hook("PlayXBegin", UMsgBegin)
usermessage.Hook("PlayXEnd", UMsgEnd)
usermessage.Hook("PlayXSpawnDialog", UMsgSpawnDialog)
usermessage.Hook("PlayXJWURL", UMsgJWURL)
usermessage.Hook("PlayXHostURL", UMsgHostURL)
usermessage.Hook("PlayXError", UMsgError)
usermessage.Hook("PlayXMetadata", UMsgMetadata)
usermessage.Hook("PlayXUse", UMsgUse)

timer.Create( "hintDelay", 2, -1, function() PlayX.HintDelay = 0 end  )
timer.Create("PlayXRangeCheck", 0.500, -1, PlayXRangeCheck)

--- Called for concmd playx_resume.
local function ConCmdResume()
    PlayX.ResumePlay()
end

--- Called for concmd playx_hide.
local function ConCmdHide()
    PlayX.HidePlayer()
end

--- Called for concmd playx_reset_render_bounds.
local function ConCmdResetRenderBounds()
    PlayX.ResetRenderBounds()
end

--- Called for concmd playx_gui_open.
local function ConCmdGUIOpen()
    -- Let's handle bookmark keywords
    if GetConVar("playx_provider"):GetString() == "" then
        local bookmark = PlayX.GetBookmarkByKeyword(GetConVar("playx_uri"):GetString())
        if bookmark then
            bookmark:Play()
            return
        end
    end
    
    PlayX.NavigatorCapturedURL = ""
    
    PlayX.RequestOpenMedia(GetConVar("playx_provider"):GetString(),
                           GetConVar("playx_uri"):GetString(),
                           GetConVar("playx_start_time"):GetString(),
                           GetConVar("playx_force_low_framerate"):GetBool(),
                           GetConVar("playx_use_jw"):GetBool(),
                           GetConVar("playx_ignore_length"):GetBool())
end

--- Called for concmd playx_gui_close.
local function ConCmdGUIClose()
    PlayX.RequestCloseMedia()
end

--- Called for concmd playx_gui_bookmark.
local function ConCmdGUIBookmark()
    local provider = GetConVar("playx_provider"):GetString():Trim()
    local uri = GetConVar("playx_uri"):GetString():Trim()
    local startAt = GetConVar("playx_start_time"):GetString():Trim()
    local lowFramerate = GetConVar("playx_force_low_framerate"):GetBool()
    
    if uri == "" then
        Derma_Message("No URI is entered.", "Error", "OK")
    else
        Derma_StringRequest("Add Bookmark", "Enter a name for the bookmark", "",
            function(title)
                local title = title:Trim()
                if title ~= "" then
			        local result, err = PlayX.AddBookmark(title, provider, uri, "",
			                                              startAt, lowFramerate)
			        
			        if result then
                        Derma_Message("Bookmark added.", "Bookmark Added", "OK")
			            
			            PlayX.SaveBookmarks()
			        else
			            Derma_Message(err, "Error", "OK")
			        end
                end
            end)
    end
end

local function ConCmdGUIBookmarkNavigator()    
    if PlayX.NavigatorCapturedURL == "" then
        Derma_Message("No URI is entered.", "Error", "OK")
    else
	    Derma_StringRequest("Add Bookmark", "Enter a name for the bookmark", "",
	        function(title)
	            local title = title:Trim()
	            if title ~= "" then
			        local result, err = PlayX.AddBookmark(title, "", PlayX.NavigatorCapturedURL, "", "", false)
			        
			        if result then
	                    Derma_Message("Bookmark added.", "Bookmark Added", "OK")
			            
			            PlayX.SaveBookmarks()
			        else
			            Derma_Message(err, "Error", "OK")
			        end
	            end
	        end)
    end
end

local sourceCodeWin = nil
local function ConCmdDumpHTML()
    if sourceCodeWin then
        sourceCodeWin:SetVisible(true)
        sourceCodeWin:MakePopup()
        sourceCodeWin:InvalidateLayout(true, true)
        return
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetTitle("PlayX HTML Code Viewer")
    frame:SetDeleteOnClose(false)
    frame:SetScreenLock(true)
    frame:SetSize(ScrW() * 0.8, ScrH() * 0.9)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    
    local text = vgui.Create("DTextEntry", frame)
    text:SetMultiline(true)

    -- Layout
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        text:StretchToParent(5, 26, 5, 5)
    end
    
    frame:InvalidateLayout(true, true)
    PlayX._SourceCodeText = text
    
    sourceCodeWin = frame
    timer.Create("PlayXHTMLCodeUpdater",1 , -1, PlayX.GetHTML)
end

--- Called for concmd playx_update_window.
local function ConCmdNavigatorWindow()
    PlayX.OpenNavigatorWindow()
end

concommand.Add("playx_resume", ConCmdResume)
concommand.Add("playx_hide", ConCmdHide)
concommand.Add("playx_reset_render_bounds", ConCmdResetRenderBounds)
concommand.Add("playx_gui_open", ConCmdGUIOpen)
concommand.Add("playx_gui_close", ConCmdGUIClose)
concommand.Add("playx_navigator_addbookmark", ConCmdGUIBookmarkNavigator)
concommand.Add("playx_gui_bookmark", ConCmdGUIBookmark)
concommand.Add("playx_dump_html", ConCmdDumpHTML) -- Debug function
concommand.Add("playx_navigator_window", ConCmdNavigatorWindow)

--- Detect a crash.
local function DetectCrash()
    if PlayX.CrashDetected and PlayX.Enabled then
        PlayX.TriggerCrashProtection()
    end
end

hook.Add("InitPostEntity", "PlayXCrashDetection", DetectCrash)
