PLAT ?= none
PLATS = linux freebsd macosx

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
EXPORT := -Wl,-E

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
macosx : EXPORT :=

linux macosx freebsd :
	$(MAKE) all PLAT=$@ SHARED="$(SHARED)" EXPORT="$(EXPORT)"
