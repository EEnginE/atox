{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'

module.exports =
class Question extends View
  @content: (params) ->
    @div class: "aTox-Question", =>
      @div class: "aTox-Question-name", => @raw "#{params.name}"
      @div class: "aTox-Question-question", => @raw "#{params.question}"
      @div class: "aTox-Question-buttons", outlet: 'buttons'

  initialize: (params) ->
    @hide()
    atom.views.getView atom.workspace
      .appendChild @element
    @acceptB = $$ ->
      @div class: "aTox-Button-accept", =>
        @raw "#{params.accept}"
    @declineB = $$ ->
      @div class: "aTox-Button-decline", =>
        @raw "#{params.decline}"
    @acceptB.css {"top": "0px", "left":  "25px" }
    @declineB.css  {"top": "0px", "right": "25px" }

    @acceptB.click => @accept()
    @declineB.click  => @decline()

    @buttons.append @acceptB
    @buttons.append @declineB

    @canAsk      = true
    @wasAnswered = false
    @event       = new Emitter

  ask: ->
    console.error "Already asked!" if !@canAsk
    @canAsk = false
    @fadeIn 250

  accept: ->
    return if @wasAnswered
    @wasAnswered = true

    @event.emit 'yes'
    @deleteQ()

  decline: ->
    return if @wasAnswered
    @wasAnswered = true

    @event.emit 'decline'
    @deleteQ()

  deleteQ: ->
    @fadeOut 250, => @remove()
