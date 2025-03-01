local event = require('jls.lang.event')
local File = require('jls.io.File')
local WebView = require('jls.util.WebView')
local FileHttpHandler = require('jls.net.http.handler.FileHttpHandler')
local RestHttpHandler = require('jls.net.http.handler.RestHttpHandler')

local scriptFile = File:new(arg[0]):getAbsoluteFile()
local scriptDir = scriptFile:getParentFile()
local htdocsDir = File:new(scriptDir, 'htdocs')

-- localhost ::1 127.0.0.1
WebView.open('http://localhost:0/calc.html', 'Calc', 320, 480, true):next(function(webview)
  local httpServer = webview:getHttpServer()
  print('WebView opened with HTTP Server bound on address', httpServer:getAddress())
  httpServer:createContext('/(.*)', FileHttpHandler:new(htdocsDir))
  httpServer:createContext('/rest/(.*)', RestHttpHandler:new({
    ['calculate(requestJson)?method=POST&content-type=application/json'] = function(exchange, requestJson)
      local f, err = load('return '..tostring(requestJson.line))
      return {line = f and f() or err or ''}
    end
  }))
  return webview:getThread():ended()
end):next(function()
  print('WebView closed')
end):catch(function(err)
  print('Cannot open webview due to '..tostring(err))
end)

--print('Looping')
event:loop()
event:close()
