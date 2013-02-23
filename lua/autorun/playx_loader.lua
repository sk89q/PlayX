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
-- Version 2.7 by Nexus [BR] on 23-02-2013 03:16 AM

--Setup Loading Log Formatation
function loadingLog (text)
	--Set Max Size
	local size = 32
	--If Text Len < max size
	if(string.len(text) < size) then
		-- Format the text to be Text+Spaces*LeftSize
		text = text .. string.rep( " ", size-string.len(text) )
	else
		--If Text is too much big then cut and add ...
		text = string.Left( text, size-3 ) .. "..."
	end
	--Log Messsage
	Msg( "||  "..text.."||\n" )
end

Msg( "\n/====================================\\\n")
Msg( "||               PlayX              ||\n" )
Msg( "||----------------------------------||\n" )
loadingLog("Version 2.7")
loadingLog("Updated on 23-02-2013")
loadingLog("Last Patch by Nexus [BR]")
Msg( "\\====================================/\n\n" )