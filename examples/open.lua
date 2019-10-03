local url = [[data:text/html,<!DOCTYPE html>
<html>
  <body>
    <h1>Welcome !</h1>
    <p>You could specify an URL to open as a command line argument.</p>
  </body>
</html>
]]

local urlArg = arg[1]
if urlArg and urlArg ~= '' then
  if urlArg == '-h' or urlArg == '/?' or urlArg == '--help' then
    print('Opens a WebView using the specified URL')
    os.exit(0)
  end
  local protocol = string.match(urlArg, '^([^:]+):.+$')
  if protocol == 'http' or protocol == 'https' or protocol == 'file' or protocol == 'data' then
    url = urlArg
  elseif string.match(urlArg, '^.:\\.+$') or string.match(urlArg, '^/.+$') then
    url = 'file://'..tostring(urlArg)
  else
    print('Invalid URL, to open a file please use an absolute path')
    os.exit(22)
  end
end

local title = arg[2] or 'Web View'

require('webview').open(url, title, 800, 600, true)
