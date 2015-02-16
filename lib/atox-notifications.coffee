{View, $, $$} = require 'atom-space-pen-views'

class PopUp extends View
  @content: (attr) ->
    tName = "aTox-PopUp-#{attr.id}_#{attr.type}"
    tType = "aTox-PopUp"

    @div id: "#{tName}", class: "#{tType}-#{attr.type}", =>
      @div id: "#{tName}-img",     class: "#{tType}-img", outlet: 'img'
      @div id: "#{tName}-name",    class: "#{tType}-name",    => @raw "#{attr.name}"
      @div id: "#{tName}-content", class: "#{tType}-content", => @raw "#{attr.content}"

  initialize: (attr) ->
    if attr.img != 'none'
      @img.css { "background-image": "url(\"#{attr.img}\")" }
    else
      @img.css { "display": "none" }


module.exports =
class Notifications extends View
  @content: ->
    @div id: "aTox-PopUp-root"

  initialize: ->
    @currentID = 0
    @PopUps = []
    @run = true
    @lts = 0
    @ani = false

    atom.views.getView atom.workspace
      .appendChild @element

  add: (type, name, content, img) ->
    if @ani is true
      setTimeout =>
        @add type, name, content, img
      , 100
      return
    temp = new PopUp { id: @currentID, type: type, name: name, content: content, img: img }
    @currentID++

    temp.hide()
    temp.appendTo this
    temp.fadeIn atom.config.get 'atox.fadeDuration'

    stimeout = ( atom.config.get 'atox.popupTimeout' ) * 1000
    aduration = ( atom.config.get 'atox.fadeDuration' ) + ( atom.config.get 'atox.notificationSpeed' ) + 200
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
    temp.animate {opacity: 0}, (atom.config.get 'atox.fadeDuration'), =>
       e.css ({position: 'relative'}) for e in @PopUps
       e.animate {top: '-75px'}, ( atom.config.get 'atox.notificationSpeed' ) for e in @PopUps
       setTimeout =>
         temp.remove()
         e.css {position: 'static', top: '0'} for e in @PopUps
         @ani = false
       , ( atom.config.get 'atox.notificationSpeed' ) + 100
