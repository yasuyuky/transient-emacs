# Transient Emacs for Atom Editor / VS Code

Emacs (transient mark mode) for Atom Editor / VS Code (Experimental).

[![Build Status](https://travis-ci.org/yasuyuky/transient-emacs.svg)](https://travis-ci.org/yasuyuky/transient-emacs)
[![dependencies Status](https://david-dm.org/yasuyuky/transient-emacs/status.svg)](https://david-dm.org/yasuyuky/transient-emacs)

This package emulate Emacs'
[transient-mark-mode](http://www.emacswiki.org/emacs/TransientMarkMode).

# Features

- [x] emacs like keybindings
- [x] kill-ring with multiple cursors
- [x] sync kill-ring with clipboard
- [x] emacs like incremental search
- [x] yank text selected from kill-ring history

# Keybindings

See keymaps/transient-emacs.cson for detailed keybindings

| keybindng          | Atom Commands                                  |
| ------------------ | ---------------------------------------------- |
| **files**          |                                                |
| `ctrl-x ctrl-b`    | fuzzy-finder:toggle-file-finder                |
| `ctrl-x b`         | fuzzy-finder:toggle-buffer-finder              |
| `ctrl-x ctrl-f`    | application:open                               |
| `ctrl-x ctrl-c`    | application:quit                               |
| `ctrl-x ctrl-s`    | core:save                                      |
| `ctrl-x ctrl-w`    | core:save-as                                   |
| `ctrl-x k`         | core:close                                     |
| **general**        |                                                |
| `ctrl-j`           | core:confirm                                   |
| `ctrl-m`           | core:confirm                                   |
| `ctrl-g`           | cancels                                        |
| `ctrl-x u`         | core:undo                                      |
| **mark**           |                                                |
| `ctrl-@`           | emacs:set-mark                                 |
| `` ctrl-` ``       | emacs:set-mark                                 |
| **edit**           |                                                |
| `ctrl-y`           | emacs:yank                                     |
| `alt-y`            | emacs:show-kill-ring                           |
| `escape y`         | emacs:show-kill-ring                           |
| `ctrl-k`           | emacs:kill                                     |
| `ctrl-w`           | emacs:kill-region-or-backward-word             |
| `alt-w`            | emacs:copy-region                              |
| `escape w`         | emacs:copy-region                              |
| `ctrl-j`           | editor:newline                                 |
| `ctrl-m`           | editor:newline                                 |
| `ctrl-d`           | core:delete                                    |
| `backspace`        | emacs:backspace                                |
| `ctrl-h`           | emacs:backspace                                |
| `ctrl-j`           | editor:newline                                 |
| `ctrl-m`           | editor:newline                                 |
| **move**           |                                                |
| `ctrl-n`           | core:move-down                                 |
| `ctrl-p`           | core:move-up                                   |
| `ctrl-f`           | core:move-right                                |
| `ctrl-b`           | core:move-left                                 |
| `ctrl-l`           | editor:scroll-to-cursor                        |
| `ctrl-a`           | editor:move-to-first-character-of-line         |
| `ctrl-e`           | editor:move-to-end-of-line                     |
| `ctrl-right`       | editor:move-to-beginning-of-next-word          |
| `ctrl-left`        | editor:move-to-beginning-of-word               |
| `ctrl-up`          | editor:move-to-beginning-of-previous-paragraph |
| `ctrl-down`        | editor:move-to-beginning-of-next-paragraph     |
| `ctrl-shift-right` | editor:select-to-beginning-of-next-word        |
| `ctrl-shift-left`  | editor:select-to-beginning-of-word             |
| `ctrl-v`           | core:page-down                                 |
| `alt-v`            | core:page-up                                   |
| `escape v`         | core:page-up                                   |
| `alt-<`            | core:move-to-top                               |
| `escape <`         | core:move-to-top                               |
| `alt->`            | core:move-to-bottom                            |
| `escape >`         | core:move-to-bottom                            |
| `alt-g g`          | go-to-line:toggle                              |
| **search**         |                                                |
| `ctrl-s`           | emacs:isearch                                  |
| `ctrl-r`           | emacs:backward-isearch                         |
| `ctrl-alt-s`       | emacs:isearch-regexp                           |
| `ctrl-alt-r`       | emacs:backward-isearch-regexp                  |
| **pane**           |                                                |
| `ctrl-x 2`         | pane:split-down                                |
| `ctrl-x 3`         | pane:split-right                               |
| `ctrl-x 0`         | pane:close                                     |
| `ctrl-x o`         | window:focus-next-pane                         |
| **misc**           |                                                |
| `alt-x`            | command-palette:toggle                         |
| `escape x`         | command-palette:toggle                         |
| `alt-/`            | autocomplete:toggle                            |
| `alt-.`            | symbols-view:toggle-file-symbols               |
