KillRing = require '../lib/kill-ring'
{WorkspaceView} = require 'atom'

describe "Kill Ring", ->

  it "should be [\"text\"]", ->
    killring = new KillRing(4)

    killring.push ["text"]

    expect(killring.top()[0]).toBe "text"
