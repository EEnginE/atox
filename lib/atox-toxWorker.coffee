toxcore = require 'toxcore'
fs = require 'fs'
os = require 'os'

module.exports =
class ToxWorker
  constructor: (opts) ->
    @event = opts.event
    @DLL   = opts.dll

  myInterval: (s, cb) ->
    setInterval cb, s

  myTimeout: (s, cb) ->
    setTimeout cb, s

  isConnected: ->
    if @TOX.isConnectedSync()
      return if @hasConnection is true
      @event.emit 'onlineStatus', {tid: 1, d: 'connected'}
      @inf "Connected!"
      @hasConnection = true
      @event.emit 'first-connect' if @firstConnect is true
      @firstConnect  = false
    else
      return if @hasConnection is false
      @event.emit 'onlineStatus', {tid: 1, d: 'disconnected'}
      @inf "Disconnected."
      @hasConnection = false

  startup: ->
    @nodes = [
      { maintainer: 'Impyy', address: '178.62.250.138', port: 33445, key: '788236D34978D1D5BD822F0A5BEBD2C53C64CC31CD3149350EE27D4D9A2F9B6B' },
      { maintainer: 'sonOfRa', address: '144.76.60.215', port: 33445, key: '04119E835DF3E78BACF0F84235B300546AF8B936F035185E2A8E9E0A67C8924F' }
    ];
    if os.platform().indexOf('win') > -1
      @TOX = new toxcore.Tox({av: false, path: "#{@DLL}"})
    else
      @TOX = new toxcore.Tox({av: false})

    @err "Failed to load TOX" unless @TOX.checkHandle (e) =>

    @TOX.on 'avatarData',          (e) => @avatarDataCB          e
    @TOX.on 'avatarInfo',          (e) => @avatarInfCB           e
    @TOX.on 'friendMessage',       (e) => @friendMsgCB           e
    @TOX.on 'friendRequest',       (e) => @friendRequestCB       e
    @TOX.on 'nameChange',          (e) => @nameChangeCB          e
    @TOX.on 'statusMessage',       (e) => @statusChangeCB        e
    @TOX.on 'userStatus',          (e) => @userStatusCB          e
    @TOX.on 'groupInvite',         (e) => @groupInviteCB         e
    @TOX.on 'groupMessage',        (e) => @groupMessageCB        e
    @TOX.on 'groupTitle',          (e) => @groupTitleCB          e
    @TOX.on 'groupNamelistChange', (e) => @groupNamelistChangeCB e

    @event.on 'setName',           (e) => @setName               e
    @event.on 'setAvatar',         (e) => @setAvatar             e
    @event.on 'setStatus',         (e) => @setStatus             e
    @event.on 'onlineStatus',      (e) => @onlineStatus          e
    @event.on 'sendToFriend',      (e) => @sendToFriend          e
    @event.on 'addFriend',         (e) => @sendFriendRequest     e
    @event.on 'addGroupChat',      (e) => @addGroupChat          e
    @event.on 'invite',            (e) => @invite                e
    @event.on 'sendToGC',          (e) => @sendToGC              e
    @event.on 'getPeerInfo',       (e) => @getPeerInfo           e
    @event.on 'toxDO',                 => @TOX.do => @inf "TOX DONE"
    @event.on 'reqAvatar',             => @reqAvatar()

    @event.on 'userStatusAT',      (e) => @onlineStatus e

    @event.emit 'setName',   atom.config.get 'aTox.userName'
    @event.emit 'setAvatar', atom.config.get 'aTox.userAvatar'
    @event.emit 'setStatus', "I am a Bot :)"

    for n in @nodes
      @TOX.bootstrapFromAddressSync(n.address, n.port, n.key)

    @TOX.start()
    @inf "Started TOX"
    @inf "Name:  <span style='color:rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )'>#{atom.config.get 'aTox.userName'}</span>"
    @inf "My ID: <span style='color:rgba(100, 100, 255, 1)'>#{@TOX.getAddressHexSync()}</span>"

    @friendOnline = []

    @firstConnect = true
    @myInterval 500, => @isConnected()

  avatarDataCB:          (e) -> @event.emit 'avatarDataAT',   {tid: e.friend(), d: e}
  avatarInfCB:           (e) -> @TOX.requestAvatarData( e.friend() )
  friendMsgCB:           (e) -> @event.emit 'friendMsgAT',    {tid: e.friend(), d: e.message()}
  nameChangeCB:          (e) -> @event.emit 'nameChangeAT',   {tid: e.friend(), d: e.name()}
  statusChangeCB:        (e) -> @event.emit 'statusChangeAT', {tid: e.friend(), d: e.statusMessage()}
  userStatusCB:          (e) -> @event.emit 'userStatusAT',   {tid: e.friend(), d: e.status()}
  groupMessageCB:        (e) -> @event.emit 'groupMessageAT', {tid: e.group(),  d: e.message(), p: e.peer()}
  groupTitleCB:          (e) -> @event.emit 'groupTitleAT',   {tid: e.group(),  d: e.title(),   p: e.peer()}
  groupNamelistChangeCB: (e) -> @event.emit 'gNLC_AT',        {tid: e.group(),  d: e.change(),  p: e.peer()}

  reqAvatar: ->
    for i in @TOX.getFriendListSync()
      @inf "Requesting Avatar (Friend ID: <span style='color:rgba(100, 100, 255, 1)'>#{i}</span>)"
      @TOX.requestAvatarData( i )

  friendRequestCB: (e) ->
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
      tid:    fNum
      pubKey: e.publicKeyHex()
    }
    @inf "Added Friend #{fNum}" #TODO: Move this into the contacts, add the randomized color to this string within the contact

    @friendOnline[fNum] = -1

    @myInterval 1000, =>
      @TOX.getFriendConnectionStatus fNum, (a, b) =>
        return @err "Friend connection error #{fNum}" if a
        @friendAutoremove {fid: fNum, online: b}

  addGroupChat: (e) ->
    try
      ret = @TOX.addGroupchatSync()
    catch e
      return @err "Failed to add group chat"

    @inf "Added group chat #{ret}"

    @event.emit 'aTox.new-contact', {
      name:   "Group Chat ##{ret}"
      status: ''
      online: 'group'
      tid:    ret
    }

  groupInviteCB: (e) ->
    @inf "Received group invite from #{e.friend()}"

    try
      ret = @TOX.joinGroupchatSync e.friend(), e.data()
    catch e
      return @err "Failed to join group chat"

    @inf "Joined group chat #{ret}"

    @event.emit 'aTox.new-contact', {
      name:   @TOX.getGroupchatTitle( ret )
      status: ''
      online: 'group'
      tid:    ret
    }

  getPeerInfo: (e) ->
    return if @TOX.peernumberIsOurs e.gNum, e.peer
    try
      key  = @TOX.getGroupchatPeerPublicKeyHexSync e.gNum, e.peer
      name = @TOX.getGroupchatPeernameSync         e.gNum, e.peer
      @event.emit 'getFidFromPubKey', {
        pubKey: key,
        cb: (fid) =>
          e.cb {key: key, fid: fid, name: name} if e.cb?
          @inf "Peer #{e.peer} in GC #{e.gNum} is '#{name}' (#{key})"
      }
    catch err
      console.log err
      return @err "Failed to get peer (#{e.peer}) info in group #{e.gNum}"

  invite: (e) ->
    try
      @TOX.inviteSync e.friend, e.gNum
    catch err
      return @err "Failed to invite friend #{e.friend} to #{e.gNum}"

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
      tid:    fNum
    }

    @inf "Added Friend #{fNum}"

  sendToFriend: (e) ->
    try
      @TOX.sendMessageSync e.tid, e.d
    catch e
      @err "Failed to send MSG to #{e.tid}"

  sendToGC: (e) ->
    try
      @TOX.sendGroupchatMessageSync e.tid, e.d
    catch e
      @err "Failed to send MSG to group chat #{e.tid}"

  onlineStatus: (e) ->
    return unless e.tid < 0

    status = 2

    switch e.d
      when 'online' then status = 0
      when 'away'   then status = 1
      when 'busy'   then status = 2

    @TOX.setUserStatusSync status

    @event.emit 'notify', {
      type:    'inf'
      name:     e.d.charAt(0).toUpperCase() + e.d.slice(1)
      content: "You are now #{e.d}"
      img:      atom.config.get 'aTox.userAvatar'
    }
    color = @getColorByStatus(e.d)
    @event.emit  'Terminal', {cid: -2, msg: "You are now <span style='color:#{color}'>#{e.d}</span>"} #TODO: Send this to all chat windows

  getColorByStatus: (status) ->
    console.log status
    if status is "online"
      return "rgba(50, 255, 50, 1)"
    else if status is "offline"
      return "rgba(80, 80, 80, 1)"
    else if status is "busy"
      return "rgba(255, 50, 50, 1)"
    else if status is "away"
      return "rgba(255, 255, 50, 1)"

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

    @event.emit 'Terminal', {cid: -2, msg: "TOX: [Info] #{msg}"}

  err: (msg) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'TOX'
      content: msg
    }

    @event.emit 'Terminal', {cid: -2, msg: "TOX: [Error] #{msg}"}
