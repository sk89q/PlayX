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
-- Version 2.7.9 by Nexus [BR] on 12-07-2013 02:48 PM

 -- Exsto
 -- PlayX Plugin 

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "PlayX",
	ID = "playx",
	Desc = "A plugin that allows PlayX Usage!",
	Owner = "Nexus [BR]",
	CleanUnload = true;
} )

function PLUGIN:Init()
	exsto.CreateFlag( "playxaccess", "Allows users to use PlayX." )
end

function PLUGIN:OnUnload()
	exsto.Flags["playxaccess"] = nil
end

PLUGIN:Register()