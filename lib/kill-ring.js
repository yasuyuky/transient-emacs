"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.KillRing = void 0;
/* global atom document:true */
const clipboardy = require("clipboardy");
class KillRing {
    constructor(buffer) {
        this.buffer = buffer;
        this.sealed = true;
    }
    put(texts, forward = true) {
        if (this.sealed)
            this.push(texts);
        else
            this.update(texts, forward);
    }
    seal() {
        this.sealed = true;
    }
    push(texts) {
        this.buffer.unshift(texts);
        clipboardy.writeSync(texts.join('\n'));
        while (this.buffer.length > 10)
            this.buffer.pop();
        this.sealed = false;
    }
    update(texts, forward) {
        const lasts = this.buffer.shift() || [];
        const newTexts = texts.map((t, i) => forward ? lasts[i] + (t ? t : '') : (t ? t : '') + lasts[i]);
        this.push(newTexts);
    }
    top() {
        this.updateBuffer();
        return this.buffer[0];
    }
    updateBuffer() {
        const lasts = this.buffer[0];
        const laststr = lasts ? lasts.join('\n') : '';
        const read = clipboardy.readSync();
        if (laststr !== read)
            this.push(read.split('\n'));
    }
}
exports.KillRing = KillRing;
//# sourceMappingURL=kill-ring.js.map