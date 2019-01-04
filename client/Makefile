include platform.mk

LUALIB_PATH ?= lualib
LUACLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall $(MYFLAGS)

# sproto
$(LUACLIB_PATH)/sproto.so : 3rd/sproto/sproto.c 3rd/sproto/lsproto.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUALIB_PATH)/sproto.lua: 3rd/sproto/sproto.lua
	cp $^ $@

$(LUALIB_PATH)/sprotoparser.lua: 3rd/sproto/sprotoparser.lua
	cp $^ $@


# pb
$(LUACLIB_PATH)/pb.so : 3rd/lua-protobuf/pb.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# cjson
$(LUACLIB_PATH)/cjson.so : 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c 3rd/lua-cjson/lua_cjson.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# lkcp
$(LUACLIB_PATH)/lkcp.so : 3rd/kcp/lkcp.c 3rd/kcp/ikcp.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# crypt
$(LUACLIB_PATH)/crypt.so : 3rd/lua-crypt/lua-crypt.c 3rd/lua-crypt/lsha1.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@


LUALIB = sproto.lua sprotoparser.lua
LUACLIB = sproto.so pb.so cjson.so lkcp.so crypt.so

update3rd :
	git clone https://github.com/sundream/sproto 3rd/sproto
	git clone https://github.com/sundream/lua-protobuf 3rd/lua-protobuf
	git clone https://github.com/sundream/lua-cjson 3rd/lua-cjson
	git clone https://github.com/sundream/lua-crypt 3rd/lua-crypt

delete3rd :
	rm -rf 3rd/sproto 3rd/lua-protobuf 3rd/lua-cjson 3rd/lua-crypt

all : \
	$(foreach v, $(LUALIB),$(LUALIB_PATH)/$(v)) \
	$(foreach v, $(LUACLIB),$(LUACLIB_PATH)/$(v))

clean :
	rm -rf $(LUALIB_PATH)/*
	rm -rf $(LUACLIB_PATH)/*

.PHONY: all clean
