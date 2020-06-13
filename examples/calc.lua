local http = require('jls.net.http')
local httpHandler = require('jls.net.http.handler')
local event = require('jls.lang.event')
local json = require('jls.util.json')
local File = require('jls.io.File')
local WebView = require('jls.util.WebView')

local scriptFile = File:new(arg[0]):getAbsoluteFile()
local scriptDir = scriptFile:getParentFile()
local htdocsDir = File:new(scriptDir, 'htdocs')

local httpServer = http.Server:new()

httpServer:createContext('/(.*)', httpHandler.file, {rootFile = htdocsDir})

httpServer:createContext('/rest/(.*)', httpHandler.rest, {handlers = {
  calculate = function(exchange)
    local request = exchange:getRequest()
    local data = json.decode(request:getBody())
    local f, err = load('return '..tostring(data.line))
    if f then
      return {line = f()}
    elseif err then
      return {line = err}
    end
  end
}})

httpServer:bind('::', 0):next(function()
  local addr = httpServer:getAddress()
  local port = addr.port
  print('HTTP Server listening on port '..tostring(port))
  WebView.open('http://localhost:'..tostring(port)..'/calc.html', 'Calc', 320, 480, true):next(function()
    print('WebView closed')
    httpServer:close():next(function()
      print('HTTP Server closed')
    end)
  end)
end, function(err)
  print('Cannot bind HTTP server, '..tostring(err))
end)

print('Looping')
event:loop()
event:close()
