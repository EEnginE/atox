ToxFriendBase = require './atox-toxFriendBase'

module.exports =
class Bot extends ToxFriendBase
  constructor: (params) ->
    super params
    @color  = "#a2a2a2F"

  receivedMsg: (msg) ->
  friendRead: (id) ->
