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
-- Version 2.8.24 by Dathus on 2021-03-31 5:15 PM (-03:00 GMT)

local apiKey = "AIzaSyCLKZU-TS5J98Q-w97PLO7oqZytJnxVUHk"

local YouTube = {}

function YouTube.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^https?://youtu%.be/([A-Za-z0-9_%-]+)",
        "^https?://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^https?://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^https?://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
        "^https?://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^https?://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    })

    if m then
        return m[1]
    end
end

function YouTube.GetPlayer(uri, useJW)
    if uri:find("^[A-Za-z0-9_%-]+$") then
        --if useJW then
        --    return {
        --        ["Handler"] = "JWYoutube",
        --        ["URI"] = uri,
        --        ["ResumeSupported"] = true,
        --        ["LowFramerate"] = false,
        --        ["MetadataFunc"] = function(callback, failCallback)
        --            YouTube.QueryMetadata(uri, callback, failCallback)
        --        end,
        --    }
        --else
            --local vars = {
            --    ["autoplay"] = "1",
            --    ["rel"] = "0",
            --    ["hd"] = "0",
            --    ["showsearch"] = "0",
            --    ["showinfo"] = "0",
            --    ["enablejsapi"] = "1",
            --    ["version"] = "3",
            --    ["controls"] = "0",
            --    ["iv_load_policy"] = "3"
            --}

            --local url = (GetConVar("playx_youtubehost_url"):GetString():Trim().."?url=https://youtube.com/watch?v="..uri)

            --local url = Format("https://www.youtube.com/embed/%s?%s", uri, playxlib.URLEscapeTable(vars))

            url = GetConVarString("playx_youtubehost_url") .. "?url=https://youtube.com/watch?v=" .. uri

            return {
                ["Handler"] = "YoutubeNative",
                ["URI"] = url,
                ["ResumeSupported"] = true,
                ["LowFramerate"] = false,
                ["MetadataFunc"] = function(callback, failCallback)
                    YouTube.QueryMetadata(uri, callback, failCallback)
                end
                --["HandlerArgs"] = {
                --    ["JSInitFunc"] = "onYouTubePlayerReady",
                --    ["JSVolumeFunc"] = "setVolume",
                --    ["StartMul"] = 1,
                --},
            }
        --end
    end
end

function YouTube.QueryMetadata(uri, callback, failCallback)
    local vars = playxlib.URLEscapeTable({
        ["part"] = "snippet,statistics,contentDetails",
        ["key"] = apiKey,
        ["maxResults"] = "1",
        ["id"] = uri,
        ["client"] = game.SinglePlayer() and "SP" or ("MP:" .. GetConVar("hostname"):GetString())
    })

    local url = Format("https://www.googleapis.com/youtube/v3/videos?%s", vars)

    http.Fetch(url, function(result, size)
        if size == 0 then
            failCallback("HTTP request failed (size = 0)")
            return
        end
        local resultsTable = util.JSONToTable(result)
        
        -- Do a check to avoid error
        if resultsTable.pageInfo.resultsPerPage == 0 or resultsTable.items[1] == nil then
          PrintMessage(HUD_PRINTTALK, "The Youtube video \""..uri.."\" that you tried to play is unavailable!")
          return false
        end
        
        
        local title = resultsTable.items[1].snippet.title
        local desc = resultsTable.items[1].snippet.description
        local submitter = resultsTable.items[1].snippet.channelTitle

        local publishedDate = nil
        local y, mo, d, h, m, s = string.match(resultsTable.items[1].snippet.publishedAt, "([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)%.000Z")
        if y then
            publishedDate = playxlib.UTCTime({year=tonumber(y), month=tonumber(m),
                                           day=tonumber(d), hour=tonumber(h),
                                           min=tonumber(m), sec=tonumber(s)})
        end

        local modifiedDate = nil
        --No modifiedDate available in the v3 API, as far as I'm aware.
        local y, mo, d, h, m, s = string.match(resultsTable.items[1].snippet.publishedAt, "([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)%.000Z")
        if y then
            modifiedDate = playxlib.UTCTime({year=tonumber(y), month=tonumber(mo),
                                          day=tonumber(d), hour=tonumber(h),
                                          min=tonumber(m), sec=tonumber(s)})
        end


        --length is in ISO
        local length_raw = resultsTable.items[1].contentDetails.duration
        --Thanks Wyozi/Wiox
        local length = tonumber(length_raw:match("(%d+)S") or 0) + tonumber(length_raw:match("(%d+)M") or 0)*60 + tonumber(length_raw:match("(%d+)H") or 0)*3600
        local tags = resultsTable.items[1].snippet.tags or {}
        local thumbnail = resultsTable.items[1].snippet.thumbnails.default.url
        local comments = resultsTable.items[1].statistics.commentCount

        local faves = resultsTable.items[1].statistics.favoriteCount
        local views = resultsTable.items[1].statistics.viewCount

        local likes = resultsTable.items[1].statistics.likeCount
        local numRaters = likes + resultsTable.items[1].statistics.dislikeCount
        local rating = likes/numRaters * 5

        if length then
            callback({
                ["URL"] = "https://www.youtube.com/watch?v=" .. uri,
                ["Title"] = title,
                ["Description"] = desc,
                ["Length"] = length,
                ["Tags"] = tags,
                ["DatePublished"] = publishedDate,
                ["DateModified"] = modifiedDate,
                ["Submitter"] = submitter,
                ["SubmitterURL"] = submitter and "https://www.youtube.com/" .. submitter or nil,
                ["NumFaves"] = faves,
                ["NumViews"] = views,
                ["NumComments"] = comments,
                ["RatingNorm"] = rating,
                ["NumRatings"] = numRaters,
                ["Thumbnail"] = thumbnail,
            })
        else
            callback({
                ["URL"] = "https://www.youtube.com/watch?v=" .. uri,
            })
        end
    end)
end

list.Set("PlayXProviders", "YouTube", YouTube)
list.Set("PlayXProvidersList", "YouTube", {"YouTube"})
