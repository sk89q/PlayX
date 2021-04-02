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

include("shared.lua")

language.Add("gmod_playx_repeater", "PlayX Repeater")
language.Add("Undone_gmod_playx_repeater", "Undone PlayX Repeater")
language.Add("Undone_#gmod_playx_repeater", "Undone PlayX Repeater")
language.Add("Cleanup_gmod_playx_repeater", "PlayX Repeaters")
language.Add("Cleaned_gmod_playx_repeater", "Cleaned up PlayX Repeaters")

function ENT:Initialize()
    self.Entity:DrawShadow(false)
    
    self.DrawCenter = false
    self.NoScreen = false
    
    self:UpdateScreenBounds()
end

function ENT:DrawScreen(centerX, centerY)
    if IsValid(self.SourceInstance) then
        if not self.SourceInstance.NoScreen then
            self.SourceInstance:DrawScreen(centerX, centerY)
        else
        draw.SimpleText("PlayX source has no screen",
                        "HUDNumber",
                        centerX, centerY, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    else
        draw.SimpleText("PlayX source is required for repeater",
                        "HUDNumber",
                        centerX, centerY, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function ENT:Think()  
    if not IsValid(self.SourceInstance) then
        self.SourceInstance = PlayX.GetInstance()
    end
    
    if IsValid(self.SourceInstance) then
        self.DrawCenter = self.SourceInstance.DrawCenter
    end
    self:NextThink(CurTime() + 0.1)  
end  

function ENT:OnRemove() 
end  