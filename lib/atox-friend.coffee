Chat = require './atox-chat'
os          = require 'os'
fs          = require 'fs'

module.exports =
class Friend
  constructor: (params) ->
    @name   = params.name
    @fID    = params.fID
    @aTox   = params.aTox
    @pubKey = params.pubKey.slice 0, 64
    @online = params.online
    @status = params.status
    @img    = 'none'
    @color  = @randomColor()

    @createChat()

  createChat: ->
    @chat = new Chat {
      aTox: @aTox
      group: false
      parent: this
    }

  needChat: -> @createChat() unless @chat? # Creates chat if needed
  sendMSG: (msg) -> @aTox.TOX.sendToFriend {fID: @fID, msg: msg}

  # TOX events
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
    @needChat()
    @chat.processMsg {msg: msg, color: @color, name: @name }
    @aTox.gui.notify {name: @name, content: msg}

  nameChange: (newName) ->
    @inf {msg: "#{@name} is now #{newName}", notify: true}
    @name = newName
    @chat.update 'name' if @chat?

  statusChange: (newStatus) ->
    @status = newStatus
    @inf {msg: "Status of #{@name} is now #{@status}", notify: true}
    @chat.update 'status' if @chat?

  userStatus: (newStatus) ->
    status = 'offline'

    switch newStatus
      when 0 then status = 'online'
      when 1 then status = 'away'
      when 2 then status = 'busy'

    @inf {msg: "#{@name} is now #{status}", notify: true}
    @online = status
    @chat.update 'online' if @chat?

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
