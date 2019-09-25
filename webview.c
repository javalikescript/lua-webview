#include <lua.h>
#include <lauxlib.h>
#include <string.h>

#define WEBVIEW_IMPLEMENTATION
#include "webview.h"

static int lua_webview_open(lua_State *l) {
	const char *url = luaL_checkstring(l, 1);
	const char *title = luaL_optstring(l, 2, "Lua Web View");
	lua_Integer width = luaL_optinteger(l, 3, 800);
	lua_Integer height = luaL_optinteger(l, 4, 600);
	lua_Integer resizable = luaL_optinteger(l, 5, 1);
	webview(title, url, width, height, resizable);
    return 0;
}

// see https://github.com/zserge/webview

static int lua_webview_new(lua_State *l) {
	struct webview *webview = (struct webview *)lua_newuserdata(l, sizeof(struct webview));
	memset(webview, 0, sizeof(struct webview));
	webview->url = luaL_optstring(l, 1, "");
	webview->title = luaL_optstring(l, 2, "Lua Web View");
	webview->width = luaL_optinteger(l, 3, 800);
	webview->height = luaL_optinteger(l, 4, 600);
	webview->resizable = luaL_optinteger(l, 5, 1);
	int r = webview_init(webview);
	if (r != 0) {
		return 0;
	}
	luaL_getmetatable(l, "webview");
	lua_setmetatable(l, -2);
	return 1;
}

static int lua_webview_loop(lua_State *l) {
	struct webview *webview = (struct webview *)lua_touserdata(l, 1);
	int blocking = lua_toboolean(l, 1);
	int r = webview_loop(webview, blocking);
	lua_pushboolean(l, r);
	return r;
}

static int lua_webview_gc(lua_State *l) {
	struct webview *webview = (struct webview *)lua_touserdata(l, 1);
	webview_exit(webview);
	return 0;
}

LUALIB_API int luaopen_webview(lua_State *l) {
	luaL_newmetatable(l, "webview");
	lua_pushstring(l, "__gc");
	lua_pushcfunction(l, lua_webview_gc);
	lua_settable(l, -3);

	luaL_Reg reg[] = {
		{ "open", lua_webview_open },
		{ "new", lua_webview_new },
		{ "loop", lua_webview_loop },
		{ NULL, NULL }
	};
	lua_newtable(l);
	luaL_setfuncs(l, reg, 0);
	lua_pushliteral(l, "Lua webview");
	lua_setfield(l, -2, "_NAME");
	lua_pushliteral(l, "0.1");
	lua_setfield(l, -2, "_VERSION");
	return 1;
}
