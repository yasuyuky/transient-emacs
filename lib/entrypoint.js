const path = require('path');
const requireCache = new Set(Object.keys(require.cache).map(k => path.basename(k, '.js')));

const mainModule = requireCache.has('atom') ? require('./atom/main') : require('./code/extension');
for (var prop in mainModule) {
  exports[prop] = mainModule[prop];
}
