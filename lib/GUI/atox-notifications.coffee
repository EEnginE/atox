{View, $, $$} = require 'atom-space-pen-views'

class PopUp extends View
  @content: (params) ->
    @div class: "aTox-PopUp-#{params.type}", =>
      @div class: "aTox-PopUp-img", outlet: 'img'
      @div class: "aTox-PopUp-name", => @raw "#{params.name}"
      @div class: "aTox-PopUp-content", => @raw "#{params.content}"

  initialize: (params) ->
    if params.img? and params.img is not "none"
      @img.css { "background-image": "url(\"#{params.img}\")" }
    else
      @img.css { "display": "none" }

module.exports =
class Notifications extends View
  @content: ->
    @div id: "aTox-PopUp-root"

  initialize: (params) ->
    @aTox  = params.aTox
    @PopUps = []
    @lts = 0
    @ani = false

    atom.views.getView atom.workspace
      .appendChild @element

  add: (msg) ->
    if @ani is true
      setTimeout =>
        @add msg
      , 100
      return
    temp = new PopUp { type: msg.type, name: msg.name, content: msg.content, img: msg.img }

    temp.hide()
    temp.appendTo this
    temp.fadeIn 250

    stimeout  = 4000
    aduration = 750
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
