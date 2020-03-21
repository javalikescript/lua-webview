## Overview

The Lua webview module provides functions to open a web page in a dedicated window from Lua.

```lua
require('webview').open('http://www.lua.org/')
```

This module is a binding of the tiny cross-platform [webview](https://github.com/zserge/webview) library.

This module is part of the [luaclibs](https://github.com/javalikescript/luaclibs) project, the binaries can be found on the [luajls](http://javalikescript.free.fr/lua/) page.

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

Lua webview can be intalled using LuaRocks on Linux

```sh
sudo apt install luarocks lua5.3 lua5.3-dev
sudo apt-get install libbluetooth-dev libgtk-3-dev libwebkit2gtk-4.0-dev
luarocks install lua-webview --local
```
