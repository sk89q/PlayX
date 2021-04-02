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

ENT.Type = "anim"
ENT.Base = "base_anim"
 
ENT.PrintName = "PlayX Player"
ENT.Author = "sk89q"
ENT.Contact = "http://www.sk89q.com"
ENT.Purpose = "Internet media player"
ENT.Instructions = "Spawn one, and then use the spawn menu."
ENT.Category = "PlayX"

ENT.WireDebugName = "PlayX Player"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

-- Model names MUST be lowercase
PlayXScreens = {
    ["models/props/cs_assault/billboard.mdl"] = {
        ["Offset"] = Vector(1, -110.5, 57.5),
        ["Width"] = 221,
        ["Height"] = 115,
        ["RotateAroundRight"] = true,
        ["RotateAroundUp"] = true,
    },
    ["models/props/cs_office/tv_plasma.mdl"] = {
        ["Offset"] = Vector(6.2, -28, 36),
        ["Width"] = 56,
        ["Height"] = 33.5,    
        ["RotateAroundRight"] = true,
        ["RotateAroundUp"] = true,
    },
    ["models/props/cs_office/computer_monitor.mdl"] = {
        ["Offset"] = Vector(3.3, -10.5, 24.55),
        ["Width"] = 21,
        ["Height"] = 15.65,    
        ["RotateAroundRight"] = true,
        ["RotateAroundUp"] = true,
    },
    ["models/props_wasteland/controlroom_monitor001b.mdl"] = {
        ["Offset"] = Vector(15, -10.5, 1.4),
        ["Width"] = 22,
        ["Height"] = 18,    
        ["RotateAroundRight"] = -103,
        ["RotateAroundUp"] = true,
    },
    ["models/props_lab/monitor02.mdl"] = {
        ["Offset"] = Vector(10.8, -9, 22.5),
        ["Width"] = 17.5,
        ["Height"] = 14,    
        ["RotateAroundRight"] = -83,
        ["RotateAroundUp"] = true,
    },
    ["models/props_c17/tv_monitor01.mdl"] = {
        ["Offset"] = Vector(6, -9, 6),
        ["Width"] = 14.5,
        ["Height"] = 10.5,    
        ["RotateAroundRight"] = -90,
        ["RotateAroundUp"] = true,
    },
    ["models/props_lab/monitor01a.mdl"] = {
        ["Offset"] = Vector(12.2, -9, 11.3),
        ["Width"] = 18,
        ["Height"] = 15,    
        ["RotateAroundRight"] = -85,
        ["RotateAroundUp"] = true,
    },
    ["models/props/cs_office/projector.mdl"] = {
        ["IsProjector"] = true,
        ["Forward"] = 0,
        ["Right"] = 1,    
        ["Up"] = 0,
    },
    ["models/dav0r/camera.mdl"] = {
        ["IsProjector"] = true,
        ["Forward"] = 1,
        ["Right"] = 0,    
        ["Up"] = 0,
    },
    ["models/props_lab/citizenradio.mdl"] = {
        ["NoScreen"] = true,
    },
    ["models/props/radio_reference.mdl"] = {
        ["NoScreen"] = true,
    },
    ["models/props_misc/german_radio.mdl"] = {
        ["NoScreen"] = true,
    },
    ["models/props/cs_office/radio.mdl"] = {
        ["NoScreen"] = true,
    },
}

cleanup.Register("gmod_playx")