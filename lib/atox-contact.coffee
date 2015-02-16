{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'

ChatBox       = require './atox-chatbox'

module.exports =
class Contact extends View
  @content: (attr) ->
    ID    = "aTox-Contact-#{attr.name}-#{attr.id}"
    CLASS = "aTox-Contact"

    @div id: "#{ID}", class: 'aTox-Contact-offline', outlet: 'mainWin', =>
      @div id: "#{ID}-name",   class: "#{CLASS}-name",   outlet: 'name',   => @raw "#{attr.name}"
      @div id: "#{ID}-status", class: "#{CLASS}-status", outlet: 'status', => @raw "#{attr.status}"
      @div id: "#{ID}-img",    class: "#{CLASS}-img",    outlet: 'img'
      @div id: "#{ID}-online", class: "#{CLASS}-os",     outlet: 'online'

  initialize: (attr) ->
    @selected = false;

    @updateImg "#{attr.img}"
    @updateOnline "#{attr.online}"

    @id     = attr.id
    @Name   = attr.name
    @Status = attr.status
    @event  = attr.event

    @click => @handleClick()

    @chatBox = new ChatBox @Name

  handleClick: ->
    @selectToggle()
    @event.emit 'aTox.select', {
      name: @Name,
      status: @Status,
      selected: @selected,
      online: @onlineSt,
      img: @Img,
      id: @id}

  updateName: (name) ->
    @Name = name
    @status.text "#{name}"

  updateStatus: (status) ->
    @Status = status
    @status.text "#{status}"

  updateOnline: (online) ->
    @onlineSt = "#{online}"
    @updateClass()

  updateClass: ->
    if @selected
      @attr "class", "aTox-Contact-#{@onlineSt}-select"
    else
      @attr "class", "aTox-Contact-#{@onlineSt}"

  updateImg: (img) ->
    @Img = img
    @img.css { "background-image": "url(\"#{img}\")" }

  select: ->
    @selected = true;
    @updateClass()

  deselect: ->
    @selected = false;
    @updateClass()

  showChat: ->
    @chatBox.show()

  hideChat: ->
    @chatBox.hide()

  selectToggle: ->
    @selected = !@selected;
    @updateClass()
