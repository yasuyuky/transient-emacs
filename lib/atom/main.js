/* global atom document:true */

const { KillRing } = require('../kill-ring');
const Searcher = require('./searcher');
const SelectList = require('atom-select-list');
const clipboardy = require('clipboardy');

module.exports = {
  config: {
    useLegacySearch: {
      type: 'boolean',
      default: true,
    },
    inputControlCharacter: {
      type: 'boolean',
      default: false,
    },
    killRing: {
      type: 'object',
      properties: {
        persistent: {
          type: 'boolean',
          default: true,
        },
        length: {
          type: 'integer',
          default: 10,
          minimum: 1,
        },
      },
    },
  },

  killring: null,
  commands: null,
  eventListeners: [],
  editorViews: [],
  addTextEditorListener: null,
  isUserCommand: true,
  searcher: null,

  activate: state => {
    module.exports.isUserCommand = true;
    module.exports.searcher = new Searcher();

    module.exports.commands = atom.commands.add('atom-text-editor', {
      'emacs:cancel': () => module.exports.cancel(),
      'emacs:set-mark': () => module.exports.setMark(),
      'emacs:yank': () => module.exports.yank(),
      'emacs:kill': () => module.exports.kill(),
      'emacs:show-kill-ring': () => module.exports.showKillRing(),
      'emacs:kill-region': () => module.exports.killRegion(),
      'emacs:copy-region': () => module.exports.copyRegion(),
      'emacs:kill-backward-word': () => module.exports.killBackwardWord(),
      'emacs:kill-region-or-backward-word': () => module.exports.killRegionOrBackwardWord(),
      'emacs:isearch': e => module.exports.searcher.search(e, true, false),
      'emacs:backward-isearch': e => module.exports.searcher.search(e, false, false),
      'emacs:isearch-regexp': e => module.exports.searcher.search(e, true, true),
      'emacs:backward-isearch-regexp': e => module.exports.searcher.search(e, false, true),
      'emacs:backspace': () => module.exports.backspace(),
    });

    const addEditorEventListner = editor => {
      module.exports.eventListeners.push(
        editor.onDidChangeCursorPosition(() => {
          if (module.exports.isUserCommand && module.exports.killring)
            module.exports.killring.seal();
          if (module.exports.searcher.isUserCommand && module.exports.searcher)
            module.exports.searcher.deactivateISearch();
        })
      );
      let editorView = atom.views.getView(editor);
      module.exports.clickListener = () => {
        editorView.classList.remove('transient-marked');
        const findAndReplace = atom.packages.getActivePackage('find-and-replace');
        if (
          findAndReplace &&
          findAndReplace.mainModule.findPanel &&
          findAndReplace.mainModule.findPanel.isVisible()
        )
          findAndReplace.mainModule.findPanel.hide();
      };
      editorView.addEventListener('click', module.exports.clickListener);
      module.exports.editorViews.push(editorView);
    };

    atom.workspace.getTextEditors().forEach(addEditorEventListner);
    module.exports.addTextEditorListener = atom.workspace.onDidAddTextEditor(event =>
      addEditorEventListner(event.textEditor)
    );

    module.exports.searcher.addIsearchCommands();
    if (atom.config.get('transient-emacs.inputControlCharacter'))
      module.exports.addInputCtrlsCommands();

    module.exports.killring =
      state && state.killring
        ? atom.deserializers.deserialize(state.killring)
        : new KillRing([], clipboardy.read, clipboardy.write);
  },

  deserializeKillRing: ({ buffer }) => new KillRing(buffer),

  addInputCtrlsCommands: () => {
    let inputCtrlKeybindings = {};
    let inputCtrlCommandMap = {};
    let inputCtrlSelector = 'atom-text-editor';
    inputCtrlKeybindings[inputCtrlSelector] = {};
    for (let code = 0; code < 32; code++) {
      const command = 'emacs:input-ctrl-' + code;
      const keybind = 'ctrl-q ctrl-' + String.fromCharCode(code + (0 < code < 27 ? 96 : 64));
      inputCtrlKeybindings[inputCtrlSelector][keybind] = command;
      inputCtrlCommandMap[command] = () => module.exports.enterControlCharacter(code);
    }
    module.exports.inputCtrlKeymaps = atom.keymaps.add(
      'emacs-input-ctrl-keymap',
      inputCtrlKeybindings,
      0
    );
    if (inputCtrlCommandMap)
      module.exports.inputCtrlCommands = atom.commands.add('atom-text-editor', inputCtrlCommandMap);
  },

  deactivate: () => {
    if (module.exports.commands) module.exports.commands.dispose();
    if (module.exports.inputCtrlCommands) module.exports.inputCtrlCommands.dispose();
    module.exports.eventListeners.forEach(listener => listener.dispose());
    module.exports.eventListeners = [];
    module.exports.editorViews.forEach(view =>
      view.removeEventListener('click', module.exports.clickListener)
    );
    module.exports.editorViews = [];
    if (module.exports.addTextEditorListener) module.exports.addTextEditorListener.dispose();
    if (module.exports.searcher) module.exports.searcher.deactivate();
    delete module.exports.searcher;
    delete module.exports.killring;
  },

  serialize: () => {
    const conf = atom.config.get('transient-emacs.killRing');
    const buffer = conf.persistent ? module.exports.killring.buffer : [];
    return { deserializer: 'KillRing', buffer: buffer };
  },

  cancel: () => {
    const editor = atom.workspace.getActiveTextEditor();
    if (module.exports.searcher.deactivateISearch()) return;
    if (module.exports.clearSelections(editor)) return;
    if (module.exports.consolidateSelections(editor)) return;
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'core:cancel');
  },

  clearSelections: editor =>
    editor.getSelections().some(selection => (!selection.isEmpty() ? selection.clear() : false)),

  backspace: () => {
    if (module.exports.searcher.isearchTile) return module.exports.searcher.backspace();
    atom.commands.dispatch(document.activeElement, 'core:backspace');
  },

  getEditor: () => {
    const pane = atom.workspace.getActivePane();
    const editor = atom.workspace.getActiveTextEditor();
    if (editor == pane.activeItem) return editor;
  },

  consolidateSelections: editor => {
    const cursors = editor.getCursors();
    if (cursors.length > 1) {
      editor.setCursorBufferPosition(editor.getCursorBufferPositions()[0]);
      return true;
    }
    return false;
  },

  setMark: () => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    atom.views.getView(editor).classList.toggle('transient-marked');
    editor.getCursors().forEach(cursor => cursor.clearSelection());
  },

  killRegionOrBackwardWord: () => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    if (editor.getLastSelection().isEmpty()) module.exports.killBackwardWord();
    else module.exports.killRegion();
  },

  pushRegionToKillring: editor => {
    atom.views.getView(editor).classList.remove('transient-marked');
    const texts = editor.getSelections().map(s => s.getText());
    module.exports.killring.push(texts);
    module.exports.killring.seal();
  },

  killRegion: () => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    module.exports.pushRegionToKillring(editor);
    editor.transact(() => editor.getSelections().forEach(s => (s.isEmpty() ? false : s.delete())));
  },

  copyRegion: () => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    module.exports.pushRegionToKillring(editor);
    editor.getCursors().forEach(cursor => cursor.clearSelection());
  },

  killBackwardWord: () => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    module.exports.isUserCommand = false;
    editor.transact(() => {
      editor.selectToBeginningOfWord();
      const texts = editor.getSelections().map(s => s.getText());
      module.exports.killring.put(texts, false);
      editor.getSelections().forEach(s => (s.isEmpty() ? false : s.delete()));
    });
    module.exports.isUserCommand = true;
  },

  kill: () => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    module.exports.isUserCommand = false;
    editor.transact(() => {
      editor.selectToEndOfLine();
      const texts = editor.getSelections().map(s => s.getText() || '\n');
      module.exports.killring.put(texts, true);
      editor.delete();
    });
    module.exports.isUserCommand = true;
  },

  yank: () => module.exports.yankTexts(module.exports.killring.top()),

  showKillRing: () => {
    module.exports.killring.updateBuffer();
    const killRingList = new SelectList({
      items: module.exports.killring.buffer.map((ss, i) => ({
        label: `${i}\t${ss.join('\\n')}`,
        value: ss,
      })),
      elementForItem: item => {
        var element = document.createElement('li');
        element.innerHTML = item.label;
        return element;
      },
      filterKeyForItem: item => item.label,
      didConfirmSelection: item => {
        module.exports.hideKillRing();
        module.exports.yankTexts(item.value);
      },
      didCancelSelection: () => module.exports.hideKillRing(),
    });
    module.exports.killring.lastFocusedElement = document.activeElement;
    module.exports.killring.panel = atom.workspace.addModalPanel({ item: killRingList });
    killRingList.focus();
  },

  hideKillRing: () => {
    if (module.exports.killring.panel) module.exports.killring.panel.destroy();
    if (module.exports.killring.lastFocusedElement) {
      module.exports.killring.lastFocusedElement.focus();
      module.exports.killring.lastFocusedElement = null;
    }
  },

  yankTexts: texts => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    editor.transact(() => {
      const cursors = editor.getCursors();
      if (texts && cursors.length == texts.length)
        cursors.forEach((c, i) => c.selection.insertText(texts[i]));
      else if (texts) cursors.forEach(c => c.selection.insertText(texts.join('\n')));
    });
  },

  enterControlCharacter: code => {
    const editor = module.exports.getEditor();
    if (!editor) return;
    editor.transact(() => editor.insertText(String.fromCharCode(code)));
  },
};
