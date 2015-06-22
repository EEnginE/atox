ToxFriendBase = require './atox-toxFriendBase'

# coffeelint: disable=max_line_length

module.exports =
class Bot extends ToxFriendBase
  constructor: (params) ->
    super params
    @color  = "#a2a2a2F"

  receivedMsg: (msg) ->
  friendRead: (id) ->

  RESP_ping: (e) -> @aTox.term.inf {"title": "Bot #{@name} is valid: #{e.valid}"}
