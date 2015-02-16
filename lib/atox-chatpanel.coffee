{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'

module.exports =
class Chatpanel extends View
  @content: (params) ->
    @div id: 'aTox-chatpanel', =>
      @div id: 'aTox-chatpanel-history-box', =>
        @div id: 'aTox-chatpanel-border', outlet: 'rborder', class: 'ui-resizable-handle ui-resizable-n'
        @div id: 'aTox-chatpanel-chathistory', outlet: 'history'
      @div id: 'aTox-chatpanel-input', =>
        @div id: 'aTox-chatpanel-input-status-con', =>
          @div id: 'aTox-chatpanel-input-status', outlet: 'status'
        @button class: 'btn', id: 'aTox-chatpanel-btn', "Send"
        @subview 'inputField', new TextEditorView(mini: true, placeholderText: 'Type to write something.')

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
        @addMessage {color: params.color, name: (atom.config.get 'atox.userName'), msg: @inputField.getText()}
        @inputField.setText ''
    $('#aTox-chatpanel-btn').click =>
      @addMessage {color: params.color, name: (atom.config.get 'atox.userName'), msg: @inputField.getText()}
      @inputField.setText ''
    jQuery('#aTox-chatpanel-history-box').resizable({handles: {n: jQuery('#aTox-chatpanel-border')}})
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
