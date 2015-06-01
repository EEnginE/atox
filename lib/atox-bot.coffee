module.exports =
class Bot
  constructor: (params) ->
    params.status = 'offline' unless params.status?

    @name   = params.name
    @fID    = params.fID
    @aTox   = params.aTox
    @pubKey = params.pubKey.slice 0, 64
    @online = params.online
    @status = params.status
    @color  = "#a2a2a2F"

    @currentStatus  = params.status
    @isFirstConnect = true

  setPreeMSGhandler: -> @aTox.term.stub {'msg': 'setPreeMSGhandler'}

  receivedMsg: (msg) ->
  friendName: (@name) ->
  friendStatusMessage: (@status) ->
  friendStatus: (newStatus) ->
    status = 'offline'

    switch newStatus
      when @aTox.TOX.consts.TOX_USER_STATUS_NONE then status = 'online'
      when @aTox.TOX.consts.TOX_USER_STATUS_AWAY then status = 'away'
      when @aTox.TOX.consts.TOX_USER_STATUS_BUSY then status = 'busy'
      when -1                                    then status = 'offline'
      when -2                                    then status = @currentStatus

    @online = status

    @currentStatus = status

    if @isFirstConnect
      @firstConnect()
      @isFirstConnect = false

  firstConnect: ->
    @aTox.manager.addBot this

  friendConnectionStatus: (newConnectionStatus) ->
    if newConnectionStatus is @aTox.TOX.consts.TOX_CONNECTION_NONE
      @friendStatus -1
    else
      @friendStatus -2 # Back online


  inf: (params) ->
    @aTox.term.inf {msg: "Bot '#{@name}': #{params.msg}", cID: -1}
    return unless params.notify? and params.notify is true
    @aTox.gui.notify {name: @name, content: params.msg}

  stub: (params) ->
    @aTox.term.stub {msg: "Friend '#{@name}': #{params.msg}", cID: -1}

  err: (params) ->
    @aTox.term.err {msg: "Friend '#{@name}': #{params.msg}", cID: -1}
