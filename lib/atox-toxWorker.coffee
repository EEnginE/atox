toxcore = require 'toxcore'
fs = require 'fs'
os = require 'os'
path = require 'path'
shell = require 'shell'

Friend       = require './atox-friend'
Bot          = require './atox-bot'
Group        = require './atox-group'
CollabGroup  = require './atox-collabGroup'
FileTransfer = require './atox-fileTransfer'
BigMessage   = require './botProtocol/prot-bigMessage'

module.exports =
class ToxWorker
  constructor: (params) ->
    @DLL      = params.dll
    @aTox     = params.aTox
    @consts   = toxcore.Consts
    @dataKey  = null

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
    console.log e

  startup: ->
    toxSaveData = null
    toxSaveData = @aTox.gSave.getBuf 'TOX' if atom.config.get 'aTox.useToxSave'

    @DLL = null unless os.platform().indexOf('win') > -1

    try
      @TOXes = new toxcore.ToxEncryptSave "path": @DLL
    catch e
      @err "Failed to init Tox", e
      console.log e, e.stack
      return

    if toxSaveData?
      if @TOXes.isDataEncryptedSync toxSaveData
        @inf "The TOX save is encrypted", null, false

        cbFunc = (pw) =>
          salt        = @TOXes.getSaltSync           toxSaveData
          @dataKey    = @TOXes.deriveKeyWithSaltSync pw, salt
          try
            decrypedData = @TOXes.decryptPassKeySync toxSaveData, @dataKey
          catch err
            @aTox.term.err {'title': 'Failed to decrypt TOX save', 'msg': 'Please check your password'}
            console.log err
            return @aTox.gui.pwPrompt.prompt cbFunc
          @success "Decrypted TOX data", null, true
          @startTox decrypedData

        return @aTox.gui.pwPrompt.prompt cbFunc

    @startTox toxSaveData

  startTox: (toxSaveData) ->
    rawJSON     = fs.readFileSync "#{__dirname}/../nodes.json"
    paresedJSON = JSON.parse rawJSON
    @nodes      = paresedJSON.bootstrapNodes
    @aToxNodes  = paresedJSON.aToxNodes

    try
      @TOX = new toxcore.Tox "old": true, "data": toxSaveData, "path": @DLL, "crypto": {"path": @DLL}
    catch e
      @err "Failed to init Tox", e
      console.log e, e.stack
      return

    @aTox.gui.setUserOnlineStatus 'disconnected'

    @TOX.on 'fileRecv',                   (e) => try @fileRecvCB e               catch a then @handleExept 'fileRecv',               a
    @TOX.on 'fileRecvControl',            (e) => try @fileRecvControlCB e        catch a then @handleExept 'fileRecvControl',        a
    @TOX.on 'fileRecvChunk',              (e) => try @fileRecvChunkCB e          catch a then @handleExept 'fileRecvChunk',          a
    @TOX.on 'fileChunkRequest',           (e) => try @fileChunkRequestCB e       catch a then @handleExept 'fileChunkRequest',       a
    @TOX.on 'friendMessage',              (e) => try @friendMsgCB e              catch a then @handleExept 'friendMessage',          a
    @TOX.on 'friendReadReceipt',          (e) => try @friendReadReceiptCB e      catch a then @handleExept 'friendReadReceipt',      a
    @TOX.on 'friendRequest',              (e) => try @friendRequestCB e          catch a then @handleExept 'friendRequest',          a
    @TOX.on 'friendName',                 (e) => try @friendNameCB e             catch a then @handleExept 'friendName',             a
    @TOX.on 'friendStatusMessage',        (e) => try @friendStatusMessageCB e    catch a then @handleExept 'friendStatusMessage',    a
    @TOX.on 'friendStatus',               (e) => try @friendStatusCB e           catch a then @handleExept 'friendStatus',           a
    @TOX.on 'friendConnectionStatus',     (e) => try @friendConnectionStatusCB e catch a then @handleExept 'friendConnectionStatus', a
    @TOX.on 'selfConnectionStatus',       (e) => try @selfConnectionStatusCB e   catch a then @handleExept 'selfConnectionStatus',   a
    @TOX.old().on 'groupInvite',          (e) => try @groupInviteCB e            catch a then @handleExept 'groupInvite',            a
    @TOX.old().on 'groupMessage',         (e) => try @groupMessageCB e           catch a then @handleExept 'groupMessage',           a
    @TOX.old().on 'groupTitle',           (e) => try @groupTitleCB e             catch a then @handleExept 'groupTitle',             a
    @TOX.old().on 'groupNamelistChange',  (e) => try @groupNamelistChangeCB e    catch a then @handleExept 'groupNamelistChange',    a

    @friends      = []
    @groups       = []
    @files        = []

    @updateFriendList()

    @collabWaitCBs = {}

    @setName   atom.config.get 'aTox.userName'
    #@setAvatar atom.config.get 'aTox.userAvatar'
    @setStatus "I am a Bot :)"

    for n in @nodes
      @TOX.bootstrapSync(n.address, n.port, n.key)

    @TOX.start()
    return @err "Failed to start TOX" unless @TOX.isStarted()
    @success "Started TOX"
    @inf "Name:  #{atom.config.get 'aTox.userName'}", null, false
    @inf "My ID", "#{@TOX.getAddressHexSync()}", false

    @isConnected  = false
    @firstConnect = true

  deactivate: ->
    if atom.config.get 'aTox.useToxSave'
      saveData = @TOX.getSavedataSync()
      saveData = @TOXes.encryptPassKeySync saveData, @dataKey if @dataKey?
      @aTox.gSave.setBuf 'TOX', saveData

      saveFriends = {}
      for i in @friends
        tmp = {}
        tmp[j] = i[j] for j in ['fID', 'name', 'pubKey', 'status', 'img', 'online', 'isHuman']
        saveFriends[i.fID] = tmp

      @aTox.gSave.set 'friends', saveFriends

    @TOX.stop()
    @TOX.free()
    @TOX   = null
    @TOXes = null

  changeTOXsaveKey: ->
    @aTox.gui.pwPrompt.promptNewPW (pw) =>
      if pw is ''
        @dataKey =  null
        @success "TOX save password removed", null, true
      else
        @dataKey = @TOXes.deriveKeyFromPassSync pw
        @success "TOX save password changed", null, true

  updateFriendList: ->
    return unless atom.config.get 'aTox.useToxSave'
    fList = @TOX.getFriendListSync()
    sList = @aTox.gSave.get 'friends'
    sList = {} unless sList?

    for i in fList
      isBot  = false
      friend = sList[i]

      if friend? and friend.fID is i
        isBot = not friend.isHuman
      else
        friend = {
          'fID':    i
          'img':    'none'
        }

      friend.aTox   = @aTox
      friend.online = 'offline'

      try friend.name   = @TOX.getFriendNameSync          i unless friend.name?
      try friend.status = @TOX.getFriendStatusMessageSync i unless friend.status?
      try friend.pubKey = @TOX.getFriendPublicKeyHexSync  i unless friend.key?

      try friend.name   = friend.name.slice   0, @TOX.getFriendNameSizeSync          i
      try friend.status = friend.status.slice 0, @TOX.getFriendStatusMessageSizeSync i

      if isBot
        @friends[i] = new Bot    friend
        @inf "Loaded bot '#{friend.name}' from TOX save",    friend.pubKey, false
      else
        @friends[i] = new Friend friend
        @inf "Loaded friend '#{friend.name}' from TOX save", friend.pubKey, false

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
      BigMessage.receive e.message(), (msg) => @friends[e.friend()].pReceivedCommand "#{msg}" # in Base class ToxFriendProtBase
    else
      BigMessage.receive e.message(), (msg) => @friends[e.friend()].receivedMsg      "#{msg}"


  friendNameCB:             (e) -> @friends[e.friend()].friendName             e.name()
  friendReadReceiptCB:      (e) -> @friends[e.friend()].friendRead             e.receipt()
  friendStatusMessageCB:    (e) -> @friends[e.friend()].friendStatusMessage    e.statusMessage()
  friendStatusCB:           (e) -> @friends[e.friend()].friendStatus           e.status()
  friendConnectionStatusCB: (e) -> @friends[e.friend()].friendConnectionStatus e.connectionStatus()
  fileRecvControlCB:        (e) -> @files[e.friend()][e.file()].control        e.control(), e.controlName()
  fileRecvChunkCB:          (e) -> @files[e.friend()][e.file()].chunk          e.position(), e.data(), e.isFinal()
  fileChunkRequestCB:       (e) -> @files[e.friend()][e.file()].chunkRequest   e.position(), e.length()

  # Sometimes thoese events are faster than our created objects created

  __groupPlaceholder: -> {
    "__isTempPlaceholder": true
    "titles": []
    "NLC": []
    "msgs": []
    "isCollab": -> false
  }

  groupMessageCB:           (e) ->
    return if @TOX.old().peernumberIsOursSync e.group(), e.peer()
    @groups[e.group()] = @__groupPlaceholder() unless @groups[e.group()]?

    if @groups[e.group()].__isTempPlaceholder
      BigMessage.receive e.message(), (msg) => @groups[e.group()].msgs.push    {"d": "#{msg}", "p": e.peer()}
    else
      BigMessage.receive e.message(), (msg) => @groups[e.group()].groupMessage {"d": "#{msg}", "p": e.peer()}

  groupTitleCB:             (e) ->
    @groups[e.group()] = @__groupPlaceholder() unless @groups[e.group()]?

    if @groups[e.group()].__isTempPlaceholder
      @groups[e.group()].titles.push {d: e.title(), p: e.peer()}
    else
      @groups[e.group()].groupTitle {d: e.title(), p: e.peer()}

  groupNamelistChangeCB:    (e) ->
    @groups[e.group()] = @__groupPlaceholder() unless @groups[e.group()]?

    if @groups[e.group()].__isTempPlaceholder
      @groups[e.group()].NLC.push {d: e.change(),  p: e.peer()}
    else
      @groups[e.group()].gNLC {d: e.change(),  p: e.peer()}

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

  friendRequestCB: (e) ->
    @inf "Friend request", "#{e.publicKeyHex()} (Autoaccept)"
    @aTox.manager.handleFriendRequest e

  addFriendNoRequest: (e) ->
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

  getFIDfromKEY: (key) ->
    for i in @friends
      return i.fID if i.pubKey is key

    return -1

  getSelfPubKey: ->
    try
      return @TOX.getPublicKeyHexSync()
    catch error
      @handleExept "getSelfPubKey", error
      return ""

  getFriendPubKey: (fID) ->
    try
      return @TOX.getFriendPublicKeyHexSync fID
    catch error
      @handleExept "getFriendPubKey", error
      return "ERROR"


#    ______ _ _        _____                    __
#    |  ___(_) |      |_   _|                  / _|
#    | |_   _| | ___    | |_ __ __ _ _ __  ___| |_ ___ _ __
#    |  _| | | |/ _ \   | | '__/ _` | '_ \/ __|  _/ _ \ '__|
#    | |   | | |  __/   | | | | (_| | | | \__ \ ||  __/ |
#    \_|   |_|_|\___|   \_/_|  \__,_|_| |_|___/_| \___|_|
#

  fileRecvCB: (e) ->
    @files[e.friend()] = [] unless @files[e.friend()]?
    @files[e.friend()][e.file()] = new FileTransfer {
      "aTox":     @aTox
      "role":     'receiver'
      "name":     e.filename()
      "kind":     e.kind()
      "size":     e.size()
      "id": {
        "friend": e.friend()
        "file":   e.file()
        "id":     @getFileID {"fID": e.friend(), "fileID": e.file()}
        "cID":    if @friends[e.friend()].chat? then @friends[e.friend()].chat.cID else null
      }
      "doneCB": => @files[e.friend()][e.file()] = null
    }

  getFileID: (e) -> @TOX.getFileIdSync e.fID, e.fileID

  broadcastAvatar: ->
    file = atom.config.get 'aTox.userAvatar'
    return if file is 'none'
    fs.readFile file, (err, data) =>
      if err then throw err
      @TOX.hash data, (err2, hash) =>
        if err2 then throw err2
        for i in @friends
          @sendFile {"fID": i.getID(), "path": file, "isAvatar": true, "id": hash}

  sendAvatar: (e) ->
    file = atom.config.get 'aTox.userAvatar'
    return if file is 'none'
    fs.readFile file, (err, data) =>
      if err then throw err
      @TOX.hash data, (err2, hash) =>
        if err2 then throw err2
        @sendFile {"fID": e.fID, "path": file, "isAvatar": true, "id": hash}

  # e: {"fID", "path", "isAvatar": <boolean optional>, "id": <optional for normal dat>}
  sendFile: (e) ->
    fs.stat e.path, (err, stats) =>
      if err
        @err "Failed to send File. Unable to get file stats"
        return console.log err

      size = stats["size"]
      id = e.id
      unless id?
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!$%&(){}[]_+-*/'#|;,:."
        id = ""
        id += chars[Math.floor(Math.random() * chars.length)] for i in [1..@consts.TOX_FILE_ID_LENGTH]
        id = new Buffer id

      if e.isAvatar
        kind = @consts.TOX_FILE_KIND_AVATAR
        name = ''
      else
        kind = @consts.TOX_FILE_KIND_DATA
        name = path.basename e.path

      fs.open e.path, 'r', (err, fd) =>
        return @err "Failed to open file #{e.path} for sending" if err?
        fileID = @TOX.sendFileSync e.fID, kind, name, size, new Buffer id

        @files[e.fID] = [] unless @files[e.fID]?
        @files[e.fID][fileID] = new FileTransfer {
          "aTox":     @aTox
          "role":     'sender'
          "fullPath": e.path
          "name":     name
          "kind":     kind
          "size":     size
          "fd":       fd
          "id": {
            "friend": e.fID
            "file":   e.fileID
            "id":     id
            "cID":    if @friends[e.fID].chat? then @friends[e.fID].chat.cID else null
          }
          "doneCB": => @files[e.fID][e.fileID] = null
        }

  controlFile: (e) ->
    switch e.control
      when 'resume' then @TOX.controlFileSync e.fID, e.fileID, @consts.TOX_FILE_CONTROL_RESUME
      when 'pause'  then @TOX.controlFileSync e.fID, e.fileID, @consts.TOX_FILE_CONTROL_PAUSE
      when 'cancel' then @TOX.controlFileSync e.fID, e.fileID, @consts.TOX_FILE_CONTROL_CANCEL
      else throw new Error "Unknown control cmd 'e.control'"

  seekFileChunk: (e) -> @TOX.seekFileSync      e.id.friend, e.id.file, e.pos
  sendFileChunk: (e) -> @TOX.sendFileChunkSync e.id.friend, e.id.file, e.pos, e.data

#     _____                         _____ _          __  __
#    |  __ \                       /  ___| |        / _|/ _|
#    | |  \/_ __ ___  _   _ _ __   \ `--.| |_ _   _| |_| |_
#    | | __| '__/ _ \| | | | '_ \   `--. \ __| | | |  _|  _|
#    | |_\ \ | | (_) | |_| | |_) | /\__/ / |_| |_| | | | |
#     \____/_|  \___/ \__,_| .__/  \____/ \__|\__,_|_| |_|
#                          | |
#                          |_|

  createGroupChat: (e={}) ->
    #return @stub 'createGroupChat' # TODO -- rework for new tox API
  #TODO: Find local repositories and open their chats on startup
  #atom.project.getRepositories().getConfigValue("remote.origin.url")
    try
      gID = @TOX.old().addGroupchatSync()
    catch error
      console.log error
      return @err "Failed to add group chat: #{e.stack}"

    @inf "Added group chat #{gID}"

    unless e.collab
      @groups[gID] = new Group {
        name:   "Group Chat ##{gID}"
        gID:    gID
        aTox:   @aTox
      }
    else
      @groups[gID] = new CollabGroup {
        "gID":  gID
        "aTox": @aTox
      }

    return @groups[gID]

  deleteGroupChat: (e) ->
    try
      @TOX.old().deleteGroupchatSync e.gID
    catch error
      console.log error
      return @err "Failed to delete group chat", error.stack

    @groups[e.gID].destructor() if @groups[e.gID].destructor?
    @groups.splice e.gID, 1
    @inf "Removed group chat #{e.gID}"

  groupInviteCB: (e) ->
    #return @stub 'groupInviteCB' # TODO -- rework for new tox API
    try
      gID = @TOX.old().joinGroupchatSync e.friend(), e.data()
    catch err
      return @err "Failed to join group chat: #{err.stack}"

    title = ""

    addCollabG = (data) => @groups[gID] = @collabWaitCBs[data.id].cb gID, title
    addNormalG =        =>
      @inf "Joined group chat #{gID}"
      @groups[gID] = new Group {
        name:   title
        gID:    gID
        aTox:   @aTox
      }


    addGroup = (counter=0) =>
      try
        title = @TOX.old().getGroupchatTitleSync gID
      catch err
        counter++
        if counter is 5
          title = ""
          @warn "Can't get GC title of GC #{gID}"
        else
          @myTimeout 500, -> addGroup counter
          return

      data  = {}

      @inf "Received group invite from #{e.friend()}", title

      isCollab = false
      data     = null
      try
        data = JSON.parse title
        throw {} unless data.id?
        throw {} unless @collabWaitCBs[data.id]?
        isCollab = true
      catch error

      NLC = titles = msgs = []

      # Check for early events
      if @groups[gID]?
        if @groups[gID].__isTempPlaceholder
          titles = @groups[gID].titles
          NLC    = @groups[gID].NLC
          msgs   = @groups[gID].msgs

      if isCollab
        addCollabG data
      else
        addNormalG()

      @groups[gID].groupTitle i   for i in titles if titles?
      @groups[gID].gNLC       i   for i in NLC    if NLC?
      @groups[gID].groupMessage i for i in msgs   if msgs?


    addGroup()

  getPeerInfo: (e) ->
    #return @stub 'getPeerInfo'  # TODO -- rework for new tox API
    try
      obj  = {}
      obj.isMe = @TOX.old().peernumberIsOursSync             e.gID, e.peer
      obj.key  = @TOX.old().getGroupchatPeerPublicKeyHexSync e.gID, e.peer
      obj.name = @TOX.old().getGroupchatPeernameSync         e.gID, e.peer
      obj.fID  = @getFIDfromKEY                              obj.key

      if obj.fID < 0
        obj.color = "#AAA"
      else
        obj.color = @friends[obj.fID].color

      e.cb obj if e.cb?
      return obj

    catch err
      console.log err
      @handleExept "getPeerInfo", err

  getGCPeerCount: (e) ->
    try
      return @TOX.old().getGroupchatPeerCountSync e.gID
    catch error
      @handleExept "getGCPeerCount", error
      throw error


  invite: (e) ->
    #return @stub 'invite' # TODO -- rework for new tox API
    try
      @TOX.old().inviteSync e.fID, e.gID
    catch err
      return @err "Failed to invite friend #{e.fID} to #{e.gID}: #{err.stack}"

  sendToGC: (e) ->
    #return @stub 'sendToGC' # TODO -- rework for new tox API
    try
      BigMessage.send e.msg, 1360, (msg) => # @consts.TOX_MAX_MESSAGE_LENGTH is to big
        @TOX.old().sendGroupchatMessageSync e.gID, "#{msg}"
    catch err
      return @handleExept err

  setGCtitle: (params) ->
    try
      @TOX.old().setGroupchatTitleSync params.gID, params.title
    catch error
      @err "Failed to set group title to #{params.title}"
      console.log error



#     _____      _     _____ _______   __
#    /  ___|    | |   |_   _|  _  \ \ / /
#    \ `--.  ___| |_    | | | | | |\ V /
#     `--. \/ _ \ __|   | | | | | |/   \
#    /\__/ /  __/ |_    | | \ \_/ / /^\ \
#    \____/ \___|\__|   \_/  \___/\/   \/
#

  setName: (name) ->
    @TOX.setNameSync "#{name}"

  setStatus: (s) ->
    @TOX.setStatusMessageSync "#{s}"

  sendFriendRequest: (e) ->
    fID   = 0
    e.msg = "Hello" if e.msg is ""

    try
      fID = @TOX.addFriendSync "#{e.addr}", "#{e.msg}"
    catch err
      if err.code is @consts.TOX_ERR_FRIEND_ADD_ALREADY_SENT
        return if e.bot? and e.bot is true
        return @warn "Friend Request already sent!", e.addr
      @err "Failed to send friend request: #{err.message}", err.stack
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

    notify = if e.bot? and e.bot is true then false else true
    @success "Friend request (#{fID}) sent", e.addr, notify

    return @friends[fID]

  deleteFriend: (e) ->
    try
      @TOX.deleteFriendSync e.fID
    catch error
      @handleExept "deleteFriend", error
      return

    @friends[e.fID].destructor()
    @inf "Deleted friend #{@friends[e.fID].getName()}"
    @friends.splice e.fID, 1

  sendToFriend: (e) ->
    try
      return BigMessage.send e.msg, @consts.TOX_MAX_MESSAGE_LENGTH, (msg) =>
        @TOX.sendFriendMessageSync e.fID, "#{msg}"
    catch err
      @warn "Failed to send MSG to #{e.fID}"
      @handleExept "sendToFriend", err
      return -1

  sendToFriendCMD: (e) ->
    try
      return BigMessage.send e.msg, @consts.TOX_MAX_MESSAGE_LENGTH, (msg) =>
        @TOX.sendFriendMessageSync e.fID, msg, @consts.TOX_MESSAGE_TYPE_ACTION
    catch err
      @handleExept "sendToFriendCMD", err
      return -1

  onlineStatus: (newS) ->
    status = 2

    switch newS
      when 'online' then status = @consts.TOX_USER_STATUS_NONE
      when 'away'   then status = @consts.TOX_USER_STATUS_AWAY
      when 'busy'   then status = @consts.TOX_USER_STATUS_BUSY

    @TOX.setStatusSync status
    @success "You are now #{newS}" # TODO send this to all chats

  getClassByStatus: (status) ->
    if status is "online"
      return "text-success"
    else if status is "offline"
      return "text-info"
    else if status is "busy"
      return "text-error"
    else if status is "away"
      return "text-warning"

  success: (msg, desc, notify) -> @aTox.term.success {
    'title':  "TOX: #{msg}"
    'msg':    desc
    'notify': notify
  }

  inf:  (msg, desc, notify) -> @aTox.term.inf  {
    'title':  "TOX: #{msg}"
    'msg':    desc
    'notify': notify
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
