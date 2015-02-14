{View, $, $$} = require 'atom-space-pen-views'

class PopUp extends View
  @content: (id, type, name, content, img) ->
    tName = "aTox-PopUp-#{id}_#{type}"
    tType = "aTox-PopUp"

    @div id: "#{tName}", class: "#{tType}-#{type}", =>
      @div id: "#{tName}-name",    class: "#{tType}-name",    => @raw "#{name}"
      @div id: "#{tName}-content", class: "#{tType}-content", => @raw "#{content}"
      @div id: "#{tName}-img",     class: "#{tType}-img",     => @raw "#{img}"


module.exports =
class PopUpHelper extends View
  @content: ->
    @div id: "aTox-PopUp-root"

  initialize: ->
    @currentID = 0
    @PopUps = []
    @run = true
    @lts = 0

    atom.views.getView atom.workspace
      .appendChild @element

  add: (type, name, content, img) ->
    temp = new PopUp( @currentID, type, name, content, img )
    @currentID++

    temp.hide()
    temp.appendTo this
    temp.fadeIn atom.config.get 'atox.fadeDuration'

    stimeout = ( atom.config.get 'atox.popupTimeout' ) * 1000
    aduration = ( atom.config.get 'atox.fadeDuration' ) + 1200
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
    temp = @PopUps[0]
    @PopUps.shift()
    console.log (atom.config.get 'atox.fadeDuration')
    temp.animate {opacity: 0}, (atom.config.get 'atox.fadeDuration'), =>
       e.css ({position: 'relative'}) for e in @PopUps
       e.animate {top: '-75px'}, 1000 for e in @PopUps
       setTimeout =>
         temp.remove()
         e.css {position: 'static', top: '0'} for e in @PopUps
       , 1100
