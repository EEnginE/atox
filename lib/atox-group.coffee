Chat = require './atox-chat'

module.exports =
class Group
  constructor: (params) ->
    @name     = params.name
    @gID      = params.gID
    @aTox     = params.aTox
    @online   = 'group'
    @status   = ''
    @img      = 'none'
    @peerlist = []

    @createChat()

  sendMSG: (msg) -> @aTox.TOX.sendToGC {gID: @gID, msg: msg}
  needChat: -> @createChat() unless @chat? # Creates chat if needed

  createChat: ->
    @chat = new Chat {
      aTox: @aTox
      group: true
      parent: this
    }

  groupMessage: (data) ->
    @needChat()
    @aTox.TOX.getPeerInfo {
      gID:  @gID
      peer: data.p
      cb: (params) =>
        @chat.genAndAddMSG {
          "msg": data.d
          "color": params.color
          "name": params.name
          }
    }

  groupTitle: (params) ->
    @aTox.TOX.getPeerInfo {
      gID:  @gID
      peer: data.p
      cb: (params) =>
        @inf {msg: "#{params.name} changed title to #{data.d}", notify: true}
        @name = data.d
        @chat.update 'name' if @chat?
    }

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
      return @aTox.term.err {cID: @cID, msg: "INDEX ERRPR peer: #{data.p}"} if index < 0
      @inf {msg: "#{@peerlist[index].name} (#{data.p}) left #{@name}"}
      @peerlist.splice index, 1
      return @chat.update 'peers' if @chat?

    @aTox.TOX.getPeerInfo {
      gID: @gID
      peer: data.p
      cb: (params) =>
        switch data.d
          when 0
            @inf {msg: "New peer in #{@name} - peer #{data.p}"}
            @peerlist.push {fID: params.fID, peer: data.p, name: params.name, color: params.color}
          when 2
            @inf {msg: "Peer #{data.p} changed name"}
            index = @getPeerListIndex params.fID, data.p
            return @aTox.term.err {cID: @cID, msg: "INDEX ERRPR peer: #{data.p}"} if index < 0
            @peerlist[index] = {fID: params.fID, peer: data.p, name: params.name, color: params.color}

        @chat.update 'peers' if @chat?
    }

  inf: (params) ->
    if @chat?
      cID = @chat.cID
    else
      cID = -1

    @aTox.term.inf {msg: "Group '#{@name}': #{params.msg}", cID: cID}
    return unless params.notify? and params.notify is true
    @aTox.gui.notify {name: @name, content: params.msg}
