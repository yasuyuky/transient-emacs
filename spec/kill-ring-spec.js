/* global describe it expect atom:true */
const KillRing = require('../lib/kill-ring');

describe('Kill Ring', ()=> {
  it('should be ["text"]', ()=> {
    atom.config.set('transient-emacs.killRing', {persistent:true});
    let killring = new KillRing([], 4);
    killring.push(['text']);
    expect(killring.top()[0]).toBe('text');
  });
});
