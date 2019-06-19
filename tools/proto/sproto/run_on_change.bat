#@echo off
cd sprotodump
lua sprotodump.lua -spb ../*.sproto -o ../all.spb
if "%GGAPP_ROOT%" == "" (
	echo "ignore copy,because GGAPP_ROOT not set!"
	pause
	exit 0
)
copy /y ..\all.spb "%GGAPP_ROOT%/gameserver/src/proto/sproto/"
copy /y ..\all.spb "%GGAPP_ROOT%/client/proto/sproto/"
copy /y ..\all.spb "%GGAPP_ROOT%/robot/proto/sproto/"
pause
