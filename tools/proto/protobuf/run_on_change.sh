#!/bin/sh
ggApp=$GGAPP_ROOT
if [ "$ggApp" = "" ]; then
	ggApp=~/ggApp
fi
protoc -oall.pb *.proto
python genProtoId.py --output=message_define.lua *.proto
cp all.pb message_define.lua $ggApp/gamesrv/src/proto/protobuf/
cp all.pb message_define.lua $ggApp/client/proto/protobuf/
cp all.pb message_define.lua $ggApp/robot/proto/protobuf/
