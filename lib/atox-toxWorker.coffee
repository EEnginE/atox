toxcore = require 'toxcore'
fs = require 'fs'
os = require 'os'

module.exports =
class ToxWorker
  constructor: (e) ->
    @event = e.event
    @DLL   = e.dll

  myInterval: (s, cb) ->
    setInterval cb, s

  areWeConnected: ->
    if @TOX.isConnectedSync()
      return if @isConnected is true
      @event.emit 'onlineStatus', {tid: 1, d: 'connected'}
      @inf "connected"
      @isConnected = true
    else
      return if @isConnected is false
      @event.emit 'onlineStatus', {tid: 1, d: 'disconnected'}
      @inf "disconnected"
      @isConnected = false

  startup: ->
    if os.platform().indexOf('win') > -1
      @TOX = new toxcore.Tox({av: false, path: "#{@DLL}"})
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
    @event.on 'toxDO',            => @TOX.do => @inf "TOX DONE"

    @event.on 'userStatusAT', (e) => @onlineStatus e

    @event.emit 'setName',   atom.config.get 'aTox.userName'
    @event.emit 'setAvatar', atom.config.get 'aTox.userAvatar'
    @event.emit 'setStatus', "I am a Bot :)"

    @TOX.start()
    @inf "Started TOX"
    @inf "Name:  #{atom.config.get 'aTox.userName'}"
    @inf "My ID: #{@TOX.getAddressHexSync()}"

    @friendOnline = []

    @myInterval 500, => @areWeConnected()

  avatarDataCB:   (e) -> @event.emit 'avatarDataAT',   {tid: e.friend(), d: e}
  avatarInfCB:    (e) -> @TOX.requestAvatarData( e.friend() )
  friendMsgCB:    (e) -> @event.emit 'friendMsgAT',    {tid: e.friend(), d: e.message()}
  nameChangeCB:   (e) -> @event.emit 'nameChangeAT',   {tid: e.friend(), d: e.name()}
  statusChangeCB: (e) -> @event.emit 'statusChangeAT', {tid: e.friend(), d: e.statusMessage()}
  userStatusCB:   (e) -> @event.emit 'userStatusAT',   {tid: e.friend(), d: e.status()}

  setName: (name) ->
    @TOX.setName "#{name}"

  setAvatar: (path) ->
    if path != 'none'
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

    @event.emit 'aTox.new-contact', {
      name:   e.addr
      status: "Working, please wait..."
      online: 'offline'
      cid:    fNum
      tid:    fNum
    }

    @inf "Added Friend #{fNum}"

  sendToFriend: (e) ->
    @TOX.sendMessage e.tid, e.d, (a) =>

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
      @err "Failed to set status to #{e.d}"

    @event.emit 'notify', {
      type:    'inf'
      name:     e.d.charAt(0).toUpperCase() + e.d.slice(1)
      content: "You are now #{e.d}"
      img:      atom.config.get 'aTox.userAvatar'
    }

    @event.emit  'aTox.terminal', "You are now #{e.d}"

  friendRequest: (e) ->
    @inf "Friend request: #{e.publicKeyHex()} (Autoaccept)"
    fNum = 0

    try
      fNum = @TOX.addFriendNoRequestSync e.publicKey()
    catch error
      @err "Failed to add Friend"
      return

    @event.emit 'aTox.new-contact', {
      name:   e.publicKeyHex()
      status: "Working, please wait..."
      online: 'offline'
      cid:    fNum
      tid:    fNum
    }
    @inf "Added Friend #{fNum}"

    @friendOnline[fNum] = -1

    @myInterval 1000, =>
      @TOX.getFriendConnectionStatus fNum, (a, b) =>
        return @err "Friend connection error #{fNum}" if a
        @friendAutoremove {fid: fNum, online: b}

  friendAutoremove: (params) ->
    return @friendOnline[params.fid] = 0 if params.online is true
    return if @friendOnline[params.fid] < 0

    @friendOnline[params.fid]++
    if @friendOnline[params.fid] > 2
      @event.emit 'userStatusAT', {tid: params.fid, d: 3}
      @friendOnline[params.fid] = -1

  inf: (msg) ->
    @event.emit 'notify', {
      type: 'inf'
      name: 'TOX'
      content: msg
    } if atom.config.get 'aTox.debugNotifications'

    @event.emit 'aTox.terminal', "TOX: [Info] #{msg}"

  err: (msg) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'TOX'
      content: msg
    }

    @event.emit 'aTox.terminal', "TOX: [Error] #{msg}"
