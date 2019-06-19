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
	cd src/gg/skynet && $(MAKE) clean
	cd src/gg/like_skynet && $(MAKE) clean
	rm -f skynet

all:
	cd src/gg/skynet && $(MAKE) PLAT=$(PLAT)
	cd src/gg/like_skynet && $(MAKE) PLAT=$(PLAT)

linux macosx freebsd:
	if ! [ -e src/gg ]; then ln -s ../../gg src/gg; fi
	-chmod -R +x src/gg/skynet/3rd/jemalloc/*
	$(MAKE) all PLAT=$(PLAT)
	cp src/gg/skynet/skynet skynet

update3rd:
	cd src/gg/skynet && $(MAKE) update3rd
	cd src/gg/like_skynet && $(MAKE) update3rd
