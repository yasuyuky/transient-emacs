/* global describe it expect beforeEach waitsForPromise runs atom:true */
const transient_emacs = require('../lib/atom/main');

describe('Transient Emacs', () => {
  let editor = null;

  beforeEach(() => {
    transient_emacs.activate();
    atom.packages.enablePackage('status-bar').activate();

    waitsForPromise(() => {
      return atom.workspace.open().then(e => {
        editor = e;
      });
    });

    runs(() => {
      expect(editor.getText()).toBe('');
      editor.setText('foo bar\nbaz\n');
      expect(editor.getText()).toBe('foo bar\nbaz\n');
    });
  });

  describe('searcher', () => {
    it('searchNext (legacy)', () => {
      editor.setCursorBufferPosition([0, 0]);
      transient_emacs.searcher.searchNext('baz');
      expect(editor.getSelectedText()).toBe('baz');
    });

    it('search incrementally (legacy)', () => {
      atom.config.set('transient-emacs.useLegacySearch', true);
      editor.setCursorBufferPosition([0, 0]);
      transient_emacs.searcher.search({}, true, true);
      transient_emacs.searcher.incrementSearch('b');
      transient_emacs.searcher.incrementSearch('a');
      transient_emacs.searcher.incrementSearch('r');
      expect(editor.getSelectedText()).toBe('bar');
    });

    it('search incrementally backward (legacy)', () => {
      atom.config.set('transient-emacs.useLegacySearch', true);
      editor.setCursorBufferPosition([2, 0]);
      transient_emacs.searcher.search({}, false, true);
      transient_emacs.searcher.incrementSearch('f');
      expect(editor.getSelectedText()).toBe('f');
    });

    it('search incrementally with multi cursors (legacy)', () => {
      atom.config.set('transient-emacs.useLegacySearch', true);
      editor.setCursorBufferPosition([0, 0]);
      editor.addCursorAtBufferPosition([1, 0]);
      transient_emacs.searcher.search({}, false, true);
      transient_emacs.searcher.incrementSearch('b');
      transient_emacs.searcher.incrementSearch('a');
      const selected = editor.getSelections().map(sel => sel.getText());
      expect(selected[0]).toBe('ba');
      expect(selected[1]).toBe('ba');
    });
  });
});
