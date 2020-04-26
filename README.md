## Overview

The Lua webview module provides functions to open a web page in a dedicated window from Lua.

```lua
require('webview').open('http://www.lua.org/')
```

It uses *gtk-webkit2* on Linux and *MSHTML* (IE10/11) on Windows.

Lua can evaluate JavaScript code and JavaScript can call a registered Lua function, see `simple.lua` in the examples.

This module is a binding of the tiny cross-platform [webview](https://github.com/zserge/webview/tree/9c1b0a888aa40039d501c1ea9f60b22a076a25ea) library.

This module is part of the [luaclibs](https://github.com/javalikescript/luaclibs) project,
the binaries can be found on the [luajls](http://javalikescript.free.fr/lua/) page.
You could also install it using [LuaRocks](#luarocks).

Lua webview is covered by the MIT license.

## Examples

Using an HTTP server
```lua
lua examples\calc.lua
```

<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-calc-linux.png" />
<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-calc-windows.png" />

Using the file system
```lua
lua examples\open.lua %CD%\examples\htdocs\todo.html
```

<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-todo-linux.png" />
<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-todo-windows.png" />

Pure Lua
```lua
wlua53 examples/simple.lua
```

<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-simple-linux.png" />
<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-simple-windows.png" />

Generic launcher, with helper function to pass JSON objects
```lua
lua examples\launch.lua %CD%\examples\htdocs\simple.html
```

## LuaRocks

Lua webview can be intalled using LuaRocks

### LuaRocks on Linux

Prerequisites:
```sh
sudo apt install luarocks lua5.3 lua5.3-dev
sudo apt-get install libbluetooth-dev libgtk-3-dev libwebkit2gtk-4.0-dev
```

```sh
luarocks install lua-webview --local
```

### LuaRocks on Windows

Prerequisites:
Download the Lua 64 bits dynamic libraries built with MinGW-w64 from [Lua Binaries](https://sourceforge.net/projects/luabinaries/).
Add [MSYS2](https://www.msys2.org/), MinGW-w64 and [git](https://git-scm.com/) in the path.


```Batchfile
luarocks --lua-dir C:/bin/lua-5.3.5 MAKE=make CC=gcc LD=gcc install lua-webview
```
Take care to use forward slashes for the Lua path.
