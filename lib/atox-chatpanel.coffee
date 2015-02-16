{ScrollView, TextEditorView, $, $$} = require 'atom-space-pen-views'

module.exports =
class Chatpanel extends ScrollView
  @content: (params) ->
    @div id: 'aTox-chatpanel', =>
      @div id: 'aTox-chatpanel-chathistory', outlet: 'history'
      @div id: 'aTox-chatpanel-input', =>
        @div id: 'aTox-chatpanel-input-status-con', =>
          @div id: 'aTox-chatpanel-input-status', outlet: 'status'
        @button class: 'btn', id: 'aTox-chatpanel-btn', "Send"
        @subview 'inputField', new TextEditorView(mini: false, placeholderText: 'Type to write something.')

  addMessage: (params) ->
    if params.msg is ''
      return
    @history.append '<p><span style="' + "color: #{params.color}" + '">' + "#{params.name}: </span>#{params.msg}</p>"
    $('#aTox-chatpanel-chathistory').scrollTop($('#aTox-chatpanel-chathistory')[0].scrollHeight);

  initialize: (params) ->
    atom.workspace.addBottomPanel {item: @element}
    $('#aTox-chatpanel-input').on 'keydown', (e) =>
      if e.keyCode is 13
        e.preventDefault()
        @addMessage {color: params.color, name: params.uname, msg: @inputField.getText()}
        @inputField.setText ''
    $('#aTox-chatpanel-btn').click =>
      @addMessage {color: params.color, name: params.uname, msg: @inputField.getText()}
      @inputField.setText ''
    @isOn = true

  changeStatus: (status) ->
    if status is 'online'
      color = '#0f0'
    else if status is 'offline'
      color = '#444'
    else if status is 'busy'
      color = '#340'
    @status.css {color: color}

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
