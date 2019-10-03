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

