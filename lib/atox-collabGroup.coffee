# coffeelint: disable=max_line_length

module.exports=
class CollabGroup
  constructor: (params) ->
    @gID      = params.gID
    @aTox     = params.aTox

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

  genID: ->
    t = ""
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!$%&(){}[]_+-*/'#|;,:."
    t += chars[Math.floor(Math.random() * chars.length)] for i in [0..20]
    return t

  groupMessage: (params) ->
  groupTitle:   (params) ->
    unless params.d is @name
      @aTox.TOX.setGCtitle {"gID": @gID, "title": @name}
      @aTox.term.warn {"title": "internal GC name changed!", "msg": params.d}

  getPeerListIndex: (fID, peer) ->
    if fID > 0
      for dummy, i in @peerlist
        return i if @peerlist[i].fID is fID

    for dummy, i in @peerlist
      return i if @peerlist[i].peer is peer

    return -1

  gNLC: (data) ->
    if data.d is 1
      index = @getPeerListIndex -5, data.p
      return @aTox.term.err {"title": "INDEX ERRPR peer: #{data.p}"} if index < 0
      @aTox.term.inf {"title": "Peer #{data.p} left collab #{@id}"}
      @peerlist.splice index, 1
      return

    @aTox.TOX.getPeerInfo {
      gID: @gID
      peer: data.p
      cb: (params) =>
        switch data.d
          when 0
            @aTox.term.inf {"title": "New peer '#{data.p}' in collab #{@id}"}
            @peerlist.push {"fID": params.fID, "peer": data.p, "key": params.key}
    }
