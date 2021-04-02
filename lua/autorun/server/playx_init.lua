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
-- Version 2.7.6 by Nexus [BR] on 20-03-2013 09:38 AM

-- Check if vON Library is Loaded Already
if von == nil then
	include("von.lua")
end

resource.AddWorkshop("106516163")

AddCSLuaFile("autorun/client/playx_init.lua")
AddCSLuaFile("playxlib.lua")
AddCSLuaFile("playx/client/playx.lua")
AddCSLuaFile("playx/client/bookmarks.lua")
AddCSLuaFile("playx/client/vgui/playx_browser.lua")
AddCSLuaFile("playx/client/panel.lua")

-- Add handlers
local p = file.Find("playx/client/handlers/*.lua","LUA")
for _, file in pairs(p) do
    AddCSLuaFile("playx/client/handlers/" .. file)
end

include("playx/playx.lua")