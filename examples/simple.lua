local webviewLib = require('webview')

local url = [[data:text/html,<!DOCTYPE html>
<html>
  <body>
    <p id="sentence">It works !</p>
    <button onclick="showText('...')">Clear</button>
    <button onclick="invokeExternal('eval', 'showText(&quot;Hi&quot;)')">Show Hi</button>
    <button onclick="invokeExternal('title', 'Hello Title')">Change Title</button>
    <button onclick="invokeExternal('lua', 'print(\'Hello Lua\')')">Print Hello</button>
    <button onclick="invokeExternal('lua', 'return \'showText(&quot;Lua date is \'..os.date()..\'&quot;)\'')">Show Date</button>
    <br/>
    <button title="Full-screen" onclick="fullscreen = !fullscreen; invokeExternal('fullscreen', '' + fullscreen)">&#x2922;</button>
    <button title="Reload" onclick="window.location.reload()">&#x21bb;</button>
    <button title="Terminate" onclick="invokeExternal('terminate')">&#x2716;</button>
  </body>
  <script type="text/javascript">
  var fullscreen = false;
  function showText(value) {
    document.getElementById("sentence").innerHTML = value;
  }
  function invokeExternal(cmd, line) {
    window.external.invoke(cmd + ':' + (line || ''));
  }
  </script>
</html>
]]

local webview = webviewLib.new(url, 'Example', 320, 200)

webviewLib.callback(webview, function(value)
    local cmd, line = string.match(value, '^([^:]+):(.*)$')
    if cmd == 'eval' then
        webviewLib.eval(webview, line, true)
    elseif cmd == 'lua' then
        local f, err = load(line)
        if f then
            local r = f()
            if type(r) == 'string' then
                webviewLib.eval(webview, r, true)
            end
        else
            print('error', err)
        end
    elseif cmd == 'title' then
        webviewLib.title(webview, line)
    elseif cmd == 'fullscreen' then
        webviewLib.fullscreen(webview, line == 'true')
    elseif cmd == 'terminate' then
        webviewLib.terminate(webview, true)
    else
        print('callback', value)
    end
end)

webviewLib.loop(webview)
