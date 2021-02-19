
local webviewLauncher = require('webview-launcher')

print('-- JSON --------')
local values = {
  'ti/ti\nta\9ta\tto\20to "tutu" ty\\ty',
  '', 'Hi', true, false, 123, -123, 1.23,
}
for _, value in ipairs(values) do
  local encoded = webviewLauncher.jsonLib.encode(value)
  local decoded = webviewLauncher.jsonLib.decode(encoded)
  if value == decoded then
    print(encoded, type(value), 'Ok')
  else
    print('>>'..tostring(value)..'<<'..type(value))
    print('>>'..tostring(encoded)..'<<'..type(encoded))
    print('>>'..tostring(decoded)..'<<'..type(decoded))
  end
end
print('-- FS --------')
print('currentdir:', webviewLauncher.fsLib.currentdir())
local paths = {'webview-launcher.lua', 'not a file'}
for _, path in ipairs(paths) do
  print(path, webviewLauncher.fsLib.attributes(path) and 'exists' or 'not found')
end
