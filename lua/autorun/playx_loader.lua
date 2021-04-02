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
-- Version 2.8.25 by Dathus on 2021-03-31 06:06 PM (-03:00 GMT)

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

function debugTable( var, name )
  if not name then name = "a" end
  if "table" ~= type( var ) then
    print( name .. " = " .. tostring( var ) )
  else
    -- for tables, recurse through children
    for k,v in pairs( var ) do
      local child
      if 1 == string.find( k, "%a[%w_]*" ) then
        -- key can be accessed using dot syntax
        child = name .. '.' .. k
      else
        -- key contains special characters
        child = name .. '["' .. k .. '"]'
      end
      debugTable( v, child )
    end
  end
end

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

Msg( "\n/====================================\\\n")
Msg( "||               PlayX              ||\n" )
Msg( "||----------------------------------||\n" )
loadingLog("Version 2.8.25")
loadingLog("Updated on 2021-03-31 06:06 PM")
Msg( "\\====================================/\n\n" )
