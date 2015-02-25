{View, $, $$} = require 'atom-space-pen-views'

ChatBox       = require './atox-chatbox'

module.exports =
class ContactView extends View
  @content: (params) ->
    ID    = "atox-Contact-#{params.cid}"
    CLASS = "atox-Contact"

    @div id: "#{ID}", class: 'atox-Contact-offline', outlet: 'mainWin', =>
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
    else
      # TODO add placeholder avatar
      @img.css { "background-image": "url(\"#{atom.config.get 'atox.userAvatar'}\")" }

    if params.selected
      @attr "class", "atox-Contact-#{params.online}-select"
    else
      @attr "class", "atox-Contact-#{params.online}"
