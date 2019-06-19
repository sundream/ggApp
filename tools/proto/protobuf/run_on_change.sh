#!/bin/sh
protoc -oall.pb *.proto
python genProtoId.py --output=message_define.lua *.proto
if [ "$GGAPP_ROOT" = "" ]; then
	echo "ignore copy,because GGAPP_ROOT not set!"
	exit 0
fi
cp all.pb message_define.lua $GGAPP_ROOT/gameserver/src/proto/protobuf/
cp all.pb message_define.lua $GGAPP_ROOT/client/proto/protobuf/
cp all.pb message_define.lua $GGAPP_ROOT/robot/proto/protobuf/
