{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'

module.exports =
class ChatBox extends View
  @content: (chatname) ->
    @div id: 'aTox-chatbox', =>
      @div id: 'aTox-chatbox-dragbar'
      @div id: 'aTox-chatbox-header', =>
        @h1 "aTox Chat - #{chatname}"
      @div id: 'aTox-chatbox-chathistory', class: 'aTox-chatbox-chathistory', outlet: "chathistory"
      @div id: 'aTox-chatbox-textfield', =>
        @subview 'inputfield', new TextEditorView(mini: true, placeholderText: 'Type here to write something.')

  addToHistory: (color, user, message) ->
      @chathistory.append " <p><span style='font-weight:bold;color:#{color};margin-left:5px;margin-top:5px'>#{user}: </span>#{message}"

  initialize: (chatname) ->
    atom.views.getView atom.workspace
      .appendChild @element
    jQuery('#aTox-chatbox').draggable {handle: '#aTox-chatbox-dragbar'}
    jQuery('#aTox-chatbox-textfield').keydown( (event) =>
      if event.which == 13 and @inputfield.getText() != ""
        @addToHistory("white", "You", @inputfield.getText());
        @addToHistory("red", "Taiterio", "Heyo");
        @addToHistory("red", "Arvius", "Neyo");
        @addToHistory("red", "Mister Mense", "Meyo");
        jQuery('#aTox-chatbox-chathistory').scrollTop(jQuery('#aTox-chatbox-chathistory')[0].scrollHeight);
        @inputfield.setText("");
    )
    @chatname = chatname
    @isOn = true

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
