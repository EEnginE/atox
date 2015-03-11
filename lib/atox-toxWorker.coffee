toxcore = require 'toxcore'
fs = require 'fs'
os = require 'os'

Friend = require './atox-friend'
Group  = require './atox-group'

module.exports =
class ToxWorker
  constructor: (params) ->
    @DLL        = params.dll
    @aTox       = params.aTox
    @fConnectCB = params.fConnectCB

  myInterval: (s, cb) ->
    setInterval cb, s

  myTimeout: (s, cb) ->
    setTimeout cb, s

  isConnected: ->
    if @TOX.isConnectedSync()
      return if @hasConnection is true
      @aTox.gui.setUserOnlineStatus 'connected'
      @inf "<span style='color:rgba(0, 255, 0, 1)''>Connected!</span>"
      @hasConnection = true
      @firstConnectCB() if @firstConnect is true
      @firstConnect  = false
    else
      return if @hasConnection is false
      @aTox.gui.setUserOnlineStatus 'disconnected'
      @inf "<span style='color:rgba(255, 0, 0, 1)''>Disconnected.</span>"
      @hasConnection = false

  startup: ->
    rawJSON     = fs.readFileSync "#{__dirname}/../nodes.json"
    paresedJSON = JSON.parse rawJSON
    @nodes      = paresedJSON.bootstrapNodes
    @aToxNodes  = paresedJSON.aToxNodes

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
    @TOX.on 'groupMessage',        (e) => @groupMessageCB        e unless @TOX.peernumberIsOursSync e.group(), e.peer()
    @TOX.on 'groupTitle',          (e) => @groupTitleCB          e
    @TOX.on 'groupNamelistChange', (e) => @groupNamelistChangeCB e if @groups[e.group()]?

    @friends = []
    @groups  = []

    @setName   atom.config.get 'aTox.userName'
    @setAvatar atom.config.get 'aTox.userAvatar'
    @setStatus "I am a Bot :)"

    for n in @nodes
      @TOX.bootstrapFromAddressSync(n.address, n.port, n.key)

    @TOX.start()
    @inf "Started TOX"
    @inf "Name:  <span style='color:rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )'>#{atom.config.get 'aTox.userName'}</span>"
    @inf "My ID: <span style='color:rgba(100, 100, 255, 1)'>#{@TOX.getAddressHexSync()}</span>"

    @friendOnline = []

    @firstConnect = true
    @myInterval 500, => @isConnected()

  firstConnectCB: ->
    for n in @aToxNodes
      @sendFriendRequest {addr: "#{n.key}", msg: "Hello #{n.maintainer}", hidden: true}
      @inf "Added aTox bot: Maintainer: #{n.maintainer}; Key: #{n.key}"

    @fConnectCB()

  avatarInfCB:           (e) -> @TOX.requestAvatarData( e.friend() )
  avatarDataCB:          (e) -> @friends[e.friend()].avatarData   e
  friendMsgCB:           (e) -> @friends[e.friend()].receivedMsg  e.message()
  nameChangeCB:          (e) -> @friends[e.friend()].nameChange   e.name()
  statusChangeCB:        (e) -> @friends[e.friend()].statusChange e.statusMessage()
  userStatusCB:          (e) -> @friends[e.friend()].userStatus   e.status()
  groupMessageCB:        (e) -> @groups[e.group()].groupMessage  {d: e.message(), p: e.peer()}
  groupTitleCB:          (e) -> @groups[e.group()].groupTitle    {d: e.title(),   p: e.peer()}
  groupNamelistChangeCB: (e) -> @groups[e.group()].gNLC          {d: e.change(),  p: e.peer()}

  reqAvatar: ->
    for i in @TOX.getFriendListSync()
      @inf "Requesting Avatar (Friend ID: <span style='color:rgba(100, 100, 255, 1)'>#{i}</span>)"
      @TOX.requestAvatarData( i )

  friendRequestCB: (e) ->
    @inf "Friend request: #{e.publicKeyHex()} (Autoaccept)"
    fID = 0

    try
      fID = @TOX.addFriendNoRequestSync e.publicKey()
    catch error
      @err "Failed to add Friend"
      return

    @friends[fID] = new Friend {
      name:   e.publicKeyHex()
      fID:    fID
      online: 'offline'
      status: "Working, please wait..."
      aTox:   @aTox
      pubKey: e.publicKeyHex()
    }

    @inf "Added Friend #{fID}" #TODO: Move this into the contacts, add the randomized color to this string within the contact

    @friendOnline[fID] = -1

    @myInterval 1000, =>
      @TOX.getFriendConnectionStatus fID, (a, b) =>
        return @err "Friend connection error #{fID}" if a
        @friendAutoremove {fID: fID, online: b}


  getFIDfromKEY: (key) ->
    for i in @friends
      return i.fID if i.pubKey is key

    return -1

#     _____                         _____ _          __  __
#    |  __ \                       /  ___| |        / _|/ _|
#    | |  \/_ __ ___  _   _ _ __   \ `--.| |_ _   _| |_| |_
#    | | __| '__/ _ \| | | | '_ \   `--. \ __| | | |  _|  _|
#    | |_\ \ | | (_) | |_| | |_) | /\__/ / |_| |_| | | | |
#     \____/_|  \___/ \__,_| .__/  \____/ \__|\__,_|_| |_|
#                          | |
#                          |_|

  createGroupChat: (e) ->
  #TODO: Find local repositories and open their chats on startup
  #atom.project.getRepositories().getConfigValue("remote.origin.url")
    try
      gID = @TOX.addGroupchatSync()
    catch e
      return @err "Failed to add group chat"

    @inf "Added group chat #{gID}" #TODO ret not set!

    @groups[gID] = new Group {
      name:   "Group Chat ##{gID}"
      gID:    gID
      aTox:   @aTox
    }

  groupInviteCB: (e) ->
    @inf "Received group invite from #{e.friend()}"

    try
      gID = @TOX.joinGroupchatSync e.friend(), e.data()
    catch e
      return @err "Failed to join group chat"

    @inf "Joined group chat #{gID}"

    @groups[gID] = new Group {
      name:   "Group Chat ##{ret}"
      gID:    @TOX.getGroupchatTitle( ret )
      aTox:   @aTox
    }

  getPeerInfo: (e) ->
    return if @TOX.peernumberIsOurs e.gID, e.peer
    #try
    key  = @TOX.getGroupchatPeerPublicKeyHexSync e.gID, e.peer
    name = @TOX.getGroupchatPeernameSync         e.gID, e.peer
    fID  = @getFIDfromKEY                        key
    @inf "FID: #{fID}"

    if fID < 0
      e.cb {key: key, fID: -1, name: name, color: "#AAA"} if e.cb?
      return @inf "Peer #{e.peer} in GC #{e.gID} is '#{name}' and NOT A CONTACT (#{key})"

    e.cb {key: key, fID: fID, name: name, color: @friends[fID].color} if e.cb?
    @inf "Peer #{e.peer} in GC #{e.gID} is '#{name}' (#{key})"
    #catch err
    #  console.log err
    #  return @err "Failed to get peer (#{e.peer}) info in group #{e.gID}"

  invite: (e) ->
    try
      @TOX.inviteSync e.fID, e.gID
    catch err
      return @err "Failed to invite friend #{e.fID} to #{e.gID}"

  sendToGC: (e) ->
    try
      @TOX.sendGroupchatMessageSync e.gID, e.msg
    catch e
      @err "Failed to send MSG to group chat #{e.gID}"

#     _____      _     _____ _______   __
#    /  ___|    | |   |_   _|  _  \ \ / /
#    \ `--.  ___| |_    | | | | | |\ V /
#     `--. \/ _ \ __|   | | | | | |/   \
#    /\__/ /  __/ |_    | | \ \_/ / /^\ \
#    \____/ \___|\__|   \_/  \___/\/   \/
#

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
      fID = @TOX.addFriendSync "#{e.addr}", "#{e.msg}"
    catch err
      @err "Failed to send friend request"
      return

    @friends[fID] = new Friend {
      name:   e.addr
      fID:    fID
      online: 'offline'
      status: "Working, please wait..."
      aTox:   @aTox
      pubKey: e.addr
    }

    @inf "Added Friend #{fID}"

  sendToFriend: (e) ->
    try
      @TOX.sendMessageSync e.fID, e.msg
    catch e
      @err "Failed to send MSG to #{e.fID}"

  onlineStatus: (newS) ->
    status = 2

    switch newS
      when 'online' then status = 0
      when 'away'   then status = 1
      when 'busy'   then status = 2

    @TOX.setUserStatusSync status

    @aTox.gui.notify {
      name:     newS.charAt(0).toUpperCase() + newS.slice(1)
      content: "You are now #{newS}"
      img:      atom.config.get 'aTox.userAvatar'
    }
    color = @getColorByStatus(newS)
    @inf msg: "You are now <span style='color:#{color}'>#{newS}</span>" # TODO send this to all chats

  getColorByStatus: (status) ->
    if status is "online"
      return "rgba(50, 255, 50, 1)"
    else if status is "offline"
      return "rgba(80, 80, 80, 1)"
    else if status is "busy"
      return "rgba(255, 50, 50, 1)"
    else if status is "away"
      return "rgba(255, 255, 50, 1)"

  friendAutoremove: (params) ->
    return @friendOnline[params.fID] = 0 if params.online is true
    return if @friendOnline[params.fID] < 0

    @friendOnline[params.fID]++
    if @friendOnline[params.fID] > 2
      @friends[fID].userStatus 3
      @friendOnline[params.fID] = -1

  inf: (msg) -> @aTox.term.inf {msg: "TOX: #{msg}"}
  err: (msg) -> @aTox.term.err {msg: "TOX: #{msg}"}
