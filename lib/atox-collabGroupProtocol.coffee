# coffeelint: disable=max_line_length

module.exports =
class CollabGroupProtocol
  __timeout: (s, cb) -> setTimeout cb, s

  constructor: (params) ->
    @aTox = params.aTox

    @pHasToken  = false
    @pIsSyncing = false

    if params.group?
      @pGroup  = params.group
      sendSync = true
    else
      @pGroup  = @aTox.TOX.createGroupChat {"collab": true}
      sendSync = false # Nobody will be in the GC

    @pGroup.msgCB = (msg) => @pHandleMSG msg
    @pID          = @pGroup.id
    @pMyKey       = @aTox.TOX.getSelfPubKey()
    @pSendSync() if sendSync

    @peerSyncStatus = []
    @peers          = []

  destructor: ->
    @pGroup.destructor()

  getID:    -> @pID
  getGroup: -> @pGroup

  pHandleMSG: (msg) ->
    return unless @pExpect msg, ["cmd"]

    switch msg.cmd
      when "next"       then @pProcessNext       msg
      when "sync"       then @pProcessSync       msg
      when "syncData"   then @pProcessSyncData   msg
      when "syncAccept" then @pProcessSyncAccept msg
      else @pINVALID "Unknown command '#{msg.cmd}'"

#     _   _                            _       _       _                        _
#    | \ | |                          | |     | |     | |                      | |
#    |  \| | ___  _ __ _ __ ___   __ _| |   __| | __ _| |_ __ _    _____  _____| |__   __ _ _ __   __ _  ___
#    | . ` |/ _ \| '__| '_ ` _ \ / _` | |  / _` |/ _` | __/ _` |  / _ \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
#    | |\  | (_) | |  | | | | | | (_| | | | (_| | (_| | || (_| | |  __/>  < (__| | | | (_| | | | | (_| |  __/
#    \_| \_/\___/|_|  |_| |_| |_|\__,_|_|  \__,_|\__,_|\__\__,_|  \___/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
#                                                                                                  __/ |
#                                                                                                 |___/

  pProcessNext: (msg) ->
    return unless @pExpect msg, ["next", "data", "isStart"]
    if msg.next is @pMyKey
      @pHasToken = true

    unless msg.isStart
      for i, index in @peers
        if msg.key is i.key
          @peers[index].hasSent = true
          @peers[index].data    = msg.data
          break

    @pSendNext()

  pSendNext: ->
    return unless @pHasToken
    return if     @pIsSyncing
    @pHasToken = false

    for i in @peers
      continue if i.key is @pMyKey
      unless i.hasSent
        return @__timeout 100, => @pSendNext() # Wait for the remaining peers

    next = 0

    for i, index in @peers
      @peers[index].hasSent = false
      next = index + 1 if i.key is @pMyKey

    current = next - 1
    next    = 0 if next is @peers.length
    index   = next

    data = []

    while index isnt current
      data.push @peers[index].data
      index++
      index = 0 if index is @peers.length

    console.log ""
    console.log ""
    console.log "DATA:"
    console.log data
    console.log ""

    @__timeout 250, =>
      @pGroup.send {
        "cmd":     "next"
        "next":    @peers[next].key
        "data":    @CMD_process data
        "isStart": false
      }


#     _____
#    /  ___|
#    \ `--. _   _ _ __   ___
#     `--. \ | | | '_ \ / __|
#    /\__/ / |_| | | | | (__
#    \____/ \__, |_| |_|\___|
#            __/ |
#           |___/

  pProcessSync: (msg) ->
    return unless @pExpect msg, ["syncPeer"]
    @pIsSyncing = true
    @pHasToken  = false
    @peers      = []
    @CMD_startSyncing()
    return unless msg.syncPeer is @pMyKey

    @peerSyncStatus = []
    peerlist        = []
    foundMyKey      = false
    for i in @pGroup.peerlist
      if i.key is @pMyKey # Sometimes the own puplic key appears in the peerlist
        foundMyKey = true
      else
        @peerSyncStatus.push {"key": i.key, "accepted": false}

      peerlist.push i.key

    peerlist.push @pMyKey unless foundMyKey

    @pSetPeerlistAfetSync peerlist

    @pGroup.send {
      "cmd":      "syncData"
      "peerlist": peerlist
      "data":     @CMD_getSyncData()
    }

  pProcessSyncAccept: (msg) ->
    return if @peerSyncStatus.length is 0 # I am not the main sync porvider
    return unless @pExpect msg, ["key"]

    for i, index in @peerSyncStatus
      if i.key is msg.key
        @peerSyncStatus[index].accepted = true
        break

    # Test if all have accepted
    for i in @peerSyncStatus
      return if i.accepted is false

    @pIsSyncing     = false
    @peerSyncStatus = []
    @pGroup.send {
      "cmd":     "next"
      "next":    @peers[0].key
      "data":    {}
      "isStart": true
    }


  pSendSync: (_counter=0) ->
    if @pGroup.peerlist.length is 0 # No Name List Change event recied jet
      return if _counter is 10      # ERROR
      console.log _counter
      return @__timeout 100, => @pSendSync ++_counter

    @pGroup.send {
      "cmd":     "sync"
      "syncPeer": @pGroup.peerlist[0].key
    }


  pProcessSyncData: (msg) ->
    return unless @pExpect msg, ["peerlist", "data"]
    @pSetPeerlistAfetSync msg.peerlist
    @CMD_stopSyncing      msg.data
    @pIsSyncing = false
    @pGroup.send {"cmd": "syncAccept"}

  # After a sync the token starts at @peers[0]
  pSetPeerlistAfetSync: (peerlist) ->
    hasSent = false
    for i in peerlist
      hasSent = true if i is @pMyKey
      @peers.push {
        "key":     i
        "hasSent": hasSent
        "data":    {}
      }

#     _   _ _   _ _
#    | | | | | (_) |
#    | | | | |_ _| |___
#    | | | | __| | / __|
#    | |_| | |_| | \__ \
#     \___/ \__|_|_|___/
#

  pExpect: (obj, keys) ->
    error = false
    for key in keys
      unless obj[key]?
        error = true
        @pINVALID "#{key} is undefined"

    return false if error
    return true

  pINVALID: (msg) ->
    @aTox.term.warn {"title": "Invalid collab msg JSON", "msg": msg}
    return false
