@echo off
cd /d G:\SteamLibrary\SteamApps\common\GarrysMod\bin
gmad.exe create -folder "D:/Github/playx" -out "D:/Github/playx.gma"
gmpublish.exe update -addon "D:/Github/playx.gma" -id 106516163
pause