## Overview

The Lua webview module provides functions to open a web page in a dedicated window from Lua.

```lua
require('webview').open('http://www.lua.org/')
```

It uses *gtk-webkit2* on Linux and *MSHTML* (IE10/11) or *Edge* (Chromium) on Windows.

Lua can evaluate JavaScript code and JavaScript can call a registered Lua function, see the `simple.lua` file in the examples.

This module is a binding of the tiny cross-platform [webview-c](https://github.com/javalikescript/webview-c) C library.

This module is part of the [luaclibs](https://github.com/javalikescript/luaclibs) project,
the binaries can be found on the [luajls](http://javalikescript.free.fr/lua/) page.
You could also install it using [LuaRocks](#luarocks).

Lua webview is covered by the MIT license.

## Launcher

An optional Lua launcher module `webview-launcher.lua` is available.
The HTML scripts using the type `text/lua` will be loaded automatically.
The Lua scripts could expose named functions with callbacks to JavaScript.

```html
<button onclick="webview.sayHello('You', console.info)">Say Hello</button>
<script type="text/lua">
  context.exposeAll({
    sayHello = function(value, callback)
      callback(nil, 'Hello '..tostring(value))
    end
  })
</script>
```
or using a Lua file
```html
<script src="assets/FileChooser.lua" type="text/lua"></script>
```

Additionally a JavaScript file `webview-init.js` is available to deal with the launcher initialization including in case of reloading.

The launcher supports events in Lua when used with [luajls](https://github.com/javalikescript/luajls).

## Examples

Using an HTTP server
```sh
lua examples/calc.lua
```

<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-calc-linux.png" />
<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-calc-windows.png" />

Using the file system
```sh
lua examples/open.lua %CD%\examples\htdocs\todo.html
```

<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-todo-linux.png" />
<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-todo-windows.png" />

Pure Lua
```sh
wlua53 examples/simple.lua
```

<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-simple-linux.png" />
<img src="https://javalikescript.github.io/lua-webview/screenshots/lua-webview-simple-windows.png" />

Generic launcher, with helper function to pass JSON objects and more
```sh
lua examples/launch.lua examples/htdocs/simple.html --wv-event=thread
```

## LuaRocks

Lua webview can be intalled using LuaRocks

### LuaRocks on Linux

Prerequisites:
```sh
sudo apt install luarocks lua5.3 lua5.3-dev
sudo apt install libgtk-3-dev libwebkit2gtk-4.0-dev
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
