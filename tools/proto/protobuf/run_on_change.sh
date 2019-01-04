#!/bin/sh
protoc -oall.pb *.proto
python genProtoId.py --output=message_define.lua *.proto
python genProtoId.py --output=message_define.cs *.proto

