{View, $} = require 'atom-space-pen-views'

jQuery = require 'jquery'
require 'jquery-ui/draggable'
require('jquery-mousewheel')($)

Contact = require './atox-contact'

module.exports =
class MainWindow extends View
  @content: ->
    @div id: 'aTox-main-window', outlet: 'mainWin', =>
      @div id: 'aTox-main-window-header', =>
        @h1 "aTox - Main Window"
        @div id: 'aTox-main-window-header-status-container', class: 'online', =>
          @div id: 'aTox-main-window-header-status-container-online', class: 'aTox-main-window-header-status'
          @div id: 'aTox-main-window-header-status-container-offline', class: 'aTox-main-window-header-status'
          @div id: 'aTox-main-window-header-status-container-busy', class: 'aTox-main-window-header-status'
          @div id: 'aTox-main-window-header-status-container-away', class: 'aTox-main-window-header-status'
      @div id: 'aTox-main-window-contacts', outlet: 'contacts'

  initialize: ->
    atom.views.getView atom.workspace
      .appendChild @element

    jQuery( "#aTox-main-window" ).draggable {handle: '#aTox-main-window-header'}

    @contacts.mousewheel (event) => @scrollHandler event

    @isOn          = true
    @contactsArray = []
    @deltaScroll   = 0
    @maxScroll     = 0

  scrollHandler: (event) ->
    return if @maxScroll <= @contacts.height()

    @deltaScroll += event.deltaY * event.deltaFactor * atom.config.get 'atox.scrollFactor'

    maxScrollHelper = -( @maxScroll - @contacts.height() )

    @deltaScroll = 0 if @deltaScroll > 0
    @deltaScroll = maxScrollHelper if @deltaScroll < maxScrollHelper

    for e in @contactsArray
      e.stop()
      e.animate { "top": "#{@deltaScroll}px" }, 100

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

  addContact: (name, status, img) ->
    temp = new Contact name, status, img
    temp.appendTo @contacts
    @contactsArray.push temp
    @maxScroll += temp.outerHeight() + parseInt temp.css( "margin" ), 10
    @maxScroll += ( parseInt temp.css( "margin" ), 10 ) if @contactsArray.length == 1
