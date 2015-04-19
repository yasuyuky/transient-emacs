Transient Emacs for Atom Editor
===============================

Emacs (transient mark mode) for Atom Editor.


[![Build Status](https://travis-ci.org/yasuyuky/transient-emacs.svg)](https://travis-ci.org/yasuyuky/transient-emacs)

This package emulate Emacs'
[transient-mark-mode](http://www.emacswiki.org/emacs/TransientMarkMode).

Features
========

- [x] emacs like keybindings
- [x] kill-ring with multiple cursors
- [x] sync kill-ring with clipboard
- [ ] yank text selected from kill-ring history
- [ ] emacs like incremental search

Keybindings
===========

See keymaps/transient-emacs.cson for detailed keybindings

Curently this package uses [Incremental Search Package](https://atom.io/packages/incremental-search)
for search key-bindings.
It's good enough to me ;)

```coffee-script
# Keybindings require three things to be fully defined: A selector that is
# matched against the focused element, the keystroke and the command to
# execute.
#
# Below is a basic keybinding which registers on all platforms by applying to
# the root workspace element.

# For more detailed documentation see
# https://atom.io/docs/latest/advanced/keymaps

'body':
  'ctrl-x b':'fuzzy-finder:toggle-buffer-finder'
  'ctrl-x ctrl-b':'fuzzy-finder:toggle-file-finder'
  'ctrl-x ctrl-f':'application:open'
  'ctrl-x ctrl-c':'application:quit'

  'ctrl-x 2':'pane:split-right'
  'ctrl-x 3':'pane:split-down'
  'ctrl-x 0':'pane:close'
  'ctrl-x o':'window:focus-next-pane'

  'ctrl-g':'core:cancel'

'atom-panel':
  'ctrl-g':'tool-panel:unfocus'

'atom-text-editor[mini]':
  'ctrl-g':'core:cancel'
  'ctrl-k':'editor:cut-to-end-of-line'
  'ctrl-y':'core:paste'

'atom-text-editor':
  'ctrl-g':'emacs:cancel'
  'ctrl-@':'emacs:set-mark'
  'ctrl-y':'emacs:yank'
  'ctrl-k':'emacs:kill'
  'ctrl-w':'emacs:kill-region-or-backward-word'
  'alt-w':'emacs:copy-region'
  'escape w':'emacs:copy-region'

  'ctrl-a':'editor:move-to-first-character-of-line'
  'ctrl-e':'editor:move-to-end-of-line'
  'ctrl-right':'editor:move-to-beginning-of-next-word'
  'ctrl-left':'editor:move-to-beginning-of-word'
  'ctrl-up':'editor:move-to-beginning-of-previous-paragraph'
  'ctrl-down':'editor:move-to-beginning-of-next-paragraph'

  'ctrl-shift-right':'editor:select-to-beginning-of-next-word'
  'ctrl-shift-left':'editor:select-to-beginning-of-word'

  'ctrl-v':'core:page-down'
  'alt-v':'core:page-up'
  'escape v':'core:page-up'
  'alt-<':'core:move-to-top'
  'escape <':'core:move-to-top'
  'alt->':'core:move-to-bottom'
  'escape >':'core:move-to-bottom'

  'ctrl-s':'incremental-search:forward'
  'ctrl-r':'incremental-search:backward'

  'ctrl-x ctrl-s':'core:save'
  'ctrl-x ctrl-w':'core:save-as'
  'ctrl-x u':'core:undo'
  'ctrl-x k':'core:close'

  'alt-.':'symbols-view:toggle-file-symbols'

  'alt-x':'command-palette:toggle'
  'escape x':'command-palette:toggle'
  'alt-/':'autocomplete:toggle'

'atom-text-editor.transient-marked':
  'ctrl-g':'emacs:set-mark'
  'right':'core:select-right'
  'ctrl-f':'core:select-right'
  'left':'core:select-left'
  'ctrl-b':'core:select-left'
  'up':'core:select-up'
  'ctrl-p':'core:select-up'
  'down':'core:select-down'
  'ctrl-n':'core:select-down'
  'ctrl-a':'editor:select-to-first-character-of-line'
  'ctrl-e':'editor:select-to-end-of-line'
  'ctrl-right':'editor:select-to-beginning-of-next-word'
  'ctrl-left':'editor:select-to-beginning-of-word'
  'ctrl-up':'editor:select-to-beginning-of-previous-paragraph'
  'ctrl-down':'editor:select-to-beginning-of-next-paragraph'
  'ctrl-v':'core:select-page-down'
  'alt-<':'core:select-to-top'
  'escape <':'core:select-to-top'
  'alt->':'core:select-to-bottom'
  'escape >':'core:select-to-bottom'


```
