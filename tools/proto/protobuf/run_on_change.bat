@echo off

ls *.proto | xargs protoc -oall.pb
ls *.proto | xargs python genProtoId.py --output=message_define.lua

if "%GGAPP_ROOT%" == "" (
	echo "ignore copy,because GGAPP_ROOT not set!"
	pause
	exit 0
)
copy /y all.pb "%GGAPP_ROOT%/gameserver/src/proto/protobuf/"
copy /y message_define.lua "%GGAPP_ROOT%/gameserver/src/proto/protobuf/"
copy /y all.pb "%GGAPP_ROOT%/client/proto/protobuf/"
copy /y message_define.lua "%GGAPP_ROOT%/client/proto/protobuf/"
copy /y all.pb "%GGAPP_ROOT%/robot/proto/protobuf/"
copy /y message_define.lua "%GGAPP_ROOT%/robot/proto/protobuf/"
pause
