{Range,Pane} = require 'atom'
{$,$$} = require 'space-pen'
_ = require 'underscore-plus'
KillRing = require './kill-ring'

# String::startsWith ?= (s) -> @[...s.length] is s
# String::endsWith   ?= (s) -> s is '' or @[-s.length..] is s

module.exports =
  config:
    useLegacySearch:
      type: 'boolean'
      default: true
  killring: null
  commands: null
  event_listeners: []
  add_text_editor_listener: null
  is_user_command: true
  auto_move: 0
  isearch_word: ""
  isearch_last: ""
  isearch_tile: null
  isforward: true

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
      'emacs:isearch': (e)=> @search(e,true)
      'emacs:backward-isearch': (e)=> @search(e,false)
      'emacs:backspace': => return @backspace()

    addEditorEventListner = (editor) =>
      editorView = $(atom.views.getView(editor))
      @event_listeners.push editor.onDidChangeCursorPosition (e)=>
        @killring?.seal() if @is_user_command
        @deactivate_isearch() if @is_user_command
      @event_listeners.push editorView.on 'click',(e)->
        editorView.removeClass "transient-marked"

    atom.workspace.getTextEditors().forEach addEditorEventListner
    @add_text_editor_listener = atom.workspace.onDidAddTextEditor (event) ->
      addEditorEventListner(event.textEditor)

    @keymap_listener = atom.keymaps.onDidMatchBinding (e)=>
      if @isearch_tile
        if e.keystrokes.length == 1
          @isearch_word += e.keystrokes
          @search_next @isearch_word
        else if e.keystrokes.startsWith 'shift-'
          @isearch_word += e.keystrokes[-1..]
          @search_next @isearch_word
        else if e.keystrokes == 'space'
          @isearch_word += ' '
          @search_next @isearch_word
    @keymap_flistener = atom.keymaps.onDidFailToMatchBinding (e)->
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
    editor = atom.workspace.getActiveTextEditor()
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
        @search_next @isearch_word
      else
        @deactivate_isearch()
      return false
    atom.commands.dispatch document.activeElement, 'core:backspace'

  search: (e,forward) ->
    if atom.config.get("transient-emacs.useLegacySearch")
      @activate_isearch(forward)
    else
      findAndReplace = atom.packages.getActivePackage("find-and-replace")
      if findAndReplace?.mainModule.findPanel?.isVisible()
        if forward
          atom.commands.dispatch(e.target, "find-and-replace:find-next")
          findAndReplace?.mainModule.findView?.focusFindEditor()
        else
          atom.commands.dispatch(e.target, "find-and-replace:find-previous")
          findAndReplace?.mainModule.findView?.focusFindEditor()
      else
        atom.commands.dispatch(e.target, "find-and-replace:show")

  activate_isearch: (forward)->
    editor = atom.workspace.getActiveTextEditor()
    editorView = atom.views.getView editor
    $(editorView).addClass "searching"
    @isforward = forward
    @isearch_word = @isearch_last if @isearch_tile? and not @isearch_word
    @search_next @isearch_word

  deactivate_isearch: ()->
    if @isearch_tile?
      @isearch_tile?.destroy()
      @isearch_tile = null
      @isearch_last = @isearch_word
      @isearch_word = ""
      editor = atom.workspace.getActiveTextEditor()
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
    escaped = (_.map word, (c)->if c=="\\" then "\\\\" else "["+c+"]").join ""
    # return new RegExp(escaped,"i") if word == word.toLowerCase()
    new RegExp(escaped)

  _select_scroll: (editor, targets)->
    @is_user_command = false
    if targets.length
      editor.setSelectedBufferRanges targets, flash:true
    editor.scrollToCursorPosition()
    @is_user_command = true

  search_next: (word, silent)->
    @_update_statusbar word,true unless silent
    return unless word
    editor = atom.workspace.getActiveTextEditor()
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
      for range,i in ranges
        if @isforward
          editor.scanInBufferRange re, range, selector
        else
          editor.backwardsScanInBufferRange re, range, selector
        return [selection,i] if selection?
      @_update_statusbar word,false unless silent
      return [new Range(sel.end, sel.end),0]
    @_select_scroll editor,(sel[0] for sel in selections)

  consolidate_selections: (editor)->
    cursors = editor.getCursors()
    if cursors.length > 1
      editor.setCursorBufferPosition editor.getCursorBufferPositions()[0]
      return true
    false

  set_mark: ->
    editor = atom.workspace.getActiveTextEditor()
    editorView = atom.views.getView editor
    $(editorView).toggleClass "transient-marked"
    cursor.clearSelection() for cursor in editor.getCursors()

  kill_region_or_backward_word: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.getLastSelection().isEmpty()
      @kill_backward_word()
    else
      @kill_region()

  _push_regeon_to_killring: (editor) ->
    editorView = atom.views.getView editor
    $(editorView).removeClass "transient-marked"
    texts = (s.getText() for s in editor.getSelections())
    @killring.push texts
    @killring.seal()

  kill_region: ->
    editor = atom.workspace.getActiveTextEditor()
    @_push_regeon_to_killring editor
    editor.transact ->
      s.delete() for s in editor.getSelections() when not s.isEmpty()

  copy_region: ->
    editor = atom.workspace.getActiveTextEditor()
    @_push_regeon_to_killring editor
    cursor.clearSelection() for cursor in editor.getCursors()

  kill_backward_word: ->
    @is_user_command = false
    editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      editor.selectToBeginningOfWord()
      texts = (s.getText() for s in editor.getSelections())
      @killring.put texts,false
      s.delete() for s in editor.getSelections() when not s.isEmpty()
    @is_user_command = true

  kill: ->
    @is_user_command = false
    editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      editor.selectToEndOfLine()
      texts = (s.getText() or '\n' for s in editor.getSelections())
      @killring.put texts,true
      editor.delete()
    @is_user_command = true

  yank: ->
    editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      cursors = editor.getCursors()
      top = @killring.top()
      if cursors.length == top?.length
        c.selection.insertText top[i] for c,i in cursors
      else if top
        c.selection.insertText top.join '\n' for c in cursors
