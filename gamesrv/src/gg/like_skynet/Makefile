include platform.mk

SKYNET_PATH ?= ../../../skynet
LUALIB_PATH ?= lualib
LUACLIB_PATH ?= luaclib
SERVICE_PATH ?= service
CSERVICE_PATH ?= cservice

LUA_INC ?= $(SKYNET_PATH)/3rd/lua
CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYFLAGS)

$(LUALIB_PATH):
	mkdir -p $(LUALIB_PATH)

$(LUACLIB_PATH):
	mkdir -p $(LUACLIB_PATH)

$(SERVICE_PATH):
	mkdir -p $(SERVICE_PATH)

$(CSERVICE_PATH):
	mkdir -p $(CSERVICE_PATH)

# skynet_package
$(CSERVICE_PATH)/package.so : 3rd/skynet_package/service_package.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_PATH)/skynet-src

$(LUALIB_PATH)/socket_proxy.lua: 3rd/skynet_package/lualib/socket_proxy.lua
	cp $^ $@

$(SERVICE_PATH)/socket_proxyd.lua: 3rd/skynet_package/service/socket_proxyd.lua
	cp $^ $@

# skynet_websocket
$(LUALIB_PATH)/websocket.lua: 3rd/skynet_websocket/websocket.lua
	cp $^ $@

# cjson
$(LUACLIB_PATH)/cjson.so : 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c 3rd/lua-cjson/lua_cjson.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# crab
$(LUACLIB_PATH)/crab.so : 3rd/crab/lua-crab.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUACLIB_PATH)/utf8.so : 3rd/crab/lua-utf8.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# pb
$(LUACLIB_PATH)/pb.so : 3rd/lua-protobuf/pb.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# lkcp
$(LUACLIB_PATH)/lkcp.so : 3rd/kcp/lkcp.c 3rd/kcp/ikcp.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# lfs
$(LUACLIB_PATH)/lfs.so : 3rd/lfs/src/lfs.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# lutil
$(LUACLIB_PATH)/lutil.so : 3rd/util/lutil.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@


LUALIB = socket_proxy.lua websocket.lua
LUACLIB = cjson.so crab.so utf8.so pb.so lkcp.so lfs.so lutil.so
SERVICE = socket_proxyd.lua
CSERVICE = package.so

all : $(LUALIB_PATH) $(LUACLIB_PATH) $(SERVICE_PATH) $(CSERVICE_PATH) \
	$(foreach v, $(LUALIB),$(LUALIB_PATH)/$(v)) \
	$(foreach v, $(LUACLIB),$(LUACLIB_PATH)/$(v)) \
	$(foreach v, $(SERVICE),$(SERVICE_PATH)/$(v)) \
	$(foreach v, $(CSERVICE),$(CSERVICE_PATH)/$(v))

clean :
	rm -rf $(LUALIB_PATH)/*
	rm -rf $(LUACLIB_PATH)/*
	rm -rf $(SERVICE_PATH)/*
	rm -rf $(CSERVICE_PATH)/*

update3rd:
	rm -rf 3rd/crab
	rm -rf 3rd/lfs
	rm -rf 3rd/lua-cjson
	rm -rf 3rd/lua-protobuf
	rm -rf 3rd/skynet_package
	rm -rf 3rd/skynet_websocket
	-git submodule update --init

.PHONY: all clean update3rd
