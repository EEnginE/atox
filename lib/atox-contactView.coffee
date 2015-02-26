{View, $, $$} = require 'atom-space-pen-views'

ChatBox       = require './atox-chatbox'

module.exports =
class ContactView extends View
  @content: (params) ->
    ID    = "aTox-Contact-#{params.cid}"
    CLASS = "aTox-Contact"

    @div id: "#{ID}", class: 'aTox-Contact-offline', outlet: 'mainWin', =>
      @div id: "#{ID}-img",    class: "#{CLASS}-img",    outlet: 'img'
      @div id: "#{ID}-name",   class: "#{CLASS}-name",   outlet: 'name'
      @div id: "#{ID}-status", class: "#{CLASS}-status", outlet: 'status'
      @div id: "#{ID}-online", class: "#{CLASS}-os",     outlet: 'online'

  initialize: (params) ->
    @click => params.handle()

  update: (params) ->
    @name.text "#{params.name}"
    @status.text "#{params.status}"

    if params.img != 'none'
      @img.css { "background-image": "url(\"#{params.img}\")" }
    else if atom.config.get('aTox.userAvatar') != 'none'
      # TODO add placeholder avatar
      @img.css { "background-image": "url(\"#{atom.config.get 'aTox.userAvatar'}\")" }

    if params.selected
      @attr "class", "aTox-Contact-#{params.online}-select"
    else
      @attr "class", "aTox-Contact-#{params.online}"
