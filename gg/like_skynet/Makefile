include platform.mk

SKYNET_PATH ?= ../skynet
LUALIB_PATH ?= lualib
LUACLIB_PATH ?= luaclib
SERVICE_PATH ?= service
CSERVICE_PATH ?= cservice

LUA_INC ?= $(SKYNET_PATH)/3rd/lua
LUA_LIB ?= $(SKYNET_PATH)/3rd/lua/liblua.a
CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(LUA_LIB) $(MYFLAGS)
OPENSSL_LIBS	?= $(shell pkg-config openssl --static --libs)

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

# lua-websocket
$(LUALIB_PATH)/websocket:
	mkdir -p $(LUALIB_PATH)/websocket
	cp 3rd/lua-websocket/lib/websocket/* $(LUALIB_PATH)/websocket

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

# lua-webclient
$(LUACLIB_PATH)/webclient.so : 3rd/lua-webclient/webclient.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lcurl

$(SERVICE_PATH)/webclient.lua : 3rd/lua-webclient/webclient.lua
	cp $^ $@

# aes128
$(LUACLIB_PATH)/aes128.so : 3rd/lua-aes/aes.c 3rd/lua-aes/laes.c
	$(CC) $(CFLAGS) $(SHARED) -DAES128=1 $^ -o $@

# aes192
$(LUACLIB_PATH)/aes192.so : 3rd/lua-aes/aes.c 3rd/lua-aes/laes.c
	$(CC) $(CFLAGS) $(SHARED) -DAES192=1 $^ -o $@

# aes256
$(LUACLIB_PATH)/aes256.so : 3rd/lua-aes/aes.c 3rd/lua-aes/laes.c
	$(CC) $(CFLAGS) $(SHARED) -DAES256=1 $^ -o $@

# lua-snowflake
$(LUACLIB_PATH)/snowflake.so : 3rd/lua-snowflake/snowflake.c 3rd/lua-snowflake/lsnowflake.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUALIB_PATH)/snowflake.lua: 3rd/lua-snowflake/snowflake.lua
	cp $^ $@

# luaxml
$(LUACLIB_PATH)/LuaXML_lib.so : 3rd/luaxml/LuaXML_lib.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUALIB_PATH)/xml.lua: 3rd/luaxml/xml.lua
	cp $^ $@

# lua-openssl
$(LUACLIB_PATH)/openssl.so : 3rd/lua-openssl/src/asn1.c 3rd/lua-openssl/deps/auxiliar/auxiliar.c 3rd/lua-openssl/src/bio.c 3rd/lua-openssl/src/cipher.c \
	3rd/lua-openssl/src/cms.c 3rd/lua-openssl/src/compat.c 3rd/lua-openssl/src/crl.c 3rd/lua-openssl/src/csr.c 3rd/lua-openssl/src/dh.c 3rd/lua-openssl/src/digest.c \
	3rd/lua-openssl/src/dsa.c 3rd/lua-openssl/src/ec.c 3rd/lua-openssl/src/engine.c 3rd/lua-openssl/src/hmac.c 3rd/lua-openssl/src/lbn.c 3rd/lua-openssl/src/lhash.c \
	3rd/lua-openssl/src/misc.c 3rd/lua-openssl/src/ocsp.c 3rd/lua-openssl/src/openssl.c 3rd/lua-openssl/src/ots.c 3rd/lua-openssl/src/pkcs12.c 3rd/lua-openssl/src/pkcs7.c \
	3rd/lua-openssl/src/pkey.c 3rd/lua-openssl/src/rsa.c 3rd/lua-openssl/src/ssl.c 3rd/lua-openssl/src/th-lock.c 3rd/lua-openssl/src/util.c 3rd/lua-openssl/src/x509.c \
	3rd/lua-openssl/src/xattrs.c 3rd/lua-openssl/src/xexts.c 3rd/lua-openssl/src/xname.c 3rd/lua-openssl/src/xstore.c 3rd/lua-openssl/src/xalgor.c 3rd/lua-openssl/src/callback.c \
	3rd/lua-openssl/src/srp.c 3rd/lua-openssl/deps/auxiliar/subsidiar.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I3rd/lua-openssl/deps/auxiliar -I3rd/lua-openssl/deps/lua-compat $(OPENSSL_LIBS) -DPTHREADS

$(LUALIB_PATH)/openssl:
	mkdir -p $(LUALIB_PATH)/openssl
	cp -r 3rd/lua-openssl/lib/* $(LUALIB_PATH)/openssl

LUALIB = socket_proxy.lua websocket snowflake.lua xml.lua openssl
LUACLIB = cjson.so crab.so utf8.so pb.so lkcp.so lfs.so lutil.so webclient.so openssl.so\
		  aes128.so aes192.so aes256.so snowflake.so LuaXML_lib.so
SERVICE = socket_proxyd.lua webclient.lua
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
	rm -rf 3rd/lua-websocket
	rm -rf 3rd/lua-webclient
	rm -rf 3rd/lua-aes
	rm -rf 3rd/luaxml
	rm -rf 3rd/lua-openssl
	-git submodule update --init

.PHONY: all clean update3rd
