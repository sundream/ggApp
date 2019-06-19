#!/bin/sh
cd sprotodump
lua sprotodump.lua -spb ../*.sproto -o ../all.spb
if [ "$GGAPP_ROOT" = "" ]; then
	echo "ignore copy,because GGAPP_ROOT not set!"
	exit 0
fi
cp ../all.spb $GGAPP_ROOT/gameserver/src/proto/sproto/
cp ../all.spb $GGAPP_ROOT/client/proto/sproto/
cp ../all.spb $GGAPP_ROOT/robot/proto/sproto/
