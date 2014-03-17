Transient Emacs for Atom Editor
===============================

Emacs (transient mark mode) for Atom Editor.

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

```coffee-script
'ctrl-@':'emacs:set-mark'
'ctrl-space':'emacs:set-mark'
'ctrl-y':'emacs:yank'
'ctrl-k':'emacs:kill'
'ctrl-w':'emacs:kill-region-or-backward-word'
'alt-w':'emacs:copy-region'
'escape w':'emacs:copy-region'

'ctrl-a':'editor:move-to-first-character-of-line'
'ctrl-e':'editor:move-to-end-of-line'
'ctrl-right':'editor:move-to-beginning-of-next-word'
'ctrl-left':'editor:move-to-beginning-of-word'
'ctrl-up':'emacs:move-to-prev-empty-line'
'ctrl-down':'emacs:move-to-next-empty-line'
'ctrl-v':'core:page-down'
'alt-v':'core:page-up'
'escape v':'core:page-up'
'alt-<':'core:move-to-top'
'escape <':'core:move-to-top'
'alt->':'core:move-to-bottom'
'escape >':'core:move-to-bottom'

'ctrl-s':'find-and-replace:find-next'

'ctrl-x ctrl-s':'core:save'
'ctrl-x ctrl-f':'application:open'
'ctrl-x ctrl-c':'application:quit'
'ctrl-x u':'core:undo'
'ctrl-x k':'core:close'

'alt-x':'command-palette:toggle'
'escape x':'command-palette:toggle'
'alt-/':'autocomplete:toggle'
```
