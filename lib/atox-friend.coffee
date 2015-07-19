Chat = require './atox-chat'

ToxFriendBase = require './atox-toxFriendBase'

module.exports =
class Friend extends ToxFriendBase
  constructor: (params) ->
    @isHuman = true
    super params

    @aTox = params.aTox

    @color = @randomColor()
    @chat = new Chat {
      aTox: @aTox
      group: false
      parent: this
    }

    @msgBuffer = []
    @inf {"msg": "Added Friend #{@getID()}"}

  destructor: ->
    super()
    @chat.destructor()

  getIsHuman: -> @isHuman

  REQ_joinCollab: (d) ->
    for i in @aTox.collab.collabList
      if i.getID() is d.cID
        @aTox.TOX.invite {"fID": @fID, "gID": i.getGroup().gID}
        @rCollabInviteReturn = "success"
        return
    @rCollabInviteReturn = "not found"

  RESP_joinCollab: (d) ->
    if d.inviteReturn is "success"
      @rInviteRequestToCollabSuccess = true
    else
      @aTox.term.warn {
        "title": "Invite to collab '#{d.name}' failed"
        "msg":   "Return: #{d.inviteReturn}"
      }
      @rInviteRequestToCollabSuccess = false

  sendMSG: (msg, cb) ->
    if @online is 'offline'
      @msgBuffer.push {"msg": msg, "cb": cb}
      return cb 'offline'
    cb @aTox.TOX.sendToFriend {fID: @fID, msg: msg}

  # TOX events
  newAvatar: ->
    @inf {"msg": "New Avatar"}
    @chat.update 'img'

  receivedMsg: (msg) ->
    @chat.genAndAddMSG {"msg": msg, "color": @color, "name": @name }
    @inf {"msg": msg, "noChat": true}

  friendRead: (id) -> @chat.markAsRead id

  friendName: (newName) ->
    super newName
    @inf {"msg": "#{@name} is now '#{newName}'"}
    @chat.update 'name'

  friendStatusMessage: (newStatus) ->
    super newStatus
    @inf {"msg": "Status of #{@name} is now '#{@status}'"}
    @chat.update 'status'

  friendStatus: (newStatus) ->
    oldOnline = @online
    super newStatus
    unless @online is oldOnline
      @inf {"msg": "#{@name} is now #{@online}"}
      @chat.update 'online'
      unless @online is 'offline'
        @sendMSG i.msg, i.cb for i in @msgBuffer
        @msgBuffer = []

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
      "noChat": params.noChat if params.noChat?
    }
