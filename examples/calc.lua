local http = require('jls.net.http')
local event = require('jls.lang.event')
local json = require('jls.util.json')
local File = require('jls.io.File')
local WebView = require('jls.util.WebView')
local FileHttpHandler = require('jls.net.http.handler.FileHttpHandler')
local RestHttpHandler = require('jls.net.http.handler.RestHttpHandler')

local scriptFile = File:new(arg[0]):getAbsoluteFile()
local scriptDir = scriptFile:getParentFile()
local htdocsDir = File:new(scriptDir, 'htdocs')

local httpServer = http.Server:new()

httpServer:createContext('/(.*)', FileHttpHandler:new(htdocsDir))

httpServer:createContext('/rest/(.*)', RestHttpHandler:new({
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
}))

-- localhost ::1 127.0.0.1
httpServer:bind('localhost', 0):next(function()
  local _, port = httpServer:getAddress()
  print('HTTP Server listening on port '..tostring(port))
  WebView.open('http://localhost:'..tostring(port)..'/calc.html', 'Calc', 320, 480, true):ended():next(function()
    print('WebView closed')
    httpServer:close():next(function()
      print('HTTP Server closed')
    end)
  end)
end, function(err)
  print('Cannot bind HTTP server, '..tostring(err))
end)

--print('Looping')
event:loop()
event:close()
