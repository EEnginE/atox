{View, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class QuickChat extends View
  @content: ->
    @div class: 'aTox-quickChat', =>
      @h1 outlet: 'chatName'
      @subview 'msg', new TextEditorView mini: true, placeholderText: "Message"
      @div outlet: 'btns', =>
        @div outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
        @div outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Send'

  initialize: (params) ->
    @aTox  = params.aTox
    @panel = atom.workspace.addModalPanel {item: this, visible: false}

    @msg.on 'keydown', (e) =>
      @send() if e.keyCode is 13
      @hide() if e.keyCode is 27

    @btn1.click => @hide()
    @btn2.click => @send()

    @chatName.css {'overflow':     'hidden'}
    @btns.css     {'padding-left': '50px', 'padding-right': '50px'}
    @btn2.css     {'float':        'right'}

  show: (cID) ->
    return unless @aTox.gui.chats[cID]?
    @currentCID = cID

    @chatName.text @aTox.gui.chats[@currentCID].name()

    @panel.show()
    @msg.focus()

  send: ->
    @aTox.gui.chats[@currentCID].sendMSG @msg.getText()
    @hide()

  hide: ->
    @panel.hide()
    @msg.setText   ''
    @chatName.text ''
