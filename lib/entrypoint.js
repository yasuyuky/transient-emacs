const path = require('path');
const requireCache = new Set(Object.keys(require.cache).map(k => path.basename(k, '.js')));

const mainModule = require(requireCache.has('atom') ? './atom/main' : './code/extension');
for (const p in mainModule) exports[p] = mainModule[p];
