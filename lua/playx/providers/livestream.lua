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
-- Version 2.7.7 by Nexus [BR] on 09-07-2013 11:46 AM

local Livestream = {}

function Livestream.Detect(uri, useJW)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "livestream%.com/([A-Za-z0-9%.%-%_]+)"
    })
    
    if m then
        return uri
    end
end

function Livestream.GetPlayer(url, useJW)
	local m = playxlib.FindMatch(url:gsub("%?.*$", ""), {
        "livestream%.com/([A-Za-z0-9%.%-%_]+)"
    })
    
    if m then
    	uri = m[1]
    else
    	uri = ""
    end
    
	local clip = playxlib.ParseURL(url)
	local channel = playxlib.FindMatch(clip.path:gsub("%?.*$", ""), {"/([A-Za-z0-9%.%-%_]+)"}) 
	local channelID = ""
	local clipID = ""
	
	if channel[1] then
		channelID = channel[1]
	end  
	
	if clip.query ~= nil then
		if clip.query.clipId ~= "" then
			clipID = clip.query.clipId
		end
	end 
	
	if clipID ~= "" then
		url = "http://cdn.livestream.com/embed/"..channelID.."?layout=4&clip="..clipID.."&height=340&width=560&autoplay=true"
	else
		url = "http://cdn.livestream.com/embed/"..channelID.."?layout=4&height=340&width=560&autoplay=true"
	end
    
    if uri:lower():find("^[a-zA-Z0-9_]+$") then        
        return {
            ["Handler"] = "Livestream",
            ["URI"] = url,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Livestream.QueryMetadata({['channelID'] = channelID, ['clipID'] = clipID}, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["VolumeMul"] = 0.1             
            },
        }
    end
end

function Livestream.QueryMetadata(data, callback, failCallback)
	local channelID = data.channelID
	local clipID = data.clipID
	local url = ""
	local result2 = ""
	
	if clipID == "" then
    	url = Format("http://x%sx.channel-api.livestream-api.com/2.0/info", channelID:gsub("_", "-"))
    else
    	url = Format("http://x%sx.channel-api.livestream-api.com/2.0/clipdetails.xml?id=%s", channelID:gsub("_", "-"), clipID)
    end

    http.Fetch(url, function(result, size)
        if size == 0 then
            failCallback("HTTP request failed (size = 0)")
            return
        end
        
        if clipID ~= "" then
        	result2 = result:split("<item>")
        	result2 = result2[2]
        else
        	result2 = result
        end
        
        local title = playxlib.HTMLUnescape(string.match(result2, "<title>([^<]+)</title>"))
        local desc = playxlib.HTMLUnescape(string.match(result, "<description>([^<]+)</description>"))
        local isLive = string.match(result, "<ls:isLive>([^<]+)</ls:isLive>") == "true"
        local viewerCount = tonumber(string.match(result, "<ls:currentViewerCount>([^<]+)</ls:currentViewerCount>"))
        local tags = playxlib.ParseTags(playxlib.HTMLUnescape(string.match(result, "<ls:tags>([^<]+)</ls:tags>")), ",")
        local link = playxlib.HTMLUnescape(string.match(result2, "<link>([^<]+)</link>"))
        
        if title then
            callback({
                ["URL"] = link,
                ["Title"] = title,
                ["Description"] = desc,
                ["Tags"] = tags,
                ["IsLive"] = isLive,
                ["ViewerCount"] = viewerCount,
            })
        else
            callback({
                ["URL"] = "http://livestream.com/" .. uri,
            })
        end
    end)
end

list.Set("PlayXProviders", "Livestream", Livestream)
list.Set("PlayXProvidersList", "Livestream", {"Livestream"})