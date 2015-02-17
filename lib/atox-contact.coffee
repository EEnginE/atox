{Emitter}   = require 'event-kit'

ContactView = require './atox-contactView'
ChatBox     = require './atox-chatbox'

module.exports =
class Contact
  constructor: (params) ->
    @selected = false

    @name     = params.name
    @img      = params.img
    @id       = params.cid
    @status   = params.status
    @online   = params.online
    @event    = params.event
    @panel    = params.panel

    @contactView = new ContactView { cid: @cid, handle: => @handleClick() }
    @chatBox     = new ChatBox { cid: @cid, online: @online, event: @event }

    @panel.addChat { cid: @cid, img: @img, event: @event }

    @event.on "aTox-add-message#{@cid}", (msg)  => @chatBox.addMessage msg
    @event.on "aTox-add-message#{@cid}", (msg)  => @panel.addMessage   msg
    @event.on "chat-#{@cid}-visibility", (newV) => @visibility         newV

    if @cid == 0
      params.win.addContact @contactView, true
    else
      params.win.addContact @contactView, false

    @update()

  visibility: (newV) ->
    if newV == 'show'
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

  showChat: ->
    @chatBox.show()

  hideChat: ->
    @chatBox.hide()
