{View, $, $$} = require 'atom-space-pen-views'

module.exports =
class ContactView extends View
  @content: (params) ->
    @div   class: 'aTox-Contact-offline', =>
      @div class: "aTox-Contact-img", outlet: 'img'
      @div class: "aTox-Contact-name", outlet: 'name'
      @div class: "aTox-Contact-status", outlet: 'status'
      @div class: "aTox-Contact-os", outlet: 'online'

  initialize: (params) ->
    @click => params.cb()
    @parent = params.parent
    @name.text   @parent.name()
    @status.text @parent.status()

    if @parent.img() != 'none'
      @img.css { "background-image": "url(\"#{@parent.img()}\")" }
    else if atom.config.get('aTox.userAvatar') != 'none'
      # TODO add placeholder avatar
      @img.css { "background-image": "url(\"#{atom.config.get 'aTox.userAvatar'}\")" }

    if @parent.selected()
      @attr {class: "aTox-Contact-#{@parent.online()}-select"}
    else
      @attr {class: "aTox-Contact-#{@parent.online()}"}

  update: (what) ->
    switch what
      when 'name'   then @name.text @parent.name()
      when 'status' then @status.text @parent.status()
      when 'img'
        if @parent.img() != 'none'
          @img.css { "background-image": "url(\"#{@parent.img()}\")" }
        else if atom.config.get('aTox.userAvatar') != 'none'
          # TODO add placeholder avatar
          @img.css { "background-image": "url(\"#{atom.config.get 'aTox.userAvatar'}\")" }
      when 'select', 'online'
        if @parent.selected()
          @attr {class: "aTox-Contact-#{@parent.online()}-select"}
        else
          @attr {class: "aTox-Contact-#{@parent.online()}"}
