include platform.mk

SKYNET_PATH ?= 3rd/skynet
LUALIB_PATH ?= $(SKYNET_PATH)/lualib
LUACLIB_PATH ?= $(SKYNET_PATH)/luaclib
SERVICE_PATH ?= $(SKYNET_PATH)/service
CSERVICE_PATH ?= $(SKYNET_PATH)/cservice

LUA_INC ?= $(SKYNET_PATH)/3rd/lua
CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYFLAGS)

# skynet_package
$(CSERVICE_PATH)/package.so : 3rd/skynet_package/service_package.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I$(SKYNET_PATH)/skynet-src

$(LUALIB_PATH)/socket_proxy.lua: 3rd/skynet_package/lualib/socket_proxy.lua
	cp $^ $@

$(SERVICE_PATH)/socket_proxyd.lua: 3rd/skynet_package/service/socket_proxyd.lua
	cp $^ $@

# pb
$(LUACLIB_PATH)/pb.so : 3rd/lua-protobuf/pb.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# cjson
$(LUACLIB_PATH)/cjson.so : 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c 3rd/lua-cjson/lua_cjson.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# crypt
$(LUACLIB_PATH)/crypt.so : 3rd/lua-crypt/lua-crypt.c 3rd/lua-crypt/lsha1.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@


LUALIB = socket_proxy.lua
LUACLIB = pb.so cjson.so crypt.so
SERVICE = socket_proxyd.lua
CSERVICE = package.so


update3rd :
	git clone https://github.com/sundream/skynet_package 3rd/skynet_package
	git clone https://github.com/sundream/lua-protobuf 3rd/lua-protobuf
	git clone https://github.com/sundream/lua-cjson 3rd/lua-cjson
	git clone https://github.com/sundream/lua-crypt 3rd/lua-crypt
	git clone https://github.com/sundream/skynet 3rd/skynet

delete3rd :
	rm -rf 3rd/skynet_package 3rd/lua-protobuf 3rd/lua-cjson 3rd/lua-crypt 3rd/skynet

all :
	cd $(SKYNET_PATH) && make $(PLAT)
	make other3rd

other3rd : \
	$(foreach v, $(LUALIB),$(LUALIB_PATH)/$(v)) \
	$(foreach v, $(LUACLIB),$(LUACLIB_PATH)/$(v)) \
	$(foreach v, $(SERVICE),$(SERVICE_PATH)/$(v)) \
	$(foreach v, $(CSERVICE),$(CSERVICE_PATH)/$(v))

clean :
	-cd $(SKYNET_PATH) && make clean
	$(foreach v, $(LUALIB),rm -rf $(LUALIB_PATH)/$(v))
	$(foreach v, $(LUACLIB),rm -rf $(LUACLIB_PATH)/$(v))
	$(foreach v, $(SERVICE),rm -rf $(SERVICE_PATH)/$(v))
	$(foreach v, $(CSERVICE),rm -rf $(CSERVICE_PATH)/$(v))

.PHONY: all clean
