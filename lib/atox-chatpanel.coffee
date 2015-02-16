{ScrollView, TextEditorView, $, $$} = require 'atom-space-pen-views'

StatusSelector = require './atox-statusSelector'

module.exports =
class Chatpanel extends ScrollView
  @content: (params) ->
    @div id: 'aTox-chatpanel', =>
      @div id: 'aTox-chatpanel-chathistory', outlet: 'history'
      @div id: 'aTox-chatpanel-input', =>
        @div id: 'aTox-chatpanel-input-status-con', outlet: 'status'
        @button class: 'btn', id: 'aTox-chatpanel-btn', "Send"
        @subview 'inputField', new TextEditorView(mini: false, placeholderText: 'Type to write something.')

  addMessage: (params) ->
    if params.msg is ''
      return
    @history.append '<p><span style="' + "color: #{params.color}" + '">' + "#{params.name}: </span>#{params.msg}</p>"
    $('#aTox-chatpanel-chathistory').scrollTop($('#aTox-chatpanel-chathistory')[0].scrollHeight);

  initialize: (params) ->
    @event = params.event

    atom.workspace.addBottomPanel {item: @element}
    $('#aTox-chatpanel-input').on 'keydown', (e) =>
      if e.keyCode is 13
        e.preventDefault()
        @addMessage {color: (atom.config.get 'atox.chatColor'), name: params.uname, msg: @inputField.getText()}
        @inputField.setText ''
    $('#aTox-chatpanel-btn').click =>
      @addMessage {color: (atom.config.get 'atox.chatColor'), name: params.uname, msg: @inputField.getText()}
      @inputField.setText ''
    @isOn = true

    @statusSelector = new StatusSelector 'panel', @event
    @statusSelector.appendTo @status

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
