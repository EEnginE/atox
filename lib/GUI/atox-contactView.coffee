{View, $, $$} = require 'atom-space-pen-views'

module.exports =
class ContactView extends View
  @content: (params) ->
    @div class: 'aTox-Contact-offline', outlet: 'mainWin', =>
      @div class: "aTox-Contact-img", outlet: 'img'
      @div class: "aTox-Contact-name", outlet: 'name'
      @div class: "aTox-Contact-status", outlet: 'status'
      @div class: "aTox-Contact-os", outlet: 'online'

  initialize: (params) ->
    @click => params.cb()

  update: (params) ->
    @name.text params.name
    @status.text params.status

    if params.img != 'none'
      @img.css { "background-image": "url(\"#{params.img}\")" }
    else if atom.config.get('aTox.userAvatar') != 'none'
      # TODO add placeholder avatar
      @img.css { "background-image": "url(\"#{atom.config.get 'aTox.userAvatar'}\")" }

    if params.selected
      @addClass "aTox-Contact-#{params.online}-select"
    else
      @removeClass "aTox-Contact-#{params.online}-select"
