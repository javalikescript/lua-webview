var filters = {
  all: function (list) {
    return list;
  },
  visible: function (list) {
    return list.filter(function(item) {
      return item.visible;
    });
  },
  hidden: function (list) {
    return list.filter(function(item) {
      return !item.visible;
    });
  }
}

var main = new Vue({
  el: '#main',
  data: {
    list: [],
    search: '',
    seen: false,
    visibility: 'all'
  },
  methods: {
    refresh: function() {
      this.value = '0';
    }
  },
  computed: {
    filteredWindows: function () {
      var searchLowerCase = this.search.toLowerCase();
      return filters[this.visibility](this.list.filter(function(item) {
        return item.text.toLowerCase().indexOf(searchLowerCase) >= 0;
      }));
    }
  }
});

function addWindows(list, clean) {
  main.list = clean ? list : main.list.concat(list);
  main.list.sort(function(a, b) {
    return a.text === b.text ? 0 : (a.text > b.text ? 1 : -1);
  })
}

try {
  window.external.invoke([
    "evalLua:",
    "context.winexp = require('examples/modules/winexp')",
    "local webviewLib = require('webview')",
    "context.winexp.lookForCurrentWindow()",
    "if context.winexp.restoreHiddenSession() then",
    " webviewLib.terminate(webview, true)",
    "else",
    " webviewLib.title(webview, 'Window Explorer')",
    "end"
  ].join('\n'));
  window.external.invoke("+listWindows:callJs('addWindows', context.winexp.listWindowsInfos(), true)");
  window.external.invoke("*toggleWindow:context.winexp.toggleWindowByHandle(value)");
  window.external.invoke("*foregroundWindow:context.winexp.foregroundWindowByHandle(value)");
  window.setTimeout(function() {
    window.external.invoke('listWindows:')
  }, 0);
} catch(e) {
  console.error('fail to register backend functions', e);
  // sample data
  main.list = [
    {handle: 123, text: 'Title', visible: false, width: 100, height: 100,left: 0, top: 0},
    {handle: 123, text: 'Hidden title', visible: true, width: 100, height: 100,left: 0, top: 0},
    {handle: 456, text: 'long long long long long long long long long long long long long long long long title', visible: true, width: 100, height: 100,left: 0, top: 0}
  ];
}
