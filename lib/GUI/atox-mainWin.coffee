{View, $} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui/draggable'
require('jquery-mousewheel')($)

StatusSelector = require './atox-statusSelector'

module.exports =
class MainWindow extends View
  @content: ->
    @div class: 'aTox-main-window', outlet: 'mainWin', =>
      @div class: 'aTox-main-window-header', outlet: 'header', =>
        @h1 "aTox - Main Window", outlet: 'winName'
      @div class: 'aTox-main-window-contacts', outlet: 'contacts'

  initialize: (params) ->
    @aTox = params.aTox

    atom.views.getView atom.workspace
      .appendChild @element

    jQuery(@element).draggable {handle: @header}
    @contacts.mousewheel (event) => @scrollHandler event #Remove that!

    @statusSelector = new StatusSelector {aTox: @aTox, win: "main-window"}
    @statusSelector.appendTo @header

    @contactsArray = []
    @deltaScroll   = 0
    @maxScroll     = 0
    @hide()

    @firstContactView = true

  scrollHandler: (event) -> #TODO: Fix this!
    return if @maxScroll <= @contacts.height()

    @deltaScroll += event.deltaY * event.deltaFactor * 0.5

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

  addContact: (contact) ->
    contact.appendTo @contacts
    @maxScroll += contact.outerHeight() + parseInt contact.css( "margin" ), 10
    @maxScroll += ( parseInt contact.css( "margin" ) ) if @firstContactView
    @contactsArray.push contact
    @firstContactView = false
