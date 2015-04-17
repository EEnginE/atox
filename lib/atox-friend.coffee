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
    if params.hidden? and params.hidden is true
      @hidden = true
    else
      @hidden = false

    @onFirstOnline = params.onFirstOnline
    @currentStatus = params.status

    @createChat() unless @hidden
    @firstOnline = true

  preeMSGhandler: (msg) -> true # return falue: true - display in chat, false ignore

  createChat: ->
    @chat = new Chat {
      aTox: @aTox
      group: false
      parent: this
    }
    @hidden = false

  setPreeMSGhandler: (cb) -> @preeMSGhandler = cb

  needChat: -> @createChat() unless @chat? # Creates chat if needed
  sendMSG: (msg) -> @aTox.TOX.sendToFriend {fID: @fID, msg: msg}

  # TOX events

  # TODO add avatar support for the new Tox API
  avatarData: (params) ->
    if params.format() == 0
      @inf { msg: "#{@name} has no Avatar" }
      @img = 'none'
      @chat.update 'img' if @chat?
      return

    if ! params.isValid()
      @inf { msg: "#{@name} has an invalid (or no) Avatar" }
      @img = 'none'
      @chat.update 'img' if @chat?
      return

    @inf { msg: "#{@name} has a new Avatar (Format: #{params.format()})"}
    @img = "#{os.tmpdir()}/atox-Avatar-#{params.hashHex()}"
    @chat.update 'img' if @chat?
    @inf { msg: "Avatar Path: #{@img}"}
    fs.writeFile @img, params.data(), (error) =>
      return if error
      @chat.update() if @chat?

  receivedMsg: (msg) ->
    if @preeMSGhandler?
      return unless @preeMSGhandler msg

    @needChat()
    @chat.processMsg {msg: msg, color: @color, name: @name }
    @aTox.gui.notify {name: @name, content: msg}

  friendName: (newName) ->
    @inf {"msg": "#{@name} is now '#{newName}'", "notify": not @hidden}
    @name = newName
    @chat.update 'name' if @chat?

  friendStatusMessage: (newStatus) ->
    @status = newStatus
    @inf {"msg": "Status of #{@name} is now '#{@status}'", "notify": not @hidden}
    @chat.update 'status' if @chat?

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
    @chat.update 'online' if @chat?

    if @firstOnline and @onFirstOnline?
      @onFirstOnline this # Call the first-time-online-callback

    @firstOnline = false
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
    if @chat?
      cID = @chat.cID
    else
      cID = -1

    @aTox.term.inf {msg: "Friend '#{@name}': #{params.msg}", cID: cID}
    return unless params.notify? and params.notify is true
    @aTox.gui.notify {name: @name, content: params.msg}
