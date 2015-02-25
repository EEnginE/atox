{View, $, $$} = require 'atom-space-pen-views'

class PopUp extends View
  @content: (params) ->
    tName = "atox-PopUp-#{params.cid}_#{params.type}"
    tType = "atox-PopUp"

    @div id: "#{tName}", class: "#{tType}-#{params.type}", =>
      @div id: "#{tName}-img",     class: "#{tType}-img", outlet: 'img'
      @div id: "#{tName}-name",    class: "#{tType}-name",    => @raw "#{params.name}"
      @div id: "#{tName}-content", class: "#{tType}-content", => @raw "#{params.content}"

  initialize: (params) ->
    if params.img?
      @img.css { "background-image": "url(\"#{params.img}\")" }
    else
      @img.css { "display": "none" }


module.exports =
class Notifications extends View
  @content: ->
    @div id: "atox-PopUp-root"

  initialize: (event) ->
    @currentID = 0
    @PopUps = []
    @run = true
    @lts = 0
    @ani = false

    atom.views.getView atom.workspace
      .appendChild @element

    @event = event
    @event.on "notify", (msg) => @add msg
    @event.on 'atox.add-message', (data) =>
      return if data.tid < 0
      @event.emit 'notify', {
        type:   'inf'
        name:    data.name
        content: data.msg
        img:     data.img
      }

  add: (msg) ->
    if @ani is true
      setTimeout =>
        @add msg
      , 100
      return
    temp = new PopUp { id: @currentID, type: msg.type, name: msg.name, content: msg.content, img: msg.img }
    @currentID++

    temp.hide()
    temp.appendTo this
    temp.fadeIn 250

    stimeout  = 4000
    aduration = 250 + 300 + 200
    if ((Date.now() + stimeout) - @lts) < aduration
      timeout = stimeout + aduration - ((Date.now() + stimeout) - @lts)
    else
      timeout = stimeout
    setTimeout =>
       @shift()
    , timeout
    @lts = Date.now() + timeout

    @PopUps.push temp

  shift: ->
    @ani = true
    temp = @PopUps[0]
    @PopUps.shift()
    temp.animate {opacity: 0}, 250, =>
       e.css ({position: 'relative'}) for e in @PopUps
       e.animate {top: '-75px'}, 300 for e in @PopUps
       setTimeout =>
         temp.remove()
         e.css {position: 'static', top: '0'} for e in @PopUps
         @ani = false
       , 400
