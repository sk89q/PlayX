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
-- Version 2.8.8 - soundcloud by xerasin on 13-02-2014 12:56 PM (-02:00 GMT)

list.Set("PlayXHandlers", "Hulu", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.HandlerResult{
        url = uri,
        center = true,
        css = [[
* { overflow: hidden !important; }
]],
        js = [[
var m = document.head.innerHTML.match(/\/embed\/([^"]+)"/);
if (m) {
	try{
	    document.body.style.overflow = 'hidden';
	    var id = m[1];
	    document.body.innerHTML = '<div id="player-container"></div>'
	    var swfObject = new SWFObject("/site-player/playerembedwrapper.swf?referrer=none&eid="+id+"&st=&et=&it=&ml=0&siteHost=http://www.hulu.com", "player", "]] .. width .. [[", "]] .. height .. [[", "10.0.22");
	    swfObject.useExpressInstall("/expressinstall.swf");
	    swfObject.setAttribute("style", "position:fixed;top:0;left:0;width:1024px;height:512px;z-index:99999;");
	    swfObject.addParam("allowScriptAccess", "always");
	    swfObject.addParam("allowFullscreen", "true");
	    swfObject.addVariable("popout", "true");
	    swfObject.addVariable("plugins", "1");
	    swfObject.addVariable("modes", 4);
	    swfObject.addVariable("initMode", 4);
	    swfObject.addVariable("sortBy", "");
	    swfObject.addVariable("continuous_play_on", "false");
	    swfObject.addVariable("st", ]] .. start .. [[);
	    swfObject.addVariable("stage_width", "]] .. width .. [[");
	    swfObject.addVariable("stage_height", "]] .. height .. [[");
	    swfObject.write("player-container");
    } catch (e) {}
} else {
    document.body.innerHTML = 'Failure to detect ID.'
}
]]}
end)

list.Set("PlayXHandlers", "justin.tv", function(width, height, start, volume, uri, handlerArgs)
	uri = handlerArgs["URL"]
	if uri:find("/b/") then
		uri = uri:split("/b/")
		uri = uri[1].."&archive_id="..uri[2]
	end
	
    return playxlib.HandlerResult{
        center = true,      
        body = [[<object type="application/x-shockwave-flash" height="]] .. height .. [[" width="]] ..width.. [[" id="clip_embed_player_flash" data="]]..(uri:find('archive_id') and 'http://www-cdn.justin.tv/widgets/archive_site' or 'http://www.justin.tv/widgets/live_embed')..[[_player.swf" bgcolor="#000000"><param name="movie" value="]]..(uri:find('archive_id') and 'http://www-cdn.justin.tv/widgets/archive_site' or 'http://www.justin.tv/widgets/live_embed')..[[_player.swf?channel=]]..uri..[[" /><param name="allowScriptAccess" value="deny" /><param name="allowNetworking" value="all" /><param name="allowFullScreen" value="true" /><param name="flashvars" value="auto_play=true&start_volume=]]..volume..[[&title=Title&channel=]]..uri..[[" /></object>]]
    }
end)

list.Set("PlayXHandlers", "Vimeo", function(width, height, start, volume, uri, handlerArgs)
    
    local volumeFunc = function(volume)	    
        return [[
        	try {
        		document.getElementsByTagName('object')[0].api_setVolume(]]..playxlib.volumeFloat(volume)..[[);
        	} catch (e) {}
        ]]
    end

    local playFunc = function(volume)
        return [[
        	try {
        		document.getElementsByTagName('object')[0].api_play();
        		document.getElementsByTagName('object')[0].style.width='100%';
        	} catch (e) {}
        ]]
    end

    local pauseFunc = function(volume)
        return [[
        	try {
	        	document.getElementsByTagName('object')[0].api_pause();
	        	document.getElementsByTagName('object')[0].style.width='1px';
        	} catch (e) {}
        ]]
    end
	    
    return playxlib.HandlerResult{
        url = "http://player.vimeo.com/video/" .. playxlib.JSEscape(uri) .. "?api=1&player_id=player&autoplay=1",
        center = false,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc,

        js = [[
var checkReady = setInterval(function(){ if(document.readyState === "complete"){ playerReady(); clearInterval(checkReady);} }, 10);
var knownState = "Loading...";
var player = document.getElementsByTagName('object')[0];

function sendPlayerData(data) {
    var str = "";
    for (var key in data) {
        str += encodeURIComponent(key) + "=" + encodeURIComponent(data[key]) + "&"
    }
    playx.processPlayerData(str);
}

function updateState() {
  sendPlayerData({ Title: "test", State: knownState, Position: player.api_getCurrentTime(), Duration: player.api_getDuration() });
}

function onPlayerStateChange(state) {
  var msg;
  
  if (state == -1) {
    msg = "LOADING";
  } else if (state == 0) {
    msg = "COMPLETED";
  } else if (state == 1) {
    msg = "PLAYING";
  } else if (state == 2) {
    msg = "PAUSED";
  } else if (state == 3) {
    msg = "BUFFERING";
  } else {
    msg = "Unknown state: " + state;
  }
  
  knownState = msg;  
  sendPlayerData({ State: msg, Position: player.api_getCurrentTime(), Duration: player.api_getDuration() });
}

function onFinish(){
	onPlayerStateChange(0);	
}

function onPlay(){
	onPlayerStateChange(1);	
}

function onPause(){
	onPlayerStateChange(2);	
}

function playerReady() {  
  try {
	  player.api_setVolume(]] .. playxlib.volumeFloat(volume) .. [[);
	  player.api_addEventListener('finish', 'onFinish');
	  player.api_addEventListener('play', 'onPlay');
	  player.api_addEventListener('pause', 'onPause');
	  player.api_seekTo(]]..start..[[);
	  setInterval(updateState, 250);
  } catch (e) {}
}
]]
}
end)

list.Set("PlayXHandlers", "Livestream", function(width, height, start, volume, uri, handlerArgs)
    local volumeFunc = function(volume)
        return [[
        	try {
        		document.lsplayer.setVolume(]] .. playxlib.volumeFloat(volume) .. [[);
        	} catch (e) {}
        ]]
    end
    
    local playFunc = function(volume)
        return [[
        	try {
	        	document.lsplayer.setPlay();
	        	document.getElementById("lsplayer").style.width='100%';
			} catch (e) {}
      	]]
    end
    
    local pauseFunc = function(volume)
        return [[
        	try {
        		document.lsplayer.setPause();
        		document.getElementById("lsplayer").style.width='1px';
        	} catch (e) {}
        ]]
    end
	    
    return playxlib.HandlerResult{
        url = playxlib.JSEscape(uri),
        center = false,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc,

        js = [[	        			      
			try {
				var checkReady = setInterval(function(){ if(document.readyState === "complete"){ playerReady(); clearInterval(checkReady);} }, 10);
			} catch (e) {}
			
			function sendPlayerData(data) {
			    var str = "";
			    for (var key in data) {
			        str += encodeURIComponent(key) + "=" + encodeURIComponent(data[key]) + "&"
			    }
			    playx.processPlayerData(str);
			}
			
			function livestreamPlayerCallback(event) {
			  var msg;
			  
			  if (event == 'chromelessPlayerLoadedEvent') {
			    msg = "LOADING";
			  } else if (event == 'playbackCompleteEvent') {
			    msg = "COMPLETED";
			  } else if (event == 'playbackEvent') {
			    msg = "PLAYING";
			  } else if (event == 'pauseEvent') {
			    msg = "PAUSED";
			  } else if (event == 'connectionEvent') {
			    msg = "BUFFERING";
			  }else{
			  	msg = "..."
			  }
			  
			  sendPlayerData({ State: msg, Position: document.lsplayer.getTime(), Duration: document.lsplayer.getDuration() });
			}
			
			function updateState() {
			  sendPlayerData({Title: document.lsplayer.getCurrentContentTitle(), Position: document.lsplayer.getTime(), Duration: document.lsplayer.getDuration() });
			}
			
			function playerReady() {  
			  try {
				  document.lsplayer.setVolume(]] .. playxlib.volumeFloat(volume) .. [[);
				  setInterval(updateState, 250);
			  } catch (e) {}
			}
	]]}
end)

-- Initial soundcloud handler by Xerasin, I fixed and make it better for my PlayX version.
list.Set("PlayXHandlers", "SoundCloud", function(width, height, start, volume, uri, handlerArgs)
  if start > 2 then
    start = start + 4 -- Lets account for buffer time...
  end
  
  local volumeFunc = function(volume)
    return "SC.Widget(document.querySelector('iframe')).setVolume("..tostring(volume)..");"
  end
  
  local playFunc = function()
    return "SC.Widget(document.querySelector('iframe')).play();"
  end
  
  local pauseFunc = function()
    return "SC.Widget(document.querySelector('iframe')).pause();"
  end
  
  return playxlib.HandlerResult{
    url =  playxlib.JSEscape("http://ziondevelopers.github.io/playx/soundcloud.html?url="..uri.."&t="..tostring(start*1000).."&vol="..tostring(volume)),
    volumeFunc = volumeFunc,
    playFunc = playFunc,
    pauseFunc = pauseFunc
  }
end)
