{View, $, $$} = require 'atom-space-pen-views'

module.exports =
class MainWindow extends View
  @content: ->
    @div id: 'aTox-main-window', =>
      @div id: 'aTox-main-window-header', =>
        @h1 "aTox - Main Window"
      @div id: 'aTox-main-window-contacts', =>
        @p "XY"
      @div id: 'aTox-main-window-mbox', =>
        @ol outlet: "list", =>
          @li "Arvius"
          @li "Mensinda"
          @li "Taiterio"

  initialize: ->
    atom.views.getView atom.workspace
      .appendChild @element

    @isOn = true

  show: ->
    @isOn = true
    super() # Calls jQuery's show

  hide: ->
    @isOn = false
    super() # Calls jQuery's hide

  toggle: ->
    if @isOn
      @hide()
    else
      @show()
