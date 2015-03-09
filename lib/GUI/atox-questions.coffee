{View, $, $$} = require 'atom-space-pen-views'

module.exports =
class Question extends View
  @content: (params) ->
    @div class: "aTox-Question", =>
      @div class: "aTox-Question-name", => @raw "#{params.name}"
      @div class: "aTox-Question-question", => @raw "#{params.question}"
      @div class: "aTox-Question-buttons", outlet: 'buttons'

  initialize: (params) ->
    @aTox = params.aTox
    @cb = params.cb

    @canAsk      = true
    @wasAnswered = false

    atom.views.getView atom.workspace
      .appendChild @element

    @acceptB = $$ ->
      @div class: "aTox-Button-accept", =>
        @raw "#{params.accept}"
    @declineB = $$ ->
      @div class: "aTox-Button-decline", =>
        @raw "#{params.decline}"

    @acceptB.click => @accept()
    @declineB.click  => @decline()

    @buttons.append @acceptB
    @buttons.append @declineB

    @hide()

  ask: ->
    console.error "Already asked!" if !@canAsk
    @canAsk = false
    @fadeIn 250

  accept: ->
    return if @wasAnswered
    @wasAnswered = true

    @cb true
    @deleteQ()

  decline: ->
    return if @wasAnswered
    @wasAnswered = true

    @cb false
    @deleteQ()

  deleteQ: ->
    @fadeOut 250, => @remove()
