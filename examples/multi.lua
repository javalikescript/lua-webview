local event = require('jls.lang.event')
local WebView = require('jls.util.WebView')

local content = [[<!DOCTYPE html>
<html>
  <body>
    <p id="sentence">Initializing...</p>
    <button onclick="window.external.invoke('count')">Count</button>
    <br/>
    <button title="Terminate" onclick="window.external.invoke('terminate')">&#x2716;</button>
    <br/>
  </body>
  <script type="text/javascript">
    function showText(value) {
      document.getElementById("sentence").innerHTML = value;
    }
    showText('It works !');
  </script>
</html>
]]

local dataUrl =  WebView.toDataUrl(content)

local threadA, webviewA = WebView.openInThread(dataUrl, 'WebView A', 320, 240, true, true)
local threadB, webviewB = WebView.openInThread(dataUrl, 'WebView B', 320, 240, true, true)

local count = 0

local function registerCallback(wva, wvb, name)
  wva:callback(function(value)
    if value == 'count' then
      count = count + 1
      wvb:eval('showText("From WebView '..name..' ('..tostring(count)..')");')
    elseif value == 'terminate' then
      wva:terminate()
      wvb:terminate()
    end
  end)
end

registerCallback(webviewA, webviewB, 'A')
registerCallback(webviewB, webviewA, 'B')

event:loop()
event:close()
