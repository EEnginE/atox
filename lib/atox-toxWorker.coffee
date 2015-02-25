toxcore = require 'toxcore'
fs = require 'fs'
os = require 'os'

module.exports =
class ToxWorker
  constructor: (event) ->
    @event = event

  startup: ->
    if os.platform().indexOf('win') > -1
      @TOX = new toxcore.Tox({av: false, path: __dirname + "\\libtoxcore.dll"})
    else
      @TOX = new toxcore.Tox({av: false})

    @err "Failed to load TOX" unless @TOX.checkHandle (e) =>

    @TOX.on 'avatarData',     (e) => @avatarDataCB   e
    @TOX.on 'avatarInfo',     (e) => @avatarInfCB    e
    @TOX.on 'friendMessage',  (e) => @friendMsgCB    e
    @TOX.on 'friendRequest',  (e) => @friendRequest  e
    @TOX.on 'nameChange',     (e) => @nameChangeCB   e
    @TOX.on 'statusMessage',  (e) => @statusChangeCB e
    @TOX.on 'userStatus',     (e) => @userStatusCB   e

    @event.on 'setName',      (e) => @setName           e
    @event.on 'setAvatar',    (e) => @setAvatar         e
    @event.on 'setStatus',    (e) => @setStatus         e
    @event.on 'onlineStatus', (e) => @onlineStatus      e
    @event.on 'sendToFriend', (e) => @sendToFriend      e
    @event.on 'addFriend',    (e) => @sendFriendRequest e

    @event.on 'userStatusAT', (e) => @onlineStatus e

    @event.emit 'setName',   atom.config.get 'atox.userName'
    @event.emit 'setAvatar', atom.config.get 'atox.userAvatar'
    @event.emit 'setStatus', "I am a Bot :)"

    @TOX.start()
    @inf "Started TOX"
    @inf "Name:  #{atom.config.get 'atox.userName'}"
    @inf "My ID: #{@TOX.getAddressHexSync()}"

  avatarDataCB:   (e) -> @event.emit 'avatarDataAT',   {tid: e.friend(), d: e}
  avatarInfCB:    (e) -> @TOX.requestAvatarData( e.friend() )
  friendMsgCB:    (e) -> @event.emit 'friendMsgAT',    {tid: e.friend(), d: e.message()}
  nameChangeCB:   (e) -> @event.emit 'nameChangeAT',   {tid: e.friend(), d: e.name()}
  statusChangeCB: (e) -> @event.emit 'statusChangeAT', {tid: e.friend(), d: e.statusMessage()}
  userStatusCB:   (e) -> @event.emit 'userStatusAT',   {tid: e.friend(), d: e.status()}

  setName: (name) ->
    @TOX.setName "#{name}"

  setAvatar: (path) ->
    fs.readFile "#{path}", (err, data) =>
      if err
        @err "Failed to load #{path}"
        return
      @TOX.setAvatar 1, data

  setStatus: (s) ->
    @TOX.setStatusMessage "#{s}"

  sendFriendRequest: (e) ->
    @inf "Sent friend request: #{e.addr}"

    try
      fNum = @TOX.addFriendSync "#{e.addr}", "#{e.msg}"
    catch err
      @err "Failed to send friend request"
      return

    @event.emit 'atox.new-contact', {
      name:   e.addr
      status: "Working Please wait..."
      online: 'offline'
      cid:    fNum
      tid:    fNum
    }

    @inf "Added Friend #{fNum}"

  sendToFriend: (e) ->
    @TOX.sendMessage e.d, e.tid, (a) =>

  onlineStatus: (e) ->
    return unless e.tid < 0

    status = 2

    switch e.d
      when 'online' then status = 0
      when 'away'   then status = 1
      when 'busy'   then status = 2

    try
      @TOX.setUserStatus status # ERROR!!!
    catch err
      @event.emit 'notify', {
        type:    'err'
        name:    'ERROR'
        content: "Failed to set status to #{e.d}"
        img:      atom.config.get 'atox.userAvatar'
      }

    @event.emit 'notify', {
      type:    'inf'
      name:     e.d.charAt(0).toUpperCase() + e.d.slice(1)
      content: "You are now #{e.d}"
      img:      atom.config.get 'atox.userAvatar'
    }

    @event.emit  'atox.terminal', "You are now #{e.d}"

  friendRequest: (e) ->
    @inf "Friend request: #{e.publicKeyHex()} (Autoaccept)"
    fNum = 0

    try
      fNum = @TOX.addFriendNoRequestSync e.publicKey()
    catch error
      @err "Failed to add Friend"
      return

    @event.emit 'atox.new-contact', {
      name:   e.publicKeyHex()
      status: "Working Please wait..."
      online: 'offline'
      cid:    fNum
      tid:    fNum
    }
    @inf "Added Friend #{fNum}"

  inf: (msg) ->
    @event.emit 'notify', {
      type: 'inf'
      name: 'TOX'
      content: msg
    } if atom.config.get 'atox.debugNotifications'

    @event.emit 'atox.terminal', "TOX: [Info] #{msg}"

  err: (msg) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'TOX'
      content: msg
    }

    @event.emit 'atox.terminal', "TOX: [Error] #{msg}"
