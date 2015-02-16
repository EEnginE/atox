{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'

module.exports =
class ChatBox extends View
  @content: (chatname) ->
    @ID = "aTox-chatbox-#{chatname}"

    @div id: "#{@ID}", class: 'aTox-chatbox', outlet: 'mainBox', =>
      @div id: "#{@ID}-dragbar", class: 'aTox-chatbox-dragbar'
      @div id: "#{@ID}-header", class: 'aTox-chatbox-header', =>
        @h1 "aTox - #{chatname}"
      @div id: "#{@ID}-chathistory", class: "aTox-chatbox-chathistory", outlet: "chathistory"
      @div id: "#{@ID}-textfield", class: 'aTox-chatbox-textfield', =>
        @subview "inputfield", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  addToHistory: (color, user, message) ->
      @chathistory.append " <p><span style='font-weight:bold;color:#{color};margin-left:5px;margin-top:5px'>#{user}: </span><span style=cursor:text;-webkit-user-select: text>#{message}</span></p>"

  initialize: (chatname) ->
    atom.views.getView atom.workspace
      .appendChild @element
    jQuery("#aTox-chatbox-#{chatname}").draggable {handle: "#aTox-chatbox-#{chatname}-dragbar"}
    jQuery("#aTox-chatbox-#{chatname}-textfield").keydown( (event) =>
      if event.which == 13 and @inputfield.getText() != ""
        @addToHistory("white", "You", @inputfield.getText());
        jQuery("#aTox-chatbox-#{chatname}-chathistory").scrollTop(jQuery("#aTox-chatbox-#{chatname}-chathistory")[0].scrollHeight);
        @inputfield.setText("");
    )
    @chatname = chatname
    @isOn = true

    @hide()

  show: ->
    @isOn = true
    console.log "show"
    super() # Calls jQuery's show

  hide: ->
    @isOn = false
    super() # Calls jQuery's hide

  toggle: ->
    if @isOn
      @hide()
    else
      @show()
