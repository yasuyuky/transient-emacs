# Transient Emacs for Atom Editor / VS Code

<img src="https://raw.githubusercontent.com/yasuyuky/transient-emacs/main/image/icon.png" width="128px">

Emacs (transient mark mode) for Atom Editor / VS Code

- [for Atom Editor](https://atom.io/packages/transient-emacs)
- [for VS Code](https://marketplace.visualstudio.com/items?itemName=yasuyuky.transient-emacs)
- [available on Open VSX Registry](https://open-vsx.org/extension/yasuyuky/transient-emacs)

[![Build Status][travis-ci status]][travis-ci]
[![Build Status][azure pipelines status]][azure pipelines]
[![Actions Status][github actions status]][github actions]
[![Dependencies Status][david-dm status]][david-dm]

This package emulate Emacs'
[transient-mark-mode](http://www.emacswiki.org/emacs/TransientMarkMode).

# Features

- [x] emacs like keybindings
- [x] kill-ring with multiple cursors
- [x] sync kill-ring with clipboard
- [x] emacs like incremental search
- [x] yank text selected from kill-ring history

# Keybindings

See keymaps/transient-emacs.cson (for atom) or package.json (for code) for detailed keybindings

| keybindngs           | Atom Editor Commands                           | VS Code Commands                                   |
| -------------------- | ---------------------------------------------- | -------------------------------------------------- |
| **files**            |                                                |                                                    |
| `ctrl-x ctrl-b`      | fuzzy-finder:toggle-file-finder                | workbench.action.quickOpen                         |
| `ctrl-x b`           | fuzzy-finder:toggle-buffer-finder              | workbench.action.openNextRecentlyUsedEditorInGroup |
| `ctrl-x ctrl-f`      | application:open                               | workbench.action.files.openFile                    |
| `ctrl-x ctrl-c`      | application:quit                               | workbench.action.quit                              |
| `ctrl-x ctrl-s`      | core:save                                      | workbench.action.files.save                        |
| `ctrl-x ctrl-w`      | core:save-as                                   | workbench.action.files.saveAs                      |
| `ctrl-x ctrl-r`      |                                                | workbench.action.files.saveWithoutFormatting       |
| `ctrl-x k`           | core:close                                     | workbench.action.closeActiveEditor                 |
| **general**          |                                                |                                                    |
| `ctrl-j`             | core:confirm                                   | transient.insertNewLine                            |
| `ctrl-m`             | core:confirm                                   |                                                    |
| `ctrl-g`             | cancels                                        | (cancels)                                          |
| `ctrl-x u`           | core:undo                                      | undo                                               |
| **mark**             |                                                |                                                    |
| `ctrl-enter`         |                                                | transient.setMark                                  |
| `ctrl-@`             | emacs:set-mark                                 | transient.setMark                                  |
| `` ctrl-` ``         | emacs:set-mark                                 |                                                    |
| **edit**             |                                                |                                                    |
| `ctrl-y`             | emacs:yank                                     | transient.yank                                     |
| `alt-y`              | emacs:show-kill-ring                           | transient.showKillRing                             |
| `ctrl-k`             | emacs:kill                                     | transient.kill                                     |
| `ctrl-w`             | emacs:kill-region-or-backward-word             | transient.killRegionOrBackwardWord                 |
| `alt-w`              | emacs:copy-region                              | transient.copyRegion                               |
| `ctrl-j`             | editor:newline                                 | transient.insertNewline                            |
| `ctrl-m`             | editor:newline                                 |                                                    |
| `ctrl-d`             | core:delete                                    | deleteRight (default)                              |
| `backspace`          | emacs:backspace                                | deleteLeft (default)                               |
| `ctrl-h`             | emacs:backspace                                | deleteLeft (default)                               |
| **move**             |                                                |                                                    |
| `ctrl-n`             | core:move-down                                 | transient.cursorDown                               |
| `ctrl-p`             | core:move-up                                   | transient.cursorUp                                 |
| `ctrl-f`             | core:move-right                                | transient.cursorRight                              |
| `ctrl-b`             | core:move-left                                 | transient.cursorLeft                               |
| `ctrl-l`             | editor:scroll-to-cursor                        | transient.adjustToCenter                           |
| `ctrl-a`             | editor:move-to-first-character-of-line         | transient.cursorHome                               |
| `ctrl-e`             | editor:move-to-end-of-line                     | transient.cursorEnd                                |
| `ctrl-right`         | editor:move-to-beginning-of-next-word          | transient.cursorWordRight                          |
| `ctrl-left`          | editor:move-to-beginning-of-word               | transient.cursorWordLeft                           |
| `ctrl-up`            | editor:move-to-beginning-of-previous-paragraph | transient.cursorParagraphUp                        |
| `ctrl-down`          | editor:move-to-beginning-of-next-paragraph     | transient.cursorParagraphDown                      |
| `ctrl-shift-right`   | editor:select-to-beginning-of-next-word        | cursorWordRightSelect                              |
| `ctrl-shift-left`    | editor:select-to-beginning-of-word             | cursorWordLeftSelect                               |
| `ctrl-v`             | core:page-down                                 | transient.cursorPageDown                           |
| `alt-v`              | core:page-up                                   | transient.cursorPageUp                             |
| `alt-<`              | core:move-to-top                               | transient.cursorTop                                |
| `alt->`              | core:move-to-bottom                            | transient.cursorBottom                             |
| `alt-g g`            | go-to-line:toggle                              | workbench.action.gotoLine                          |
| `alt-g n`            |                                                | editor.action.marker.next                          |
| `alt-g p`            |                                                | editor.action.marker.prev                          |
| **search**           |                                                |                                                    |
| `ctrl-s`             | emacs:isearch                                  | actions.find                                       |
| `ctrl-r`             | emacs:backward-isearch                         | actions.find (reverse search)                      |
| `ctrl-alt-s`         | emacs:isearch-regexp                           |                                                    |
| `ctrl-alt-r`         | emacs:backward-isearch-regexp                  |                                                    |
| **pane**             |                                                |                                                    |
| `ctrl-x 2`           | pane:split-down                                | workbench.action.splitEditorDown                   |
| `ctrl-x 3`           | pane:split-right                               | workbench.action.splitEditorRight                  |
| `ctrl-x 0`           | pane:close                                     | workbench.action.closeEditorsInGroup               |
| `ctrl-x o`           | window:focus-next-pane                         | workbench.action.focusNextGroup                    |
| **misc**             |                                                |                                                    |
| `alt-x`              | command-palette:toggle                         | workbench.action.showCommands                      |
| `alt-/`              | autocomplete:toggle                            |                                                    |
| `alt-.`              | symbols-view:toggle-file-symbols               | workbench.action.gotoSymbol                        |
| `alt-.`              |                                                |                                                    |
| `shift+alt+1`        |                                                | transient.shellCommand                             |
| `ctrl+u shift+alt+1` |                                                | transient.shellCommandAndInsert                    |
| `shift+alt+\`        |                                                | transient.shellCommandOnRegion                     |
| `ctrl+u shift+alt+\` |                                                | transient.shellCommandOnRegionAndReplace           |

# Release flow

1. Update CHANGELOG
2. `apm publish (major|minor|patch)`
3. `vsce package && vsce publish`
4. `npx ovsx publish transient-emacs-$(jq -r .version package.json).vsix -p $OVSX_TOKEN`

[travis-ci status]: https://travis-ci.org/yasuyuky/transient-emacs.svg
[travis-ci]: https://travis-ci.org/yasuyuky/transient-emacs
[azure pipelines status]: https://dev.azure.com/yasuyuky/transient-emacs/_apis/build/status/yasuyuky.transient-emacs?branchName=main
[azure pipelines]: https://dev.azure.com/yasuyuky/transient-emacs/_build/latest?definitionId=1&branchName=main
[github actions status]: https://img.shields.io/github/workflow/status/yasuyuky/transient-emacs/Test.svg?logo=github
[github actions]: https://github.com/yasuyuky/transient-emacs/actions
[david-dm status]: https://david-dm.org/yasuyuky/transient-emacs/status.svg
[david-dm]: https://david-dm.org/yasuyuky/transient-emacs
