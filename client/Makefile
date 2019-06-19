include platform.mk

LUA_LIB ?= 3rd/lua/liblua.a
LUA_INC ?= 3rd/lua
LUAV ?= 5.3

LUALIB_PATH ?= lualib
LUACLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYFLAGS)

$(LUALIB_PATH):
	mkdir -p $(LUALIB_PATH)

$(LUACLIB_PATH):
	mkdir -p $(LUACLIB_PATH)

# lua
$(LUA_LIB):
	cd 3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)


# sproto
$(LUACLIB_PATH)/sproto.$(SO) : 3rd/sproto/sproto.c 3rd/sproto/lsproto.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUALIB_PATH)/sproto.lua: 3rd/sproto/sproto.lua
	cp $^ $@

$(LUALIB_PATH)/sprotoparser.lua: 3rd/sproto/sprotoparser.lua
	cp $^ $@


# pb
$(LUACLIB_PATH)/pb.$(SO) : 3rd/lua-protobuf/pb.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# cjson
$(LUACLIB_PATH)/cjson.$(SO) : 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c 3rd/lua-cjson/lua_cjson.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# lkcp
$(LUACLIB_PATH)/lkcp.$(SO) : 3rd/kcp/lkcp.c 3rd/kcp/ikcp.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

# crypt
$(LUACLIB_PATH)/crypt.$(SO) : 3rd/lua-crypt/lua-crypt.c 3rd/lua-crypt/lsha1.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@


LUALIB = sproto.lua sprotoparser.lua
LUACLIB = sproto.$(SO) pb.$(SO) cjson.$(SO) lkcp.$(SO) crypt.$(SO)

update3rd :
	#git clone --branch v5.3 https://github.com/lua/lua 3rd/lua
	#cd 3rd && curl -R -O http://www.lua.org/ftp/lua-5.3.5.tar.gz
	#cd 3rd && tar -zxvf lua-5.3.5.tar.gz
	#cd 3rd && mv lua-5.3.5 lua
	#cd 3rd &&rm -rf lua-5.3.5.tar.gz
	git clone https://github.com/ejoy/lua 3rd/lua_temp
	mv 3rd/lua_temp/src 3rd/lua
	rm -rf 3rd/lua_temp
	git clone https://github.com/sundream/sproto 3rd/sproto
	git clone https://github.com/sundream/lua-protobuf 3rd/lua-protobuf
	git clone https://github.com/sundream/lua-cjson 3rd/lua-cjson
	git clone https://github.com/sundream/lua-crypt 3rd/lua-crypt
	git clone https://github.com/diegonehab/luasocket 3rd/luasocket

delete3rd :
	rm -rf 3rd/lua 3rd/sproto 3rd/lua-protobuf 3rd/lua-cjson 3rd/lua-crypt 3rd/luasocket

all : $(LUALIB_PATH) $(LUACLIB_PATH) $(LUA_LIB) \
	$(foreach v, $(LUALIB),$(LUALIB_PATH)/$(v)) \
	$(foreach v, $(LUACLIB),$(LUACLIB_PATH)/$(v))
	cd 3rd/luasocket && $(MAKE) PLAT=$(PLAT) LUAV=$(LUAV) LUAINC_$(PLAT)=../../../$(LUA_INC) LUALIB_$(PLAT)=../../../$(LUA_LIB) && \
	$(MAKE) install INSTALL_TOP_CDIR=../../../$(LUACLIB_PATH) INSTALL_TOP_LDIR=../../../$(LUALIB_PATH)

clean :
	rm -rf $(LUALIB_PATH)/*
	rm -rf $(LUACLIB_PATH)/*
	-cd 3rd/lua && $(MAKE) clean

.PHONY: all clean
