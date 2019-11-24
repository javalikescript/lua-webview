local webviewLib = require('webview')

-- This script allows to launch a web page that could executes custom Lua code.

-- Default web content
local url = [[data:text/html,<!DOCTYPE html>
<html>
  <body>
    <h1>Welcome !</h1>
    <p>You could specify an URL to launch as a command line argument.</p>
    <button onclick="window.external.invoke('terminate:')">Close</button>
  </body>
</html>
]]

-- Named requests callable from JS using window.external.invoke('name:value')
-- Custom request can be registered using window.external.invoke('+name:Lua code')
-- The Lua code has access to the string value, the evalJs() and callJs() functions
-- The callJs() function is only available if a JSON module is available
local requestFunctionMap = {
  -- Toggles the web view full screen on/off
  fullscreen = function(value, _, _, _, webview)
    webviewLib.fullscreen(webview, value == 'true')
  end,
  -- Sets the web view title
  title = function(value, _, _, _, webview)
    webviewLib.title(webview, value)
  end,
  -- Terminates the web view
  terminate = function(_, _, _, _, webview)
    webviewLib.terminate(webview, true)
  end,
  -- Executes the specified Lua code, the returning value will be eveluated as JS code
  evalLua = function(value, evalJs, callJs, context, webview)
    local f, err = load('local evalJs, callJs, context, webview = ...; '..value)
    if f then
      return f(evalJs, callJs, context, webview)
    else
      print('Error', err, 'while loading', value)
    end
  end,
  -- Evaluates the specified JS code
  evalJs = function(value, _, _, _, webview)
    webviewLib.eval(webview, value, true)
  end,
}

-- Parse command line arguments
local urlArg = arg[1]
if urlArg and urlArg ~= '' then
  if urlArg == '-h' or urlArg == '/?' or urlArg == '--help' then
    print('Launchs a WebView using the specified URL')
    print('Optional arguments: url title width height resizable')
    os.exit(0)
  end
  local protocol = string.match(urlArg, '^([^:]+):.+$')
  if protocol == 'http' or protocol == 'https' or protocol == 'file' or protocol == 'data' then
    url = urlArg
  elseif string.match(urlArg, '^.:\\.+$') or string.match(urlArg, '^/.+$') then
    url = 'file://'..tostring(urlArg)
  else
    print('Invalid URL, to launch a file please use an absolute path')
    os.exit(22)
  end
end
local title = arg[2] or 'Web View'
local width = arg[3] or 800
local height = arg[4] or 600
local resizable = arg[5] ~= 'false'
local verbose = arg[6] == 'true'

-- Creates the web view
local webview = webviewLib.new(url, title, width, height, resizable)

-- Defines a context that will be shared across Lua calls
local context = {}

-- Setup a Lua function to evaluates JS code
local function evalJs(value)
  webviewLib.eval(webview, value, true)
end

-- Setup a Lua function to call JS function,
-- the Lua function arguments are JSON encoded then passed to the JS function
local callJs, jsonLibLoaded, jsonLib
jsonLibLoaded, jsonLib = pcall(require, 'cjson')
if not jsonLibLoaded then
  jsonLibLoaded, jsonLib = pcall(require, 'dkjson')
end
if not jsonLibLoaded then
  print('Fail to find suitable JSON Lua module')
  jsonLib = nil
end
if jsonLib then
  callJs = function(functionName, ...)
    local args = {...}
    local jsArgs = {}
    for _, arg in ipairs(args) do
      table.insert(jsArgs, jsonLib.encode(arg))
    end
    local jsString = functionName..'('..table.concat(jsArgs, ',')..')'
    webviewLib.eval(webview, jsString, true)
  end
end

-- Registers the web view callback that handles the JS requests coming from window.external.invoke()
webviewLib.callback(webview, function(request)
  local flag, name, value = string.match(request, '^([%+%-%*]?)([^:]+):(.*)$')
  if name then
    if flag == '' then
      -- Look for the specified request
      local fn = requestFunctionMap[name]
      if fn then
        if verbose then
          print('Calling '..name..' with', value)
        end
        local s, r = pcall(fn, value, evalJs, callJs, context, webview, jsonLib)
        if not s then
          print('Fail to execute '..name..' due to', r)
        end
      else
        print('Unknown function', name)
      end
    elseif flag == '-' then
      requestFunctionMap[name] = nil
    elseif flag == '+' or flag == '*' then
      -- Registering the new request using the specified Lua code
      local injected = 'local value, evalJs, callJs, context, webview = ...; '
      if flag == '*' then
        injected = 'local jsonValue, evalJs, callJs, context, webview, jsonLib = ...; local value = jsonLib.decode(jsonValue); '
      end
      local fn, err = load(injected..value)
      requestFunctionMap[name] = fn
      if fn then
        if verbose then
          print('Loaded '..name..' as', value)
        end
      else
        print('Error', err, 'while loading', value)
      end
    else
      print('Invalid flag', flag)
    end
  else
    print('Invalid request', request)
  end
end)

-- Runs the web view event loop
webviewLib.loop(webview)
