{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'

module.exports =
class ChatBox extends View
  @content: (attr) ->
    ID = "aTox-chatbox-#{attr.id}"
    HEADER = "aTox-chatbox-header-offline"

    @div id: "#{ID}", class: 'aTox-chatbox', outlet: 'mainBox', =>
      @div id: "#{ID}-header",      class: "aTox-chatbox-header-offline", outlet: 'header', =>
        @h1 outlet: 'name'
      @div id: "#{ID}-chathistory", class: "aTox-chatbox-chathistory",    outlet: 'chathistory'
      @div id: "#{ID}-textfield",   class: 'aTox-chatbox-textfield',      outlet: 'textfield',  =>
        @subview "inputfield", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  addToHistory: (color, user, message) ->
    @chathistory.append "<p><span style='font-weight:bold;color:rgba(#{color.red},#{color.green},#{color.blue},#{color.alpha});margin-left:5px;margin-top:5px'>#{user}: </span><span style=cursor:text;-webkit-user-select: text>#{message}</span></p>"
    jQuery( @chathistory ).scrollTop(jQuery( @chathistory )[0].scrollHeight);

  initialize: (attr) ->
    atom.views.getView atom.workspace
      .appendChild @element

    @id = attr.id

    jQuery( @element   ).draggable { handle: @header }
    jQuery( @textfield ).keydown( (event) =>
      if event.which is 13 and @inputfield.getText() != ""
        attr.event.emit "user-write-#{attr.id}", { msg: @inputfield.getText() }
        @inputfield.setText("");
      else if event.which is 27
        attr.event.emit "chat-#{attr.id}-visibility", 'hide'
    )
    @chatname = attr.name

    @hide()

  userMessage: (msg) ->
    @addToHistory(( atom.config.get 'atox.chatColor' ), ( atom.config.get 'atox.userName' ), msg.msg );

  update: (attr) ->
    @header.attr 'class', "aTox-chatbox-header-#{attr.online}"
    @name.text   attr.name
