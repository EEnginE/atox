{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery    = require 'jquery'
require 'jquery-ui'

module.exports =
class QuickChat extends View
  @content: ->
    @div    class: 'aTox-quickChat', =>
      @div  class: 'chatName',       => @h1 outlet: 'chatName'
      @div  class: 'input',          =>
        @subview 'msg', new TextEditorView(mini: true, placeholderText: "Message")
        @div class: 'btns', =>
          @div outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
          @div outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Send'

  initialize: (params) ->
    @aTox = params.aTox
    @isVisible = false;

    atom.views.getView atom.workspace
      .appendChild @element

    @msg.on 'keydown', (e) =>
      @send() if e.keyCode is 13
      @hide() if e.keyCode is 27

    @hide()

  show: (cID) ->
    return if @isVisible
    return unless @aTox.gui.chats[cID]?
    @isVisible  = true
    @currentCID = cID

    @chatName.text @aTox.gui.chats[@currentCID].name()
    super()

    @msg.focus()

  send: ->
    @aTox.gui.chats[@currentCID].sendMSG @msg.getText()
    @hide()

  hide: ->
    @isVisible  = false
    @msg.setText   ''
    @chatName.text ''
    super()
