/*
This script triggers the webview launcher initialisation sequence.
By default the initialisation is done on first load, this script provides support for navigation and page reload.
Lua code in HTML must support multiple executions as well as onWebviewInitalized handler.
*/
(function() {
  var timeoutDelay = 1;

  function handleLoad() {
    if ((typeof window.external !== 'object') || (typeof window.external.invoke !== 'function')) {
      if (timeoutDelay > 30000) {
        throw 'window.external is not available';
      }
      setTimeout(handleLoad, timeoutDelay); // Let external.invoke be registered
      timeoutDelay = timeoutDelay * 2;
    } else if (typeof window.webview !== 'object') {
      window.external.invoke(':init:');
    }
  }

  if (document.readyState === 'complete') {
    handleLoad();
  } else {
    window.addEventListener('load', handleLoad);
  }
})();
