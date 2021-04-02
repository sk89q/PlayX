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

local Flash = {}

function Flash.Detect(uri)
    return nil
end

function Flash.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "Flash",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Flash.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Flash.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "Flash", Flash)
list.Set("PlayXProvidersList", "Flash", {"Flash"})

local FlashMovie = {}

function FlashMovie.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://.+%.swf$",
        "^https?://.+%.SWF$",
    })
    
    if m then
        return m[1]
    end
end

function FlashMovie.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "Flash",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                FlashMovie.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["ForcePlay"] = true,
            },
        }
    end
end

function FlashMovie.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "FlashMovie", FlashMovie)
--list.Set("PlayXProvidersList", "FlashMovie", {"Flash movie [force play buttons]"})