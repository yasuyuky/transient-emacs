import clipboardy = require('clipboardy');

export class KillRing {
  buffer: string[][];
  sealed: boolean;
  readClipboard: () => Thenable<string>;
  writeClipboard: (s: string) => Thenable<void>;

  constructor(
    buffer: string[][],
    readClipboard: null | (() => Thenable<string>),
    writeClipboard: null | ((s: string) => Thenable<void>)
  ) {
    this.buffer = buffer;
    this.sealed = true;
    this.readClipboard = readClipboard ? readClipboard : clipboardy.read;
    this.writeClipboard = writeClipboard ? writeClipboard : clipboardy.write;
  }

  put(texts: string[], forward: boolean = true) {
    if (this.sealed) this.push(texts);
    else this.update(texts, forward);
  }

  seal() {
    this.sealed = true;
  }

  push(texts: string[]) {
    this.buffer.unshift(texts);
    try {
      this.writeClipboard(texts.join('\n'));
    } catch (e) {
      console.log(e);
    }
    while (this.buffer.length > 10) this.buffer.pop();
    this.sealed = false;
  }

  update(texts: string[], forward: boolean) {
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
    const laststr = lasts ? lasts.join('\n') : '';
    try {
      this.readClipboard().then(s => {
        if (laststr !== s) this.push(s.split('\n'));
      });
    } catch (e) {
      console.log(e);
    }
  }
}
