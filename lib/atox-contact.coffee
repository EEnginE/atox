{Emitter}   = require 'event-kit'

ContactView = require './atox-contactView'
ChatBox     = require './atox-chatbox'

module.exports =
class Contact
  constructor: (attr) ->
    @selected = false
    @name     = attr.name
    @img      = attr.img
    @cid      = attr.cid
    @status   = attr.status
    @online   = attr.online
    @event    = attr.event
    @panel    = attr.panel

    @contactView = new ContactView { cid: @cid, handle: => @handleClick() }
    @chatBox     = new ChatBox { cid: @cid, online: @online, event: @event }

    @panel.addChat { cid: @cid, img: @img, event: @event }

    @event.on "aTox-add-message#{@cid}", (msg)  => @chatBox.addMessage msg
    @event.on "aTox-add-message#{@cid}", (msg)  => @panel.addMessage   msg
    @event.on "chat-#{@cid}-visibility", (what) => @visibility         what


    @update()

    if @cid == 0
      attr.win.addContact @contactView, true
    else
      attr.win.addContact @contactView, false

  visibility: (what) ->
    if what == 'show'
      @chatBox.show()
      @selected = true
    else
      @chatBox.hide()
      @selected = false

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
      @event.emit "chat-#{@cid}-visibility", 'hide'
    else
      @event.emit "chat-#{@cid}-visibility", 'show'

    @event.emit 'aTox.select', {
      name: @name,
      status: @status,
      selected: @selected,
      online: @online,
      img: @img,
      cid: @cid
    }

    @update()

  showChat: ->
    @chatBox.show()

  hideChat: ->
    @chatBox.hide()
