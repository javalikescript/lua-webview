(function() {

  function directoryFirst(fa, fb) {
    var da = fa.isDirectory;
    var db = fb.isDirectory;
    return da === db ? 0 : (da ? -1 : 1);
  }

  function filterFiles(files, showAll, contains) {
    var containsLowerCase = contains && contains.toLowerCase();
    return files.filter(function(file) {
      if (!showAll && file.name.charAt(0) === '.' && file.name !== '..') {
        return false;
      }
      return file.isDirectory || !containsLowerCase || file.name.toLowerCase().indexOf(containsLowerCase) >= 0;
    })
  }

  function fileList(path, useFetch, callback) {
    if (useFetch) {
      if (webview && webview.fileList) {
        webview.fileList(path, callback);
      } else {
        callback('webview.fileList is not available');
      }
    } else {
      fetch('rest/listFiles', {
        method: 'POST',
        headers: {
          "Content-Type": "text/plain"
        },
        body: path
      }).then(function(response) {
        return response.json();
      }).then(function(list) {
        callback(null, list);
      }, function(reason) {
        callback(reason || 'Unknown error');
      });
    }
  }

  var FileChooserDialog = Vue.component('file-chooser-dialog', {
    template: '<div class="file-chooser-dialog">' +
    '<div class="file-chooser-flex-row">' +
    '  <input type="text" v-model="inputPath" v-on:keyup="setPath(inputPath)" class="file-chooser-flex-row-content" />' +
    '  <button v-on:click="showSettings = !showSettings">&#x2699;</button>' +
    '</div>' +
    '<div class="file-chooser-content" style="overflow: auto;">' +
    '  <ul>' +
    '    <li v-for="file in filteredList" v-on:click="onFilePressed(file)">' +
    '      <input type="checkbox" v-model="file.selected" :disabled="!file.selectable">' +
    '      <span :class="[\'file\', file.isDirectory ? \'file-chooser-directory\' : \'\']">{{ file.name }}</span>' +
    '    </li>' +
    '  </ul>' +
    '</div>' +
    '<div v-if="showSettings" class="file-chooser-flex-row">' +
    '  <button v-on:click="refresh()">Refresh</button>' +
    '  <span>Filter:</span>' +
    '  <input type="text" v-model="extention" class="file-chooser-flex-row-content" />' +
    '  <input type="checkbox" v-model="showAll" />' +
    '  <span>Show All</span>' +
    '</div>' +
    '<div class="file-chooser-footer file-chooser-flex-row">' +
    '  <input type="text" v-model="name" v-show="save" class="file-chooser-flex-row-content" />' +
    '  <button v-on:click="done()">{{ label }}</button>' +
    '  <button v-if="showCancel" v-on:click="cancel()">Cancel</button>' +
    '</div></div>',
    data: function() { return {
      extention: '',
      inputPath: '',
      name: '',
      path: '',
      files: [],
      label: 'Open',
      multiple: false,
      save: false,
      directory: false,
      showAll: false,
      showCancel: true,
      showSettings: false,
      fetch: false
    }; },
    methods: {
      onFilePressed: function(file) {
        if (file.isDirectory) {
          this.setPath(this.path + '/' + file.name);
          return;
        }
        if (!this.multiple) {
          this.files.forEach(function(f) { 
            if (f !== file) {
              f.selected = false;
            }
          });
        }
        if (!this.directory) {
          if (this.save) {
            this.name = file.name;
          }
          file.selected = !file.selected;
        }
      },
      setPath: function(path) {
        if (this.path !== path) {
          this.list(path);
        }
      },
      refresh: function() {
        if (this.save) {
          this.multiple = false;
        }
        this.list(this.path !== '' ? this.path : '.')
      },
      list: function(path) {
        var fc = this;
        fileList(path, this.fetch, function(reason, files) {
          if (files) {
            var path = files.shift();
            fc.show(path, files);
          } else {
            fc.error(reason);            
          }
        });
      },
      error: function(message) {
        console.error('file-chooser error', message);
        this.$emit('selected', []);
      },
      cancel: function() {
        this.$emit('selected', []);
      },
      done: function() {
        var files;
        if (this.directory) {
          files = [];
        } else if (this.save) {
          files = [this.name];
        } else {
          files = this.files.filter(function(file) {
            return file.selected;
          }).map(function(file) {
            return file.name;
          });
        }
        files.unshift(this.path)
        this.$emit('selected', files)
      },
      show: function(path, files) {
        this.inputPath = path;
        this.path = path;
        if (!Array.isArray(files)) {
          files = [];
        }
        files.forEach(function(file) {
          file.selected = false;
          file.selectable = true;
        });
        this.files = files;
      }
    },
    computed: {
      filteredList: function () {
        var files = filterFiles(this.files, this.showAll, this.extention);
        files.sort(directoryFirst);
        return files;
      }
    }
  });

  FileChooserDialog.show = function(vm, options) {
    var fileChooser = new FileChooserDialog();
    fileChooser.$mount();
    if (typeof options === 'object') {
      for (var k in options) {
        fileChooser[k] = options[k];
      }
    }
    vm.$el.appendChild(fileChooser.$el);
    fileChooser.$on('selected', function(files) {
      vm.$el.removeChild(fileChooser.$el);
      fileChooser.$destroy();
      fileChooser = null;
    });
    return fileChooser;
  }

  Vue.component('file-chooser-input', {
    template: '<span>' +
    '<input :placeholder="placeholder" :size="size" list="file-chooser-input-list"' +
    '  v-on:click="clean()" v-on:input="nameChanged()" v-model="name" :title="path" />' +
    '<datalist id="file-chooser-input-list">' +
    '  <option v-for="file in filteredList" :value="file.name" />' +
    '</datalist></span>',
    data: function() { return {
      name: '',
      path: '',
      files: [],
      size: 40,
      fetch: false
    }; },
    methods: {
      nameChanged: function() {
        console.info('nameChanged() "' + this.name + '"');
        var value = this.name;
        if (this.path === '') {
          this.list('.');
          return;
        }
        if (value === '') {
          return;
        }
        for (var i = 0; i < this.files.length; i++) {
          var file = this.files[i];
          if (file.isDirectory && file.name === value) {
            this.list(this.path + '/' + file.name);
            break;
          }
        }
      },
      clean: function() {
        if (this.path === '') {
          this.list('.');
        } else if (this.name !== '') {
          console.info('clean() "' + this.path + '"');
          this.name = '';
        }
      },
      refresh: function() {
        this.list(this.path !== '' ? this.path : '.')
      },
      list: function(path) {
        console.info('list("' + path + '")');
        var fc = this;
        fileList(path, this.fetch, function(reason, files) {
          if (files) {
            var path = files.shift();
            fc.show(path, files);
          } else {
            this.error(reason);            
          }
        });
      },
      error: function(message) {
        console.error('file-chooser error', message);
        this.$emit('selected', []);
      },
      show: function(path, files) {
        console.info('show("' + path + '")');
        this.path = path;
        if (!Array.isArray(files)) {
          files = [];
        }
        this.files = files;
        this.name = '';
      }
    },
    computed: {
      filteredList: function () {
        var files = filterFiles(this.files);
        files.sort(directoryFirst);
        return files;
      },
      placeholder: function() {
        if (this.path) {
          return this.path.length <= this.size ? this.path : '...' + this.path.slice(3-this.size);
        }
        return 'Click to browse';
      }
    }
  });

})();