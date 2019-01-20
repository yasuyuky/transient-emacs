KillRing = require './kill-ring'
Searcher = require './searcher'
DOMListener = require 'dom-listener'

module.exports =
  config:
    useLegacySearch:
      type: 'boolean'
      default: true
    inputControlCharacter:
      type: 'boolean'
      default: false
    killRing:
      type: 'object'
      properties:
        persistent:
          type: 'boolean'
          default: true
        length:
          type: 'integer'
          default: 10
          minimum: 1
  killring: null
  commands: null
  eventListeners: []
  addTextEditorListener: null
  isUserCommand: true
  searcher: null

  activate: (state) ->
    @isUserCommand = true
    @searcher = new Searcher()

    @commands = atom.commands.add 'atom-text-editor',
      'emacs:cancel': => @cancel()
      'emacs:set-mark': => @setMark()
      'emacs:yank': => @yank()
      'emacs:kill': => @kill()
      'emacs:show-kill-ring': => @showKillRing()
      'emacs:kill-region': => @killRegion()
      'emacs:copy-region': => @copyRegion()
      'emacs:kill-backward-word': => @killBackwardWord()
      'emacs:kill-region-or-backward-word': => @killRegionOrBackwardWord()
      'emacs:isearch': (e)=> @searcher.search(e, true, false)
      'emacs:backward-isearch': (e)=> @searcher.search(e, false, false)
      'emacs:isearch-regexp': (e)=> @searcher.search(e, true, true)
      'emacs:backward-isearch-regexp': (e)=> @searcher.search(e, false, true)
      'emacs:backspace': => return @backspace()

    addEditorEventListner = (editor) =>
      @eventListeners.push editor.onDidChangeCursorPosition (e)=>
        @killring?.seal() if @isUserCommand
        @searcher?.deactivateISearch() if @searcher.isUserCommand
      listener = new DOMListener(atom.views.getView(editor))
      @eventListeners.push listener.add 'atom-text-editor', 'click', (e)->
        (atom.views.getView editor).classList.remove("transient-marked")
        findAndReplace = atom.packages.getActivePackage("find-and-replace")
        if findAndReplace?.mainModule.findPanel?.isVisible()
          findAndReplace?.mainModule.findPanel?.hide()

    atom.workspace.getTextEditors().forEach addEditorEventListner
    @addTextEditorListener = atom.workspace.onDidAddTextEditor (event) ->
      addEditorEventListner(event.textEditor)

    @searcher.addIsearchCommands()
    @addInputCtrlsCommands() if atom.config.get("transient-emacs.inputControlCharacter")

    @killring = if state and state.killring
        atom.deserializers.deserialize(state.killring)
      else
        new KillRing([])

  deserializeKillRing: ({buffer}) -> new KillRing(buffer)

  addInputCtrlsCommands: ->
    inputCtrlKeybindings = {}
    inputCtrlCommandMap = {}
    inputCtrlSelector = 'atom-text-editor'
    inputCtrlKeybindings[inputCtrlSelector] = {}
    for code in [0..31]
      command = 'emacs:input-ctrl-'+code
      keybind = 'ctrl-q ctrl-'+String.fromCharCode(code+if 0 < code < 27 then 96 else 64)
      inputCtrlKeybindings[inputCtrlSelector][keybind] = command
      inputCtrlCommandMap[command] = ((s_)=>(=> @enterControlCharacter s_))(code)
    @inputCtrlKeymaps = atom.keymaps.add 'emacs-input-ctrl-keymap', inputCtrlKeybindings, 0
    @inputCtrlCommands = atom.commands.add 'atom-text-editor', inputCtrlCommandMap

  deactivate: ->
    @commands?.dispose()
    @inputCtrlCommands?.dispose()
    @eventListeners.forEach (listener) -> listener.dispose()
    @eventListeners = []
    @addTextEditorListener?.dispose()
    @searcher?.deactivate()
    delete @searcher
    delete @killring

  serialize: ->
    killring: @killring.serialize()

  cancel: ->
    editor = atom.workspace.getActiveTextEditor()
    return if @searcher.deactivateISearch()
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
    return @searcher.backspace() if @searcher.isearchTile
    atom.commands.dispatch document.activeElement, 'core:backspace'

  getEditor: ->
    pane = atom.workspace.getActivePane()
    editor = atom.workspace.getActiveTextEditor()
    return editor if editor == pane.activeItem

  consolidateSelections: (editor)->
    cursors = editor.getCursors()
    if cursors.length > 1
      editor.setCursorBufferPosition editor.getCursorBufferPositions()[0]
      return true
    false

  setMark: ->
    editor = @getEditor()
    return unless editor
    (atom.views.getView editor).classList.toggle "transient-marked"
    cursor.clearSelection() for cursor in editor.getCursors()

  killRegionOrBackwardWord: ->
    editor = @getEditor()
    return unless editor
    if editor.getLastSelection().isEmpty()
      @killBackwardWord()
    else
      @killRegion()

  pushRegionToKillring: (editor) ->
    (atom.views.getView editor).classList.remove "transient-marked"
    texts = (s.getText() for s in editor.getSelections())
    @killring.push texts
    @killring.seal()

  killRegion: ->
    editor = @getEditor()
    return unless editor
    @pushRegionToKillring editor
    editor.transact ->
      s.delete() for s in editor.getSelections() when not s.isEmpty()

  copyRegion: ->
    editor = @getEditor()
    return unless editor
    @pushRegionToKillring editor
    cursor.clearSelection() for cursor in editor.getCursors()

  killBackwardWord: ->
    editor = @getEditor()
    return unless editor
    @isUserCommand = false
    editor.transact =>
      editor.selectToBeginningOfWord()
      texts = (s.getText() for s in editor.getSelections())
      @killring.put texts, false
      s.delete() for s in editor.getSelections() when not s.isEmpty()
    @isUserCommand = true

  kill: ->
    editor = @getEditor()
    return unless editor
    @isUserCommand = false
    editor.transact =>
      editor.selectToEndOfLine()
      texts = (s.getText() or '\n' for s in editor.getSelections())
      @killring.put texts, true
      editor.delete()
    @isUserCommand = true

  yank: ->
    @yankTexts @killring.top()

  showKillRing: ->
    @killring.show (item) =>
      @yankTexts item.value

  yankTexts: (texts)->
    editor = @getEditor()
    return unless editor
    editor.transact =>
      cursors = editor.getCursors()
      if cursors.length == texts?.length
        c.selection.insertText texts[i] for c, i in cursors
      else if texts
        c.selection.insertText texts.join '\n' for c in cursors

  enterControlCharacter: (code)->
    editor = @getEditor()
    return unless editor
    editor.transact ->
      editor.insertText(String.fromCharCode(code))
