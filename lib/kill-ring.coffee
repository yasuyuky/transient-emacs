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
    if @buffer.length > @limit then @buffer.shift()
    console.log _.last @buffer
    @sealed = false

  update: (texts,forward) ->
    concat = (t) -> if forward then t[0] + (t[1] or '') else (t[1] or '') + t[0]
    new_texts = ((concat t) for t in _.zip (_.last @buffer),texts)
    @buffer.pop
    @push new_texts

  top: ->
    _.last @buffer

  list: ->
    @buffer
