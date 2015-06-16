ToxFriendBase = require './atox-toxFriendBase'

module.exports =
class Bot extends ToxFriendBase
  constructor: (params) ->
    @color  = "#a2a2a2F"
    @isFirstConnect = true

  setPreeMSGhandler: -> @aTox.term.stub {'msg': 'setPreeMSGhandler'}

  receivedMsg: (msg) ->
  friendStatus: (newStatus) ->
    super newStatus
    if @isFirstConnect
      @firstConnect()
      @isFirstConnect = false

  firstConnect: ->
    @aTox.manager.addBot this

  inf: (params) ->
    @aTox.term.inf {msg: "Bot '#{@name}': #{params.msg}", cID: -1}
    return unless params.notify? and params.notify is true
    @aTox.gui.notify {name: @name, content: params.msg}

  stub: (params) ->
    @aTox.term.stub {msg: "Bot '#{@name}': #{params.msg}", cID: -1}

  err: (params) ->
    @aTox.term.err {msg: "Bot '#{@name}': #{params.msg}", cID: -1}
