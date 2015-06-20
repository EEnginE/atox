ToxFriendProtBase = require './botProtocol/prot-toxFriendProtBase'

module.exports =
class ToxFriendBase extends ToxFriendProtBase
  constructor: (params) ->
    params.status = 'offline' unless params.status?

    @name   = params.name
    @fID    = params.fID
    @aTox   = params.aTox
    @pubKey = params.pubKey.slice 0, 64
    @online = params.online
    @status = params.status
    @img    = 'none'

    @currentStatus = params.status

    @isFirstConnect = true

  friendName: (@name) ->
  friendStatusMessage: (@status) ->
  friendStatus: (newStatus) ->
    status = 'offline'

    switch newStatus
      when @aTox.TOX.consts.TOX_USER_STATUS_NONE then status = 'online'
      when @aTox.TOX.consts.TOX_USER_STATUS_AWAY then status = 'away'
      when @aTox.TOX.consts.TOX_USER_STATUS_BUSY then status = 'busy'
      when -1                                              then status = 'offline'
      when -2                                              then status = @currentStatus

    @online        = status
    @currentStatus = status

  firstConnect: ->
    @pInitBotProtocol {
      "id":      @fID
      "manager": @aTox.manager
      "sendCB":  (msg) => @aTox.TOX.sendToFriendCMD {"fID": @fID, "msg": msg}
      "pubKey":  @pubKey
    }

  friendConnectionStatus: (newConnectionStatus) ->
    if newConnectionStatus is @aTox.TOX.consts.TOX_CONNECTION_NONE
      @friendStatus -1
    else
      @friendStatus -2 # Back online
      if @isFirstConnect
        @firstConnect()
        @isFirstConnect = false

  receivedMsg: (msg) -> @stub "receivedMsg"
  sendMSG: (msg, cb) -> @stub "sendMSG"
  friendRead: (id)   -> @stub "firendRead"

  stub: (func) ->
    @aTox.term.stub {msg: "CLASS: ToxFriendBase -- Unimplemeted base function #{func}!", cID: -1}
