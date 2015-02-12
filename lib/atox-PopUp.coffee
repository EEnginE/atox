{View, $, $$} = require 'atom-space-pen-views'

class PopUp extends View
  @content: (id, type, name, content, img) ->
    name = "aTox-PopUp-#{id}_#{type}"
    type = "aTox-PopUp-#{type}"

    @div id: "#{name}", class: "#{type}", =>
      @div id: "#{name}-name",    class: "#{type}-name",    => @raw "#{name}"
      @div id: "#{name}-content", class: "#{type}-content", => @raw "#{content}"
      @div id: "#{name}-img",     class: "#{type}-img",     => @raw "#{img}"


module.exports =
class PopUpHelper
  constructor: ->
    @currentID = 0
    @PopUps = []

  add: (type, name, content, img) ->
    temp = new PopUp( 0, type, name, content, img )
    temp.appendTo atom.views.getView atom.workspace
    @PopUps.push temp
    console.log "Added #{type} popup '#{name}' [#{@currentID}]"
    @currentID++
