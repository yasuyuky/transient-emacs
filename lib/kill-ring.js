/* global atom document:true */
const clipboard = atom.clipboard;
const SelectList = require('atom-select-list');

module.exports =
class KillRing {
  constructor(buffer) {
    this.buffer = buffer;
    this.sealed = true;
  }

  serialize() {
    const conf = atom.config.get('transient-emacs.killRing');
    const buffer = conf.persistent ? this.buffer : [];
    return {deserializer: 'KillRing', buffer: buffer};
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
    const conf = atom.config.get('transient-emacs.killRing');
    while(this.buffer.length > conf.length) this.buffer.shift();
    this.sealed = false;
  }

  update(texts, forward) {
    const lasts = this.buffer.pop();
    const newTexts = texts.map((t,i) => forward ? lasts[i]+(t?t:'') : (t?t:'')+lasts[i]);
    this.push(newTexts);
  }

  top() {
    this.updateBuffer();
    return this.buffer.slice(-1)[0];
  }

  show(onSelect) {
    this.updateBuffer();
    const killRingList = new SelectList({
      items: this.buffer.map(ss => ({label: ss.join('\n'), value:ss})),
      elementForItem: item => {
        var element = document.createElement('li');
        element.innerHTML = item.label;
        return element;
      },
      filterKeyForItem: item => item.label,
      didConfirmSelection: item => {
        this.hide();
        onSelect(item);
      },
      didCancelSelection: () => this.hide()
    });
    this.lastFocusedElement = document.activeElement;
    this.panel = atom.workspace.addModalPanel({item: killRingList});
    killRingList.focus();
  }

  hide() {
    if (this.panel)
      this.panel.destroy();
    if (this.lastFocusedElement) {
      this.lastFocusedElement.focus();
      this.lastFocusedElement = null;
    }
  }

  updateBuffer() {
    const lasts = this.buffer.slice(-1)[0];
    if(clipboard.md5(lasts?lasts.join('\n'):'') != clipboard.md5(clipboard.read()))
      this.push(clipboard.read().split('\n'));
  }

};
