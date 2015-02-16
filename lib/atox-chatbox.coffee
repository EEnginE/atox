{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'


class ChatList extends View
  @content: (id, users) ->
    @div id: "aTox-chatbox-#{id}-chatlist", class: "aTox-chatbox-chatlist"

  initialize: (id, users) ->
    for user in users
      @addUser(user)

  addUser: (user) -> #Change this to have the color also be synced with the chatpanel
    jQuery( @element ).append "<p><span style='font-weight:bold;margin-left:3px;color:rgba(#{@randomNumber(255)}, #{@randomNumber(255)}, #{@randomNumber(255)}, 1)'>#{user}</span></p>"

  randomNumber:(max, min=0) ->
    Math.floor(Math.random() * (max - min) + min)



module.exports =
class ChatBox extends View
  @content: (attr) ->
    ID = "aTox-chatbox-#{attr.id}"

    @div id: "#{ID}", class: 'aTox-chatbox', =>
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


    if attr.online is 'group'
      @chatList = new ChatList attr.id, ["Taiterio", "Mensinda", "Arvius"] #Handle this somewhere else and get a real list of users
      width = jQuery(@element).css ('width')
      width = parseInt(width)
      width += width * 0.25
      jQuery(@element).css ({ width: "#{width}px" })
      jQuery(@textfield).css ({ width: jQuery(@header).css('width')})
      @chatList.appendTo @element


    @hide()

  userMessage: (msg) ->
    @addToHistory(( atom.config.get 'atox.chatColor' ), ( atom.config.get 'atox.userName' ), msg.msg );

  update: (attr) ->
    @online = attr.online
    @header.attr 'class', "aTox-chatbox-header-#{attr.online}"
    @name.text   attr.name
