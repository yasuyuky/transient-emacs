/* global atom document:true */
import ncp = require('copy-paste');

export class KillRing {
  buffer: Array<Array<string>>;
  sealed: boolean;

  constructor(buffer: Array<Array<string>>) {
    this.buffer = buffer;
    this.sealed = true;
  }

  put(texts: Array<string>, forward: boolean = true) {
    if (this.sealed) this.push(texts);
    else this.update(texts, forward);
  }

  seal() {
    this.sealed = true;
  }

  push(texts: Array<string>) {
    this.buffer.unshift(texts);
    ncp.copy(texts.join('\n'));
    while (this.buffer.length > 10) this.buffer.pop();
    this.sealed = false;
  }

  update(texts: Array<string>, forward: boolean) {
    const lasts = this.buffer.shift() || [];
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
    if (lasts ? lasts.join('\n') : '' !== ncp.paste()) this.push(ncp.paste().split('\n'));
  }
}
