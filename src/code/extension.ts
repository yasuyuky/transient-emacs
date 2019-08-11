import * as vscode from 'vscode';
import { TextEditor, Selection, Position } from 'vscode';
import { KillRing } from '../kill-ring';

var markSet: boolean = false;
var isUserCommand: boolean = true;
var killRing: KillRing = new KillRing([]);

export function activate(context: vscode.ExtensionContext) {
  let commands = new Map<string, (...args: any[]) => any>([
    ['transient.cancel', cancel],
    ['transient.setMark', setMark],
    ['transient.unsetMark', unsetMark],
    ['transient.yank', yank],
    ['transient.kill', kill],
    ['transient.killRegion', killRegion],
    ['transient.killRegionOrBackwardWord', killRegionOrBackwardWord],
    ['transient.killBackwardWord', killBackwardWord],
    ['transient.showKillRing', showKillRing],
    ['transient.copyRegion', copyRegion],
    ['cursorParagraphUp', cursorParagraphUp],
    ['cursorParagraphDown', cursorParagraphDown],
    ['cursorParagraphUpSelect', cursorParagraphUpSelect],
    ['cursorParagraphDownSelect', cursorParagraphDownSelect]
  ]);
  commands.forEach((func, key) =>
    context.subscriptions.push(vscode.commands.registerTextEditorCommand(key, func))
  );

  let moves = [
    'cursorLeft',
    'cursorRight',
    'cursorUp',
    'cursorDown',
    'cursorHome',
    'cursorEnd',
    'cursorPageUp',
    'cursorPageDown',
    'cursorTop',
    'cursorBottom',
    'cursorWordLeft',
    'cursorWordRight',
    'cursorParagraphUp',
    'cursorParagraphDown'
  ];

  moves.forEach(move => {
    let key = 'transient.' + move;
    let f = () => vscode.commands.executeCommand(markSet ? move + 'Select' : move);
    let command = vscode.commands.registerTextEditorCommand(key, f);
    context.subscriptions.push(command);
  });

  context.subscriptions.push(
    vscode.window.onDidChangeTextEditorSelection(e => {
      if (isUserCommand) killRing.seal();
      if (e.textEditor.selection.isEmpty) vscode.commands.executeCommand('closeFindWidget');
    })
  );
}

export function deactivate() {}

function cursorParagraphDown(editor: TextEditor) {
  let end = editor.document.lineAt(editor.document.lineCount - 1).range.end;
  cursorParagraphMove(editor, l => l + 1, l => l < editor.document.lineCount, end, false);
}

function cursorParagraphDownSelect(editor: TextEditor) {
  let end = editor.document.lineAt(editor.document.lineCount - 1).range.end;
  cursorParagraphMove(editor, l => l + 1, l => l < editor.document.lineCount, end, true);
}

function cursorParagraphUp(editor: TextEditor) {
  cursorParagraphMove(editor, l => l - 1, l => l >= 0, new Position(0, 0), false);
}

function cursorParagraphUpSelect(editor: TextEditor) {
  cursorParagraphMove(editor, l => l - 1, l => l >= 0, new Position(0, 0), true);
}

function cursorParagraphMove(
  editor: TextEditor,
  next: (l: number) => number,
  limit: (l: number) => boolean,
  end: Position,
  select: boolean
) {
  const doc = editor.document;
  editor.selections = editor.selections.map(s => {
    var l = s.active.line;
    for (var flag = false; limit(l); l = next(l)) {
      if (!doc.lineAt(l).isEmptyOrWhitespace) flag = true;
      if (flag && doc.lineAt(l).isEmptyOrWhitespace) {
        const p = new Position(l, 0);
        return new Selection(select ? s.anchor : p, p);
      }
    }
    return new Selection(select ? s.anchor : end, end);
  });
  editor.revealRange(editor.selections[editor.selections.length - 1].with());
}

function cancel(editor: TextEditor) {
  if (markSet) {
    clearSelections(editor);
    unsetMark(editor);
    return;
  }
  if (clearSelections(editor)) return;
  if (consolidateSelections(editor)) return;
}

function clearSelections(editor: TextEditor): boolean {
  if (editor.selections.some(s => !s.isEmpty)) {
    editor.selections = editor.selections.map(s => new Selection(s.active, s.active));
    return true;
  }
  return false;
}

function consolidateSelections(editor: TextEditor): boolean {
  if (editor.selections.length > 1) {
    editor.selections = [editor.selection];
    editor.revealRange(editor.selection.with());
    return true;
  }
  return false;
}

function setMark(editor: TextEditor) {
  console.log('set mark');
  markSet = true;
}

function unsetMark(editor: TextEditor) {
  console.log('unset mark');
  markSet = false;
}

function killRegionOrBackwardWord(editor: TextEditor) {
  if (editor.selection.isEmpty) killBackwardWord(editor);
  else killRegion(editor);
}

function pushRegionToKillring(editor: TextEditor) {
  markSet = false;
  const texts = editor.selections.map(s => editor.document.getText(s));
  killRing.push(texts);
  killRing.seal();
}

function killRegion(editor: TextEditor) {
  pushRegionToKillring(editor);
  editor.edit(edit => editor.selections.forEach(s => (s.isEmpty ? false : edit.delete(s))));
}

function copyRegion(editor: TextEditor) {
  pushRegionToKillring(editor);
  editor.selections = editor.selections.map(s => new Selection(s.active, s.active));
}

function killBackwardWord(editor: TextEditor) {
  isUserCommand = false;
  editor
    .edit(edit => {
      editor.selections = editor.selections.map(s => {
        let wordRange = editor.document.getWordRangeAtPosition(s.active);
        if (wordRange && !wordRange.start.isEqual(s.active))
          return new Selection(wordRange.start, s.active);
        const delimExp = /[\\\[\]`~!\@@#\%\^\&*()-\=+{}\|\;\:\'\"\,.\<>\/\?\s]+/g;
        let delimRange = editor.document.getWordRangeAtPosition(s.active, delimExp);
        if (delimRange) return new Selection(delimRange.start, s.active);
        return s;
      });
      const texts = editor.selections.map(s => editor.document.getText(s));
      killRing.put(texts, false);
      editor.selections.forEach(s => (s.isEmpty ? false : edit.delete(s)));
    })
    .then(() => {
      isUserCommand = true;
    });
}

function kill(editor: TextEditor) {
  isUserCommand = false;
  editor
    .edit(edit => {
      editor.selections = editor.selections.map(s => {
        let line = editor.document.lineAt(s.active);
        if (line.isEmptyOrWhitespace)
          return new Selection(s.active, line.rangeIncludingLineBreak.end);
        return new Selection(s.active, line.range.end);
      });
      const texts = editor.selections.map(s => editor.document.getText(s));
      killRing.put(texts, true);
      editor.selections.forEach(s => (s.isEmpty ? false : edit.delete(s)));
    })
    .then(() => {
      isUserCommand = true;
    });
}

function yank(editor: TextEditor) {
  yankTexts(editor, killRing.top());
}

function showKillRing(editor: TextEditor) {
  killRing.updateBuffer();
  vscode.window
    .showQuickPick(killRing.buffer.map(ss => ss.join('\n')))
    .then(s => yankTexts(editor, (s || '').split('\n')));
}

function yankTexts(editor: TextEditor, texts: string[]) {
  editor
    .edit(edit => {
      const sels = editor.selections;
      if (texts && sels.length === texts.length) sels.forEach((s, i) => edit.replace(s, texts[i]));
      else if (texts) sels.forEach(s => edit.replace(s, texts.join('\n')));
    })
    .then(() => {
      editor.selections = editor.selections.map(s => new Selection(s.active, s.active));
    });
}
