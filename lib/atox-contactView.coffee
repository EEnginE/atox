{View, $, $$} = require 'atom-space-pen-views'

ChatBox       = require './atox-chatbox'

module.exports =
class ContactView extends View
  @content: (attr) ->
    ID    = "aTox-Contact-#{attr.id}"
    CLASS = "aTox-Contact"

    @div id: "#{ID}", class: 'aTox-Contact-offline', outlet: 'mainWin', =>
      @div id: "#{ID}-img",    class: "#{CLASS}-img",    outlet: 'img'
      @div id: "#{ID}-name",   class: "#{CLASS}-name",   outlet: 'name'
      @div id: "#{ID}-status", class: "#{CLASS}-status", outlet: 'status'
      @div id: "#{ID}-online", class: "#{CLASS}-os",     outlet: 'online'

  initialize: (attr) ->
    @click => attr.handle()

  update: (attr) ->
    @name.text "#{attr.name}"
    @status.text "#{attr.status}"
    @img.css { "background-image": "url(\"#{attr.img}\")" }

    if attr.selected
      @attr "class", "aTox-Contact-#{attr.online}-select"
    else
      @attr "class", "aTox-Contact-#{attr.online}"
