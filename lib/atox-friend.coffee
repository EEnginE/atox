Chat = require './atox-chat'
os   = require 'os'
fs   = require 'fs'

ToxFriendBase = require './atox-toxFriendBase'

module.exports =
class Friend extends ToxFriendBase
  constructor: (params) ->
    super params

    @color = @randomColor()
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

  friendRead: (id) -> @chat.markAsRead id

  friendName: (newName) ->
    super newName
    @inf {"msg": "#{@name} is now '#{newName}'", "notify": not @hidden}
    @chat.update 'name'

  friendStatusMessage: (newStatus) ->
    super newStatus
    @inf {"msg": "Status of #{@name} is now '#{@status}'", "notify": not @hidden}
    @chat.update 'status'

  friendStatus: (newStatus) ->
    oldOnline = @online
    super newStatus
    unless @online is oldOnline
      @inf {msg: "#{@name} is now #{@online}", notify: not @hidden}
      @chat.update 'online'

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
