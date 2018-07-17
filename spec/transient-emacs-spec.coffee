transient_emacs = require '../lib/transient-emacs'
{Pane} = require 'atom'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Transient Emacs", ->
  editor = null
  editorBackground = null
  editorView = null

  beforeEach ->
    transient_emacs.activate()
    waitsForPromise ->
      atom.workspace.open().then (e)-> editorBackground = e
      atom.workspace.open().then (e)-> editor = e

    runs ->
      editorView = atom.views.getView editor
      expect(editor.getText()).toBe ""
      editor.setText "foo bar\nbaz\n"
      expect(editor.getText()).toBe "foo bar\nbaz\n"


  describe "transient-emacs", ->
    it "set-mark", ->
      expect(editorView.classList.contains('transient-marked')).not.toBeTruthy()
      transient_emacs.setMark()
      expect(editorView.classList.contains('transient-marked')).toBeTruthy()

    it "kill and yank", ->
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.kill()
      expect(editor.getText()).toBe "\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"

    it "kill twice and yank twice", ->
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.kill()
      transient_emacs.kill()
      expect(editor.getText()).toBe "baz\n"
      transient_emacs.yank()
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nfoo bar\nbaz\n"

    it "kill, change editor, kill and yank twice", ->
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.kill()
      panes = atom.workspace.getPaneItems()
      expect(panes.length).toBe 2
      transient_emacs.kill()
      expect(editor.getText()).toBe "baz\n"
      transient_emacs.yank()
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nfoo bar\nbaz\n"

    it "kill, move, kill and yank", ->
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.kill()
      editor.setCursorBufferPosition [1, 0]
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.kill()
      expect(editor.getText()).toBe "baz\n"
      transient_emacs.yank()
      transient_emacs.yank()
      expect(editor.getText()).toBe "\n\nbaz\n"

    it "kill and yank with multi cursor", ->
      editor.setCursorBufferPosition [0, 0]
      editor.addCursorAtBufferPosition [1, 0]
      transient_emacs.kill()
      expect(editor.getText()).toBe "\n\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"

    it "kill, consolidate and yank with multi cursors", ->
      editor.setCursorBufferPosition [0, 0]
      editor.addCursorAtBufferPosition [1, 0]
      transient_emacs.kill()
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n\n"

    it "kill, consolidate and yank with inversed multi cursors", ->
      editor.setCursorBufferPosition [1, 0]
      editor.addCursorAtBufferPosition [0, 0]
      transient_emacs.kill()
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.yank()
      expect(editor.getText()).toBe "baz\nfoo bar\n\n"

    it "kill, consolidate, add cursor and yank with multi cursors", ->
      editor.setCursorBufferPosition [0, 0]
      editor.addCursorAtBufferPosition [1, 0]
      transient_emacs.kill()
      editor.setCursorBufferPosition [0, 0]
      editor.addCursorAtBufferPosition [1, 0]
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"

    it "kill-backword-word and yank twice", ->
      editor.setCursorBufferPosition [0, 7]
      transient_emacs.killBackwardWord()
      expect(editor.getText()).toBe "foo \nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo barbar\nbaz\n"

    it "kill-backword-word twice and yank twice", ->
      editor.setCursorBufferPosition [0, 7]
      transient_emacs.killBackwardWord()
      transient_emacs.killBackwardWord()
      expect(editor.getText()).toBe "\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo barfoo bar\nbaz\n"

    it "kill-backword-word 3 times and yank twice", ->
      editor.setCursorBufferPosition [0, 7]
      transient_emacs.killBackwardWord()
      transient_emacs.killBackwardWord()
      transient_emacs.killBackwardWord()
      expect(editor.getText()).toBe "\nbaz\n"
      transient_emacs.yank()
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo barfoo bar\nbaz\n"

    it "kill-backword-word, move, kill-backword-word and yank twice", ->
      editor.setCursorBufferPosition [0, 7]
      transient_emacs.killBackwardWord()
      expect(editor.getCursorBufferPosition().toArray()).toEqual [0, 4]
      editor.setCursorBufferPosition [0, 3]
      editor.setCursorBufferPosition [0, 4]
      transient_emacs.killBackwardWord()
      expect(editor.getText()).toBe "\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo \nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo foo \nbaz\n"

    it "kill-region and yank", ->
      editor.setSelectedBufferRange [[0, 0], [0, 3]]
      transient_emacs.killRegion()
      expect(editor.getText()).toBe " bar\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"

    it "kill multi regions and yank", ->
      editor.setSelectedBufferRanges [[[0, 0], [0, 3]], [[1, 0], [1, 3]]]
      transient_emacs.killRegion()
      expect(editor.getText()).toBe " bar\n\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"

    it "kill-region and yank with extra cursor", ->
      editor.setSelectedBufferRange [[0, 0], [0, 3]]
      editor.addCursorAtBufferPosition [1, 0]
      transient_emacs.killRegion()
      expect(editor.getText()).toBe " bar\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"

    it "copy-region and yank", ->
      editor.setSelectedBufferRanges [[[0, 0], [0, 3]], [[1, 0], [1, 3]]]
      transient_emacs.copyRegion()
      expect(editor.getText()).toBe "foo bar\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foofoo bar\nbazbaz\n"

    it "copy-region, kill and yank", ->
      editor.setSelectedBufferRange [[0, 0], [0, 3]]
      transient_emacs.copyRegion()
      transient_emacs.kill()
      expect(editor.getText()).toBe "foo\nbaz\n"
      transient_emacs.yank()
      expect(editor.getText()).toBe "foo bar\nbaz\n"
