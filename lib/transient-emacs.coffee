{Range} = require 'atom'
{$,$$} = require 'space-pen'
_ = require 'underscore-plus'
KillRing = require './kill-ring'

# String::startsWith ?= (s) -> @[...s.length] is s
# String::endsWith   ?= (s) -> s is '' or @[-s.length..] is s

module.exports =
  killring: null
  commands: null
  event_listeners: []
  add_text_editor_listener: null
  is_user_command: true
  auto_move: 0
  isearch_word: ""
  isearch_tile: null

  activate: (state) ->
    @seal_blocker = 0
    @is_user_command = true
    @commands = atom.commands.add 'atom-text-editor',
      'emacs:cancel': => @cancel()
      'emacs:set-mark': => @set_mark()
      'emacs:yank': => @yank()
      'emacs:kill': => @kill()
      'emacs:kill-region': => @kill_region()
      'emacs:copy-region': => @copy_region()
      'emacs:kill-backward-word': => @kill_backward_word()
      'emacs:kill-region-or-backward-word': => @kill_region_or_backward_word()
      'emacs:isearch': => @activate_isearch(true)
      'emacs:backward-isearch': => @activate_isearch(false)
      'emacs:backspace': => return @backspace()

    atom.workspace.getTextEditors().forEach (editor) =>
      @event_listeners.push editor.onDidChangeCursorPosition (e)=>
        @killring.seal() if @is_user_command
        @deactivate_isearch() if @is_user_command

    @add_text_editor_listener = atom.workspace.onDidAddTextEditor (event) =>
      @event_listeners.push event.textEditor.onDidChangeCursorPosition =>
        @killring.seal() if @is_user_command
        @deactivate_isearch() if @is_user_command
      @event_listeners.push event.textEditor.onWillInsertText (e)=>
        if @isearch_tile
          e.cancel()
          @isearch_word += e.Text
          @isearch @isearch_word

    @keymap_listener = atom.keymap.onDidMatchBinding (e)=>
      if @isearch_tile
        if e.keystrokes.length == 1
          @isearch_word += e.keystrokes
          @isearch @isearch_word
        else if e.keystrokes.startsWith 'shift-'
          @isearch_word += e.keystrokes[-1..]
          @isearch @isearch_word
        else if e.keystrokes == 'space'
          @isearch_word += ' '
          @isearch @isearch_word
    @keymap_flistener = atom.keymap.onDidFailToMatchBinding (e)->
      # console.log "Fail",e

    @killring = new KillRing()

  deactivate: ->
    @commands?.dispose()
    @event_listeners.forEach (listener) -> listener.dispose()
    @add_text_editor_listener?.dispose()
    @keymap_listener?.dispose()
    @keymap_flistener?.dispose()
    delete @killring

  serialize: ->
    @killring.seal()

  cancel: ->
    editor = atom.workspace.getActiveEditor()
    return if @deactivate_isearch()
    return if @clear_selections editor
    return if @consolidate_selections editor
    atom.commands.dispatch atom.views.getView(atom.workspace), 'core:cancel'

  clear_selections: (editor)->
    return true if editor.getSelections().some (selection) ->
      unless selection.isEmpty()
        selection.clear()
      false
    false

  backspace: ()->
    if @isearch_tile
      if @isearch_word.length
        @isearch_word = @isearch_word.slice 0, -1
        @isearch @isearch_word
      else
        @deactivate_isearch()
      return false
    editorView = atom.views.getView atom.workspace.getActiveEditor()
    atom.commands.dispatch editorView, 'core:backspace'

  activate_isearch: (forward)->
    editor = atom.workspace.getActiveEditor()
    editorView = atom.views.getView editor
    $(editorView).toggleClass "searching"
    @isforward = forward
    @isearch @isearch_word

  deactivate_isearch: ()->
    if @isearch_tile?
      @isearch_tile?.destroy()
      @isearch_tile = null
      @isearch_word = ""
      editor = atom.workspace.getActiveEditor()
      editorView = atom.views.getView editor
      $(editorView).removeClass "searching"
      return true

  _update_statusbar: (word,found)->
    status_bar = document.querySelector("status-bar")
    span_class = if found then "found" else "not-found"
    if status_bar?
      prefix = if @isforward then "isearch:" else "backword-isearch:"
      istile = $$ ->
        @div class:"isearch inline-block", =>
          @span class:span_class, =>
            @text prefix
          @span class:span_class+" isearch-text", =>
            @text word
      @isearch_tile?.destroy()
      @isearch_tile = status_bar.addLeftTile(item: istile, priority: 10)

  _create_re: (word)->
    escaped = (_.map word, (c)->"["+c+"]").join ""
    return new RegExp(escaped,"i") if word == word.toLowerCase()
    new RegExp(escaped)

  _select_scroll: (editor, targets)->
    @is_user_command = false
    editor.setSelectedBufferRanges targets if targets.length
    editor.scrollToCursorPosition()
    @is_user_command = true


  isearch: (word)->
    @_update_statusbar word,true
    return unless word
    editor = atom.workspace.getActiveEditor()
    return if not editor or editor.mini
    buffer_end = editor.getBuffer().getEndPosition()
    re = @_create_re word
    selections = editor.getSelectedBufferRanges().map (sel)=>
      selected_text = editor.getTextInBufferRange(sel)
      matched = (re.exec selected_text)?[0] == selected_text
      start = if matched ^ @isforward then sel.start else sel.end
      selection = null
      selector = ({match,matchText,range,stop,replace}) ->
        selection ?= range
        stop()
      ranges = [new Range(start, buffer_end), new Range([0,0], start)]
      ranges.reverse() unless @isforward
      for range in ranges
        editor.scanInBufferRange re, range, selector if @isforward
        editor.backwardsScanInBufferRange re, range, selector unless @isforward
        return selection if selection?
      @_update_statusbar word,false
      return new Range(sel.end, sel.end)
    @_select_scroll editor,selections


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
