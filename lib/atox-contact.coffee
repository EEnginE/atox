{Emitter}   = require 'event-kit'
os          = require 'os'

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
    @chatBox     = new ChatBox { cid: @cid, online: @online, event: @event }

    @panel.addChat { cid: @cid, img: @img, event: @event }

    @event.on "chat-visibility",   (newV) => @visibility   newV
    @event.on "aTox-contact-sent", (msg)  => @contactSendt msg

    @event.on 'avatarDataAT',      (data) => @avatarData   data
    @event.on 'friendMsgAT',       (data) => @friendMsg    data
    @event.on "nameChangeAT",      (data) => @nameChange   data
    @event.on "statusChangeAT",    (data) => @statusChange data
    @event.on "avatarChangeAT",    (data) => @avatarChange data
    @event.on "userStatusAT",      (data) => @userStatus   data
    @event.on 'aTox.add-message',  (data) => @sendMsg      data

    if @cid == 0
      params.win.addContact @contactView, true
    else
      params.win.addContact @contactView, false

    @update()

    @color = @randomColor()

    @event.emit 'aTox.terminal', "New Contact: Name: #{@name}; Status: #{@status}; ID: #{@cid}"

  avatarData: (data) ->
    return unless data.tid == @tid
    @event.emit 'aTox.terminal', "#{@name} has a new Avatar"
    @img = "#{os.tmpdir()}/aTox-Avatar-#{data.d.hashHex()}"
    @event.emit 'aTox.terminal', "Avatar Path: #{@img}"
    fs.writeFile @img, data.d.data(), (error) =>
      return if error
      @update()

  friendMsg: (data) ->
    return if     @status  == 'group'
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
    @event.emit 'aTox.terminal', "Name #{@name} is now #{data.d}"
    @name = data.d
    @update()

  statusChange: (data) ->
    return unless data.tid == @tid
    @event.emit 'aTox.terminal', "Status of #{@name} is now #{data.d}"
    @status = data.d
    @update()

  avatarChange: (data) ->
    return unless data.tid == @tid
    @event.emit 'aTox.terminal', "#{@name} changed avatar"
    @online = status
    @update()

  userStatus: (data) ->
    return unless data.tid == @tid

    status = 'offline'

    switch data.d
      when 0 then status = 'online'
      when 1 then status = 'away'
      when 2 then status = 'busy'

    @event.emit 'aTox.terminal', "#{@name} changed user stauts to #{status}"
    @online = status
    @update()

    @event.emit 'notify', {
      type:    'inf'
      name:     status.charAt(0).toUpperCase() + status.slice(1)
      content: "#{@name} is now #{status}"
      img:      @img
    }

  sendMsg: (data) ->
    return unless data.tid == -1
    return unless data.cid == @cid
    @event.emit 'sendToFriend', {tid: @tid, d: data.msg}

  contactSendt: (msg) ->
    if msg.tid?
      tid = msg.tid
    else
      tid = @cid

    @event.emit "aTox.add-message", {
      cid:   @cid
      tid:    tid  # Will be later the TOX ID
      color: @color
      name:  @name
      img:   @img
      msg:   msg.msg
    }

  visibility: (newV) ->
    return unless newV.cid is @cid

    if newV.what == 'show'
      @chatBox.show()
      @selected = true
      @event.emit 'aTox.terminal', "Opened chat #{@cid}"
    else
      @chatBox.hide()
      @selected = false
      @event.emit 'aTox.terminal', "Cloesed chat #{@cid}"

    @update()

  update: ->
    temp = {
      name:     @name,
      status:   @status,
      online:   @online,
      img:      @img,
      selected: @selected,
    }

    @contactView.update temp
    @chatBox.update     temp

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
