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
-- Version 2.7.5 by Nexus [BR] on 07-03-2013 09:02 PM

local Vimeo = {}

function Vimeo.Detect(uri, useJW)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://[A-Za-z0-9%.%-]*%.vimeo%.com/([0-9]+)",
        "^https?://vimeo%.com/([0-9]+)",
    })
    
    if m then
        return m[1]
    end
end

function Vimeo.GetPlayer(uri, useJW)
    if uri:lower():find("^[0-9]+$") then
        return {
            ["Handler"] = "Vimeo",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Vimeo.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["JSInitFunc"] = "vimeo_player_loaded",
                ["JSVolumeFunc"] = "setVolume",
                ["JSStartFunc"] = "seekTo",
            },
        }
    end
end

function Vimeo.QueryMetadata(uri, callback, failCallback)
    local url = Format("http://vimeo.com/api/v2/video/%s.xml", uri)

    http.Fetch(url, function(result, size)
        if size == 0 then
            failCallback("HTTP request failed (size = 0)")
            return
        end
        
        local title = playxlib.HTMLUnescape(string.match(result, "<title>([^<]+)</title>"))
        local desc = playxlib.HTMLUnescape(string.match(result, "<description>([^<]+)</description>"))
        
        local publishedDate = nil
        local y, mo, d, h, m, s = string.match(result, "<upload_date>([0-9]+)%-([0-9]+)%-([0-9]+) ([0-9]+):([0-9]+):([0-9]+)</upload_date>")
        if y then
            publishedDate = playxlib.UTCTime{year=tonumber(y), month=tonumber(mo),
                                          day=tonumber(d), hour=tonumber(h),
                                          min=tonumber(m), sec=tonumber(s)}
        end
        
        local thumbnail = playxlib.HTMLUnescape(string.match(result, "<thumbnail_large>([^<]+)</thumbnail_large>"))
        local submitter = playxlib.HTMLUnescape(string.match(result, "<user_name>([^<]+)</user_name>"))
        local submitterURL = playxlib.HTMLUnescape(string.match(result, "<user_url>([^<]+)</user_url>"))
        local submitterAvatar = playxlib.HTMLUnescape(string.match(result, "<user_portrait_huge>([^<]+)</user_portrait_huge>"))
        local likes = tonumber(string.match(result, "<stats_number_of_likes>([0-9]+)</stats_number_of_likes>"))
        local plays = tonumber(string.match(result, "<stats_number_of_plays>([0-9]+)</stats_number_of_plays>"))
        local comments = tonumber(string.match(result, "<stats_number_of_comments>([0-9]+)</stats_number_of_comments>"))
        local length = tonumber(string.match(result, "<duration>([0-9]+)</duration>"))
        local tags = playxlib.ParseTags(playxlib.HTMLUnescape(string.match(result, "<tags>([^<]+)</tags>")), ",")
        local width = tonumber(string.match(result, "<width>([0-9]+)</width>"))
        local height = tonumber(string.match(result, "<height>([0-9]+)</height>"))
        
        if length then
            callback({
                ["URL"] = "http://vimeo.com/" .. uri,
                ["Title"] = title,
                ["Description"] = desc,
                ["Length"] = length,
                ["Tags"] = tags,
                ["DatePublished"] = publishedDate,
                ["Submitter"] = submitter,
                ["SubmitterURL"] = submitterURL,
                ["SubmitterAvatar"] = submitterAvatar,
                ["NumFaves"] = likes,
                ["NumViews"] = plays,
                ["NumComments"] = comments,
                ["Thumbnail"] = thumbnail,
                ["Width"] = width,
                ["Height"] = height,
            })
        else
            callback({
                ["URL"] = "http://vimeo.com/" .. uri,
            })
        end
    end)
end

list.Set("PlayXProviders", "Vimeo", Vimeo)
list.Set("PlayXProvidersList", "Vimeo", {"Vimeo"})