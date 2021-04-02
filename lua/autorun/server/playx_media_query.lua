-- PlayX Media Query Extension
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
-- Licensed under the GNU General Public License v2
--
-- This extension allows you to control PlayX, as well as search YouTube
-- from chat. Anyone can invoke the YouTube functions, but only those
-- permitted to do so can control PlayX.
--
-- Chat commands:
--   !yt <query> -  Search YouTube in-game for embeddable videos, and get
--      the first result (it will not play, though)
--   !ytplay [query] - Search YouTube, and play it as well, but if you do
--      not provide an argument/search query, then the last found video
--      (via !yt or so) will be played
--   !ytlisten [query] - Works just like !ytplay, except it will put videos
--      into low frame rate mode (for music-only videos)
--   !ytlast - Plays the last found video
--   !play <URI> - Plays a piece of media (provider is auto-detected)
--   !link <URI> - Alias of !play
--   !playx <URI> - Alias of !play
--
-- In addition to that, a user can also just paste a YouTube URL anywhere
-- in his or her message and the title of the video will be looked up and
-- printed to chat. It will also set the "last result" as the URL, so you
-- can then just do !ytplay, !ytliste, or !ytlast.
--
-- To install, drop this file into your lua/autorun/server folder.
--
-- $Id$
-- Version 2.8.25 by Dathus on 2021-03-31 06:06 PM (-03:00 GMT)

local lastResult = nil

local function UnHTMLEncode(s)
    -- Warning: Improper
    s = s:gsub("&lt;", "<")
    s = s:gsub("&gt;", ">")
    s = s:gsub("&quot;", "\"")
    s = s:gsub("&#34;", "'")
    s = s:gsub("&amp;", "&")
    return s
end

local function URLEncode(s)
    s = tostring(s)
    local new = ""

    for i = 1, #s do
        local c = s:sub(i, i)
        local b = c:byte()
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
            (b >= 48 and b <= 57) or
            c == "_" or c == "." or c == "~" then
            new = new .. c
        else
            new = new .. string.format("%%%X", b)
        end
    end

    return new
end

local function URLEncodeTable(vars)
    local str = ""

    for k, v in pairs(vars) do
        str = str .. URLEncode(k) .. "=" .. URLEncode(v) .. "&"
    end

    return str:sub(1, -2)
end

local function FindMatch(str, patterns)
    for _, pattern in pairs(patterns) do
        local m = {str:match(pattern)}
        if m[1] then return m end
    end

    return nil
end

local function SearchYouTube(q, successF, failureF)
    local vars = URLEncodeTable({
        ["q"] = q,
        ["orderby"] = "relevance",
        ["fields"] = "items(id,snippet(title,thumbnails(default(url))))",
        ["maxResults"] = "1",
        -- ["format"] = "5", -- We can now play embedded videos!
        ["part"] = "snippet",
        ["key"] = "AIzaSyCLKZU-TS5J98Q-w97PLO7oqZytJnxVUHk",
        ["type"] = "video"
    })
    local url = "https://www.googleapis.com/youtube/v3/search?" .. vars

    http.Fetch(url, function(result, size)
        if size > 0 then
            local searchTable = util.JSONToTable(result)

            if(searchTable.items) then
                if(searchTable.items[1]) then
                    if(searchTable.items[1].id) then
                        successF(searchTable.items[1].id.videoId,searchTable.items[1].snippet.title)
                    else
                        failureF("An error occurred while querying YouTube.")
                    end
                else
                    failureF("An error occurred while querying YouTube.")
                end
            else
                failureF("An error occurred while querying YouTube.")
            end
        else
            failureF("An error occurred while querying YouTube.")
        end
    end)
end

local function Play(ply, provider, uri, lowFramerate)
    if PlayX.IsPermitted(ply) then
        PrintMessage(HUD_PRINTCONSOLE, ply:Nick().." started a video!")
        local result, err = PlayX.OpenMedia(provider, uri, 0, lowFramerate, true, false)
        if not result then
            ply:ChatPrint("PlayX ERROR: " .. err)
        end
    else
        ply:ChatPrint("NOTE: You are not permitted to control the player")
    end
end

hook.Add("PlayerSay", "PlayXMediaQueryPlayerSay", function(ply, text, teamchat, death)
    if teamchat then return end

    text = text:TrimRight()

    local m = FindMatch(text, {
        "^[!%.](yt) (.+)",
        "^[!%.](ytplay) (.+)",
        "^[!%.](ytplay)",
        "^[!%.](ytlisten) (.+)",
        "^[!%.](ytlisten)",
        "^[!%.](ytlast)",
    })

    if m then
        if m[1] == "yt" or (m[1] == "ytplay" and m[2]) or (m[1] == "ytlisten" and m[2]) then
            local function successF(videoID, title)
                lastResult = videoID

                if m[1] ~= "yt" then -- Play
                    Play(ply, "YouTube", videoID, m[1] == "ytlisten")
                end

                for _, v in pairs(player.GetAll()) do
                    v:ChatPrint(string.format("YouTube query: Query '%s': http://www.youtube.com/watch?v=%s (%s).",
                                              m[2], videoID, title))
                end
            end

            local function failureF(msg)
                ply:ChatPrint(string.format("YouTube query: No video found for query '%s'.", q))
            end

            SearchYouTube(m[2], successF, failureF)
        elseif m[1] == "ytplay" or m[1] == "ytlisten" or m[1] == "ytlast" then -- Play last
            if lastResult then
                Play(ply, "YouTube", lastResult, m[1] == "ytlisten")
            else
                ply:ChatPrint("ERROR: No last result exists!")
            end
        end

        return nil
    end

    local m = FindMatch(text, {
        "^[!%.]play (.+)",
        "^[!%.]link (.+)",
        "^[!%.]playx (.+)",
    })

    if m then
        Play(ply, "", m[1], false)

        return nil
    end

    local m = FindMatch(text, {
        "https?://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "https?://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "https?://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
        "https?://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "https?://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    })

    if m then
        lastResult = m[1]

        local function successF(videoID, title)
            lastResult = videoID

            for _, v in pairs(player.GetAll()) do
                v:ChatPrint(string.format("YouTube video %s: \"%s\"",
                                          videoID, title))
            end
        end

        SearchYouTube(m[1], successF, function() end)

        return nil
    end

    return nil
end)
