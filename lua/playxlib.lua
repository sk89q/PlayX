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
-- Version 2.8.23 by Science on 05-26-2017 04:45 PM (-06:00 GMT)

playxlib = {}

--- Takes a width and height and returns a boolean to indicate whether the shape
-- is optimally a square. This is used by the engine code to determine
-- whether a square screen is better than a rectangular screen for a certain
-- set of screen dimensions.
-- @param Width
-- @param Height
-- @return Boolean
function playxlib.IsSquare(width, height)
    -- Square screens with the new Webkit materials added by AzuiSleet
    -- seems to observe some serious problems
    return false
    --return math.abs(width / height - 1) < 0.2
end

--- Encodes a string to be placed into a JavaScript string.
-- @param str String to encode
-- @return Encoded
function playxlib.JSEscape(str)
    return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'")
        :gsub("\r", "\\r"):gsub("\n", "\\n")
end

--- Percent encodes a value for URLs.
-- @param s String
-- @return Encoded
function playxlib.URLEscape(s)
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

--- Percent encodes a table for the query part of a URL.
-- @param vars Table of keys and values
-- @return Encoded string
function playxlib.URLEscapeTable(vars)
    local str = ""
    
    for k, v in pairs(vars) do
        str = str .. playxlib.URLEscape(k) .. "=" .. playxlib.URLEscape(v) .. "&"
    end
    
    return str:sub(1, -2)
end

--- HTML encodes a string.
-- @param str
-- @return Encoded string
function playxlib.HTMLEscape(str)
    return str:gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub("\"", "&quot;")
end

--- Unescape HTML. This function fudges the job, and it does not handle all of
-- HTML's named entities.
-- @param s The string
-- @return Unescaped string
function playxlib.HTMLUnescape(s)
    if not s then return nil end
    
    s = s:gsub("<br */?>", "\n")
    s = s:gsub("&#([0-9]+);", function(m) return string.char(tonumber(m)) end)
    s = s:gsub("&#x(%x+);", function(m) return string.char(tonumber(m, 16)) end)
    s = s:gsub("&lt;", "<")
    s = s:gsub("&gt;", ">")
    s = s:gsub("&quot;", "\"")
    s = s:gsub("&amp;", "&")
    s = s:gsub("<[^<]+>", "")
    
    return s
end

--- URL unescapes a string. Doesn't handle %####
-- @param str String
-- @return Unescaped string
function playxlib.URLUnescape(str)
    -- Probably should de-anonymize this...
    return str:gsub("%%([A-Fa-f0-9][A-Fa-f0-9])", function(m)
        local n = tonumber(m, 16)
        if not n then return "" end -- Not technically required
        return string.char(n)
    end)
end

--- Parses a query.
-- @param str String to parse
-- @return Table with keys and values
function playxlib.ParseQuery(str)
    local str = str:gsub("^%?", "")
    local parts = string.Explode("&", str)
    local out = {}
    
    for _, part in pairs(parts) do
        local key, value = part:match("^([^=]+)=([^=]+)$")
        if key then
            out[playxlib.URLUnescape(key)] = playxlib.URLUnescape(value)
        elseif part:Trim() ~= "" then
            out[playxlib.URLUnescape(part)] = ""
        end
    end
    
    return out
end

--- Attempts to match a list of patterns against a string, and returns
-- the first match, or nil if there were no matches.
-- @param str The string
-- @param patterns Table of patterns
-- @return Table of results, or bil
function playxlib.FindMatch(str, patterns)
    for _, pattern in pairs(patterns) do
        local m = {str:match(pattern)}
        if m[1] then return m end
    end
    
    return nil
end

--- Gets a timestamp in UTC.
-- @param t Time
-- @return Time
function playxlib.UTCTime(t)
	local tSecs = os.time(t)
	t = os.date("*t", tSecs)
	local tUTC = os.date("!*t", tSecs)
	tUTC.isdst = t.isdst
	local utcSecs = os.time(tUTC)
	return tSecs + os.difftime(tSecs, utcSecs)
end

--- Turns seconds into minutes and seconds.
-- @param t Time
-- @return String
function playxlib.ReadableTime(t)
    return string.format("%s:%02s", math.floor(t / 60), math.floor(t) % 60)
end

--- Gets the tags out of a string.
-- @param s
-- @param delim Delimiter
-- @return Table
function playxlib.ParseTags(s, delim)
    if not s then return nil end
    
    local final = {}
    
    local tags = string.Explode(delim, s)
    for _, tag in pairs(tags) do
        tag = tag:Trim()
        if tag ~= "" and not table.HasValue(final, tag) then
            table.insert(final, tag)
        end
    end
    
    return final
end

--- Casts a console command arg to a string.
-- @param v
-- @param default
-- @return Boolean
function playxlib.CastToString(v, default)
    if v == nil then return default end
    return tostring(v)
end

--- Casts a console command arg to a number.
-- @param v
-- @param default
-- @return Boolean
function playxlib.CastToNumber(v, default)
    v = tonumber(v)
    if v == nil then return default end
    return v
end

--- Casts a console command arg to a bool.
-- @param v
-- @param default
-- @return Boolean
function playxlib.CastToBool(v, default)
    if v == nil then return default end
    if v == "false" then return false end
    v = tonumber(v)
    if v == nil then return true end
    return v ~= 0
end

--- Parses a human-readable time string. Returns the number in seconds, or
-- nil if it cannot detect a format. Blank strings will return 0.
-- @param str
-- @return Time
function playxlib.ParseTimeString(str)
    if str == "" or str == nil then return 0 end
    
    str = str:Trim()
    
    if tonumber(str) then
        return tonumber(str)
    end
    
    str = str:gsub("t=", "")
    str = str:gsub("#", "")
    
    local m, s = str:match("^([0-9]+):([0-9]+)$")
    if m then
        return tonumber(m) * 60 + tonumber(s)
    end
    
    local m, s, ms = str:match("^([0-9]+):([0-9]+)(%.[0-9]+)$")
    if m then
        return tonumber(m) * 60 + tonumber(s) + tonumber(ms)
    end
    
    local h, m, s = str:match("^([0-9]+):([0-9]+):([0-9]+)$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
    end
    
    local h, m, s, ms = str:match("^([0-9]+):([0-9]+):([0-9]+)(%.[0-9]+)$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms)
    end
    
    local s = str:match("^([0-9]+)s$")
    if s then
        return tonumber(s)
    end
    
    local m, s = str:match("^([0-9]+)m *([0-9]+)s$")
    if m then
        return tonumber(m) * 60 + tonumber(s)
    end
    
    local m, s = str:match("^([0-9]+)m$")
    if m then
        return tonumber(m) * 60
    end
    
    local h, m, s = str:match("^([0-9]+)h *([0-9]+)m *([0-9]+)s$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
    end
    
    local h, m = str:match("^([0-9]+)h *([0-9]+)m$")
    if h then
        return tonumber(h) * 3600 + tonumber(m) * 60
    end
    
    return nil
end

--- Parses a string containing data formatted in CSV into a table.
-- Fields can be quoted with double quotations or be unquoted, and characters
-- can be escaped with a backslash. This CSV parser is very forgiving. The
-- return table has each line in a new entry, and each field is then a further
-- entry in a table. Not all the rows may have the same number of fields in
-- the returned table.
-- @param data CSV data
-- @return Table containg data
function playxlib.ParseCSV(data)
    local lines = string.Explode("\n", data:gsub("\r", ""))
    local result = {}
    
    for i, line in pairs(lines) do
        local line = line:Trim()
        
        if line ~= "" then
	        local buffer = ""
	        local escaped = false
	        local inQuote = false
	        local fields = {}
	        
	        for c = 1, #line do
	            local char = line:sub(c, c)
	            if escaped then
	                buffer = buffer .. char
	                escaped = false
	            else
	                if char == "\\" then
	                    escaped = true
	                elseif char == "\"" then
	                    inQuote = not inQuote
	                elseif char == "," then
	                    if inQuote then
	                        buffer = buffer .. char
	                    else
	                        table.insert(fields, buffer)
	                        buffer = ""
	                    end
	                else
	                    buffer = buffer .. char
	                end
	            end
	        end
	        
	        table.insert(fields, buffer)
	        table.insert(result, fields)
	   end
    end
    
    return result
end

--- Turns a table into CSV data.
-- @param data Table to convert
-- @return CSV data
function playxlib.WriteCSV(data)
    local output = ""
    
    for _, v in pairs(data) do
        local line = ""
        for _, p in pairs(v) do
            if type(p) == 'boolean' then
                line = line .. ",\"" .. (p and "true" or "false") .. "\""
            else
                line = line .. ",\"" .. tostring(p):gsub("[\"\\]", "\\%1") .. "\""
            end
        end
        
        output = output .. "\n" .. line:sub(2)
    end
    
    return output:sub(2)
end

--- Tries to interpret a string as a boolean. "true," "y," etc. are considered
-- to be true.
-- @param s String
-- @return Boolean
function playxlib.IsTrue(s)
    local s = s:lower():Trim()
    return s == "t" or s == "true" or s == "1" or s == "y" or s == "yes"
end

function playxlib.EmptyToNil(s)
    if s == "" then return nil end
    return s
end

--- Converts a decimal Volume to a Float Volume
-- @param volume String
-- @return number
function playxlib.volumeFloat(volume)
	if(volume == 100) then
		volume = 1
    elseif(volume >= 10) then
    	volume = tonumber("0."..volume)
    elseif(volume <= 9) then
    	volume = tonumber("0.0"..volume)
    end   
    return volume
end

-- Handler result
local HandlerResult = {}
playxlib.HandlerResult = HandlerResult

-- Make callable
local mt = {}
mt.__call = function(...)
    return HandlerResult.new(...)
end
setmetatable(HandlerResult, mt)

function HandlerResult:new(t, js, body, jsURL, center, url)
    local css, volumeFunc, playFunc, pauseFunc
    
    if type(t) == 'table' then
        css = t.css
        js = t.js
        body = t.body
        jsURL = t.jsURL
        center = t.center
        url = t.url
        volumeFunc = t.volumeFunc and t.volumeFunc or nil
        playFunc = t.playFunc and t.playFunc or nil
        pauseFunc = t.pauseFunc and t.pauseFunc or nil
    else
        css = t
    end
    
    css = playxlib.EmptyToNil(css)
    js = playxlib.EmptyToNil(js)
    jsURL = playxlib.EmptyToNil(jsURL)
    url = playxlib.EmptyToNil(url)
    
    local instance = {
        CSS = css,
        Body = body,
        JS = js,
        JSInclude = jsURL,
        Center = center,
        ForceURL = url
    }
    
    if volumeFunc ~= nil then
        instance.GetVolumeChangeJS = volumeFunc
    end
    
    if playFunc ~= nil then
        instance.GetPlayJS = playFunc
    end
    
    if pauseFunc ~= nil then
        instance.GetPauseJS = pauseFunc
    end
	    
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function HandlerResult:GetVolumeChangeJS(volume)
    return nil
end

function HandlerResult:GetPlayJS()
    return nil
end

function HandlerResult:GetPauseJS()
    return nil
end

function HandlerResult:AppendJavaScript(js)
    self.JS = (self.JS and self.JS or "") .. js
end

function HandlerResult:GetHTML()
    return [[
<!DOCTYPE html>
<html>
<head>
<title>PlayX</title>
<style type="text/css">
]] .. self.CSS .. [[
</style>
<script type="text/javascript">
]] .. (self.JS and self.JS or "") .. [[
</script>
</head>
<body>
]] .. self.Body .. [[
</body>
</html>
]]
end

--- Generates the HTML for an IFrame.
-- @param width
-- @param height
-- @param url
-- @return HTML
function playxlib.GenerateIFrame(width, height, url)
    return playxlib.HandlerResult(nil, nil, nil, nil, false, url)
end

--- Generates the HTML for an image viewer. The image viewer will automatiaclly
-- center the image (once size information becomes exposed in JavaScript).
-- @param width
-- @param height
-- @param url
-- @return HTML
function playxlib.GenerateImageViewer(width, height, url)
    local url = playxlib.HTMLEscape(url)
    
    -- CSS to center the image
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}
td {
  text-align: center;
  vertical-align: middle;
}
]]
    
    -- Resizing code
    local js = [[
var keepResizing = true;
function resize(obj) {
  var ratio = obj.width / obj.height;
  if (]] .. width .. [[ / ]] .. height .. [[ > ratio) {
    obj.style.width = (]] .. height .. [[ * ratio) + "px";
  } else {
    obj.style.height = (]] .. width .. [[ / ratio) + "px";
  }
}
setInterval(function() {
  if (keepResizing && document.images[0]) {
    resize(document.images[0]);
  }
}, 1000);
]]
    
    local body = [[
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
<table border="0" cellpadding="0" cellmargin="0" style="width: ]] .. width .. [[px; height: ]] .. height .. [[px">
<tr>
<td style="text-align: center">
<img src="]] .. url .. [[" alt="" onload="resize(this); keepResizing = false" style="margin: auto" />
</td>
</tr>
</table>
</div>
]]
    
    return playxlib.HandlerResult(css, js, body)
end

--- Generates the HTML for a Flash player viewer.
-- @param width
-- @param height
-- @param url
-- @param flashVars Table
-- @param js Extra JavaScript to add
-- @param forcePlay Forces the movie to be 'played' every 1 second, if not playing
-- @return HTML
function playxlib.GenerateFlashPlayer(width, height, url, flashVars, js, forcePlay)
    local extraParams = ""
    local url = playxlib.HTMLEscape(url)
    local flashVars = flashVars and playxlib.URLEscapeTable(flashVars) or ""
    
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}]]
    
    if forcePlay then        
        js = (js and js or "") .. [[
setInterval(function() {
  try {
    var player = document.getElementById('player');
    if (player && !player.IsPlaying()) {
      player.play();
    }
  } catch (e) {}
}, 1000);
]]
        extraParams = [[
<param name="loop" value="false">
]]
    end
    
    local body = [[
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
<object
  type="application/x-shockwave-flash"
  src="]] .. url .. [["
  width="100%" height="100%" id="player">
  <param name="movie" value="]] .. url .. [[">
  <param name="quality" value="high">
  <param name="allowscriptaccess" value="always">
  <param name="allownetworking" value="all">
  <param name="allowfullscreen" value="false">
  <param name="FlashVars" value="]] .. flashVars .. [[">
]] .. extraParams .. [[
<div style="background: red; color: white; font: 20pt Arial, sans-serif; padding: 10px">
    Adobe Flash Player <strong style="text-decoration: underline">for other browsers</strong>
    is not installed. Please visit http://get.adobe.com/flashplayer/otherversions/
    and select "Other Browsers." Garry's Mod must be restarted after installing.
</div>
</object> 
</div>
]]
    
    local result = playxlib.HandlerResult(css, js, body)
    if forcePlay then result.ForceIE = true end
    return result
end

function playxlib.url(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str    
end

--- Generates the HTML for the Youtube Native Embed
-- @param width
-- @param height
-- @param url
-- @return HTML
function playxlib.GenerateYoutubeEmbed(width, height, start, volume, uri, provider)
    local volumeFunc = function(volume)
        return [[player.setVolume(]] .. tostring(volume) .. [[)]]
    end
    local playFunc = function()
        return [[player.playVideo()]]
    end
    
    local pauseFunc = function()
        return [[player.pauseVideo()]]
    end
	
    return playxlib.HandlerResult{
        url = uri .. "&start=" .. start,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc
    }
    --return playxlib.HandlerResult(nil, nil, nil, nil, false, uri)
end


--- Generate the HTML page for the JW player.
-- @param width
-- @param height
-- @param start In seconds
-- @param volume 0-100
-- @param uri
-- @param provider JW player provider ("image", "audio", etc.)
-- @return HTML
function playxlib.GenerateJWPlayer(width, height, start, volume, uri, provider)
    
    local volumeFunc = function(volume)
        return [[try { jwplayer().setVolume(]] .. tostring(volume) .. [[);} catch (e) {}]]
    end
    
    local playFunc = function()
        return [[try {jwplayer().play();} catch (e) {}]]
    end
    
    local pauseFunc = function()
        return [[try { jwplayer().pause(); } catch (e) {}]]
    end
	
    return playxlib.HandlerResult{
        url = PlayX.HostURL .. '?url=' .. playxlib.url(uri),
        center = false,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc,
        js = [[  
var knownState = "";

function sendPlayerData(data) {
    var str = "";
    for (var key in data) {
        str += encodeURIComponent(key) + "=" + encodeURIComponent(data[key]) + "&"
    }
    playx.processPlayerData(str);
}

function getStats(duration, position) {
    sendPlayerData({ State: jwplayer().getState(), Position: position, Duration: duration });
}

jwplayer().onReady(function () {
    jwplayer().onTime(getStats)
});

jwplayer().seek(]] .. tostring(start) .. [[);

]]
}
end
--
--- Generates the HTML code for an included JavaScript file.
-- @param width
-- @param height
-- @param url
-- @return HTML
function playxlib.GenerateJSEmbed(width, height, url, js)
    local url = playxlib.HTMLEscape(url)
    
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}
]]

    local body = [[
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
  <script src="]] .. url .. [[" type="text/javascript"></script>
</div>
]]
    
    return playxlib.HandlerResult(css, js, body, url)
end

--- Parse URL Query
-- @param query String
-- @return table
function playxlib.ParseURLQuery(query)
	local parsed = {}
	local pos = 0
	
	query = string.gsub(query, "&amp;", "&")
	query = string.gsub(query, "&lt;", "<")
	query = string.gsub(query, "&gt;", ">")
	
	local function ginsert(qstr)
		local first, last = string.find(qstr, "=")
		if first then
			parsed[string.sub(qstr, 0, first-1)] = string.sub(qstr, first+1)
		end
	end
	
	while true do
		local first, last = string.find(query, "&", pos)
		if first then
			ginsert(string.sub(query, pos, first-1));
			pos = last+1
		else
			ginsert(string.sub(query, pos));
			break;
		end
	end
	
	return parsed
end

--- Parse URL
-- @param url String
-- @param default String
-- @return Table
function playxlib.ParseURL(url, default)
    -- initialize default parameters
    local parsed = {}
    for i,v in _G.pairs(default or parsed) do parsed[i] = v end
    -- remove whitespace
    -- url = string.gsub(url, "%s", "")
    -- get fragment
    url = string.gsub(url, "#(.*)$", function(f)
        parsed.fragment = f
        return ""
    end)
    -- get scheme. Lower-case according to RFC 3986 section 3.1.
    url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
        function(s) parsed.scheme = string.lower(s); return "" end)
    -- get authority
    url = string.gsub(url, "^//([^/]*)", function(n)
        parsed.authority = n
        return ""
    end)
    -- get query stringing
    url = string.gsub(url, "%?(.*)", function(q)
        parsed.query = playxlib.ParseURLQuery(q)
        return ""
    end)
    -- get params
    url = string.gsub(url, "%;(.*)", function(p)
        parsed.params = p
        return ""
    end)
    -- path is whatever was left
    parsed.path = url
    local authority = parsed.authority
    if not authority then return parsed end
    authority = string.gsub(authority,"^([^@]*)@",
        function(u) parsed.userinfo = u; return "" end)
    authority = string.gsub(authority, ":([0-9]*)$",
        function(p) if p ~= "" then parsed.port = p end; return "" end)
    if authority ~= "" then parsed.host = authority end
    local userinfo = parsed.userinfo
    if not userinfo then return parsed end
    userinfo = string.gsub(userinfo, ":([^:]*)$",
        function(p) parsed.password = p; return "" end)
    parsed.user = userinfo
    return parsed
end
