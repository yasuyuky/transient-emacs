{Range} = require 'atom'

module.exports =
class Searcher
  isUserCommand: true
  isearchWord: ""
  isearchLast: ""
  isearchTile: null
  isforward: true

  constructor: ->

  deactivate: ->
    @isearchCommands?.dispose()
    @isearchKeymaps?.dispose()

  incrementSearch: (c)->
    editor = @getEditor()
    if (atom.views.getView editor).classList.contains "searching"
      @isearchWord += c
      @searchNext @isearchWord

  activateIsearch: (forward)->
    editor = @getEditor()
    (atom.views.getView editor).classList.add "searching"
    @isforward = forward
    @isearchWord = @isearchLast if @isearchTile? and not @isearchWord
    @searchNext @isearchWord

  deactivateISearch: ()->
    if @isearchTile?
      @isearchTile?.destroy()
      @isearchTile = null
      @isearchLast = @isearchWord
      @isearchWord = ""
      editor = @getEditor()
      (atom.views.getView editor).classList.remove "searching"
      return true

  updateStatusbar: (word, found)->
    statusBar = document.querySelector("status-bar")
    spanClass = if found then "found" else "not-found"
    if statusBar?
      prefix = if @isforward then "isearch:" else "backword-isearch:"
      el = (tag, className, children) ->
        e = document.createElement(tag)
        e.className = className
        (e.appendChild c for c in children)
        e
      tile = el "div", "isearch inline-block", [
        el "span", spanClass, [new Text prefix]
        el "span", spanClass+" isearch-text", [new Text word]
      ]
      @isearchTile?.destroy()
      @isearchTile = statusBar.addLeftTile(item: tile, priority: 10)

  createRegExp: (word)->
    escaped = (word.split('').map (c)->if c=="\\" then "\\\\" else "["+c+"]").join ""
    new RegExp(escaped)

  selectScroll: (editor, targets)->
    @isUserCommand = false
    if targets.length
      editor.setSelectedBufferRanges targets, flash: true
    editor.scrollToCursorPosition()
    @isUserCommand = true

  searchNext: (word, silent)->
    @updateStatusbar word, true unless silent
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
      selector = ({match, matchText, range, stop, replace}) ->
        selection ?= range
        stop()
      ranges = [new Range(start, bufferEnd), new Range([0, 0], start)]
      ranges.reverse() unless @isforward
      for range, i in ranges
        if @isforward
          editor.scanInBufferRange re, range, selector
        else
          editor.backwardsScanInBufferRange re, range, selector
        return [selection, i] if selection?
      @updateStatusbar word, false unless silent
      return [new Range(sel.end, sel.end), 0]
    @selectScroll editor, (sel[0] for sel in selections)

  addIsearchCommands: ->
    searchKeybindings = {}
    isearchCommandMap = {}
    searchSelector = 'atom-workspace atom-text-editor.searching'
    searchKeybindings[searchSelector] = {}
    for code in [32..126]
      s = String.fromCharCode(code)
      command = 'emacs:input-isearch-'+code
      searchKeybindings[searchSelector][if s==' ' then 'space' else s] = command
      isearchCommandMap[command] = ((s_)=>(=> @incrementSearch s_))(s)
    @isearchKeymaps = atom.keymaps.add 'emacs-isearch-keymap', searchKeybindings, 0
    @isearchCommands = atom.commands.add 'atom-text-editor', isearchCommandMap

  search: (e, forward, useRegex) ->
    if atom.config.get("transient-emacs.useLegacySearch")
      @activateIsearch(forward)
    else
      findAndReplace = atom.packages.getActivePackage("find-and-replace")
      if findAndReplace?.mainModule.findPanel?.isVisible()
        if forward
          atom.commands.dispatch(e.target, "find-and-replace:find-next")
        else
          atom.commands.dispatch(e.target, "find-and-replace:find-previous")
        findAndReplace?.mainModule.findView?.findEditor?.element?.focus()
      else
        findAndReplace?.mainModule.findOptions?.set 'useRegex': useRegex
        tempListener = atom.packages.onDidActivatePackage (pkg)->
          if pkg.name == "find-and-replace"
            pkg.mainModule.findOptions?.set 'useRegex': useRegex
            tempListener.dispose()
        atom.commands.dispatch(e.target, "find-and-replace:show")

  backspace: ->
    if @isearchWord.length
      @isearchWord = @isearchWord.slice 0, -1
      @searchNext @isearchWord
    else
      @deactivateISearch()
    return false

  getEditor: ->
    pane = atom.workspace.getActivePane()
    editor = atom.workspace.getActiveTextEditor()
    return editor if editor == pane.activeItem
