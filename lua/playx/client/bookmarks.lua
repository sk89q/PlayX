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

PlayX.BookmarksWindow = nil
PlayX.Bookmarks = {}

local bookmarksWindowList = nil
local advancedView = false

function PlayX.BookmarkDelete(line)
    local title = line:GetValue(1)
    
    Derma_Query("Are you sure you want to delete '" .. title .. "'?",
                "Delete Bookmark",
                "Yes", function()
                    local bookmark = PlayX.GetBookmark(title)
                    if bookmark then
                        bookmark:Delete()
                        PlayX.SaveBookmarks()
                    end
                end,
                "No", function() end)
end

local function IsTrue(s)
    local s = s:lower():Trim()
    return s == "t" or s == "true" or s == "1" or s == "y" or s == "yes"
end

local Bookmark = {}

function Bookmark:new(title, provider, uri, keyword, startAt, lowFramerate)
    local instance = {
        ["Title"] = title,
        ["Provider"] = provider,
        ["URI"] = uri,
        ["Keyword"] = keyword,
        ["StartAt"] = startAt,
        ["LowFramerate"] = lowFramerate,
        ["Deleted"] = false,
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function Bookmark:Update(title, provider, uri, keyword, startAt, lowFramerate)
    if self.Deleted then
        Error("Operation performed on deleted bookmark")    
    end
    
    local title = title:Trim()
    local provider = provider:Trim()
    local uri = uri:Trim()
    local keyword = keyword:Trim()
    local startAt = startAt:Trim()
    local lowFramerate = lowFramerate
    
    if title == "" then
        return false, "A title is required."
    end
    if uri == "" then
        return false, "A URI is required."
    end
    
    for _, bookmark in pairs(PlayX.Bookmarks) do
        if keyword ~= "" and keyword:lower() == bookmark.Keyword:lower() and
            self.Title:lower() ~= bookmark.Title:lower() then
            return false, "An existing, different entry already has the keyword '" .. keyword .. "'."
        end
    end
    
    local oldTitle = self.Title
    
    self.Title = title
    self.Provider = provider
    self.URI = uri
    self.Keyword = keyword
    self.StartAt = startAt
    self.LowFramerate = lowFramerate
    
    -- Update the panel
    if PlayX._BookmarksPanelList then
        local bookmarks = PlayX._BookmarksPanelList
        for _, line in pairs(bookmarks:GetLines()) do
           if line:GetValue(1):lower() == oldTitle:lower() then
                line:SetValue(1, title)
                line:SetValue(2, uri)
                if keyword ~= "" then
                    line:SetTooltip("Keyword: " .. keyword)
                else
                    line:SetTooltip(false)
                end
                break
           end
        end
    end
    
    -- Update the window
    if bookmarksWindowList then
        local bookmarks = bookmarksWindowList
        for _, line in pairs(bookmarks:GetLines()) do
           if line:GetValue(1):lower() == oldTitle:lower() then
                line:SetValue(1, title)
                line:SetValue(2, uri)
                line:SetValue(3, provider)
                line:SetValue(4, keyword)
                break
           end
        end
    end
    
    return true
end

function Bookmark:Delete()
    self.Deleted = true
    
    for i, bookmark in pairs(PlayX.Bookmarks) do
        if bookmark == self then
            table.remove(PlayX.Bookmarks, i)
                        
            -- Now let's update the panel
            if PlayX._BookmarksPanelList then
                local bookmarks = PlayX._BookmarksPanelList
                for _, line in pairs(bookmarks:GetLines()) do
                   if line:GetValue(1):lower() == self.Title:lower() then
                        bookmarks:RemoveLine(line:GetID())
                        break
                   end
                end
            end
            
            -- Now let's update the window
            if bookmarksWindowList then
                local bookmarks = bookmarksWindowList
                for _, line in pairs(bookmarks:GetLines()) do
                   if line:GetValue(1):lower() == self.Title:lower() then
                        bookmarks:RemoveLine(line:GetID())
                        break
                   end
                end
            end
            
            return true
        end
    end
    
    return false
end

function Bookmark:Play()
    if self.Deleted then
        Error("Operation performed on deleted bookmark")    
    end
    
    PlayX.NavigatorCapturedURL = ""
    
    PlayX.RequestOpenMedia(self.Provider, self.URI, self.StartAt,
                           self.LowFramerate, GetConVar("playx_use_jw"):GetBool(),
                           GetConVar("playx_ignore_length"):GetBool())
end

function Bookmark:CopyToPanel()
    if self.Deleted then
        Error("Operation performed on deleted bookmark")    
    end
    
    RunConsoleCommand("playx_provider", self.Provider)
    RunConsoleCommand("playx_uri", self.URI)
    RunConsoleCommand("playx_start_time", self.StartAt)
    RunConsoleCommand("playx_force_low_framerate", self.LowFramerate and "1" or "0")
end

function PlayX.LoadBookmarks()
    local data = file.Read("playx/bookmarks.txt")
    
    if data == nil then
        -- Default data
        data = [[
No One Sleeps When I'm Awake,,http://youtube.com/watch?v=3Muci-5Yt0o,,0:00,
What Is Love?,,http://www.youtube.com/watch?v=0YXuq25BMVI,,0:00,1
Divenire,,http://youtube.com/watch?v=_RyPFwAWSKM,,0:00,
Come Sei Veramente,,http://youtube.com/watch?v=qKMZ2H_a0z8,,0:00,1
Frozen Grand Central,,http://www.youtube.com/watch?v=jwMj3PJDxuo,,0:00,
Sound of Music,,http://www.youtube.com/watch?v=7EYAUazLI9k,,0:00,
Google Chrome Speed Tests,,http://youtube.com/watch?v=nCgQDjiotG0,,0:00,
Phoenix,,http://www.youtube.com/watch?v=w0BPaY6_9hs,,0:00
This Is Halloween,,http://youtube.com/watch?v=i_zYrYkbrGY,,0:00,
]]
    end
    
    PlayX.Bookmarks = {}
    
    local result = playxlib.ParseCSV(data)
    for k, v in pairs(result) do
        local bookmark = Bookmark:new(v[1] and v[1] or "", -- Title
                                      v[2] and v[2] or "", -- Provider
                                      v[3] and v[3] or "", -- URI
                                      v[4] and v[4] or "", -- Keyword
                                      v[5] and v[5] or "0:00", -- Start at
                                      v[6] and IsTrue(v[6]) or false) -- Low framerate
        table.insert(PlayX.Bookmarks, bookmark)
    end
    
    -- Let's make a backup
    if #PlayX.Bookmarks > 0 then
       file.Write("playx/bookmarks_backup.txt", data)
    end
    
    -- Update lists
    if PlayX._BookmarksPanelList then
        local bookmarks = PlayX._BookmarksPanelList
        bookmarks:Clear()
        for k, bookmark in pairs(PlayX.Bookmarks) do
            local line = bookmarks:AddLine(bookmark.Title, bookmark.URI)
            if bookmark.Keyword ~= "" then
                line:SetTooltip("Keyword: " .. bookmark.Keyword)
            end
        end
    end
    
    if bookmarksWindowList then
        local bookmarks = bookmarksWindowList
        bookmarks:Clear()
	    for k, bookmark in pairs(PlayX.Bookmarks) do
	        bookmarks:AddLine(bookmark.Title, bookmark.URI, bookmark.Provider,
	                          bookmark.Keyword)
	    end
    end
    
    return true
end

function PlayX.SaveBookmarks()
    local data = {}
    
    for _, bookmark in pairs(PlayX.Bookmarks) do
        table.insert(data, {bookmark.Title, bookmark.Provider, bookmark.URI,
                            bookmark.Keyword, bookmark.StartAt,
                            bookmark.LowFramerate})
    end
    
    local output = playxlib.WriteCSV(data)
    
    file.CreateDir("playx")
    file.Write("playx/bookmarks.txt", output)
    
    return true
end

function PlayX.AddBookmark(title, provider, uri, keyword, startAt, lowFramerate)
    local title = title:Trim()
    local provider = provider:Trim()
    local uri = uri:Trim()
    local keyword = keyword:Trim()
    local startAt = startAt:Trim()
    local lowFramerate = lowFramerate and lowFramerate or false
    
    if title == "" then
        return false, "A title is required."
    end
    if uri == "" then
        return false, "A URI is required."
    end
    
    for _, bookmark in pairs(PlayX.Bookmarks) do
        if keyword ~= "" and keyword:lower() == bookmark.Keyword:lower() then
            return false, "An existing entry already has the keyword '" .. keyword .. "'."
        end
        if title:lower() == bookmark.Title:lower() then
            return false, "An existing entry already has the title '" .. title .. "'."
        end
    end
    
    local bookmark = Bookmark:new(title, provider, uri, keyword, startAt, lowFramerate)
    table.insert(PlayX.Bookmarks, bookmark)
    
    -- Let's update the bookmarks panel
    if PlayX._BookmarksPanelList then
        local bookmarks = PlayX._BookmarksPanelList
        local line = bookmarks:AddLine(title, uri)
        if keyword ~= "" then
            line:SetTooltip("Keyword: " .. keyword)
        end
    end
    
    -- Let's update the bookmarks window
    if bookmarksWindowList then
        local bookmarks = bookmarksWindowList
        bookmarks:AddLine(title, uri, provider, keyword)
    end
    
    return true
end

function PlayX.GetBookmark(title)
    for i, bookmark in pairs(PlayX.Bookmarks) do
        if title:lower() == bookmark.Title:lower() then
            return bookmark
        end
    end
    
    return nil
end

function PlayX.GetBookmarkByKeyword(keyword)
    if keyword:Trim() == "" then return end
    
    for i, bookmark in pairs(PlayX.Bookmarks) do
        if keyword:lower():Trim() == bookmark.Keyword:lower():Trim() then
            return bookmark
        end
    end
    
    return nil
end

function PlayX.OpenBookmarksWindow(selectTitle)
    if PlayX.BookmarksWindow and PlayX.BookmarksWindow:IsValid() then
        return
    end
    
    local bookmarks = nil
    
    local frame = vgui.Create("DFrame")
    PlayX.BookmarksWindow = frame
    frame:SetTitle("Local PlayX Bookmarks")
    frame:SetDeleteOnClose(true)
    frame:SetScreenLock(true)
    frame:SetSize(math.min(600, ScrW() - 20), ScrH() * 4/5)
    frame:SetSizable(true)
    frame:Center()
    frame:MakePopup()
    
    -- Title input
    local titleLabel = vgui.Create("DLabel", frame)
    titleLabel:SetText("Title:")
    titleLabel:SetWide(200)
    local titleInput = vgui.Create("DTextEntry", frame)
    titleInput:SetWide(250)
    
    -- URI input
    local uriLabel = vgui.Create("DLabel", frame)
    uriLabel:SetText("URI:")
    uriLabel:SetWide(200)
    local uriInput = vgui.Create("DTextEntry", frame)
    uriInput:SetWide(250)
    
    -- Advanced link
    surface.SetFont("Default")
    local w, h = surface.GetTextSize("<< Advanced")
    local advancedLink = vgui.Create("DButton", frame)
    advancedLink:SetText("")
    advancedLink:SetTall(20)
    advancedLink:SetWide(w + 5)
    advancedLink:SetTooltip("Show advanced bookmark settings")
    advancedLink:SetCursor("hand")
    advancedLink.DoClick = function()
        advancedView = not advancedView
        frame:InvalidateLayout(true, true)
    end
    advancedLink.Paint = function()
        local textStyleColor = advancedLink:GetTextStyleColor()
        local text = asdvancedView and "<< Advanced" or "Advanced >>"
        surface.SetFont("Default")
        surface.SetDrawColor(textStyleColor)
        surface.SetTextColor(textStyleColor)
        surface.SetTextPos(0, 0) 
        local w, h = surface.GetTextSize(text)
        surface.DrawText(text)
        surface.DrawLine(0, h, w, h)
    end
    
    -- Keyword input
    local keywordLabel = vgui.Create("DLabel", frame)
    keywordLabel:SetText("Keyword:")
    keywordLabel:SetWide(200)
    local keywordInput = vgui.Create("DTextEntry", frame)
    keywordInput:SetWide(100)
    keywordInput:SetTooltip("Keywords can be entered in the Administrate panel as a URI")
    
    -- Time input
    local startAtLabel = vgui.Create("DLabel", frame)
    startAtLabel:SetText("Start At:")
    startAtLabel:SetWide(200)
    local startAtInput = vgui.Create("DTextEntry", frame)
    startAtInput:SetWide(50)
    startAtInput:SetValue("0:00")
    
    -- Low framerate checkbox
    local lowFramerateCheck = vgui.Create("DCheckBoxLabel", frame)
    lowFramerateCheck:SetText("Force low framerate")
    lowFramerateCheck:SetWide(200)
    
    -- Provider input
    local providerLabel = vgui.Create("DLabel", frame)
    providerLabel:SetText("Provider:")
    providerLabel:SetWide(200)
    local providerInput = vgui.Create("DTextEntry", frame)
    providerInput:SetWide(150)
    providerInput:SetTooltip("Leave blank for auto-detection")
    
    --providerInput:AddChoice("")
    --for id, name in pairs(PlayX.Providers) do
    --    providerInput:AddChoice(id)
    --end
    
    -- Update button
    local updateButton = vgui.Create("DButton", frame)
    updateButton:SetText("Update")
    updateButton:SetWide(80)
    updateButton:SetTooltip("Update the selected entry with these values")
    updateButton.DoClick = function()
        local oldTitle = ""
        local line = nil
        
        if bookmarks:GetSelectedLine() then
            line = bookmarks:GetLine(bookmarks:GetSelectedLine())
            oldTitle = line:GetValue(1)
        else
            Derma_Message("A bookmark is not selected.", "Error", "OK")
            return
        end
            
        local title = titleInput:GetValue():Trim()
        local provider = providerInput:GetValue():Trim()
        local uri = uriInput:GetValue():Trim()
        local keyword = keywordInput:GetValue():Trim()
        local startAt = startAtInput:GetValue():Trim()
        local lowFramerate = lowFramerateCheck:GetChecked()
        
        local bookmark = PlayX.GetBookmark(oldTitle)
        
        if not bookmark then
            Derma_Message("The selected bookmark does not exist.", "Error", "OK")
            return
        end
        
        local result, err = bookmark:Update(title, provider, uri, keyword,
                                            startAt, lowFramerate)
        if not result then
            Derma_Message(err, "Error", "OK")
            return
        end
        
        PlayX.SaveBookmarks()
    end
    
    -- Add button
    local addButton = vgui.Create("DButton", frame)
    addButton:SetText("Add")
    addButton:SetWide(80)
    addButton:SetTooltip("Add a new entry with these values")
    addButton.DoClick = function()
        local title = titleInput:GetValue():Trim()
        local provider = providerInput:GetValue():Trim()
        local uri = uriInput:GetValue():Trim()
        local keyword = keywordInput:GetValue():Trim()
        local startAt = startAtInput:GetValue():Trim()
        local lowFrameRate = lowFramerateCheck:GetChecked()
        
        local result, err = PlayX.AddBookmark(title, provider, uri, keyword,
                                              startAt, lowFramerate)
        if result then
	        titleInput:SetValue("")
	        uriInput:SetValue("")
	        providerInput:SetText("")
            keywordInput:SetValue("")
            startAtInput:SetValue("0:00")
            lowFramerateCheck:SetValue(false)
	        
	        PlayX.SaveBookmarks()
        else
            Derma_Message(err, "Error", "OK")
        end
    end
    
    -- Clear button
    local clearButton = vgui.Create("DButton", frame)
    clearButton:SetText("Clear")
    clearButton:SetWide(80)
    clearButton:SetTooltip("Clear the form")
    clearButton.DoClick = function()
        titleInput:SetValue("")
        uriInput:SetValue("")
        providerInput:SetText("")
        keywordInput:SetValue("")
        startAtInput:SetValue("0:00")
        lowFramerateCheck:SetValue(false)
	    
	    PlayX.SaveBookmarks()
    end
    
    -- Delete button
    local deleteButton = vgui.Create("DButton", frame)
    deleteButton:SetText("Delete...")
    deleteButton:SetWide(80)
    deleteButton:SetTooltip("Delete the selected entry (after confirmation)")
    deleteButton.DoClick = function()
        if bookmarks:GetSelectedLine() then
            -- GetSelected() not working
            PlayX.BookmarkDelete(bookmarks:GetLine(bookmarks:GetSelectedLine()))
        else
            Derma_Message("A bookmark is not selected.", "Error", "OK")
        end
    end
    
    -- Close button
    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetText("Close")
    closeButton:SetWide(80)
    closeButton.DoClick = function()
        frame:Close()
    end
    
    -- Reload button
    local reloadButton = vgui.Create("DButton", frame)
    reloadButton:SetText("Reload")
    reloadButton:SetWide(80)
    reloadButton:SetTooltip("Reload the bookmarks from disk")
    reloadButton.DoClick = function()
        PlayX.LoadBookmarks()
    end
    
    -- Save button
    local saveButton = vgui.Create("DButton", frame)
    saveButton:SetText("Save")
    saveButton:SetWide(80)
    saveButton:SetTooltip("Save the bookmarks to disk (automatically done after every operation)")
    saveButton.DoClick = function()
        PlayX.SaveBookmarks()
    end
    
    -- Make list view
    bookmarks = vgui.Create("DListView", frame)
    bookmarksWindowList = bookmarks
    bookmarks:SetMultiSelect(false)
    bookmarks:AddColumn("Title")
    bookmarks:AddColumn("URI")
    bookmarks:AddColumn("Provider"):SetFixedWidth(100)
    bookmarks:AddColumn("Keyword"):SetFixedWidth(90)
    
    for k, bookmark in pairs(PlayX.Bookmarks) do
        bookmarks:AddLine(bookmark.Title, bookmark.URI, bookmark.Provider,
                          bookmark.Keyword)
    end
    
    bookmarks.OnRowSelected = function(lst, index)
        local line = lst:GetLine(index)
        local bookmark = PlayX.GetBookmark(line:GetValue(1))
        titleInput:SetValue(bookmark.Title)
        uriInput:SetValue(bookmark.URI)
        providerInput:SetText(bookmark.Provider)
        keywordInput:SetValue(bookmark.Keyword)
        startAtInput:SetValue(bookmark.StartAt)
        lowFramerateCheck:SetValue(bookmark.LowFramerate)
    end
    
    bookmarks.OnRowRightClick = function(lst, index, line)
        local menu = DermaMenu()
        menu:AddOption("Open", function()
	        PlayX.GetBookmark(line:GetValue(1):Trim()):Play()
            frame:Close()
        end)
        menu:AddOption("Delete...", function()
            PlayX.BookmarkDelete(line)
        end)
        menu:AddOption("Copy URI", function()
            SetClipboardText(line:GetValue(2))
        end)
        menu:AddOption("Copy to 'Administrate'", function()
            PlayX.GetBookmark(line:GetValue(1):Trim()):CopyToPanel()
            frame:Close()
        end)
        menu:Open() 
    end
    
    bookmarks.DoDoubleClick = function(lst, index, line)
        if not line then return end
        PlayX.GetBookmark(line:GetValue(1):Trim()):Play()
        frame:Close()
    end
    
    if selectTitle then
        for _, line in pairs(bookmarks:GetLines()) do
           if line:GetValue(1):lower() == selectTitle:lower() then
                bookmarks:SelectItem(line)
                break
           end
        end
    end
    
    -- Layout
    local oldPerform = frame.PerformLayout
    frame.PerformLayout = function()
        oldPerform(frame)
        bookmarks:StretchToParent(10, 28, 10, advancedView and 160 or 110)
        
        titleLabel:SetPos(10, bookmarks:GetTall() + 35)
        titleInput:SetPos(70, bookmarks:GetTall() + 35)
        
        uriLabel:SetPos(10, bookmarks:GetTall() + 35 + 23)
        uriInput:SetPos(70, bookmarks:GetTall() + 35 + 23)
        uriInput:SetWide(frame:GetWide() - 300)
        
        advancedLink:SetPos(10, bookmarks:GetTall() + 20 + 35 + 27)
        
        keywordLabel:SetPos(10, bookmarks:GetTall() + 35 + 20 + 23 * 2)
        keywordLabel:SetVisible(advancedView)
        keywordInput:SetPos(70, bookmarks:GetTall() + 35 + 20 + 23 * 2)
        keywordInput:SetVisible(advancedView)
        
        startAtLabel:SetPos(10 + 180, bookmarks:GetTall() + 35 + 20 + 23 * 2)
        startAtLabel:SetVisible(advancedView)
        startAtInput:SetPos(70 + 180, bookmarks:GetTall() + 35 + 20 + 23 * 2)
        startAtInput:SetVisible(advancedView)
        
        providerLabel:SetPos(10, bookmarks:GetTall() + 35 + 20 + 23 * 3)
        providerLabel:SetVisible(advancedView)
        providerInput:SetPos(70, bookmarks:GetTall() + 35 + 20 + 23 * 3)
        providerInput:SetVisible(advancedView)
        
        lowFramerateCheck:SetPos(240, bookmarks:GetTall() + 20 + 35 * 3 + 1)
        lowFramerateCheck:SetVisible(advancedView)
        
        reloadButton:SetPos(frame:GetWide() - reloadButton:GetWide() - saveButton:GetWide() - 13,
                            bookmarks:GetTall() + 35)
        saveButton:SetPos(frame:GetWide() - reloadButton:GetWide() - 10,
                            bookmarks:GetTall() + 35)
        
        updateButton:SetPos(10, frame:GetTall() - 32)
        addButton:SetPos(3 + updateButton:GetWide() + 10,
                         frame:GetTall() - 32)
        clearButton:SetPos(3 + updateButton:GetWide() + addButton:GetWide() + 30,
                           frame:GetTall() - 32)
        deleteButton:SetPos(3 + updateButton:GetWide() + addButton:GetWide() + clearButton:GetWide() + 33,
                            frame:GetTall() - 32)
        closeButton:SetPos(frame:GetWide() - closeButton:GetWide() - 10,
                            frame:GetTall() - 32)
    end
    
    frame:InvalidateLayout(true, true)
end

PlayX.LoadBookmarks()