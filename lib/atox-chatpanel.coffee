{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'

StatusSelector = require './atox-statusSelector'

module.exports =
class Chatpanel extends View
  @content: (params) ->
    @div class: 'aTox-chatpanel', =>
      @div id: 'aTox-chatpanel-history-box', outlet: 'hbox', =>
        @div class: 'aTox-chatpanel-border ui-resizable-handle ui-resizable-n', outlet: 'rborder'
        @div class: 'aTox-chatpanel-chathistory', outlet: 'history'
      @div class: 'aTox-chatpanel-input', outlet: 'input', =>
        @div class: 'aTox-chatpanel-input-status-con', outlet: 'status'
        @button class: 'btn aTox-chatpanel-btn', outlet: 'btn', "Send"
        @subview 'inputField', new TextEditorView(mini: true, placeholderText: 'Type to write something.')

  addMessage: (params) ->
    if params.msg is ''
      return
    @history.append '<p><span style="' + "color: rgba(#{params.color.red}, #{params.color.green}, #{params.color.blue}, #{params.color.alpha})" + '">' + "#{params.name}: </span>#{params.msg}</p>"
    @scrollBot()

  initialize: (params) ->
    @event = params.event

    atom.workspace.addBottomPanel {item: @element}
    @input.on 'keydown', (e) =>
      if e.keyCode is 13
        e.preventDefault()
        @addMessage {color: (atom.config.get 'atox.chatColor'), name: (atom.config.get 'atox.userName'), msg: @inputField.getText()}
        @inputField.setText ''
      else if e.keyCode is 27
        @hide()
    @btn.click =>
      @addMessage {color: (atom.config.get 'atox.chatColor'), name: (atom.config.get 'atox.userName'), msg: @inputField.getText()}
      @inputField.setText ''

    jQuery(@hbox).resizable
      handles: {n: @rborder}
      resize: (event, ui) =>
        @scrollBot()
    @isOn = true

    @statusSelector = new StatusSelector 'panel', @event
    @statusSelector.appendTo @status

  scrollBot: ->
    @history.scrollTop(@history[0].scrollHeight);

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
