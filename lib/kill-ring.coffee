_ = require 'underscore-plus'

module.exports =
class KillRing
  buffer:[]
  sealed: true
  limit: 16

  constructor: (limit=16)->
    @limit = limit

  put: (texts, forward=true) ->
    if @sealed
      @push texts
    else
      @update texts,forward

  seal: ->
    @sealed = true

  push: (texts) ->
    @buffer.push texts
    atom.clipboard.write texts.join '\n'
    if @buffer.length > @limit then @buffer.shift()
    @sealed = false

  update: (texts,forward) ->
    concat = (t) -> if forward then t[0] + (t[1] or '') else (t[1] or '') + t[0]
    newTexts = ((concat t) for t in _.zip (_.last @buffer),texts)
    @buffer.pop()
    @push newTexts

  top: ->
    _.last @list()

  list: ->
    last = _.last @buffer
    last ?= [""]
    if atom.clipboard.md5(last.join '\n') != atom.clipboard.signatureForMetadata
      @push [atom.clipboard.read()]
    @buffer
