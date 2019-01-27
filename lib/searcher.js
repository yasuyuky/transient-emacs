/* global atom document Text:true */
const Range = require('atom').Range;
const SEARCH_CLASS = 'searching';

module.exports = class Searcher {
  constructor() {
    this.isUserCommand = true;
    this.isearchWord = '';
    this.isearchLast = '';
    this.isearchTile = null;
    this.isforward = true;
  }

  deactivate() {
    if (this.isearchCommands) this.isearchCommands.dispose();
    if (this.isearchKeymaps) this.isearchKeymaps.dispose();
  }

  incrementSearch(c) {
    const editor = this.getEditor();
    if (!editor || editor.mini) return;
    if (atom.views.getView(editor).classList.contains(SEARCH_CLASS)) {
      this.isearchWord += c;
      this.searchNext(this.isearchWord);
    }
  }

  activateIsearch(forward) {
    const editor = this.getEditor();
    if (!editor || editor.mini) return;
    atom.views.getView(editor).classList.add(SEARCH_CLASS);
    this.isforward = forward;
    if (this.isearchTile && !this.isearchWord) this.isearchWord = this.isearchLast;
    else this.isearchWord = editor.getSelectedText();
    this.searchNext(this.isearchWord);
  }

  deactivateISearch() {
    if (this.isearchTile) {
      this.isearchTile.destroy();
      this.isearchTile = null;
      this.isearchLast = this.isearchWord;
      this.isearchWord = '';
      const editor = this.getEditor();
      if (!editor || editor.mini) return;
      atom.views.getView(editor).classList.remove(SEARCH_CLASS);
      return true;
    }
  }

  updateStatusbar(word, found) {
    const statusBar = document.querySelector('status-bar');
    const spanClass = found ? 'found' : 'not-found';
    if (statusBar) {
      const prefix = this.isforward ? 'isearch:' : 'backword-isearch:';
      const el = (tag, className, children) => {
        let e = document.createElement(tag);
        e.className = className;
        children.forEach(c => e.appendChild(c));
        return e;
      };
      const tile = el('div', 'isearch inline-block', [
        el('span', spanClass, [new Text(prefix)]),
        el('span', spanClass + ' isearch-text', [new Text(word)])
      ]);
      if (this.isearchTile) this.isearchTile.destroy();
      this.isearchTile = statusBar.addLeftTile({ item: tile, priority: 10 });
    }
  }

  createRegExp(word) {
    const escaped = word
      .split('')
      .map(c => (c == '\\' ? '\\\\' : '[' + c + ']'))
      .join('');
    return new RegExp(escaped);
  }

  selectScroll(editor, targets) {
    this.isUserCommand = false;
    if (targets.length) editor.setSelectedBufferRanges(targets, { flash: true });
    editor.scrollToCursorPosition();
    this.isUserCommand = true;
  }

  searchNext(word, silent) {
    if (!silent) this.updateStatusbar(word, true);
    if (!word) return;
    const editor = this.getEditor();
    if (!editor || editor.mini) return;
    const selections = editor
      .getSelectedBufferRanges()
      .map(sel => this.getSelections(editor, sel, word, silent));
    this.selectScroll(editor, selections);
  }

  getSelections(editor, sel, word, silent) {
    const re = this.createRegExp(word);
    const bufferEnd = editor.getBuffer().getEndPosition();
    const selectedText = editor.getTextInBufferRange(sel);
    const start = (selectedText == this.isearchWord) ^ this.isforward ? sel.start : sel.end;
    const targetRanges = [new Range(start, bufferEnd), new Range([0, 0], start)];
    if (!this.isforward) targetRanges.reverse();
    const selectedRange = targetRanges.reduce(
      (selected, targetRange) => this.updateselectedRange(selected, editor, re, targetRange),
      null
    );
    if (selectedRange) return selectedRange;
    if (!silent) this.updateStatusbar(word, false);
    return new Range(sel.end, sel.end);
  }

  updateselectedRange(selected, editor, re, targetRange) {
    if (selected) return selected;
    let newRange = null;
    const selector = ({ range, stop }) => {
      newRange = range;
      stop();
    };
    if (this.isforward) editor.scanInBufferRange(re, targetRange, selector);
    else editor.backwardsScanInBufferRange(re, targetRange, selector);
    return newRange;
  }

  addIsearchCommands() {
    let searchKeybindings = {};
    let isearchCommandMap = {};
    const searchSelector = 'atom-workspace atom-text-editor.searching';
    searchKeybindings[searchSelector] = {};
    for (var code = 32; code < 126; code++) {
      const s = String.fromCharCode(code);
      const command = 'emacs:input-isearch-' + code;
      searchKeybindings[searchSelector][s == ' ' ? 'space' : s] = command;
      isearchCommandMap[command] = () => this.incrementSearch(s);
    }
    this.isearchKeymaps = atom.keymaps.add('emacs-isearch-keymap', searchKeybindings, 0);
    this.isearchCommands = atom.commands.add('atom-text-editor', isearchCommandMap);
  }

  search(e, forward, useRegex) {
    if (atom.config.get('transient-emacs').useLegacySearch) this.activateIsearch(forward);
    else {
      const findAndReplace = atom.packages.getLoadedPackage('find-and-replace');
      if (findAndReplace) this.searchWithFindAndReplace(e, forward, useRegex, findAndReplace);
      else this.activateIsearch(forward);
    }
  }

  searchWithFindAndReplace(e, forward, useRegex, findAndReplace) {
    if (findAndReplace.mainModule.findPanel && findAndReplace.mainModule.findPanel.isVisible()) {
      if (forward) atom.commands.dispatch(e.target, 'find-and-replace:find-next');
      else atom.commands.dispatch(e.target, 'find-and-replace:find-previous');
      findAndReplace.mainModule.findView.findEditor.element.focus();
    } else {
      if (findAndReplace.mainModule.findOptions)
        findAndReplace.mainModule.findOptions.set({ useRegex: useRegex });
      const tempListener = atom.packages.onDidActivatePackage(pkg => {
        if (pkg.name == 'find-and-replace') {
          pkg.mainModule.findOptions.set({ useRegex: useRegex });
          tempListener.dispose();
        }
      });
      atom.commands.dispatch(e.target, 'find-and-replace:show');
    }
  }

  backspace() {
    if (this.isearchWord.length) {
      this.isearchWord = this.isearchWord.slice(0, -1);
      this.searchNext(this.isearchWord);
    } else this.deactivateISearch();
    return false;
  }

  getEditor() {
    const pane = atom.workspace.getActivePane();
    const editor = atom.workspace.getActiveTextEditor();
    if (editor == pane.activeItem) return editor;
  }
};
