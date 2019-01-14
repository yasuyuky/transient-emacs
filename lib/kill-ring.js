/* global atom:true */
const _ = require('underscore-plus');
const clipboard = atom.clipboard;

module.exports =
class KillRing {
  constructor(limit=16) {
    this.buffer = [];
    this.sealed = true;
    this.limit = limit;
  }

  put(texts, forward=true) {
    if(this.sealed)
      this.push(texts);
    else
      this.update(texts, forward);
  }

  seal() {
    this.sealed = true;
  }

  push(texts) {
    this.buffer.push(texts);
    clipboard.write(texts.join('\n'));
    if(this.buffer.length > this.limit) this.buffer.shift();
    this.sealed = false;
  }

  update(texts, forward) {
    const lasts = this.buffer.pop();
    const newTexts = texts.map((t,i) => forward ? lasts[i]+(t?t:'') : (t?t:'')+lasts[i]);
    this.push(newTexts);
  }

  top() {
    return _.last(this.list());
  }

  list() {
    const lasts = _.last(this.buffer);
    const last = lasts?lasts.join('\n'):'';
    if(clipboard.md5(last) != clipboard.signatureForMetadata)
      this.push(clipboard.read());
    return this.buffer;
  }

};
