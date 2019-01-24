#include <lua.h>
#include <lauxlib.h>

#include <time.h>
#include <stdint.h>

#if defined(__APPLE__)
#include <sys/time.h>
#endif

static uint64_t
getms() {
#if !defined(__APPLE__) || defined(AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER)
	struct timespec ti;
	clock_gettime(CLOCK_REALTIME, &ti);
	return (uint64_t)(1000 * ti.tv_sec + ti.tv_nsec/1000000);
#else
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (uint64_t)(1000 * tv.tv_sec + tv.tv_usec/1000);
#endif
}

static int
lgetms(lua_State *L) {
	lua_pushinteger(L,getms());
	return 1;
}

LUAMOD_API int
luaopen_lutil(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{"getms",lgetms},
		{NULL,NULL},
	};
	luaL_newlib(L,l);
	return 1;
}


