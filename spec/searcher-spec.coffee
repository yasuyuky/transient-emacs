transient_emacs = require '../lib/transient-emacs'

describe "Transient Emacs", ->
  editor = null
  editorView = null

  beforeEach ->
    transient_emacs.activate()
    atom.packages.enablePackage('status-bar').activate()
    waitsForPromise ->
      atom.workspace.open().then (e)->
        editor = e

    runs ->
      editorView = atom.views.getView editor
      expect(editor.getText()).toBe ""
      editor.setText "foo bar\nbaz\n"
      expect(editor.getText()).toBe "foo bar\nbaz\n"

  describe "searcher", ->
    it "searchNext (legacy)", ->
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.searcher.searchNext "baz"
      expect(editor.getSelectedText()).toBe "baz"

    it "search incrementally (legacy)", ->
      atom.config.set("transient-emacs.useLegacySearch", true)
      editor.setCursorBufferPosition [0, 0]
      transient_emacs.searcher.search {}, true, true
      transient_emacs.searcher.incrementSearch "b"
      transient_emacs.searcher.incrementSearch "a"
      transient_emacs.searcher.incrementSearch "r"
      expect(editor.getSelectedText()).toBe "bar"
