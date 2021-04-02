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
-- Version 2.8.3 by Nexus [BR] on 16-12-2013 07:00 PM (-02:00 GMT)

local PANEL = {}

function PANEL:Init()
	self.Chrome = vgui.Create("PlayXHTMLControls", self);
	self.Chrome:Dock(TOP)
    self.Chrome.HomeURL = "http://www.youtube.com/"
end

function PANEL:OpeningVideo(provider, uri)
end

function PANEL:Open(provider, uri)
    MsgN("PlayXBrowser: Requested to open <" .. provider .. "> / <"  .. uri .. ">")
    PlayX.RequestOpenMedia(provider, uri, 0, false, GetConVar("playx_use_jw"):GetBool(),
                           GetConVar("playx_ignore_length"):GetBool())
    self:OpeningVideo(provider, uri)
end

function PANEL:Paint()
	if not self.Started then
		self.Started = true
		
		self.HTML = vgui.Create("PlayXHTML", self)
		self.HTML:Dock(FILL)
		self.HTML:OpenURL(self.Chrome.HomeURL)
        
		self.Chrome:SetHTML(self.HTML)
        
        local oldOpenURL = self.HTML.OpeningURL
        self.HTML.OpeningURL = function(_, url, target, postdata)
            local activity, value = url:match("^playx://([^/]+)/(.*)$")
            
            if activity and value then
                value = playxlib.URLUnescape(value)
                
                if activity == "open" then
                    self:Open("", value)
                elseif activity == "open-provider" then
                    local provider, uri = value:match("^([^/]+)/(.*)$")
                    self:Open(provider, uri)
                end
                
                return true
            end
            
            PlayX.NavigatorCapturedURL = url
            
            local value = url:match("youtube.*v=([^&]+)")
            
            if value then
				self.HTML:OpenURL(self.Chrome.HomeURL);
                self:Open("", "http://www.youtube.com/watch?v=" .. value)                
                return true
            end
            
            oldOpenURL(_, url, target, postdata)
        end
        
		self:InvalidateLayout()
		
	end
end

vgui.Register("PlayXBrowser", PANEL, "Panel")
