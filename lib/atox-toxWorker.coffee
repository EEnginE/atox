toxcore = require 'toxcore'
fs = require 'fs'
os = require 'os'
shell = require 'shell'

Friend = require './atox-friend'
Bot    = require './atox-bot'
Group  = require './atox-group'

# coffeelint: disable=max_line_length

module.exports =
class ToxWorker
  constructor: (params) ->
    @DLL    = params.dll
    @aTox   = params.aTox
    @consts = toxcore.Consts

  myInterval: (s, cb) ->
    setInterval cb, s

  myTimeout: (s, cb) ->
    setTimeout cb, s

  handleExept: (name, e) ->
    @aTox.term.err  {
      'title': "Caught Exeption in #{name}"
      'msg':   "#{e}"
      'stack': e.stack
      'description': 'Internal Error'
    }

  startup: ->
    rawJSON     = fs.readFileSync "#{__dirname}/../nodes.json"
    paresedJSON = JSON.parse rawJSON
    @nodes      = paresedJSON.bootstrapNodes
    @aToxNodes  = paresedJSON.aToxNodes

    try
      if os.platform().indexOf('win') > -1
        @TOX = new toxcore.Tox({"path": "#{@DLL}"})
      else
        @TOX = new toxcore.Tox()
    catch e
      @err "Failed to init tox", e
      console.log e
      return

    @aTox.gui.setUserOnlineStatus 'disconnected'

    @TOX.on 'avatarData',             (e) => try @avatarDataCB e             catch a then @handleExept 'avatarData',             a
    @TOX.on 'avatarInfo',             (e) => try @avatarInfCB e              catch a then @handleExept 'avatarInfo',             a
    @TOX.on 'friendMessage',          (e) => try @friendMsgCB e              catch a then @handleExept 'friendMessage',          a
    @TOX.on 'friendReadReceipt',      (e) => try @friendReadReceiptCB e      catch a then @handleExept 'friendReadReceipt',      a
    @TOX.on 'friendRequest',          (e) => try @friendRequestCB e          catch a then @handleExept 'friendRequest',          a
    @TOX.on 'friendName',             (e) => try @friendNameCB e             catch a then @handleExept 'friendName',             a
    @TOX.on 'friendStatusMessage',    (e) => try @friendStatusMessageCB e    catch a then @handleExept 'friendStatusMessage',    a
    @TOX.on 'friendStatus',           (e) => try @friendStatusCB e           catch a then @handleExept 'friendStatus',           a
    @TOX.on 'friendConnectionStatus', (e) => try @friendConnectionStatusCB e catch a then @handleExept 'friendConnectionStatus', a
    @TOX.on 'selfConnectionStatus',   (e) => try @selfConnectionStatusCB e   catch a then @handleExept 'selfConnectionStatus',   a
    @TOX.on 'groupInvite',            (e) => try @groupInviteCB e            catch a then @handleExept 'groupInvite',            a
    @TOX.on 'groupMessage',           (e) => try @groupMessageCB e           catch a then @handleExept 'groupMessage',           a
    @TOX.on 'groupTitle',             (e) => try @groupTitleCB e             catch a then @handleExept 'groupTitle',             a
    @TOX.on 'groupNamelistChange',    (e) => try @groupNamelistChangeCB e    catch a then @handleExept 'groupNamelistChange',    a

    @friends      = []
    @groups       = []
    @sentRequests = []

    @setName   atom.config.get 'aTox.userName'
    #@setAvatar atom.config.get 'aTox.userAvatar'
    @setStatus "I am a Bot :)"

    for n in @nodes
      @TOX.bootstrapSync(n.address, n.port, n.key)

    @TOX.start()
    return @err "Failed to start TOX" unless @TOX.isStarted()
    @success "Started TOX"
    @inf "Name:  <span style='color:rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )'>#{atom.config.get 'aTox.userName'}</span>"
    @inf "My ID", "#{@TOX.getAddressHexSync()}"

    @isConnected  = false
    @firstConnect = true

  deactivate: ->
    @TOX.stop()

  firstConnectCB: ->
    for n in @aToxNodes
      @sendFriendRequest {
        'addr': "#{n.key}",
        'msg':  "aTox - client",
        'bot':  true,
      }

    @aTox.manager.aToxAuth()

  friendMsgCB: (e) ->
    if e.messageType() is @consts.TOX_MESSAGE_TYPE_ACTION
      @friends[e.friend()].pReceivedCommand e.message() # in Base class ToxFriendProtBase
    else
      @friends[e.friend()].receivedMsg      e.message()


  friendNameCB:             (e) -> @friends[e.friend()].friendName             e.name()
  friendReadReceiptCB:      (e) -> @friends[e.friend()].friendRead             e.receipt()
  friendStatusMessageCB:    (e) -> @friends[e.friend()].friendStatusMessage    e.statusMessage()
  friendStatusCB:           (e) -> @friends[e.friend()].friendStatus           e.status()
  friendConnectionStatusCB: (e) -> @friends[e.friend()].friendConnectionStatus e.connectionStatus()
  groupMessageCB:           (e) -> @groups[e.group()].groupMessage            {d: e.message(), p: e.peer()} unless @TOX.peernumberIsOursSync e.group(), e.peer()
  groupTitleCB:             (e) -> @groups[e.group()].groupTitle              {d: e.title(),   p: e.peer()}
  groupNamelistChangeCB:    (e) -> @groups[e.group()].gNLC                    {d: e.change(),  p: e.peer()} if @groups[e.group()]?

  selfConnectionStatusCB: (e) ->
    if e.isConnected()
      @aTox.gui.setUserOnlineStatus 'connected'
      @inf "Connected to the TOX network"
      @isConnected = true
      @firstConnectCB() if @firstConnect is true
      @firstConnect = false
    else
      @aTox.gui.setUserOnlineStatus 'disconnected'
      @inf "Disconnected from the TOX network"
      @isConnected = false

  reqAvatar: ->
    return @stub 'reqAvatar'
    #for i in @TOX.getFriendListSync()
    #  @inf "Requesting Avatar (Friend ID: <span style='color:rgba(100, 100, 255, 1)'>#{i}</span>)"
    #  @TOX.requestAvatarData( i )

  friendRequestCB: (e) ->
    @inf "Friend request", "#{e.publicKeyHex()} (Autoaccept)"
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
    return @stub 'createGroupChat' # TODO -- rework for new tox API
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
    return @stub 'groupInviteCB' # TODO -- rework for new tox API
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
    return @stub 'getPeerInfo'  # TODO -- rework for new tox API
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
    return @stub 'invite' # TODO -- rework for new tox API
    try
      @TOX.inviteSync e.fID, e.gID
    catch err
      return @err "Failed to invite friend #{e.fID} to #{e.gID}"

  sendToGC: (e) ->
    return @stub 'sendToGC' # TODO -- rework for new tox API
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
    @TOX.setNameSync "#{name}"

  setAvatar: (path) ->
    return @stub "setAvatar"  # TODO -- rework for new tox API
    #if path != 'none'
    #  fs.readFile "#{path}", (err, data) =>
    #    if err
    #      @err "Failed to load #{path}"
    #      return
    #    @TOX.setAvatar 1, data

  setStatus: (s) ->
    @TOX.setStatusMessageSync "#{s}"

  sendFriendRequest: (e) ->
    for i in @sentRequests
      return @warn "Friend Request already sent!", e.addr if i is e.addr

    @sentRequests.push e.addr

    fID   = 0
    e.msg = "Hello" if e.msg is ""

    try
      fID = @TOX.addFriendSync "#{e.addr}", "#{e.msg}"
    catch err
      @err "Failed to send friend request\n#{err.message}", err.stack
      return

    if e.bot? and e.bot is true
      @friends[fID] = new Bot {
        name:   e.addr
        fID:    fID
        online: 'offline'
        status: "Working, please wait..."
        aTox:   @aTox
        pubKey: e.addr
      }
    else
      @friends[fID] = new Friend {
        name:   e.addr
        fID:    fID
        online: 'offline'
        status: "Working, please wait..."
        aTox:   @aTox
        pubKey: e.addr
      }

    @success "Friend request (#{fID}) sent", e.addr

    return @friends[fID]

  sendToFriend: (e) ->
    try
      return @TOX.sendFriendMessageSync e.fID, e.msg
    catch e
      @warn "Failed to send MSG to #{e.fID}"
      return -1

  sendToFriendCMD: (e) ->
    try
      return @TOX.sendFriendMessageSync e.fID, e.msg, @consts.TOX_MESSAGE_TYPE_ACTION
    catch e
      return -1

  onlineStatus: (newS) ->
    status = 2

    switch newS
      when 'online' then status = @consts.TOX_USER_STATUS_NONE
      when 'away'   then status = @consts.TOX_USER_STATUS_AWAY
      when 'busy'   then status = @consts.TOX_USER_STATUS_BUSY

    @TOX.setStatusSync status
    @success "You are now <span class='#{@getClassByStatus newS}'>#{newS}</span>" # TODO send this to all chats

  getClassByStatus: (status) ->
    if status is "online"
      return "text-success"
    else if status is "offline"
      return "text-info"
    else if status is "busy"
      return "text-error"
    else if status is "away"
      return "text-warning"

  success: (msg, desc) -> @aTox.term.success {
    'title': "TOX: #{msg}"
    'msg':   desc
  }

  inf:  (msg, desc) -> @aTox.term.inf  {
    'title': "TOX: #{msg}"
    'msg':   desc
  }

  err:  (msg, stack) -> @aTox.term.err  {
    'title': 'TOX Worker'
    'msg':   "TOX: #{msg}"
    'stack': stack
    'buttons': [
      {
        'text':       'Restart TOX'
        'onDidClick': => @startup()
      }
    ]
  }

  warn: (msg, stack) -> @aTox.term.warn {
    'title': 'TOX Worker'
    'msg':   "TOX: #{msg}"
    'stack': stack
  }

  stub: (msg, stack) -> @aTox.term.stub {
    'title': 'TOX Worker'
    'msg':   "TOX::#{msg}"
    'stack': stack
  }
