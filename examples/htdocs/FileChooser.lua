local Path = require('jls.io.Path')
local File = require('jls.io.File')

local function listFiles(value, callback)
  if type(callback) ~= 'function' then
    return
  end
  local dir = File:new(value or '.'):getAbsoluteFile()
  local files = dir:listFiles()
  local parent = dir:getParent()
  if files then
    local list = {}
    if parent then
      table.insert(list, {
        name = '..',
        isDirectory = true,
        length = 0,
        lastModified = dir:lastModified(),
      })
    end
    for _, file in ipairs(files) do
      table.insert(list, {
        name = file:getName(),
        isDirectory = file:isDirectory(),
        length = file:length(),
        lastModified = file:lastModified(),
      })
    end
    local path = Path.normalizePath(dir:getPath())
    --print('listFiles('..tostring(value)..') "'..tostring(path)..'" found '..tostring(#list)..' entries, parent: "'..tostring(parent)..'"')
    table.insert(list, 1, path)
    callback(nil, list)
  end
end

if expose ~= nil then
  -- loaded as html src
  expose('fileList', listFiles)
else
  -- loaded as module
  return {
    listFiles = listFiles
  }
end
