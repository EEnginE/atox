Chat = require './atox-chat'
os   = require 'os'
fs   = require 'fs'

module.exports =
class Friend
  constructor: (params) ->
    params.status = 'offline' unless params.status?

    @name   = params.name
    @fID    = params.fID
    @aTox   = params.aTox
    @pubKey = params.pubKey.slice 0, 64
    @online = params.online
    @status = params.status
    @img    = 'none'
    @color  = @randomColor()

    @currentStatus = params.status

    @chat = new Chat {
      aTox: @aTox
      group: false
      parent: this
    }

  sendMSG: (msg, cb) ->
    cb @aTox.TOX.sendToFriend {fID: @fID, msg: msg}

  # TOX events

  # TODO add avatar support for the new Tox API
  avatarData: (params) ->
    if params.format() == 0
      @inf { msg: "#{@name} has no Avatar" }
      @img = 'none'
      @chat.update 'img'
      return

    if ! params.isValid()
      @inf { msg: "#{@name} has an invalid (or no) Avatar" }
      @img = 'none'
      @chat.update 'img'
      return

    @inf { msg: "#{@name} has a new Avatar (Format: #{params.format()})"}
    @img = "#{os.tmpdir()}/atox-Avatar-#{params.hashHex()}"
    @chat.update 'img'
    @inf { msg: "Avatar Path: #{@img}"}
    fs.writeFile @img, params.data(), (error) =>
      return if error
      @chat.update()

  receivedMsg: (msg) ->
    @chat.genAndAddMSG {"msg": msg, "color": @color, "name": @name }
    @inf {"msg": msg, "noChat": true}

  firendRead: (id) -> @chat.markAsRead id

  friendName: (newName) ->
    @inf {"msg": "#{@name} is now '#{newName}'", "notify": not @hidden}
    @name = newName
    @chat.update 'name'

  friendStatusMessage: (newStatus) ->
    @status = newStatus
    @inf {"msg": "Status of #{@name} is now '#{@status}'", "notify": not @hidden}
    @chat.update 'status'

  friendStatus: (newStatus) ->
    status = 'offline'

    switch newStatus
      when @aTox.TOX.consts.TOX_USER_STATUS_NONE then status = 'online'
      when @aTox.TOX.consts.TOX_USER_STATUS_AWAY then status = 'away'
      when @aTox.TOX.consts.TOX_USER_STATUS_BUSY then status = 'busy'
      when -1                                    then status = 'offline'
      when -2                                    then status = @currentStatus

    @inf {msg: "#{@name} is now #{status}", notify: not @hidden}
    @online = status
    @chat.update 'online'

    @currentStatus = status

  friendConnectionStatus: (newConnectionStatus) ->
    if newConnectionStatus is @aTox.TOX.consts.TOX_CONNECTION_NONE
      @friendStatus -1
    else
      @friendStatus -2 # Back online

  # Utils
  randomNumber: (min, max) ->
    Math.floor(Math.random() * (max - min) + min)

  randomColor: ->
    # Make sure color is bright enough
    mainColor = @randomNumber 1, 3

    red = green = blue = 0

    red   = 100 if mainColor is 1
    green = 100 if mainColor is 2
    blue  = 100 if mainColor is 3

    "rgba( #{@randomNumber( red, 255 )}, #{@randomNumber( green, 255 )}, #{@randomNumber( blue, 255 )}, 1 )"

  inf: (params) ->
    @aTox.term.inf {
      "title": "#{@name}"
      "msg": "#{params.msg}"
      "cID": @chat.cID
      "notify": params.notify
      "noChat": params.noChat if params.noChat?
    }
