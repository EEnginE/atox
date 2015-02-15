{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'
Button        = require './atox-UI-utils'

module.exports =
class YesNoQuestion extends View
  @content: (name, q, yes_t, no_t) ->
    num = parseInt ( Math.random() * 100000000 ), 10

    #@div class: 'aTox-Q-center-helper', =>
    @div id: "aTox-YNQ-#{num}", class: "aTox-YNQ", =>
      @div id: "aTox-YNQ-#{num}-n", class: "aTox-YNQ-n", => @raw "#{name}"
      @div id: "aTox-YNQ-#{num}-q", class: "aTox-YNQ-q", => @raw "#{q}"
      @div id: "aTox-YNQ-#{num}-b", class: "aTox-YNQ-b", outlet: 'buttons'

  initialize: (name, q, yes_t, no_t) ->
    @hide()

    atom.views.getView atom.workspace
      .appendChild @element

    @yesB = new Button "#{yes_t}", "yes"
    @noB  = new Button "#{no_t}", "no"

    @yesB.css {"top": "0px", "left":  "25px" }
    @noB.css  {"top": "0px", "right": "25px" }

    @yesB.click => @yes()
    @noB.click  => @no()

    @buttons.append @yesB
    @buttons.append @noB

    @canAsk     = true
    @wasAnswered = false
    @event      = new Emitter

  ask: ->
    console.error "Already asked!" if !@canAsk
    @canAsk = false
    @fadeIn atom.config.get 'atox.fadeDuration'

  yes: ->
    return if @wasAnswered
    @wasAnswered = true

    @event.emit 'yes'
    @delQ()

  no: ->
    return if @wasAnswered
    @wasAnswered = true

    @event.emit 'no'
    @delQ()

  callbacks: (yesC, noC) ->
    @event.on 'yes', yesC
    @event.on 'no',  noC

  delQ: ->
    @fadeOut (atom.config.get 'atox.fadeDuration'), => @remove()
