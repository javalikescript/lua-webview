#include <lua.h>
#include <lauxlib.h>

#define WEBVIEW_IMPLEMENTATION

// wget https://raw.githubusercontent.com/zserge/webview/master/webview.h
#include "webview.h"

/*
********************************************************************************
* Lua 5.1 compatibility
********************************************************************************
*/

#if LUA_VERSION_NUM < 502
// From Lua 5.3 lauxlib.c
LUALIB_API void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
  luaL_checkstack(L, nup, "too many upvalues");
  for (; l->name != NULL; l++) {  /* fill the table with given functions */
    int i;
    for (i = 0; i < nup; i++)  /* copy upvalues to the top */
      lua_pushvalue(L, -nup);
    lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
    lua_setfield(L, -(nup + 2), l->name);
  }
  lua_pop(L, nup);  /* remove upvalues */
}
LUALIB_API void *luaL_testudata (lua_State *L, int ud, const char *tname) {
  void *p = lua_touserdata(L, ud);
  if (p != NULL) {  /* value is a userdata? */
    if (lua_getmetatable(L, ud)) {  /* does it have a metatable? */
      luaL_getmetatable(L, tname);  /* get correct metatable */
      if (!lua_rawequal(L, -1, -2))  /* not the same? */
        p = NULL;  /* value is a userdata with wrong metatable */
      lua_pop(L, 2);  /* remove both metatables */
      return p;
    }
  }
  return NULL;  /* value is not a userdata with a metatable */
}
#endif

/*
********************************************************************************
* Lua reference structure and functions
********************************************************************************
*/

typedef struct LuaReferenceStruct {
	lua_State *state;
	int ref;
} LuaReference;

static void initLuaReference(LuaReference *r) {
	if (r != NULL) {
		r->state = NULL;
		r->ref = LUA_NOREF;
	}
}

static void registerLuaReference(LuaReference *r, lua_State *l) {
	if ((r != NULL) && (l != NULL)) {
		if ((r->state != NULL) && (r->ref != LUA_NOREF)) {
			luaL_unref(r->state, LUA_REGISTRYINDEX, r->ref);
		}
		r->state = l;
		r->ref = luaL_ref(l, LUA_REGISTRYINDEX);
	}
}

static void unregisterLuaReference(LuaReference *r) {
	if ((r != NULL) && (r->state != NULL) && (r->ref != LUA_NOREF)) {
		luaL_unref(r->state, LUA_REGISTRYINDEX, r->ref);
		r->state = NULL;
		r->ref = LUA_NOREF;
	}
}

/*
********************************************************************************
* Lua webview structure
********************************************************************************
*/

typedef struct LuaWebViewStruct {
	LuaReference cbFn;
	int initialized;
	struct webview webview;
} LuaWebView;

#define WEBVIEW_PTR(_cp) \
	((LuaWebView *) ((char *) (_cp) - offsetof(LuaWebView, webview)))

/*
********************************************************************************
* Lua webview functions
********************************************************************************
*/

static int lua_webview_open(lua_State *l) {
	const char *url = luaL_checkstring(l, 1);
	const char *title = luaL_optstring(l, 2, "Lua Web View");
	lua_Integer width = luaL_optinteger(l, 3, 800);
	lua_Integer height = luaL_optinteger(l, 4, 600);
	lua_Integer resizable = lua_toboolean(l, 5);
	webview(title, url, width, height, resizable);
	return 0;
}

static LuaWebView *lua_webview_asudata(lua_State *l, int ud) {
	if (lua_islightuserdata(l, ud)) {
		return lua_touserdata(l, ud);
	}
	return (LuaWebView *)luaL_checkudata(l, ud, "webview");
}

static LuaWebView * lua_webview_newuserdata(lua_State *l) {
	const char *url = luaL_optstring(l, 1, "");
	const char *title = luaL_optstring(l, 2, "Lua Web View");
	lua_Integer width = luaL_optinteger(l, 3, 800);
	lua_Integer height = luaL_optinteger(l, 4, 600);
	lua_Integer resizable = lua_toboolean(l, 5);
	LuaWebView *lwv = (LuaWebView *)lua_newuserdata(l, sizeof(LuaWebView));
	memset(lwv, 0, sizeof(LuaWebView));
	lwv->initialized = 0;
	lwv->webview.url = url;
	lwv->webview.title = title;
	lwv->webview.width = width;
	lwv->webview.height = height;
	lwv->webview.resizable = resizable;
	initLuaReference(&lwv->cbFn);
	return lwv;
}

static int lua_webview_new(lua_State *l) {
	LuaWebView *lwv = lua_webview_newuserdata(l);
	int r = webview_init(&lwv->webview);
	if (r != 0) {
		return 0;
	}
	lwv->initialized = 1;
	luaL_getmetatable(l, "webview");
	lua_setmetatable(l, -2);
	return 1;
};

static int lua_webview_allocate(lua_State *l) {
	(void) lua_webview_newuserdata(l);
	luaL_getmetatable(l, "webview");
	lua_setmetatable(l, -2);
	return 1;
};

static int lua_webview_init(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	if (!lwv->initialized) {
		if (lua_isstring(l, 1)) {
			lwv->webview.url = lua_tostring(l, 1);
		}
		if (lua_isstring(l, 2)) {
			lwv->webview.title = lua_tostring(l, 2);
		}
		if (lua_isnumber(l, 3)) {
			lwv->webview.width = lua_tointeger(l, 3);
		}
		if (lua_isnumber(l, 4)) {
			lwv->webview.height = lua_tointeger(l, 4);
		}
		if (lua_isboolean(l, 5)) {
			lwv->webview.resizable = lua_toboolean(l, 5);
		}
		int r = webview_init(&lwv->webview);
		lwv->initialized = (r == 0);
	}
	lua_pushboolean(l, lwv->initialized);
	return 1;
}

static const char *const lua_webview_loop_modes[] = {
  "default", "once", "nowait", NULL
};

static int lua_webview_loop(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	int mode = luaL_checkoption(l, 2, "default", lua_webview_loop_modes);
	int r;
	do {
		r = webview_loop(&lwv->webview, mode != 2);
	} while ((mode == 0) && (r == 0));
	lua_pushboolean(l, r);
	return 1;
}

static void lua_webview_invoke_cb(struct webview *w, const char *arg) {
	if ((w != NULL) && (arg != NULL)) {
		LuaWebView *lwv = WEBVIEW_PTR(w);
		lua_State *l = lwv->cbFn.state;
		int ref = lwv->cbFn.ref;
		if ((l != NULL) && (ref != LUA_NOREF)) {
			lua_rawgeti(l, LUA_REGISTRYINDEX, ref);
			lua_pushstring(l, arg);
			lua_pcall(l, 1, 0, 0);
		}
	}
}

static int lua_webview_callback(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	if (lua_isfunction(l, 2)) {
		lua_pushvalue(l, 2);
		registerLuaReference(&lwv->cbFn, l);
		lwv->webview.external_invoke_cb = &lua_webview_invoke_cb;
	} else {
		unregisterLuaReference(&lwv->cbFn);
		lwv->webview.external_invoke_cb = NULL;
	}
	return 0;
}

static void dispatched_eval(struct webview *w, void *arg) {
	webview_eval(w, (const char *) arg);
}

static int lua_webview_eval(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	const char *js = luaL_checkstring(l, 2);
	int dispatch = lua_toboolean(l, 3);
	if (dispatch) {
		// do we need to register the js code to dispatch?
		webview_dispatch(&lwv->webview, dispatched_eval, (void *)js);
		return 0;
	}
	int r = webview_eval(&lwv->webview, js);
	lua_pushboolean(l, r);
	return 1;
}

static int lua_webview_title(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	const char *title = luaL_checkstring(l, 2);
	webview_set_title(&lwv->webview, title);
	return 0;
}

static int lua_webview_fullscreen(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	int fullscreen = lua_toboolean(l, 2);
	webview_set_fullscreen(&lwv->webview, fullscreen);
	return 0;
}

static void dispatched_terminate(struct webview *w, void *arg) {
	webview_terminate(w);
}

static int lua_webview_terminate(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)lua_webview_asudata(l, 1);
	int dispatch = lua_toboolean(l, 2);
	if (dispatch) {
		webview_dispatch(&lwv->webview, dispatched_terminate, NULL);
		return 0;
	}
	webview_terminate(&lwv->webview);
	return 0;
}

static int lua_webview_lighten(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)luaL_checkudata(l, 1, "webview");
 	lua_pushlightuserdata(l, lwv);
	return 1;
}

static int lua_webview_asstring(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)luaL_checkudata(l, 1, "webview");
 	lua_pushlstring(l, (const char *) &lwv, sizeof(void *));
	return 1;
}

static int lua_webview_fromstring(lua_State *l) {
	size_t len = 0;
	const char *udata = luaL_optlstring(l, 1, NULL, &len);
	if (len == sizeof(void *)) {
		lua_pushlightuserdata(l, *((void **) udata));
		return 1;
	}
	return 0;
}

static int lua_webview_gc(lua_State *l) {
	LuaWebView *lwv = (LuaWebView *)luaL_testudata(l, 1, "webview");
	if (lwv != NULL) {
		//webview_debug("lua_webview_gc()");
		webview_exit(&lwv->webview);
		unregisterLuaReference(&lwv->cbFn);
	}
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
		{ "allocate", lua_webview_allocate },
		{ "init", lua_webview_init },
		{ "loop", lua_webview_loop },
		{ "eval", lua_webview_eval },
		{ "callback", lua_webview_callback },
		{ "terminate", lua_webview_terminate },
		{ "fullscreen", lua_webview_fullscreen },
		{ "title", lua_webview_title },
		{ "lighten", lua_webview_lighten },
		{ "asstring", lua_webview_asstring },
		{ "fromstring", lua_webview_fromstring },
		{ NULL, NULL }
	};
	lua_newtable(l);
	luaL_setfuncs(l, reg, 0);
	lua_pushliteral(l, "Lua webview");
	lua_setfield(l, -2, "_NAME");
	lua_pushliteral(l, "1.0");
	lua_setfield(l, -2, "_VERSION");
	return 1;
}
