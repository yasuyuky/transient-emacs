{Range} = require 'atom'
_ = require 'underscore-plus'
KillRing = require './kill-ring'

module.exports =
  killring: null
  seal_blocker: 0

  activate: (state) ->
    atom.workspaceView.eachEditorView (editorView) =>
      @enableEmacs(editorView) if editorView.attached
    @killring = new KillRing()

  deactivate: ->

  serialize: ->

  enableEmacs: (editorView) ->
    editorView.command "emacs:set-mark", => @set_mark()
    editorView.command "emacs:yank", => @yank()
    editorView.command "emacs:kill", => @kill()
    editorView.command "emacs:kill-region", => @kill_region()
    editorView.command "emacs:copy-region", => @copy_region()
    editorView.command "emacs:kill-backward-word", => @kill_backward_word()
    editorView.command "emacs:kill-region-or-backward-word", => @kill_region_or_backward_word()
    editorView.command "emacs:move-to-next-empty-line", => @move_or_select_to_empty_line(true)
    editorView.command "emacs:move-to-prev-empty-line", => @move_or_select_to_empty_line(false)
    editorView.command "emacs:select-to-next-empty-line", => @move_or_select_to_empty_line(true,true)
    editorView.command "emacs:select-to-prev-empty-line", => @move_or_select_to_empty_line(false,true)

    editorView.on "cursor:moved editor:consolidate-selections", (event) => @seal_killring()

  set_mark: ->
    console.log "set mark command"
    editorView = atom.workspaceView.find '.editor.is-focused'
    editorView.toggleClass "transient-marked"
    console.log atom.workspaceView.find('.transient-marked')
    editor = atom.workspace.getActiveEditor()
    cursor.clearSelection() for cursor in editor.getCursors()

  kill_region_or_backward_word: ->
    editor = atom.workspace.getActiveEditor()
    if editor.getSelection().isEmpty()
      @kill_backward_word()
    else
      @kill_region()

  _push_regeon_to_killring: ->
    editorView = atom.workspaceView.find '.editor.is-focused'
    editorView.removeClass "transient-marked"
    editor = atom.workspace.getActiveEditor()
    selectionRanges = (s.getScreenRange() for s in editor.getSelections())
    texts = (editor.getTextInRange r for r in selectionRanges)
    @killring.push texts
    editor

  kill_region: ->
    editor = @_push_regeon_to_killring()
    editor.cutSelectedText()

  copy_region: ->
    editor = @_push_regeon_to_killring()
    cursor.clearSelection() for cursor in editor.getCursors()

  kill_backward_word: ->
    editor = atom.workspace.getActiveEditor()
    editor.selectToBeginningOfWord()
    selectionRanges = (s.getScreenRange() for s in editor.getSelections())
    texts = (editor.getTextInRange r for r in selectionRanges)
    @killring.put texts,false
    editor.cutSelectedText()
    @seal_blocker = texts.length

  kill: ->
    editor = atom.workspace.getActiveEditor()
    editor.selectToEndOfLine()
    selectionRanges = (s.getScreenRange() for s in editor.getSelections())
    texts = (editor.getTextInRange(r) or '\n' for r in selectionRanges)
    @killring.put texts,true
    editor.cutSelectedText()
    @seal_blocker = Math.max 0,_.filter(texts,(t) => t == '\n').length-1

  yank: ->
    editor = atom.workspace.getActiveEditor()
    cursors = editor.getCursors()
    top = @killring.top()
    if cursors.length == top?.length
      c.selection.insertText top[i] for c,i in cursors
    else if top
      c.selection.insertText top.join '\n' for c in cursors

  seal_killring: ->
    if @seal_blocker == 0
      @killring.seal()
    else if @seal_blocker
      @seal_blocker -= 1

  move_or_select_to_empty_line: (forward,select=false) ->
    editor = atom.workspace.getActiveEditor()
    selections = editor.getSelections()
    lines = editor.getText().split '\n'
    all_indices = (i for l,i in lines when /^\s*$/.test l)
    for s in selections
      rows = s.getBufferRowRange()
      cur_row = if s.isReversed() then _.min rows else _.max rows
      indices = _.filter all_indices, (x) => if forward then x > cur_row else x < cur_row
      new_row = if forward then _.head indices else _.last indices
      new_row ?= if forward then lines.length-1 else 0
      if select
        if forward
          s.selectDown() for j in [cur_row..new_row-1]
        else
          s.selectUp() for j in [new_row..cur_row-1]
      else
        s.setBufferRange new Range [new_row,0],[new_row,0]
