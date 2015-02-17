{Emitter}   = require 'event-kit'

ContactView = require './atox-contactView'
ChatBox     = require './atox-chatbox'

module.exports =
class Contact
  constructor: (params) ->
    @selected = false

    @name     = params.name
    @img      = params.img
    @cid      = params.cid
    @status   = params.status
    @online   = params.online
    @event    = params.event
    @panel    = params.panel

    @contactView = new ContactView { cid: @cid, handle: => @handleClick() }
    @chatBox     = new ChatBox { cid: @cid, online: @online, event: @event }

    @panel.addChat { cid: @cid, img: @img, event: @event }

    @event.on "chat-visibility",   (newV) => @visibility         newV
    @event.on "aTox-contact-sent", (msg)  => @contactSendt       msg

    if @cid == 0
      params.win.addContact @contactView, true
    else
      params.win.addContact @contactView, false

    @update()

    @color = @randomColor()

  contactSendt: (msg) ->
    @event.emit "aTox.add-message", {
      cid:   @cid
      tid:   @cid # Will be later the TOX ID
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
    else
      @chatBox.hide()
      @selected = false

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

  showChat: ->
    @chatBox.show()

  hideChat: ->
    @chatBox.hide()


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
