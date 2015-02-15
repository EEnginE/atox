{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'

module.exports =
class Contact extends View
  @content: (attr) ->
    num   = parseInt ( Math.random() * 100000000 ), 10
    ID    = "aTox-Contact-#{attr.name}-#{num}"
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

    @Name   = attr.name
    @Status = attr.status
    @event  = new Emitter
    @event.on 'aTox:select', attr.selectCall

    @click => @handleClick()

  handleClick: ->
    @selectToggle()
    @event.emit 'aTox:select', {
      name: @Name,
      status: @Status,
      selected: @selected,
      online: @onlineSt,
      img: @Img}

  updateName: (name) ->
    @status.text "#{name}"

  updateStatus: (status) ->
    @name.text "#{name}"

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

  selectToggle: ->
    @selected = !@selected;
    @updateClass()
