{Emitter}   = require 'event-kit'
os          = require 'os'
fs          = require 'fs'

ContactView = require './atox-contactView'
ChatBox     = require './atox-chatbox'

module.exports =
class Contact
  constructor: (params) ->
    @selected = false

    @name     = params.name
    @img      = params.img
    @tid      = params.tid
    @cid      = params.cid
    @status   = params.status
    @online   = params.online
    @event    = params.event
    @panel    = params.panel

    @contactView = new ContactView { cid: @cid, handle: => @handleClick() }
    if @cid == 0
      params.win.addContact @contactView, true
    else
      params.win.addContact @contactView, false
    @chatBox     = new ChatBox { cid: @cid, online: @online, event: @event }

    @event.on "chat-visibility",   (newV) => @visibility     newV
    @event.on 'aTox.add-message',  (data) => @sendMsg        data

    @color = @randomColor()
    @event.emit 'Terminal', { cid: -2, msg: "New Contact: Name: #{@name}; Status: #{@status}; ID: #{@cid}" }

    if @online is 'group'
      @peerlist = []
      @event.on 'groupMessageAT',  (data) => @groupMessage data
      @event.on 'groupTitleAT',    (data) => @groupTitle   data
      @event.on 'gNLC_AT',         (data) => @gNLC         data

      @panel.addChat { cid: @cid, img: @img, event: @event, group: true }
      @update()
      return

    @event.on 'avatarDataAT',      (data) => @avatarData   data
    @event.on 'friendMsgAT',       (data) => @friendMsg    data
    @event.on "nameChangeAT",      (data) => @nameChange   data
    @event.on "statusChangeAT",    (data) => @statusChange data
    @event.on "avatarChangeAT",    (data) => @avatarChange data
    @event.on "userStatusAT",      (data) => @userStatus   data
    @event.on 'getColor',          (data) => @getColor     data

    @panel.addChat { cid: @cid, img: @img, event: @event, group: false }
    @update()

#     _____             _             _                 _
#    /  __ \           | |           | |               | |
#    | /  \/ ___  _ __ | |_ __ _  ___| |_    ___  _ __ | |_   _
#    | |    / _ \| '_ \| __/ _` |/ __| __|  / _ \| '_ \| | | | |
#    | \__/\ (_) | | | | || (_| | (__| |_  | (_) | | | | | |_| |
#     \____/\___/|_| |_|\__\__,_|\___|\__|  \___/|_| |_|_|\__, |
#                                                          __/ |
#                                                         |___/

  avatarData: (data) ->
    return unless data.tid == @tid

    if data.d.format() == 0
      @event.emit 'Terminal', { cid: @cid, msg: "#{@name} has no Avatar" }
      @img = 'none'
      @update()
      return

    if ! data.d.isValid()
      @event.emit 'Terminal', { cid: @cid, msg: "#{@name} has an invalid (or no) Avatar" }
      @img = 'none'
      @update()
      return

    @event.emit 'Terminal', {cid: @cid, msg: "#{@name} has a new Avatar (Format: #{data.d.format()})"}
    @img = "#{os.tmpdir()}/atox-Avatar-#{data.d.hashHex()}"
    @event.emit 'Terminal', {cid: @cid, msg: "Avatar Path: #{@img}"}
    fs.writeFile @img, data.d.data(), (error) =>
      return if error
      @update()

  friendMsg: (data) ->
    return unless data.tid == @tid
    @event.emit "aTox.add-message", {
      cid:   @cid
      tid:   @tid
      color: @color
      name:  @name
      msg:   data.d
    }

  nameChange: (data) ->
    return unless data.tid == @tid
    @event.emit 'Terminal', {cid: @cid, msg: "Name #{@name} is now #{data.d}"}
    @name = data.d
    @update()

  statusChange: (data) ->
    return unless data.tid == @tid
    @event.emit 'Terminal', { cid: @cid, msg: "Status of #{@name} is now #{data.d}"}
    @status = data.d
    @update()

  avatarChange: (data) ->
    return unless data.tid == @tid
    @event.emit 'Terminal', { cid: @cid, msg: "#{@name} changed avatar"}
    @online = status
    @update()

  userStatus: (data) ->
    return unless data.tid == @tid

    status = 'offline'

    switch data.d
      when 0 then status = 'online'
      when 1 then status = 'away'
      when 2 then status = 'busy'

    @event.emit 'Terminal', {cid: @cid, msg: "#{@name} changed user status to #{status}"}
    @online = status
    @update()

    @event.emit 'notify', {
      type:    'inf'
      name:     status.charAt(0).toUpperCase() + status.slice(1)
      content: "#{@name} is now #{status}"
      img:      @img
    }

  getColor: (data) ->
    return unless data.tid == @tid
    data.cb @color

#     _____                         _____ _           _                 _
#    |  __ \                       /  __ \ |         | |               | |
#    | |  \/_ __ ___  _   _ _ __   | /  \/ |__   __ _| |_    ___  _ __ | |_   _
#    | | __| '__/ _ \| | | | '_ \  | |   | '_ \ / _` | __|  / _ \| '_ \| | | | |
#    | |_\ \ | | (_) | |_| | |_) | | \__/\ | | | (_| | |_  | (_) | | | | | |_| |
#     \____/_|  \___/ \__,_| .__/   \____/_| |_|\__,_|\__|  \___/|_| |_|_|\__, |
#                          | |                                             __/ |
#                          |_|                                            |___/

  groupMessage: (data) ->
    return unless data.tid == @tid
    console.log data.p
    @event.emit 'getPeerInfo', {
      gNum: @tid
      peer: data.p
      cb: (params) =>
        index = @getPeerListIndex params.fid
        @event.emit "aTox.add-message", {
          cid:   @cid
          tid:   @tid
          color: params.color
          name:  params.name
          msg:   data.d
        }
    }

  groupTitle: (data) ->
    return unless data.tid == @tid
    @event.emit 'Terminal', {cid: @cid, msg: "Group #{@name} is now #{data.d} - peer #{data.p}"}
    @name = data.d
    @update()

  getPeerListIndex: (fid) ->
    for i in [0..@peerlist.length] by 1
      return i if @peerlist[i].fid is fid

    return -1

  gNLC: (data) ->
    return unless data.tid == @tid

    if data.d is 1
      @event.emit 'Terminal', {cid: @cid, msg: "Peer #{data.p} left #{@name}"}
      index = @peerlist.indexOf {fid: params.fid, name: params.name}
      @peerlist.splice index, 1 unless index < 0
      return @update()

    @event.emit 'getPeerInfo', {
      gNum: @tid
      peer: data.p
      cb: (params) =>
        switch data.d
          when 0
            @event.emit 'Terminal', {cid: @cid, msg: "New peer in #{@name} - peer #{data.p}"}
            @peerlist.push {fid: params.fid, name: params.name, color: params.color}
          when 2
            @event.emit 'Terminal', {cid: @cid, msg: "Peer #{data.p} changed name"}
            index = @getPeerListIndex params.fid
            @peerlist[index] = {fid: params.fid, name: params.name, color: params.color} unless index < 0

        @update()
    }

#    ______       _   _
#    | ___ \     | | | |
#    | |_/ / ___ | |_| |__
#    | ___ \/ _ \| __| '_ \
#    | |_/ / (_) | |_| | | |
#    \____/ \___/ \__|_| |_|
#

  sendMsg: (data) ->
    return unless data.tid == -1
    return unless data.cid == @cid
    return @event.emit 'sendToGC',     {tid: @tid, d: data.msg} if @online is 'group'
    return @event.emit 'sendToFriend', {tid: @tid, d: data.msg}

  visibility: (newV) ->
    return unless newV.cid is @cid

    sourcecid = -2
    if newV.scid?
      sourceid = newV.scid

    if newV.what == 'show'
      @chatBox.show()
      @selected = true
      @event.emit 'Terminal', {cid: sourceid, msg: "Opened chat #{@cid}"}
    else
      @chatBox.hide()
      @selected = false
      @event.emit 'Terminal', {cid: sourceid, msg: "Closed chat #{@cid}"}

    @update()

  update: ->
    temp = {
      name:     @name,
      status:   @status,
      online:   @online,
      img:      @img,
      selected: @selected,
      peerlist: @peerlist
    }

    @contactView.update temp
    @chatBox.update     temp

    @panel.updateImg {cid: @cid, data: temp}

    return unless @online is 'group'

    for i in @peerlist
      @event.emit 'Terminal', {cid: @cid, msg: "Peerlist: #{i.fid} - #{i.name}"}

  handleClick: ->
    if @selected
      @event.emit "chat-visibility", { cid: @cid, what: 'hide' }
    else
      @event.emit "chat-visibility", { cid: @cid, what: 'show' }

    @event.emit 'aTox.select', {
      cid: @cid
      name: @name,
      status: @status,
      selected: @selected,
      online: @online,
      img: @img,
    }

  showChat: -> @event.emit "chat-visibility", { cid: @cid, what: 'show' }
  hideChat: -> @event.emit "chat-visibility", { cid: @cid, what: 'hide' }


  # Utils
  randomNumber: (min, max) ->
    Math.floor(Math.random() * (max - min) + min)

  randomColor: ->
    # Make sure color is bright enough
    mainColor = @randomNumber 1, 3

    red = green = blue = 0

    red   = 100 if mainColor is 1
    green = 100 if mainColor is 2
    blue  = 100 if mainColor is 3

    "rgba( #{@randomNumber( red, 255 )}, #{@randomNumber( green, 255 )}, #{@randomNumber( blue, 255 )}, 1 )"
