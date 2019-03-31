/* global atom document:true */
const clipboard = atom.clipboard;
const SelectList = require('atom-select-list');

module.exports = class KillRing {
  constructor(buffer) {
    this.buffer = buffer;
    this.sealed = true;
  }

  serialize() {
    const conf = atom.config.get('transient-emacs.killRing');
    const buffer = conf.persistent ? this.buffer : [];
    return { deserializer: 'KillRing', buffer: buffer };
  }

  put(texts, forward = true) {
    if (this.sealed) this.push(texts);
    else this.update(texts, forward);
  }

  seal() {
    this.sealed = true;
  }

  push(texts) {
    this.buffer.unshift(texts);
    clipboard.write(texts.join('\n'));
    const conf = atom.config.get('transient-emacs.killRing');
    while (this.buffer.length > conf.length) this.buffer.pop();
    this.sealed = false;
  }

  update(texts, forward) {
    const lasts = this.buffer.shift();
    const newTexts = texts.map((t, i) =>
      forward ? lasts[i] + (t ? t : '') : (t ? t : '') + lasts[i]
    );
    this.push(newTexts);
  }

  top() {
    this.updateBuffer();
    return this.buffer[0];
  }

  updateBuffer() {
    const lasts = this.buffer[0];
    if (clipboard.md5(lasts ? lasts.join('\n') : '') != clipboard.md5(clipboard.read()))
      this.push(clipboard.read().split('\n'));
  }
};
