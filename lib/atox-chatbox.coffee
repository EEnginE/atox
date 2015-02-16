{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'

module.exports =
class ChatBox extends View
  @content: (attr) ->
    @ID = "aTox-chatbox-#{attr.name}-#{attr.id}"
    @HEADER = "aTox-chatbox-header-#{attr.online}"

    @div id: "#{@ID}", class: 'aTox-chatbox', outlet: 'mainBox', =>
      @div id: "#{@ID}-header", class: "#{@HEADER}", outlet: "header", =>
        @h1 "#{attr.name}"
      @div id: "#{@ID}-chathistory", class: "aTox-chatbox-chathistory", outlet: "chathistory"
      @div id: "#{@ID}-textfield", class: 'aTox-chatbox-textfield', =>
        @subview "inputfield", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  addToHistory: (color, user, message) ->
    @chathistory.append " <p><span style='font-weight:bold;color:rgba(#{color.red},#{color.green},#{color.blue},#{color.alpha});margin-left:5px;margin-top:5px'>#{user}: </span><span style=cursor:text;-webkit-user-select: text>#{message}</span></p>"
    jQuery("#aTox-chatbox-#{@chatname}-#{@id}-chathistory").scrollTop(jQuery("#aTox-chatbox-#{@chatname}-#{@id}-chathistory")[0].scrollHeight);

  initialize: (attr) ->
    atom.views.getView atom.workspace
      .appendChild @element

    @event = attr.event
    @event.on "user-write-#{attr.id}", (msg) => @userMessage msg

    @id = attr.id

    ID = "chatbox-#{attr.name}-#{attr.id}"
    jQuery("#aTox-#{ID}").draggable {handle: @header}
    jQuery("#aTox-#{ID}-textfield").keydown( (event) =>
      if event.which is 13 and @inputfield.getText() != ""
        @event.emit "user-write-#{attr.id}", { msg: @inputfield.getText() }
        @inputfield.setText("");
      else if event.which is 27
        @hide()
    )
    @chatname = attr.name
    @isOn = true

    @hide()

  userMessage: (msg) ->
    @addToHistory(( atom.config.get 'atox.chatColor' ), ( atom.config.get 'atox.userName' ), msg.msg );

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
