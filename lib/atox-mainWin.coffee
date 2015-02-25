{View, $} = require 'atom-space-pen-views'

jQuery = require 'jquery'
require 'jquery-ui/draggable'
require('jquery-mousewheel')($)

StatusSelector = require './atox-statusSelector'

module.exports =
class MainWindow extends View
  @content: ->
    @div id: 'atox-main-window', outlet: 'mainWin', =>
      @div id: 'atox-main-window-header',   outlet: 'header', =>
        @h1 "atox - Main Window",           outlet: 'winName'
      @div id: 'atox-main-window-contacts', outlet: 'contacts'

  initialize: (event) ->
    atom.views.getView atom.workspace
      .appendChild @element

    @mainEvent = event
    @addClass 'atox-hidden'

    jQuery( "#atox-main-window" ).draggable {handle: '#atox-main-window-header'}

    @contacts.mousewheel (event) => @scrollHandler event

    @statusSelector = new StatusSelector "main-window", @mainEvent
    @statusSelector.appendTo @header

    @contactsArray = []

    @isOn          = false
    @deltaScroll   = 0
    @maxScroll     = 0

  scrollHandler: (event) ->
    return if @maxScroll <= @contacts.height()

    @deltaScroll += event.deltaY * event.deltaFactor * 0.5

    maxScrollHelper = -( @maxScroll - @contacts.height() )

    @deltaScroll = 0 if @deltaScroll > 0
    @deltaScroll = maxScrollHelper if @deltaScroll < maxScrollHelper

    for e in @contactsArray
      e.stop()
      e.animate { "top": "#{@deltaScroll}px" }, 100

  showAT: ->
    @isOn = true
    @removeClass 'atox-hidden'

  hideAT: ->
    @isOn = false
    @addClass 'atox-hidden'

  toggle: ->
    if @isOn
      @hideAT()
    else
      @showAT()

  addContact: (contact, first) ->
    contact.appendTo @contacts
    @maxScroll += contact.outerHeight() + parseInt contact.css( "margin" ), 10
    @maxScroll += ( parseInt contact.css( "margin" ), 10 ) if first
    @contactsArray.push contact
