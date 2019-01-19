/* global describe:true it:true expect:true */
const KillRing = require('../lib/kill-ring');

describe('Kill Ring', ()=> {
  it('should be ["text"]', ()=> {
    let killring = new KillRing([], 4);
    killring.push(['text']);
    expect(killring.top()[0]).toBe('text');
  });
});
