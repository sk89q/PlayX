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
-- Version 2.8.3 by Nexus [BR] on 16-12-2013 07:00 PM (-02:00 GMT)

include("shared.lua")

language.Add("gmod_playx", "PlayX Player")
language.Add("Undone_gmod_playx", "Undone PlayX Player")
language.Add("Undone_#gmod_playx", "Undone PlayX Player")
language.Add("Cleanup_gmod_playx", "PlayX Player")
language.Add("Cleaned_gmod_playx", "Cleaned up the PlayX Player")

surface.CreateFont( "PlayXDefaultBold", {font = "Tahoma", size = 13, weight = 1000})

function ENT:Initialize()
    self.Entity:DrawShadow(false)
    
    self.HadStarted = false
    self.CurrentPage = nil
    self.Playing = false
    self.LowFramerateMode = false
    self.DrawCenter = false
    self.NoScreen = false
    self.PlayerData = {}
	self.Forward = 1
	self.Right = 1
	self.Up = 1
    
    self:UpdateScreenBounds()
end

function ENT:UpdateScreenBounds()
    local model = self.Entity:GetModel()
    local info = PlayXScreens[model:lower()]
    
    pcall(hook.Remove, "HUDPaint", "PlayXInfo" .. self:EntIndex())
    
    if info then
        self.NoScreen = false
        
        if info.NoScreen then
            self.NoScreen = true
            self:SetProjectorBounds(0, 0, 0)
            
            hook.Add("HUDPaint", "PlayXInfo" .. self:EntIndex(), function()
                if IsValid(self) then
                    self:HUDPaint()
                end
            end)
        elseif info.IsProjector then
            self:SetProjectorBounds(info.Forward, info.Right, info.Up)
        else
            local rotateAroundRight = info.RotateAroundRight
            local rotateAroundUp = info.RotateAroundUp
            local rotateAroundForward = info.RotateAroundForward or 0
            
            -- For backwards compatibility, adapt to the new rotation system
            if type(rotateAroundRight) == 'boolean' then
                rotateAroundRight = rotateAroundRight and -90 or 0
            end
            if type(rotateAroundUp) == 'boolean' then
                rotateAroundUp = rotateAroundUp and 90 or 0
            end
            if type(rotateAroundForward) == 'boolean' then
                rotateAroundForward = rotateAroundForward and 90 or 0
            end
            
            self:SetScreenBounds(info.Offset, info.Width, info.Height,
                                 rotateAroundRight,
                                 rotateAroundUp,
                                 rotateAroundForward)
        end
    else
        local center = self.Entity:OBBCenter()
        local mins = self.Entity:OBBMins()
        local maxs = self.Entity:OBBMaxs()
        local rightArea = (maxs.z * mins.z) * (maxs.y * mins.y)
        local forwardArea = (maxs.z * mins.z) * (maxs.x * mins.x)
        local topArea = (maxs.y * mins.y) * (maxs.x * mins.x)
        local maxArea = math.max(rightArea, forwardArea, topArea)
        
        if maxArea == rightArea then
            local width = maxs.y - mins.y
            local height = maxs.z - mins.z
            local pos = Vector(center.x + (maxs.x - mins.x) / 2 + 0.5,
                               center.y - width / 2,
                               center.z + height / 2)
            self:SetScreenBounds(pos, width, height, -90, 90, 0)
        elseif maxArea == forwardArea then
            local width = maxs.x - mins.x
            local height = maxs.z - mins.z
            local pos = Vector(center.x + width / 2,
                               center.y + (maxs.y - mins.y) / 2 + 0.5,
                               center.z + height / 2)
            self:SetScreenBounds(pos, width, height, 180, 0, -90)
        else
            local width = maxs.y - mins.y
            local height = maxs.x - mins.x
            local pos = Vector(center.x + height / 2,
                               center.y + width / 2,
                               center.z + (maxs.z - mins.z) / 2 + 0.5)
            self:SetScreenBounds(pos, width, height, 0, -90, 0)
        end
    end
    
    self:ResetRenderBounds()
end

function ENT:SetScreenBounds(pos, width, height, rotateAroundRight,
                             rotateAroundUp, rotateAroundForward)
    self.IsProjector = false
    
    self.ScreenOffset = pos
    self.ScreenWidth = width
    self.ScreenHeight = height
    self.IsSquare = playxlib.IsSquare(width, height) -- Uncalibrated number!
    
    if self.IsSquare then
        self.HTMLWidth = 1024
        self.HTMLHeight = 1024
    else
        self.HTMLWidth = 1024
        self.HTMLHeight = 512
    end
    
    if width / height < self.HTMLWidth / self.HTMLHeight then
        self.DrawScale = width / self.HTMLWidth
        self.DrawWidth = self.HTMLWidth
        self.DrawHeight = height / self.DrawScale
        self.DrawShiftX = 0
        self.DrawShiftY = (self.DrawHeight - self.HTMLHeight) / 2
    else
        self.DrawScale = height / self.HTMLHeight
        self.DrawWidth = width / self.DrawScale
        self.DrawHeight = self.HTMLHeight
        self.DrawShiftX = (self.DrawWidth - self.HTMLWidth) / 2
        self.DrawShiftY = 0
    end
    
    self.RotateAroundRight = rotateAroundRight
    self.RotateAroundUp = rotateAroundUp
    self.RotateAroundForward = rotateAroundForward or 0
end

function ENT:SetProjectorBounds(forward, right, up)
    self.IsProjector = true
    
    self.Forward = forward
    self.Right = right
    self.Up = up
    
    self.HTMLWidth = 1024
    self.HTMLHeight = 512
    
    self.DrawScale = 1 -- Not used
end

function ENT:CreateBrowser()
    self.Browser = vgui.Create("PlayXHTML")
    self.Browser:SetMouseInputEnabled(false)        
    self.Browser:SetSize(self.HTMLWidth, self.HTMLHeight)
    self.Browser:SetPaintedManually(true)
    self.Browser:SetVerticalScrollbarEnabled(false)
end

function ENT:DestructBrowser()
    if self.HadStarted then
        self.HadStarted = false
        PlayX.CrashDetectionEnd()
    end
    
    if self.Browser and self.Browser:IsValid() then
        self.Browser:Remove()
    end
    
    self.Browser = nil
end

function ENT:Play(handler, uri, start, volume, handlerArgs)
    local h = list.Get("PlayXHandlers")[handler]
    local result = h(self.HTMLWidth, self.HTMLHeight, start, volume, uri, handlerArgs)
    self.DrawCenter = result.Center
    self.CurrentPage = result
    self.PlayerData = {}
    
    if not self.Browser then
        self:CreateBrowser()
    end

    self.Browser.FinishedURL = function()
		if not IsValid(self) then return end
		MsgN("PlayX: Page loaded, preparing to inject")		
        self:InjectPage()
        if (PlayX.VideoRangeStatus == 0 and GetConVarNumber("playx_video_range_enabled") == 1) or (PlayX.Pause == 1 and GetConVarNumber("playx_video_range_enabled") == 1) then
			self.Browser:RunJavascript('document.body.innerHTML = ""')
			PlayX.StartPaused = 1
			PlayX.Pause = 0
		end	
		
		-- Initial Volume Change Fix
		timer.Create("playxVolumeFix", 0.5, 5, function () if IsValid(self) then self:ChangeVolume(GetConVarNumber("playx_volume"))  end end)	
    end
    
    self.Playing = true
    
    PlayX.CrashDetectionBegin()
    self.HadStarted = true
    
    if result.ForceURL then
        self.Browser:OpenURL(result.ForceURL)
    else
        self.Browser:OpenURL(PlayX.HostURL)
    end    
end

function ENT:Stop()
	if self.Playing then
	    self:DestructBrowser()
	    self.Playing = false
	    self.PlayerData = {}
    end
end

function ENT:ChangeVolume(volume)
	local js = ""
	
    pcall(function () js = self.CurrentPage.GetVolumeChangeJS(volume) end)
    
    if js and self.Browser ~= nil then
        pcall(function () self.Browser:Exec(js) end)
        return true
    end
    
    return false
end

function ENT:SetFPS(fps)
    self.FPS = fps
end

function ENT:GetProjectorTrace()
    -- Potential GC bottleneck?
    local excludeEntities = player.GetAll()
    table.insert(excludeEntities, self.Entity)
    local dir = self.Entity:GetForward() * self.Forward * 4000 +
                self.Entity:GetRight() * self.Right * 4000 +
                self.Entity:GetUp() * self.Up * 4000
    local tr = util.QuickTrace(self.Entity:LocalToWorld(self.Entity:OBBCenter()),
                               dir, excludeEntities)
    
    return tr
end

function ENT:ResetRenderBounds()
    local tr = self:GetProjectorTrace()
        
    if tr.Hit then
        -- This makes the screen show all the time
        self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + tr.HitPos,
                               Vector(1100, 1100, 1100) + tr.HitPos)
    else
       -- This makes the screen show all the time
        self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + self:GetPos(),
                               Vector(1100, 1100, 1100) + self:GetPos())
    end
end

function ENT:Draw()
    self.Entity:DrawModel()
    
    if self.NoScreen then return end
    if not self.DrawScale then return end
    
    render.SuppressEngineLighting(true)
    
    if self.IsProjector then
        local tr = self:GetProjectorTrace()
        
        if tr.Hit then
            local ang = tr.HitNormal:Angle()
            ang:RotateAroundAxis(ang:Forward(), 90) 
            ang:RotateAroundAxis(ang:Right(), -90)
            
            local width = tr.HitPos:Distance(self.Entity:LocalToWorld(self.Entity:OBBCenter())) * 0.001
            local height = width / 2
            local pos = tr.HitPos - ang:Right() * height * self.HTMLHeight / 2
                        - ang:Forward() * width * self.HTMLWidth / 2
                        + ang:Up() * 2
            
            -- This makes the screen show all the time
            self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + tr.HitPos,
                                   Vector(1100, 1100, 1100) + tr.HitPos)
            
            cam.Start3D2D(pos, ang, width)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(0, 0, 1024, 512)
            self:DrawScreen(1024 / 2, 512 / 2)
            cam.End3D2D()
        end
    else
        local shiftMultiplier = 1
        if not self.DrawCenter then
            shiftMultiplier = 2
        end
        
        local pos = self.Entity:LocalToWorld(self.ScreenOffset - 
            Vector(0, self.DrawShiftX * self.DrawScale, self.DrawShiftY * shiftMultiplier * self.DrawScale))
        local ang = self.Entity:GetAngles()
        
        ang:RotateAroundAxis(ang:Right(), self.RotateAroundRight)
        ang:RotateAroundAxis(ang:Up(), self.RotateAroundUp)
        ang:RotateAroundAxis(ang:Forward(), self.RotateAroundForward)
        
        -- This makes the screen show all the time
        self:SetRenderBoundsWS(Vector(-1100, -1100, -1100) + self:GetPos(),
                               Vector(1100, 1100, 1100) + self:GetPos())
        
        cam.Start3D2D(pos, ang, self.DrawScale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(-self.DrawShiftX, -self.DrawShiftY * shiftMultiplier, self.DrawWidth, self.DrawHeight)
        self:DrawScreen(self.DrawWidth / 2 - self.DrawShiftX,
                        self.DrawHeight / 2 - self.DrawShiftY * shiftMultiplier)
        cam.End3D2D()
    end

    render.SuppressEngineLighting(false)
end

function ENT:DrawScreen(centerX, centerY)
    if self.Browser and self.Browser:IsValid() and self.Playing then
        if not self.LowFramerateMode then
            if not self.BrowserMat then return end
            
            render.SetMaterial(self.BrowserMat)
            -- GC issue here?
            render.DrawQuad(Vector(0, 0, 0), Vector(self.HTMLWidth, 0, 0),
                            Vector(self.HTMLWidth, self.HTMLHeight, 0),
                            Vector(0, self.HTMLHeight, 0)) 
        else
            local text = "Video started in low framerate mode."
            
            if self.PlayerData.State then
                text = self.PlayerData.State
                
                if text == "BUFFERING" then
                    text = "Buffering" .. string.rep(".", CurTime() % 3)
                elseif text == "PLAYING" then
                    text = "Playing"
                elseif text == "ERROR" then
                    text = "ERROR"
                elseif text == "COMPLETED" then
                    text = "Playback Complete."
                    self:Stop()
                elseif text == "STOPPED" then
                    text = "Stopped"
                elseif text == "PAUSED" then
                    text = "Paused"
                end
            end
            
            if PlayX.CurrentMedia.Title then
                draw.SimpleText(text,
                                "MenuLarge",
                                centerX, centerY + 20, Color(255, 255, 255, 255),
                                TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                
	            draw.SimpleText(PlayX.CurrentMedia.Title:sub(1, 50),
	                            "HUDNumber",
	                            centerX, centerY - 50, Color(255, 255, 255, 255),
	                            TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            else
	            draw.SimpleText(text,
	                            "HUDNumber",
	                            centerX, centerY, Color(255, 255, 255, 255),
	                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            if self.PlayerData.Duration or self.PlayerData.Position then
                local pct = self.PlayerData.Duration and 
                    math.Clamp(self.PlayerData.Position / self.PlayerData.Duration, 0, 1) or 0
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawOutlinedRect(centerX - 200, centerY + 5, 400, 10)
                if self.PlayerData.Position and self.PlayerData.Duration then
	                surface.SetDrawColor(255, 0, 0, 255)
	                surface.DrawRect(centerX - 199, centerY + 6, 398 * pct, 8)
                end
                
                if self.PlayerData.Position then
	                draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Position),
	                    "MenuLarge", centerX - 200, centerY + 20,
	                    Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
                
		        if self.PlayerData.Duration then
	                draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Duration),
	                    "MenuLarge", centerX + 200, centerY + 20,
	                    Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	            end
            end
        end
    else
        if PlayX.CrashDetected then
            draw.SimpleText("Disabled due to detected crash (see tool menu -> Options)",
                            "HUDNumber",
                            centerX, centerY, Color(255, 255, 0, 255),
                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif not PlayX.Enabled then
            draw.SimpleText("Re-enable the player in the tool menu -> Options",
                            "HUDNumber",
                            centerX, centerY, Color(255, 255, 255, 255),
                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function ENT:HUDPaint()
    if not self.DrawScale then return end
    if not self.NoScreen then return end
    if not self.Playing then return end
    if not PlayX.ShowRadioHUD then return end

    local text = nil
    
    if self.PlayerData.State then
        text = self.PlayerData.State
        
        if text == "BUFFERING" then
            text = "Buffering" .. string.rep(".", CurTime() % 3)
        elseif text == "PLAYING" then
            text = "Playing"
        elseif text == "ERROR" then
            text = "ERROR"
        elseif text == "COMPLETED" then
            text = "Playback Completed."
            self:Stop()
        elseif text == "STOPPED" then
            text = "Stopped"
        elseif text == "PAUSED" then
            text = "Paused"
        end
    end
    
    local hasBottomBar = text or self.PlayerData.Duration or self.PlayerData.Position
    local bw = 320
    local bh = hasBottomBar and 65 or 34
    local bx = ScrW() / 2 - bw / 2
    local by = 15
    
    draw.RoundedBox(6, bx, by, bw, bh, Color(0, 0, 0, 150))
        
    local titleText = PlayX.CurrentMedia.Title and PlayX.CurrentMedia.Title:sub(1, 50) 
        or "Title Unavailable"
    draw.SimpleText(titleText,
                    "PlayXDefaultBold",
                    ScrW() / 2, 25, Color(255, 255, 255, 255),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    
    if text then
        draw.SimpleText(text,
                        "Default",
                        ScrW() / 2, by + 60, Color(255, 255, 255, 255),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    if self.PlayerData.Duration or self.PlayerData.Position then
        local pct = self.PlayerData.Duration and 
            math.Clamp(self.PlayerData.Position / self.PlayerData.Duration, 0, 1) or 0
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawOutlinedRect(bx + 10, by + 27, bw - 20, 18)
        if self.PlayerData.Position and self.PlayerData.Duration then
	        surface.SetDrawColor(255, 0, 0, 255)
	        surface.DrawRect(bx + 11, by + 28, (bw - 22) * pct, 15)
        end
        
        if self.PlayerData.Position then
	        draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Position),
	            "PlayXDefaultBold", bx + 13, by + 43,
	            Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        
        if self.PlayerData.Duration then
	        draw.SimpleText(playxlib.ReadableTime(self.PlayerData.Duration),
	            "PlayXDefaultBold", bx + bw - 12, by + 43,
	            Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	    end
    end
end

function ENT:Think()
    if self.LowFramerateMode or self.NoScreen then
        self.BrowserMat = nil
    end
    
    if not self.Browser then
        self.BrowserMat = nil
    else
        self.Browser:UpdateHTMLTexture()
        self.BrowserMat = self.Browser:GetHTMLMaterial()  
    end  
    
    self:NextThink(CurTime() + 0.1)  
end  

function ENT:OnRemove()
    if self.HadStarted then
        self.HadStarted = false
        PlayX.CrashDetectionEnd()
    end
    
    local ent = self
    local entIndex = self:EntIndex()
    local browser = self.Browser
    
    -- Give Gmod 200ms to really delete the entity
    timer.Simple(0.2, function()
        if not IsValid(ent) then -- Entity is really gone
            if browser and browser:IsValid() then browser:Remove() end
            pcall(hook.Remove, "HUDPaint", "PlayXInfo" .. entIndex)
        end
    end)
end

function ENT:ProcessPlayerData(data)
    for k, v in pairs(data) do
        if k == "State" then
            self.PlayerData[k] = v
        elseif k == "Position" or k == "Duration" then
            self.PlayerData[k] = tonumber(v)
        end
    end
end

function ENT:InjectPage()
    if not self.Browser or not self.Browser:IsValid() or not self.CurrentPage then
        return
    end
    
    if self.CurrentPage.ForceURL then
        self.Browser:Exec([[
document.body.style.overflow = 'hidden';
]])
    end
    
    if self.CurrentPage.JS then
        self.Browser:Exec(self.CurrentPage.JS)
    end
    
    if self.CurrentPage.JSInclude then
        self.Browser:Exec([[
var script = document.createElement('script');
script.type = 'text/javascript';
script.src = ']] .. playxlib.JSEscape(self.CurrentPage.JSInclude) .. [[';
document.body.appendChild(script);
]])
    elseif self.CurrentPage.Body then
        self.Browser:Exec([[
document.body.innerHTML = ']] .. playxlib.JSEscape(self.CurrentPage.Body) .. [[';
]])
    end
    
    if not self.CurrentPage.ForceURL then
        self.Browser:Exec([[
document.body.style.margin = '0';
document.body.style.padding = '0';
document.body.style.border = '0';
document.body.style.background = '#000000';
document.body.style.overflow = 'hidden';
]])
    end

    if self.CurrentPage.CSS then
        self.Browser:Exec([[
var style = document.createElement('style');
style.type = 'text/css';
style.styleSheet.cssText = ']] .. playxlib.JSEscape(self.CurrentPage.CSS) .. [[';
document.getElementsByTagName('head')[0].appendChild(style);
]])
    end
    
    if not self.CurrentPage.ForceURL and (self.LowFramerateMode or self.NoScreen) then
        self.Browser:Exec([[
var elements = document.getElementsByTagName('*');
for (var i = 0; i < elements.length; i++) {
    elements[i].style.position = 'absolute';
    elements[i].style.top = '-5000px';
    elements[i].style.left = '-5000px';
    elements[i].style.width = '1px';
    elements[i].style.height = '1px';
}
var blocker = document.createElement("div")
with (blocker.style) {
    position = 'fixed';
    top = '0';
    left = '0';
    width = '5000px;'
    height = '5000px';
    zIndex = 9999;
    background = 'black';
}
document.body.appendChild(blocker); 
]])
    end
end
