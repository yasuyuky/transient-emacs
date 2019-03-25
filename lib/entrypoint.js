const path = require('path');
const requireCache = new Set(Object.keys(require.cache).map(k => path.basename(k, '.js')));

if (requireCache.has('atom')) {
  const transientEmacsAtom = require('./transient-emacs');
  for (var prop in transientEmacsAtom) {
    exports[prop] = transientEmacsAtom[prop];
  }
} else {
  const transientEmacsCode = require('./code/extension');
  for (var prop in transientEmacsCode) {
    exports[prop] = transientEmacsCode[prop];
  }
}
