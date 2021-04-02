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
-- Version 2.7.6 by Nexus [BR] on 20-03-2013 09:56 AM

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

--resource.AddFile("materials/vgui/entities/gmod_playx.vmt")

ENT.InputProvider = ""
ENT.InputURI = ""
ENT.InputStartAt = 0
ENT.InputDisableJW = false
ENT.InputForceLowFramerate = false

function ENT:Initialize()
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
    self.Entity:SetSolid(SOLID_VPHYSICS)
    self.Entity:DrawShadow(false)
    self.Entity:SetUseType(SIMPLE_USE)
    
    if WireAddon then
        self.Inputs = Wire_CreateInputs(self.Entity, {
            "Provider [STRING]",
            "URI [STRING]",
            "StartAt",
            "DisableJW",
            "ForceLowFramerate",
            "Open",
            "Close",
        })
        
        self.Outputs = Wire_CreateOutputs(self.Entity, {
            "InputError [STRING]",
            "Provider [STRING]",
            "Handler [STRING]",
            "URI [STRING]",
            "Start",
            "ActualStartTime",
            --"CurrentPos",
            "Length",
            "URL [STRING]",
            "Title [STRING]",
            "Description [STRING]",
            "Tags [ARRAY]",
            "DatePublished",
            "DateModified",
            "Submitter [STRING]",
            "SubmitterURL [STRING]",
            "SubmitterAvatar [STRING]",
            "Faved",
            "Views",
            "Comments",
            "NormalizedRating",
            "RatingCount",
            "Thumbnail [STRING]",
            "Width",
            "Height",
            "IsLive",
            "ViewerCount",
        })
        
        self:ClearWireOutputs()
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:SpawnFunction(ply, tr)
    PlayX.SendSpawnDialogUMsg(ply)
end

function ENT:OnRemove()
    PlayX.CloseMedia()
end

function ENT:Use( activator, caller, use_type, value )
    PlayX.Use( activator )
end

function ENT:ClearWireOutputs()
    if WireAddon then
        Wire_TriggerOutput(self.Entity, "Provider", "")
        Wire_TriggerOutput(self.Entity, "Handler", "")
        Wire_TriggerOutput(self.Entity, "URI", "")
        Wire_TriggerOutput(self.Entity, "Start", -1)
        Wire_TriggerOutput(self.Entity, "ActualStartTime", -1)
        --Wire_TriggerOutput(self.Entity, "CurrentPos", -1)
        Wire_TriggerOutput(self.Entity, "Length", -1)
        Wire_TriggerOutput(self.Entity, "URL", "")
        Wire_TriggerOutput(self.Entity, "Title", "")
        Wire_TriggerOutput(self.Entity, "Description", "")
        Wire_TriggerOutput(self.Entity, "Tags", {})
        Wire_TriggerOutput(self.Entity, "DatePublished", -1)
        Wire_TriggerOutput(self.Entity, "DateModified", -1)
        Wire_TriggerOutput(self.Entity, "Submitter", "")
        Wire_TriggerOutput(self.Entity, "SubmitterURL", "")
        Wire_TriggerOutput(self.Entity, "SubmitterAvatar", "")
        Wire_TriggerOutput(self.Entity, "Faved", -1)
        Wire_TriggerOutput(self.Entity, "Views", -1)
        Wire_TriggerOutput(self.Entity, "Comments", -1)
        Wire_TriggerOutput(self.Entity, "NormalizedRating", -1)
        Wire_TriggerOutput(self.Entity, "RatingCount", -1)
        Wire_TriggerOutput(self.Entity, "Thumbnail", "")
        Wire_TriggerOutput(self.Entity, "Width", -1)
        Wire_TriggerOutput(self.Entity, "Height", -1)
        Wire_TriggerOutput(self.Entity, "IsLive", -1)
        Wire_TriggerOutput(self.Entity, "ViewerCount", -1)
    end
end

function ENT:SetWireMetadata(data)
    if WireAddon then
        Wire_TriggerOutput(self.Entity, "Provider", data.Provider and data.Provider or "")
        Wire_TriggerOutput(self.Entity, "Handler", data.Handler)
        Wire_TriggerOutput(self.Entity, "URI", data.URI)
        Wire_TriggerOutput(self.Entity, "Start", data.StartAt)
        Wire_TriggerOutput(self.Entity, "ActualStartTime", data.StartTime + data.StartAt)
        --Wire_TriggerOutput(self.Entity, "CurrentPos", data.Position)
        Wire_TriggerOutput(self.Entity, "Length", data.Length and data.Length or -1)
        Wire_TriggerOutput(self.Entity, "URL", data.URL and data.URL or "")
        Wire_TriggerOutput(self.Entity, "Title", data.Title and data.Title or "")
        Wire_TriggerOutput(self.Entity, "Description", data.Description and data.Description or "")
        Wire_TriggerOutput(self.Entity, "Tags", data.Tags and data.Tags or {})
        Wire_TriggerOutput(self.Entity, "DatePublished", data.DatePublished and data.DatePublished or -1)
        Wire_TriggerOutput(self.Entity, "DateModified", data.DateModified and data.DateModified or -1)
        Wire_TriggerOutput(self.Entity, "Submitter", data.Submitter and data.Submitter or "")
        Wire_TriggerOutput(self.Entity, "SubmitterURL", data.SubmitterURL and data.SubmitterURL or "")
        Wire_TriggerOutput(self.Entity, "SubmitterAvatar", data.SubmitterAvatar and data.SubmitterAvatar or "")
        Wire_TriggerOutput(self.Entity, "Faved", data.NumFaves and data.NumFaves or -1)
        Wire_TriggerOutput(self.Entity, "Views", data.NumViews and data.NumViews or -1)
        Wire_TriggerOutput(self.Entity, "Comments", data.NumComments and data.NumComments or -1)
        Wire_TriggerOutput(self.Entity, "NormalizedRating", data.RatingNorm and data.RatingNorm or -1)
        Wire_TriggerOutput(self.Entity, "RatingCount", data.NumRatings and data.NumRatings or -1)
        Wire_TriggerOutput(self.Entity, "Thumbnail", data.Thumbnail and data.Thumbnail or "")
        Wire_TriggerOutput(self.Entity, "Width", data.Width and data.Width or -1)
        Wire_TriggerOutput(self.Entity, "Height", data.Height and data.Height or -1)
        Wire_TriggerOutput(self.Entity, "IsLive", data.IsLive and data.IsLive or -1)
        Wire_TriggerOutput(self.Entity, "ViewerCount", data.ViewerCount and data.ViewerCount or -1)
    end
end

function ENT:TriggerInput(iname, value)
    if iname == "Close" then
        if value > 0 then
            if not GetConVar("playx_wire_input"):GetBool() then
                Wire_TriggerOutput(self.Entity, "InputError", "Cvar playx_wire_input is not 1")
            else
                PlayX.CloseMedia()
                Wire_TriggerOutput(self.Entity, "InputError", "")
            end
        end
    elseif iname == "Open" then
        if value > 0 then
            if not GetConVar("playx_wire_input"):GetBool() then
                Wire_TriggerOutput(self.Entity, "InputError", "Cvar playx_wire_input is not 1")
            elseif GetConVar("playx_race_protection"):GetFloat() > 0 and 
                (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_race_protection"):GetFloat() then
                Wire_TriggerOutput(self.Entity, "InputError", "Race protection triggered (playx_race_protection)")
            elseif GetConVar("playx_wire_input_delay"):GetFloat() > 0 and 
                (CurTime() - PlayX.LastOpenTime) < GetConVar("playx_wire_input_delay"):GetFloat() then
                Wire_TriggerOutput(self.Entity, "InputError", 
                    "Wire input flood protection triggered (playx_wire_input_delay = " .. 
                    GetConVar("playx_wire_input_delay"):GetFloat() .. " seconds)")
            else
                local uri = self.InputURI:Trim()
                local provider = self.InputProvider:Trim()
                local start = self.InputStartAt
                local forceLowFramerate = self.InputForceLowFramerate
                local useJW = not self.InputDisableJW
                
                if uri == "" then
                    Wire_TriggerOutput(self.Entity, "InputError", "Empty URI inputted")
                elseif start == nil then
                    Wire_TriggerOutput(self.Entity, "InputError", "Time format inputted for StartAt unrecognized")
                elseif start < 0 then
                    Wire_TriggerOutput(self.Entity, "InputError", "Non-negative start time is required")
                else
                    MsgN(string.format("Video played via wire input: %s", uri))
                    print(provider, uri, start, forceLowFramerate, useJW)
                    
                    local result, err = PlayX.OpenMedia(provider, uri, start,
                                                        forceLowFramerate, useJW,
                                                        false)
                    
                    if not result then
                        Wire_TriggerOutput(self.Entity, "InputError", err)
                    else
                        Wire_TriggerOutput(self.Entity, "InputError", "")
                    end
                end
            end
        end
    elseif iname == "Provider" then
        self.InputProvider = tostring(value)
    elseif iname == "URI" then
        self.InputURI = tostring(value)
    elseif iname == "StartAt" then
        self.InputStartAt = playxlib.ParseTimeString(tostring(value))
    elseif iname == "DisableJW" then
        self.InputDisableJW = value > 0
    elseif iname == "ForceLowFramerate" then
        self.InputForceLowFramerate = value > 0
    end
end

local function PlayXEntityDuplicator(ply, model, pos, ang)
    if PlayX.PlayerExists() then
        return nil
    end
    
    if not PlayX.IsPermitted(ply) then
        return nil
    end
    
    local ent = ents.Create("gmod_playx")
    ent:SetModel(model)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    
    if ply.AddCleanup then
        ply:AddCleanup("gmod_playx", ent)
    end
    
    return ent
end

duplicator.RegisterEntityClass("gmod_playx", PlayXEntityDuplicator, "Model", "Pos", "Ang")