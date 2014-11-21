{Range} = require 'atom'
{$} = require 'space-pen'
_ = require 'underscore-plus'
KillRing = require './kill-ring'

module.exports =
  killring: null
  commands: null
  command_listeners: []
  add_text_editor_listener: null
  is_user_command: true

  activate: (state) ->
    @seal_blocker = 0
    @is_user_command = true
    @commands = atom.commands.add 'atom-text-editor',
     "emacs:cancel": => @cancel()
     "emacs:set-mark": => @set_mark()
     "emacs:yank": => @yank()
     "emacs:kill": => @kill()
     "emacs:kill-region": => @kill_region()
     "emacs:copy-region": => @copy_region()
     "emacs:kill-backward-word": => @kill_backward_word()
     "emacs:kill-region-or-backward-word": => @kill_region_or_backward_word()
     "emacs:move-to-next-empty-line": => @move_or_select_to_empty_line(true)
     "emacs:move-to-prev-empty-line": => @move_or_select_to_empty_line(false)
     "emacs:select-to-next-empty-line": => @move_or_select_to_empty_line(true,true)
     "emacs:select-to-prev-empty-line": => @move_or_select_to_empty_line(false,true)

    atom.workspace.getTextEditors().forEach (editor) =>
      @command_listeners.push editor.onDidChangeCursorPosition =>
        @killring.seal() if @is_user_command

    @add_text_editor_listener = atom.workspace.onDidAddTextEditor (event) =>
      @command_listeners.push event.textEditor.onDidChangeCursorPosition =>
        @killring.seal() if @is_user_command

    @killring = new KillRing()

  deactivate: ->
    @commands.dispose()
    @command_listeners.forEach (listener) -> listener.dispose()
    @add_text_editor_listener.dispose()
    delete @killring

  serialize: ->
    @killring.seal()

  cancel: ->
    editor = atom.workspace.getActiveEditor()
    return if @clear_selections editor
    return if @consolidate_selections editor
    atom.commands.dispatch atom.views.getView(atom.workspace), "core:cancel"

  clear_selections: (editor)->
    return true if editor.getSelections().some (selection) ->
      unless selection.isEmpty()
        selection.clear()
      false
    false

  consolidate_selections: (editor)->
    cursors = editor.getCursors()
    if cursors.length > 1
      editor.setCursorBufferPosition editor.getCursorBufferPositions()[0]
      return true
    false

  set_mark: ->
    editor = atom.workspace.getActiveEditor()
    editorView = atom.views.getView editor
    $(editorView).toggleClass "transient-marked"
    cursor.clearSelection() for cursor in editor.getCursors()

  kill_region_or_backward_word: ->
    editor = atom.workspace.getActiveEditor()
    if editor.getSelection().isEmpty()
      @kill_backward_word()
    else
      @kill_region()

  _push_regeon_to_killring: ->
    editor = atom.workspace.getActiveEditor()
    editorView = atom.views.getView editor
    $(editorView).removeClass "transient-marked"
    texts = (s.getText() for s in editor.getSelections())
    @killring.push texts
    @killring.seal()
    editor

  kill_region: ->
    editor = @_push_regeon_to_killring()
    s.delete() for s in editor.getSelections() when not s.isEmpty()

  copy_region: ->
    editor = @_push_regeon_to_killring()
    cursor.clearSelection() for cursor in editor.getCursors()

  kill_backward_word: ->
    @is_user_command = false
    editor = atom.workspace.getActiveEditor()
    editor.selectToBeginningOfWord()
    texts = (s.getText() for s in editor.getSelections())
    @killring.put texts,false
    s.delete() for s in editor.getSelections() when not s.isEmpty()
    @is_user_command = true

  kill: ->
    @is_user_command = false
    editor = atom.workspace.getActiveEditor()
    editor.selectToEndOfLine()
    texts = (s.getText() or '\n' for s in editor.getSelections())
    @killring.put texts,true
    editor.delete()
    @is_user_command = true

  yank: ->
    editor = atom.workspace.getActiveEditor()
    cursors = editor.getCursors()
    top = @killring.top()
    if cursors.length == top?.length
      c.selection.insertText top[i] for c,i in cursors
    else if top
      c.selection.insertText top.join '\n' for c in cursors

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
