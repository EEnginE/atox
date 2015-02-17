{Emitter}   = require 'event-kit'

ContactView = require './atox-contactView'
ChatBox     = require './atox-chatbox'

module.exports =
class Contact
  constructor: (params) ->
    @selected = false
    @name     = params.name
    @img      = params.img
    @id       = params.id
    @status   = params.status
    @online   = params.online
    @event    = params.event

    @contactView = new ContactView { id: @id, handle: => @handleClick() }
    @chatBox     = new ChatBox { id: @id, online: params.online, event: @event }

    @event.on "user-write-#{@id}",      (msg)  => @chatBox.userMessage msg
    @event.on "chat-#{@id}-visibility", (what) => @visibility what


    if @id == 0
      params.win.addContact @contactView, true
    else
      params.win.addContact @contactView, false

    @update()

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

  showChat: ->
    @chatBox.show()

  hideChat: ->
    @chatBox.hide()
