local webviewLib = require('webview')

-- This module allows to launch a web page that could executes custom Lua code.

-- Load JSON module
local status, jsonLib = pcall(require, 'cjson')
if not status then
  status, jsonLib = pcall(require, 'dkjson')
  if not status then
    -- provide a basic JSON implementation suitable for basic types
    local escapeMap = { ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['"'] = '\\"', ['\\'] = '\\\\', ['/'] = '\\/', }
    local revertMap = {}; for c, s in pairs(escapeMap) do revertMap[s] = c; end
    jsonLib = {
      null = {},
      decode = function(value)
        if string.sub(value, 1, 1) == '"' and string.sub(value, -1, -1) == '"' then
          return string.gsub(string.gsub(string.sub(value, 2, -2), '\\u(%x%x%x%x)', function(s)
            return string.char(tonumber(s, 16))
          end), '\\.', function(s)
            return revertMap[s] or ''
          end)
        elseif string.match(value, '^%s*[%-%+]?%d[%d%.%s]*$') then
          return tonumber(value)
        elseif (value == 'true') or (value == 'false') then
          return value == 'true'
        elseif value == 'null' then
          return jsonLib.null
        end
        return nil
      end,
      encode = function(value)
        local valueType = type(value)
        if (valueType == 'boolean') or (valueType == 'number') then
          return tostring(value)
        elseif valueType == 'string' then
          return '"'..string.gsub(value, '[%c"/\\]', function(c)
            return escapeMap[c] or string.format('\\u%04X', string.byte(c))
          end)..'"'
        elseif value == jsonLib.null then
          return 'null'
        end
        return 'undefined'
      end
    }
  end
end

-- OS file separator
local fileSeparator = string.sub(package.config, 1, 1) or '/'

-- Load file system module
local fsLib
status, fsLib = pcall(require, 'luv')
if status then
  local uvLib = fsLib
  fsLib = {
    currentdir = uvLib.cwd,
    attributes = uvLib.fs_stat,
  }
else
  status, fsLib = pcall(require, 'lfs')
  if not status then
    -- provide a basic file system implementation
    fsLib = {
      currentdir = function()
        local f = io.popen(fileSeparator == '\\' and 'cd' or 'pwd')
        if f then
          local d = f:read()
          f:close()
          return d
        end
        return '.'
      end,
      attributes = function(p)
        local f = io.open(p)
        if f then
          f:close() 
          return {}
        end
        return nil
      end,
    }
  end
end

-- Lua code injected to provide default local variables
local localContextLua = 'local evalJs, callJs, expose, sendMessage = context.evalJs, context.callJs, context.expose, context.sendMessage; '

local function exposeFunctionJs(name, entry)
  if entry then
    local invokeName = entry.json and 'callLua' or 'invokeLua'
    return "webview."..name.." = function(value) { webview."..invokeName.."('"..name.."', value); };\n"
  end
  return "delete webview."..name..";\n"
end

-- Initializes the web view and provides a global JavaScript webview object
local function initializeJs(webview, functionMap, options)
  local jsContent = [[
  if (typeof window.webview === 'object') {
    console.log('webview object already exists');
  } else {
    console.log('initialize webview object');
    var webview = {};
    window.webview = webview;
    webview.invokeLua = function(cmd, string) {
      window.external.invoke(cmd + ':' + string);
    };
    webview.callLua = function(cmd, obj) {
      window.external.invoke(cmd + ':' + JSON.stringify(obj));
    };
    webview.onMessage = function(data) {
      console.log('onMessage not implemented');
    };
  ]]
  if options and options.captureError then
    jsContent = jsContent..[[
      window.onerror = function(message, source, lineno, colno, error) {
        var message = '' + message; // Just "Script error." when occurs in different origin
        if (source) {
          message += '\n  source: ' + source + ', line: ' + lineno + ', col: ' + colno;
        }
        if (error) {
          message += '\n  error: ' + error;
        }
        window.external.invoke(':error:' + message);
        return true;
      };
    ]]
  end
  if options and options.useJsTitle then
    jsContent = jsContent..[[
      if (document.title) {
        webview.invokeLua('title', document.title);
      }
    ]]
  end
  if functionMap then
    for name, entry in pairs(functionMap) do
      jsContent = jsContent..exposeFunctionJs(name, entry)
    end
  end
  if options and options.luaScript then
    jsContent = jsContent..[[
      var evalLuaScripts = function() {
        var scripts = document.getElementsByTagName('script');
        for (var i = 0; i < scripts.length; i++) {
          var script = scripts[i];
          if (script.getAttribute('type') === 'text/lua') {
            var src = script.getAttribute('src');
            if (src) {
              webview.invokeLua('evalLuaSrc', src);
            } else {
              webview.invokeLua('evalLua', script.text);
            }
          }
        }
      };
      if (document.readyState !== 'loading') {
        evalLuaScripts();
      } else {
        document.addEventListener('DOMContentLoaded', evalLuaScripts);
      }
    ]]
  end
  jsContent = jsContent..[[
    var completeInitialization = function() {
      if (typeof window.onWebviewInitalized === 'function') {
        window.onWebviewInitalized(webview);
      }
    };
    if (document.readyState === 'complete') {
      completeInitialization();
    } else {
      window.addEventListener('load', completeInitialization);
    }
  }
  ]]
  webviewLib.eval(webview, jsContent, true)
end

-- Registers a Lua function that can be invoke from JS
local function registerFunction(functionMap, name, fn, valueIsJson)
  local entry = nil
  if type(fn) == 'function' then
    entry = {
      fn = fn,
      json = valueIsJson
    }
  end
  functionMap[name] = entry
  return entry
end

-- Exposes a Lua function to JS
local function exposeFunction(functionMap, name, fn, valueIsJson, webview)
  local entry = registerFunction(functionMap, name, fn, valueIsJson)
  webviewLib.eval(webview, exposeFunctionJs(name, entry), true)
end

-- Prints error message to the error stream
local function printError(value)
  io.stderr:write(tostring(value)..'\n')
end

-- Executes the specified Lua code
local function evalLua(value, context, webview)
  local f, err = load('local context, webview = ...; '..localContextLua..value)
  if f then
    f(context, webview)
  else
    printError('Error '..tostring(err)..' while loading '..tostring(value))
  end
end

-- Toggles the web view full screen on/off
local function fullscreen(value, _, webview)
  webviewLib.fullscreen(webview, value == 'true')
end

-- Sets the web view title
local function setTitle(value, _, webview)
  webviewLib.title(webview, value)
end

-- Terminates the web view
local function terminate(_, _, webview)
  webviewLib.terminate(webview, true)
end

-- Executes the specified Lua file relative to the URL
local function evalLuaSrc(value, context, webview)
  local content
  if context.dirPath then
    local file = io.open(context.dirPath..string.gsub(value, '[/\\]+', fileSeparator))
    content = file and file:read('a')
  end
  if content then
    evalLua(content, context, webview)
  else
    printError('Cannot load Lua file from src "'..tostring(value)..'"')
  end
end

-- Evaluates the specified JS code
local function evalJs(value, _, webview)
  webviewLib.eval(webview, value, true)
end

-- Calls the specified JS function name,
-- the arguments are JSON encoded then passed to the JS function
local function callJs(webview, functionName, ...)
  local argCount = select('#', ...)
  local args = {...}
  for i = 1, argCount do
    args[i] = jsonLib.encode(args[i])
  end
  local jsString = functionName..'('..table.concat(args, ',')..')'
  webviewLib.eval(webview, jsString, true)
end

-- Handles message
local function sendMessage(value, context, _)
  context.onMessage(value, context)
end

-- Creates the webview context and sets the callback and default functions
local function createContext(webview, options)
  local initialized = false

  -- Named requests callable from JS using window.external.invoke('name:value')
  -- Custom request can be registered using window.external.invoke('+name:Lua code')
  -- The Lua code has access to the string value, the evalJs() and callJs() functions
  local functionMap = {}

  registerFunction(functionMap, 'fullscreen', fullscreen)
  registerFunction(functionMap, 'title', setTitle)
  registerFunction(functionMap, 'terminate', terminate)
  registerFunction(functionMap, 'evalLua', evalLua)
  registerFunction(functionMap, 'evalLuaSrc', evalLuaSrc)
  registerFunction(functionMap, 'evalJs', evalJs)
  registerFunction(functionMap, 'sendMessage', sendMessage, true)

  -- Defines the context that will be shared across Lua calls
  local context = {
    expose = function(name, fn, valueIsJson)
      exposeFunction(functionMap, name, fn, valueIsJson, webview)
    end,
    -- Setup a Lua function to evaluates JS code
    evalJs = function(value)
      webviewLib.eval(webview, value, true)
    end,
    callJs = function(functionName, ...)
      callJs(webview, functionName, ...)
    end,
    -- Setup a Lua function to send a message to JS
    sendMessage = function(data)
      local dataJs = ''
      if data then
        dataJs = jsonLib.encode(data)
      end
      webviewLib.eval(webview, 'webview.onMessage('..dataJs..')', true)
    end,
    -- Setup a Lua function to receive a message from JS
    onMessage = function(data)
      printError('context.onMessage() not implemented')
    end,
    terminate = function()
      webviewLib.terminate(webview, true)
    end,
  }

  -- Registers the web view callback that handles the JS requests coming from window.external.invoke()
  webviewLib.callback(webview, function(request)
    local flag, name, value = string.match(request, '^([^a-zA-Z]?)([a-zA-Z][^:]*):(.*)$')
    if name then
      if flag == '' then
        -- Look for the specified function
        local entry = functionMap[name]
        if entry then
          if entry.json then
            value = jsonLib.decode(value)
          end
          local s, r = pcall(entry.fn, value, context, webview)
          if not s then
            printError('Fail to execute '..name..' due to '..tostring(r))
          end
        else
          printError('Unknown function '..name)
        end
      elseif flag == '-' then
        functionMap[name] = nil
      elseif flag == '+' or flag == '*' then
        -- Registering the new function using the specified Lua code
        local injected = 'local value, context, webview = ...; '
        local fn, err = load(injected..localContextLua..value)
        if fn then
          exposeFunction(functionMap, name, fn, flag == '*', initialized and webview)
        else
          printError('Error '..tostring(err)..' while loading '..tostring(value))
        end
      elseif name == 'error' and flag == ':' then
        printError(value)
      elseif name == 'init' and flag == ':' then
        initialized = true
        initializeJs(webview, functionMap, options)
      else
        printError('Invalid flag '..flag..' for name '..name)
      end
    else
      printError('Invalid request '..tostring(request))
    end
  end)

  if options and options.initialize then
    initialized = true
    initializeJs(webview, functionMap, options)
  end

  return context
end

local function escapeUrl(value)
  return string.gsub(value, "[ %c!#$%%&'()*+,/:;=?@%[%]]", function(c)
    return string.format('%%%02X', string.byte(c))
  end)
end

local function launch(url, title, width, height, resizable, options)
  local webview = webviewLib.new(url, title or 'Web View', width or 800, height or 600, resizable ~= false)
  local context = createContext(webview, options)
  webviewLib.loop(webview)
end

local function launchFromArgs()
  -- Default web content
  local url = 'data:text/html,'..escapeUrl([[<!DOCTYPE html>
  <html>
    <head>
      <title>Welcome WebView</title>
    </head>
    <script type="text/lua">
      print('You could specify an HTML file to launch as a command line argument.')
    </script>
    <body>
      <h1>Welcome !</h1>
      <p>You could specify an HTML file to launch as a command line argument.</p>
      <button onclick="window.external.invoke('terminate:')">Close</button>
    </body>
  </html>
  ]])

  local title
  local width = 800
  local height = 600
  local resizable = true
  local debug = false
  local initialize = true
  local luaScript = true
  local captureError = true

  local dirPath = nil
  local fileSeparator = string.sub(package.config, 1, 1) or '/'

  -- Parse command line arguments
  local urlArg = arg[1]
  if urlArg and urlArg ~= '' then
    if urlArg == '-h' or urlArg == '/?' or urlArg == '--help' then
      print('Launchs a WebView using the specified URL')
      print('Optional arguments: url --wv-title= --wv-width='..tostring(width)..' --wv-height='..tostring(height)..' --wv-resizable='..tostring(resizable))
      os.exit(0)
    end
    local protocol = string.match(urlArg, '^([^:]+):.+$')
    if protocol == 'http' or protocol == 'https' or protocol == 'file' or protocol == 'data' then
      url = urlArg
    else
      local filePath
      if string.match(urlArg, '^.:\\.+$') or string.match(urlArg, '^/.+$') then
        filePath = tostring(urlArg)
      elseif fsLib then
        filePath = fsLib.currentdir()..fileSeparator..tostring(urlArg)
      end
      if not filePath then
        print('Invalid URL, to launch a file please use an absolute path')
        os.exit(22)
      end
      dirPath = string.match(filePath, '^(.*[/\\])[^/\\]+$')
      url = 'file://'..filePath
    end
  end

  local ctxArgs = {}

  for i = 2, #arg do
    local name, value = string.match(arg[i], '^%-%-wv%-([^=]+)=?(.*)$')
    if not name then
      table.insert(ctxArgs, arg[i])
    elseif name == 'size' and value then
      local w, h = string.match(value, '^(%d+)[xX-/](%d+)$')
      width = tonumber(w)
      height = tonumber(h)
    elseif name == 'title' and value then
      title = value
    elseif name == 'width' and tonumber(value) then
      width = tonumber(value)
    elseif name == 'height' and tonumber(value) then
      height = tonumber(value)
    elseif name == 'resizable' then
      resizable = value ~= 'false'
    elseif name == 'debug' then
      debug = value == 'true'
    elseif name == 'initialize' then
      initialize = value ~= 'false'
    elseif name == 'script' then
      luaScript = value ~= 'false'
    elseif name == 'captureError' then
      captureError = value ~= 'false'
    else
      print('Invalid argument', arg[i])
      os.exit(22)
    end
  end

  local webview = webviewLib.new(url, title or 'Web View', width, height, resizable, debug)

  local context = createContext(webview, {
    initialize = initialize,
    useJsTitle = not title,
    luaScript = luaScript,
    captureError = captureError,
  })

  context.args = ctxArgs
  context.dirPath = dirPath

  webviewLib.loop(webview)
end

return {
  initializeJs = initializeJs,
  createContext = createContext,
  escapeUrl = escapeUrl,
  launch = launch,
  launchFromArgs = launchFromArgs,
  jsonLib = jsonLib,
  fsLib = fsLib,
}
