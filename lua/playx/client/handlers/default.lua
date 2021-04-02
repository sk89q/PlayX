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
-- Version 2.8.23 by Science on 5-26-2017 04:40 PM (-06:00 GMT)

list.Set("PlayXHandlers", "IFrame", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateIFrame(width, height, uri)
end)

list.Set("PlayXHandlers", "YoutubeNative", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateYoutubeEmbed(width, height, start, volume, uri, "youtube")
end)

list.Set("PlayXHandlers", "JW", function(width, height, start, volume, uri, handlerArgs)
     return playxlib.GenerateJWPlayer(width, height, start, volume, uri, handlerArgs)
end)

list.Set("PlayXHandlers", "JWVideo", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateJWPlayer(width, height, start, volume, uri, "video")
end)

--list.Set("PlayXHandlers", "JWYoutube", function(width, height, start, volume, uri, handlerArgs)
--    return playxlib.GenerateJWPlayer(width, height, start, volume, "http://www.youtube.com/watch?v="..uri, "youtube")
--end)

list.Set("PlayXHandlers", "JWAudio", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateJWPlayer(width, height, start, volume, uri, "mp3")
end)

list.Set("PlayXHandlers", "JWRTMP", function(width, height, start, volume, uri, handlerArgs)
     return playxlib.GenerateJWPlayer(width, height, start, volume, uri, "rtmp")
end)

list.Set("PlayXHandlers", "Flash", function(width, height, start, volume, uri, handlerArgs)
    local flashVars = handlerArgs.FlashVars and handlerArgs.FlashVars or {}
    local forcePlay = handlerArgs.ForcePlay
    local center = handlerArgs.Center
    local result = playxlib.GenerateFlashPlayer(width, height, uri, flashVars, nil, forcePlay)
    result.center = center
    return result
end)

list.Set("PlayXHandlers", "Image", function(width, height, start, volume, uri, handlerArgs)
    local result = playxlib.GenerateImageViewer(width, height, uri)
    result.center = true
    return result
end)

list.Set("PlayXHandlers", "FlashAPI", function(width, height, start, volume, uri, handlerArgs)
    local url = uri
    local js = ""
    local result = nil
    local volChangeJSF = nil
    
    if not handlerArgs.NoDimRepl then
        url = url:gsub("__width__", width)
        url = url:gsub("__height__", height)
    end
    
    if handlerArgs.VolumeMul ~= nil then
        url = url:gsub("__volume__", handlerArgs.VolumeMul * volume)
    end
    
    if handlerArgs.StartMul ~= nil then
        url = url:gsub("__start__", handlerArgs.StartMul * start)
    end
    
    if handlerArgs.JSInitFunc ~= nil then
        local code = ""
        local jsVolMul = handlerArgs.JSVolumeMul and handlerArgs.JSVolumeMul or 1
        local jsStartMul = handlerArgs.JSStartMul and handlerArgs.JSStartMul or 1
        
        if handlerArgs.JSVolumeFunc then
            code = code .. "try { player." .. handlerArgs.JSVolumeFunc .. "(" .. 
                tostring(jsVolMul * volume) .. "); } catch (e) {}"
            
            volChangeJSF = function(volume)
                return "try { player." .. handlerArgs.JSVolumeFunc .. "(" ..  tostring(jsVolMul * volume) .. "); } catch (e) {}"
            end
        end
        
        if handlerArgs.JSStartFunc then
            code = "try { "..code .. "player." .. handlerArgs.JSStartFunc .. "(" .. tostring(jsStartMul * start) .. "); } catch (e) {}"
        end

        if handlerArgs.RawInitJS ~= nil then
            code = code .. handlerArgs.RawInitJS
        end
        
        js = js .. [[
var player;
try {
	function ]] .. handlerArgs.JSInitFunc .. [[() {  
	    player = document.getElementById('player');
	]] .. code .. [[
	}
} catch (e) {}
]]
    end
    
    if handlerArgs.RawJS ~= nil then
        js = js .. handlerArgs.RawJS
    end
    
    if handlerArgs.URLIsJavaScript then -- Include a JS file instead
        result = playxlib.GenerateJSEmbed(width, height, url, js)
    else
        result = playxlib.GenerateFlashPlayer(width, height, url, nil, js)
    end
    
    if volChangeJSF then
        result.GetVolumeChangeJS = volChangeJSF
    end
    
    return result
end)
