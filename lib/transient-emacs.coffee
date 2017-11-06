{Range,Pane} = require 'atom'
{$,$$} = require 'space-pen'
_ = require 'underscore-plus'
KillRing = require './kill-ring'

module.exports =
  config:
    useLegacySearch:
      type: 'boolean'
      default: true
  killring: null
  commands: null
  eventListeners: []
  addTextEditorListener: null
  isUserCommand: true
  isearchWord: ""
  isearchLast: ""
  isearchTile: null
  isforward: true

  activate: (state) ->
    @isUserCommand = true
    @commands = atom.commands.add 'atom-text-editor',
      'emacs:cancel': => @cancel()
      'emacs:set-mark': => @setMark()
      'emacs:yank': => @yank()
      'emacs:kill': => @kill()
      'emacs:kill-region': => @killRegion()
      'emacs:copy-region': => @copyRegion()
      'emacs:kill-backward-word': => @killBackwardWord()
      'emacs:kill-region-or-backward-word': => @killRegionOrBackwardWord()
      'emacs:isearch': (e)=> @search(e,true,false)
      'emacs:backward-isearch': (e)=> @search(e,false,false)
      'emacs:isearch-regexp': (e)=> @search(e,true,true)
      'emacs:backward-isearch-regexp': (e)=> @search(e,false,true)
      'emacs:backspace': => return @backspace()

    addEditorEventListner = (editor) =>
      editorView = $(atom.views.getView(editor))
      @eventListeners.push editor.onDidChangeCursorPosition (e)=>
        @killring?.seal() if @isUserCommand
        @deactivateISearch() if @isUserCommand
      @eventListeners.push editorView.on 'click',(e)->
        editorView.removeClass "transient-marked"

    atom.workspace.getTextEditors().forEach addEditorEventListner
    @addTextEditorListener = atom.workspace.onDidAddTextEditor (event) ->
      addEditorEventListner(event.textEditor)

    @keymapListener = atom.keymaps.onDidMatchBinding (e)=>
      if @isearchTile
        if e.keystrokes.length == 1
          @isearchWord += e.keystrokes
          @searchNext @isearchWord
        else if e.keystrokes.startsWith 'shift-'
          @isearchWord += e.keystrokes[-1..]
          @searchNext @isearchWord
        else if e.keystrokes == 'space'
          @isearchWord += ' '
          @searchNext @isearchWord
    @keymapFlistener = atom.keymaps.onDidFailToMatchBinding (e)->
      # console.log "Fail",e

    @killring = new KillRing()

  deactivate: ->
    @commands?.dispose()
    @eventListeners.forEach (listener) -> listener.dispose()
    @addTextEditorListener?.dispose()
    @keymapListener?.dispose()
    @keymapFlistener?.dispose()
    delete @killring

  serialize: ->
    @killring.seal()

  cancel: ->
    editor = atom.workspace.getActiveTextEditor()
    return if @deactivateISearch()
    return if @clearSelections editor
    return if @consolidateSelections editor
    atom.commands.dispatch atom.views.getView(atom.workspace), 'core:cancel'

  clearSelections: (editor)->
    return true if editor.getSelections().some (selection) ->
      unless selection.isEmpty()
        selection.clear()
      false
    false

  backspace: ()->
    if @isearchTile
      if @isearchWord.length
        @isearchWord = @isearchWord.slice 0, -1
        @searchNext @isearchWord
      else
        @deactivateISearch()
      return false
    atom.commands.dispatch document.activeElement, 'core:backspace'

  search: (e,forward,useRegex) ->
    if atom.config.get("transient-emacs.useLegacySearch")
      @activateIsearch(forward)
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
        findAndReplace?.mainModule.findOptions?.set 'useRegex':useRegex
        atom.packages.onDidActivatePackage (pkg)->
          if pkg.name == "find-and-replace"
            pkg.mainModule.findOptions?.set 'useRegex':useRegex
        atom.commands.dispatch(e.target, "find-and-replace:show")

  activateIsearch: (forward)->
    editor = atom.workspace.getActiveTextEditor()
    editorView = atom.views.getView editor
    $(editorView).addClass "searching"
    @isforward = forward
    @isearchWord = @isearchLast if @isearchTile? and not @isearchWord
    @searchNext @isearchWord

  deactivateISearch: ()->
    if @isearchTile?
      @isearchTile?.destroy()
      @isearchTile = null
      @isearchLast = @isearchWord
      @isearchWord = ""
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView editor
      $(editorView).removeClass "searching"
      return true

  updateStatusbar: (word,found)->
    statusBar = document.querySelector("status-bar")
    spanClass = if found then "found" else "not-found"
    if statusBar?
      prefix = if @isforward then "isearch:" else "backword-isearch:"
      istile = $$ ->
        @div class:"isearch inline-block", =>
          @span class:spanClass, =>
            @text prefix
          @span class:spanClass+" isearch-text", =>
            @text word
      @isearchTile?.destroy()
      @isearchTile = statusBar.addLeftTile(item: istile, priority: 10)

  createRegExp: (word)->
    escaped = (_.map word, (c)->if c=="\\" then "\\\\" else "["+c+"]").join ""
    new RegExp(escaped)

  selectScroll: (editor, targets)->
    @isUserCommand = false
    if targets.length
      editor.setSelectedBufferRanges targets, flash:true
    editor.scrollToCursorPosition()
    @isUserCommand = true

  getEditor: ->
    pane = atom.workspace.getActivePane()
    editor = atom.workspace.getActiveTextEditor()
    return editor if editor == pane.activeItem

  searchNext: (word, silent)->
    @updateStatusbar word,true unless silent
    return unless word
    editor = @getEditor()
    return if not editor or editor.mini
    bufferEnd = editor.getBuffer().getEndPosition()
    re = @createRegExp word
    selections = editor.getSelectedBufferRanges().map (sel)=>
      selectedText = editor.getTextInBufferRange(sel)
      matched = (re.exec selectedText)?[0] == selectedText
      start = if matched ^ @isforward then sel.start else sel.end
      selection = null
      selector = ({match,matchText,range,stop,replace}) ->
        selection ?= range
        stop()
      ranges = [new Range(start, bufferEnd), new Range([0,0], start)]
      ranges.reverse() unless @isforward
      for range,i in ranges
        if @isforward
          editor.scanInBufferRange re, range, selector
        else
          editor.backwardsScanInBufferRange re, range, selector
        return [selection,i] if selection?
      @updateStatusbar word,false unless silent
      return [new Range(sel.end, sel.end),0]
    @selectScroll editor,(sel[0] for sel in selections)

  consolidateSelections: (editor)->
    cursors = editor.getCursors()
    if cursors.length > 1
      editor.setCursorBufferPosition editor.getCursorBufferPositions()[0]
      return true
    false

  setMark: ->
    editor = @getEditor()
    return unless editor
    editorView = atom.views.getView editor
    $(editorView).toggleClass "transient-marked"
    cursor.clearSelection() for cursor in editor.getCursors()

  killRegionOrBackwardWord: ->
    editor = @getEditor()
    return unless editor
    if editor.getLastSelection().isEmpty()
      @killBackwardWord()
    else
      @killRegion()

  pushRegeonToKillring: (editor) ->
    editorView = atom.views.getView editor
    $(editorView).removeClass "transient-marked"
    texts = (s.getText() for s in editor.getSelections())
    @killring.push texts
    @killring.seal()

  killRegion: ->
    editor = @getEditor()
    return unless editor
    @pushRegeonToKillring editor
    editor.transact ->
      s.delete() for s in editor.getSelections() when not s.isEmpty()

  copyRegion: ->
    editor = @getEditor()
    return unless editor
    @pushRegeonToKillring editor
    cursor.clearSelection() for cursor in editor.getCursors()

  killBackwardWord: ->
    editor = @getEditor()
    return unless editor
    @isUserCommand = false
    editor.transact =>
      editor.selectToBeginningOfWord()
      texts = (s.getText() for s in editor.getSelections())
      @killring.put texts,false
      s.delete() for s in editor.getSelections() when not s.isEmpty()
    @isUserCommand = true

  kill: ->
    editor = @getEditor()
    return unless editor
    @isUserCommand = false
    editor.transact =>
      editor.selectToEndOfLine()
      texts = (s.getText() or '\n' for s in editor.getSelections())
      @killring.put texts,true
      editor.delete()
    @isUserCommand = true

  yank: ->
    editor = @getEditor()
    return unless editor
    editor.transact =>
      cursors = editor.getCursors()
      top = @killring.top()
      if cursors.length == top?.length
        c.selection.insertText top[i] for c,i in cursors
      else if top
        c.selection.insertText top.join '\n' for c in cursors
