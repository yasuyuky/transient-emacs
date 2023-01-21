# Transient Emacs for Atom Editor / VS Code

<img src="https://raw.githubusercontent.com/yasuyuky/transient-emacs/main/image/icon.png" width="128px">

Emacs (transient mark mode) for VS Code (and formaly Atom Editor)

- [for VS Code](https://marketplace.visualstudio.com/items?itemName=yasuyuky.transient-emacs)
- [available on Open VSX Registry](https://open-vsx.org/extension/yasuyuky/transient-emacs)

[![Actions Status][github actions status]][github actions]

This package emulates Emacs'
[transient-mark-mode](http://www.emacswiki.org/emacs/TransientMarkMode).

# Features

- [x] emacs like keybindings
- [x] kill-ring with multiple cursors
- [x] sync kill-ring with clipboard
- [x] emacs like incremental search
- [x] yank text selected from kill-ring history

# Keybindings

See keymaps/transient-emacs.cson (for atom) or package.json (for code) for detailed keybindings

| keybindngs           | VS Code Commands                                   |
| -------------------- | -------------------------------------------------- |
| **files**            |                                                    |
| `ctrl-x ctrl-b`      | workbench.action.quickOpen                         |
| `ctrl-x b`           | workbench.action.openNextRecentlyUsedEditorInGroup |
| `ctrl-x ctrl-f`      | workbench.action.files.openFile                    |
| `ctrl-x ctrl-c`      | workbench.action.quit                              |
| `ctrl-x ctrl-s`      | workbench.action.files.save                        |
| `ctrl-x ctrl-w`      | workbench.action.files.saveAs                      |
| `ctrl-x ctrl-r`      | workbench.action.files.saveWithoutFormatting       |
| `ctrl-x k`           | workbench.action.closeActiveEditor                 |
| **general**          |                                                    |
| `ctrl-j`             | transient.insertNewLine                            |
| `ctrl-g`             | (cancels)                                          |
| `ctrl-x u`           | undo                                               |
| **mark**             |                                                    |
| `ctrl-enter`         | transient.setMark                                  |
| `ctrl-@`             | transient.setMark                                  |
| **edit**             |                                                    |
| `ctrl-y`             | transient.yank                                     |
| `alt-y`              | transient.showKillRing                             |
| `ctrl-k`             | transient.kill                                     |
| `ctrl-w`             | transient.killRegionOrBackwardWord                 |
| `alt-w`              | transient.copyRegion                               |
| `ctrl-j`             | transient.insertNewline                            |
| `ctrl-d`             | deleteRight (default)                              |
| `backspace`          | deleteLeft (default)                               |
| `ctrl-h`             | deleteLeft (default)                               |
| **move**             |                                                    |
| `ctrl-n`             | transient.cursorDown                               |
| `ctrl-p`             | transient.cursorUp                                 |
| `ctrl-f`             | transient.cursorRight                              |
| `ctrl-b`             | transient.cursorLeft                               |
| `ctrl-l`             | transient.adjustToCenter                           |
| `ctrl-a`             | transient.cursorHome                               |
| `ctrl-e`             | transient.cursorEnd                                |
| `ctrl-right`         | transient.cursorWordRight                          |
| `ctrl-left`          | transient.cursorWordLeft                           |
| `ctrl-up`            | transient.cursorParagraphUp                        |
| `ctrl-down`          | transient.cursorParagraphDown                      |
| `ctrl-shift-right`   | cursorWordRightSelect                              |
| `ctrl-shift-left`    | cursorWordLeftSelect                               |
| `ctrl-v`             | transient.cursorPageDown                           |
| `alt-v`              | transient.cursorPageUp                             |
| `alt-<`              | transient.cursorTop                                |
| `alt->`              | transient.cursorBottom                             |
| `alt-g g`            | workbench.action.gotoLine                          |
| `alt-g n`            | editor.action.marker.next                          |
| `alt-g p`            | editor.action.marker.prev                          |
| **search**           |                                                    |
| `ctrl-s`             | actions.find                                       |
| `ctrl-r`             | actions.find (reverse search)                      |
| **pane**             |                                                    |
| `ctrl-x 2`           | workbench.action.splitEditorDown                   |
| `ctrl-x 3`           | workbench.action.splitEditorRight                  |
| `ctrl-x 0`           | workbench.action.closeEditorsInGroup               |
| `ctrl-x o`           | workbench.action.focusNextGroup                    |
| **misc**             |                                                    |
| `alt-x`              | workbench.action.showCommands                      |
| `alt-.`              | workbench.action.gotoSymbol                        |
| `shift+alt+1`        | transient.shellCommand                             |
| `ctrl+u shift+alt+1` | transient.shellCommandAndInsert                    |
| `shift+alt+\`        | transient.shellCommandOnRegion                     |
| `ctrl+u shift+alt+\` | transient.shellCommandOnRegionAndReplace           |

# Release flow

1. Update CHANGELOG
2. `apm publish (major|minor|patch)`
3. `vsce package && vsce publish`
4. `npx ovsx publish transient-emacs-$(jq -r .version package.json).vsix -p $OVSX_TOKEN`

[github actions status]: https://img.shields.io/github/actions/workflow/status/yasuyuky/transient-emacs/test.yml?branch=main
[github actions]: https://github.com/yasuyuky/transient-emacs/actions
