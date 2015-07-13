# coffeelint: disable=max_line_length

module.exports=
class CollabGroup
  constructor: (params) ->
    @gID      = params.gID
    @aTox     = params.aTox
    @msgCB    = => @aTox.term.error {"title": "msgCB not set!"}

    if params.name?
      @name = params.name
      d = {}
      try
        d = JSON.parse @name
      catch error
        @aTox.term.error {"title": "Invalid collab group chat"}
        throw {"id": 1, "message": "Failed to parse JSON"}

      throw {"id": 2, "message": "Invalid JSON"} unless d.id? and d.collab is true
      @id = d.id
    else
      @id = @genID()
      @name = JSON.stringify {"collab": true, "id": @id}
      @aTox.TOX.setGCtitle {"gID": @gID, "title": @name}

    @peerlist = []

  destructor: ->
    @aTox.TOX.deleteGroupChat {"gID": @gID}

  getID:    -> @gID
  getName:  -> @name
  isCollab: -> true

  genID: ->
    t = ""
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"$&(){}[]_+-*/%=?^'#|;,:.<>~`"
    t += chars[Math.floor(Math.random() * chars.length)] for i in [0..20]
    return t

  groupMessage: (params) ->
    try
      msg = JSON.parse params.d
      console.log ""
      console.log "COLLAB: <---"
      console.log msg
    catch error
      @aTox.term.warn {"title": "Invalid collab event", "msg": "Message is not JSON"}
      console.log error

    for i in @peerlist
      if i.peer is params.p
        msg.key = i.key
        return @msgCB msg

  send: (msg) ->
    try
      console.log ""
      console.log "COLLAB: --->"
      console.log msg
      msgString = JSON.stringify msg
      @aTox.TOX.sendToGC {"gID": @gID, "msg": msgString}
    catch error
      @aTox.term.warn {"title": "Invalid obj. Can't create JSON"}
      console.log error


  groupTitle:   (params) ->
    unless params.d is @name
      @aTox.TOX.setGCtitle {"gID": @gID, "title": @name}
      @aTox.term.warn {"title": "internal GC name changed!", "msg": params.d}

  getPeerListIndex: (peer) ->
    for dummy, i in @peerlist
      return i if @peerlist[i].peer is peer

    return -1

  gNLC: (data) ->
    return if data.d is 2 # Name changes are not interesting
    if data.d is 1
      index = @getPeerListIndex data.p
      return @aTox.term.err {cID: @cID, msg: "INDEX ERRPR peer: #{data.p}"} if index < 0
      return @peerlist.splice index, 1

    info = @aTox.TOX.getPeerInfo {"gID": @gID, "peer": data.p}
    return if info.isMe
    return unless data.d is 0
    @peerlist.push {"peer": data.p, "key": info.key}
    @chat.update 'peers' if @chat?
