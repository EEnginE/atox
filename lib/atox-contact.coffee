{View, $, $$} = require 'atom-space-pen-views'

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
    @updateImg "#{attr.img}"
    @updateOnline "#{attr.online}"

  updateName: (name) ->
    @status.text "#{name}"

  updateStatus: (status) ->
    @name.text "#{name}"

  updateOnline: (online) ->
    @attr "class", "aTox-Contact-#{online}"

  updateImg: (img) ->
    @img.css { "background-image": "url(\"#{img}\")" }
