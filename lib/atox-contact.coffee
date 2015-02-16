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
    @chatBox     = new ChatBox { name: @name, id: @id, event: @event }

    @update()

    if @id == 0
      attr.win.addContact @contactView, true
    else
      attr.win.addContact @contactView, false

  update: ->
    @contactView.update {
      name:   @name,
      status: @status,
      online: @online,
      img:    @img
    }

  handleClick: ->
    @selected = ! @selected

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
