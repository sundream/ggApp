PLAT ?= none
PLATS = linux freebsd macosx mingw

CC ?= gcc

.PHONY : none $(PLATS) clean all

#ifneq ($(PLAT), none)

.PHONY : default

default :
	$(MAKE) $(PLAT)

#endif

none :
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

SHARED := -fPIC --shared
SO := so
LUA_TOP ?= 3rd/lua/5.3
LUA_INC ?= $(LUA_TOP)/include
LUA_LIB ?= $(LUA_TOP)/lib/lua$(subst .,,$(LUAV)).$(SO)
LUAV ?= 5.3

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

macosx: PLAT = macosx
macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup

mingw : PLAT = mingw
mingw : SO := dll
mingw : CC := gcc
mingw : SHARED := -shared

linux macosx freebsd:
	$(MAKE) all PLAT=$@ SO=$(SO) CC=$(CC) SHARED="$(SHARED)"
mingw:
	$(MAKE) all PLAT=$@ SO=$(SO) CC=$(CC) SHARED="$(SHARED)" $(LUA_LIB)
