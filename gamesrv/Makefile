PLAT ?= none
PLATS = linux freebsd macosx
.PHONY : none $(PLATS) all clean update3rd

none :
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

clean:
	cd skynet && $(MAKE) clean
	cd src/gg/like_skynet && $(MAKE) clean

all:
	cd skynet && $(MAKE) PLAT=$(PLAT)
	cd src/gg/like_skynet && $(MAKE) PLAT=$(PLAT)

linux macosx freebsd:
	-chmod +x skynet/3rd/jemalloc/autogen.sh
	$(MAKE) all PLAT=$(PLAT)

update3rd:
	cd skynet && $(MAKE) update3rd
	cd src/gg/like_skynet && $(MAKE) update3rd
