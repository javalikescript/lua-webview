local webviewLib = require('webview')

local content = [[<!DOCTYPE html>
<html>
  <body>
    <p id="sentence">It works !</p>
    <button onclick="window.external.invoke('title=Changed Title')">Change Title</button>
    <button onclick="window.external.invoke('print_date')">Print Date</button>
    <button onclick="window.external.invoke('show_date')">Show Date</button>
    <br/>
    <button title="Reload" onclick="window.location.reload()">&#x21bb;</button>
    <button title="Toggle fullscreen" onclick="fullscreen = !fullscreen; window.external.invoke(fullscreen ? 'fullscreen' : 'exit_fullscreen')">&#x2922;</button>
    <button title="Terminate" onclick="window.external.invoke('terminate')">&#x2716;</button>
    <br/>
  </body>
  <script type="text/javascript">
  var fullscreen = false;
  </script>
</html>
]]

content = string.gsub(content, "[ %c!#$%%&'()*+,/:;=?@%[%]]", function(c)
    return string.format('%%%02X', string.byte(c))
end)

local webview = webviewLib.new('data:text/html,'..content, 'Example', 480, 240)

webviewLib.callback(webview, function(value)
    if value == 'print_date' then
        print(os.date())
    elseif value == 'show_date' then
        webviewLib.eval(webview, 'document.getElementById("sentence").innerHTML =  "Lua date is '..os.date()..'"', true)
    elseif value == 'fullscreen' then
        webviewLib.fullscreen(webview, true)
    elseif value == 'exit_fullscreen' then
        webviewLib.fullscreen(webview, false)
    elseif value == 'terminate' then
        webviewLib.terminate(webview, true)
    elseif string.find(value, '^title=') then
        webviewLib.title(webview, string.sub(value, 7))
    else
        print('callback received', value)
    end
end)

webviewLib.loop(webview)
