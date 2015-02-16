{Emitter}   = require 'event-kit'

ContactView = require './atox-contactView'
ChatBox     = require './atox-chatbox'

module.exports =
class Contact
  constructor: (attr) ->
    @selected = false
    @name     = attr.name
    @img      = attr.img
    @id       = attr.id
    @status   = attr.status
    @online   = attr.online
    @event    = attr.event

    @contactView = new ContactView { id: @id, handle: => @handleClick() }
    @chatBox     = new ChatBox { id: @id, event: @event }

    @event.on "user-write-#{@id}",      (msg)  => @chatBox.userMessage msg
    @event.on "chat-#{@id}-visibility", (what) => @visibility what


    @update()

    if @id == 0
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
      @event.emit "chat-#{@id}-visibility", 'hide'
    else
      @event.emit "chat-#{@id}-visibility", 'show'

    @event.emit 'aTox.select', {
      name: @name,
      status: @status,
      selected: @selected,
      online: @online,
      img: @img,
      id: @id}

    @update()

  showChat: ->
    @chatBox.show()

  hideChat: ->
    @chatBox.hide()
