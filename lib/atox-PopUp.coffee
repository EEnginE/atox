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

    atom.views.getView atom.workspace
      .appendChild @element

  add: (type, name, content, img) ->
    temp = new PopUp( @currentID, type, name, content, img )
    @currentID++

    temp.hide()
    temp.appendTo this
    temp.fadeIn   atom.config.get 'atox.fadeDuration'

    setTimeout =>
       @shift()
    , ( atom.config.get 'atox.popupTimeout' ) * 1000

    @PopUps.push temp

  shift: ->
    temp = @PopUps[0]
    @PopUps.shift()

    temp.fadeOut (atom.config.get 'atox.fadeDuration'), =>
       temp.remove()
