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

local JustinTV = {}

function JustinTV.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://www%.justin%.tv/([a-zA-Z0-9_/]+)$",
        "^https?://justin%.tv/([a-zA-Z0-9_/]+)$",
    })
    
    if m then
        return m[1]
    end
end

function JustinTV.GetPlayer(uri, useJW)
    if uri:lower():find("^[a-zA-Z0-9_/]+$") then
        return {
            ["Handler"] = "justin.tv",
            ["URI"] = GetConVarString("playx_host_url"),
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                JustinTV.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["URL"] = uri           
            }
    }
    end
end

function JustinTV.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = "http://www.justin.tv/" .. uri,
    })
end

list.Set("PlayXProviders", "justin.tv", JustinTV)
list.Set("PlayXProvidersList", "justin.tv", {"justin.tv"})