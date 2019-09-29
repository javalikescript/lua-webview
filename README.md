The Lua webview module provides functions to open a web page in a dedicated window from Lua.

```lua
local webviewLib = require('webview')
webviewLib.open('http://www.lua.org/')
```

This module is a binding of the tiny cross-platform [webview](https://github.com/zserge/webview) library.

This module is part of the [luaclibs](https://github.com/javalikescript/luaclibs) project, a makefile example is available in the file [lua-webview.mk](https://github.com/javalikescript/luaclibs/blob/master/lua-webview.mk), the binaries can be found on the [luajls](http://javalikescript.free.fr/lua/) page.

Lua webview is covered by the MIT license.
