#!/bin/sh
# merge to one file
#cat *.sproto > all.sproto
cd sprotodump
lua sprotodump.lua -spb ../*.sproto -o ../all.spb
