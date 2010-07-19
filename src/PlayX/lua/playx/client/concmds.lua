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
    local useJW = useJW or true
    
    if hook.Call("PlayXRequestOpenMedia", GAMEMODE, provider, uri,
        start, forceLowFramerate, useJW, ignoreLength) == false then
        return
    end
    
    RunConsoleCommand("playx_open", uri, provider, start,
                      forceLowFramerate and 1 or 0, useJW and 1 or 0,
                      ignoreLength and 1 or 0)
end

--- Puts in a request to close media. A request will be sent to the server
-- for processing.
function PlayX.RequestCloseMedia()
    if hook.Call("PlayXRequestCloseMedia", GAMEMODE) == false then
        return
    end
    
    RunConsoleCommand("playx_close")
end

--- Called for concmd playx_resume.
local function ConCmdResume()
    PlayX.ResumePlay()
end

--- Called for concmd playx_hide.
local function ConCmdHide()
    PlayX.StopPlay()
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

--- Bookmark add dialog, triggered from playx_gui_bookmark.
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

--- Called for concmd playx_update_window.
local function ConCmdUpdateWindow()
    PlayX.OpenUpdateWindow()
end

concommand.Add("playx_resume", ConCmdResume)
concommand.Add("playx_hide", ConCmdHide)
concommand.Add("playx_reset_render_bounds", ConCmdResetRenderBounds)
concommand.Add("playx_gui_open", ConCmdGUIOpen)
concommand.Add("playx_gui_close", ConCmdGUIClose)
concommand.Add("playx_gui_bookmark", ConCmdGUIBookmark)
concommand.Add("playx_dump_html", ConCmdDumpHTML) -- Debug function
concommand.Add("playx_update_window", ConCmdUpdateWindow)