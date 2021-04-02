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

local StaticWeb = {}

function StaticWeb.Detect(uri)    
    return nil
end

function StaticWeb.GetPlayer(uri, useJW)
    if uri:find("^https?://") then
        return {
            ["Handler"] = "IFrame",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                StaticWeb.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function StaticWeb.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "StaticWeb", StaticWeb)
list.Set("PlayXProvidersList", "StaticWeb", {"Non-browsable Webpage"})