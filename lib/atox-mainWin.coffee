{View, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui/draggable'

module.exports =
class MainWindow extends View
  @content: ->
    @div id: 'aTox-main-window', =>
      @div id: 'aTox-main-window-dragbar'
      @div id: 'aTox-main-window-header', =>
        @h1 "aTox - Main Window"
        @div id: 'aTox-main-window-header-status-container', class: 'online', =>
          @div id: 'aTox-main-window-header-status-container-online', class: 'aTox-main-window-header-status'
          @div id: 'aTox-main-window-header-status-container-offline', class: 'aTox-main-window-header-status'
          @div id: 'aTox-main-window-header-status-container-busy', class: 'aTox-main-window-header-status'
          @div id: 'aTox-main-window-header-status-container-away', class: 'aTox-main-window-header-status'
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
    jQuery('#aTox-main-window').draggable {handle: '#aTox-main-window-dragbar'}

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
