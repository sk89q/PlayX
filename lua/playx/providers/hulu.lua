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

local Hulu = {}

function Hulu.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^https?://www.hulu.com/watch/[0-9]+$",
    })
    
    if m then
        return uri
    end
end

function Hulu.GetPlayer(uri, useJW)
    local m = playxlib.FindMatch(uri, {
        "^https?://www.hulu.com/watch/[0-9]+$",
    })
    
    if m then
        return {
            ["Handler"] = "Hulu",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Hulu.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Hulu.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "Hulu", Hulu)
list.Set("PlayXProvidersList", "Hulu", {"Hulu"})