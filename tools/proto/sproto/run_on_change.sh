#!/bin/sh
ggApp=$GGAPP_ROOT
if [ "$ggApp" = "" ]; then
	ggApp=~/ggApp
fi
cd sprotodump
lua sprotodump.lua -spb ../*.sproto -o ../all.spb
cp ../all.spb $ggApp/gamesrv/src/proto/sproto/
cp ../all.spb $ggApp/client/proto/sproto/
cp ../all.spb $ggApp/robot/proto/sproto/
