{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui'


class ChatList extends View
  @content: (params) ->
    @div id: "aTox-chatbox-#{params.id}-chatlist", class: "aTox-chatbox-chatlist"

  initialize: (params) ->
    @event = params.event
    for user in params.users
      @addUser(user)

  addUser: (user) -> #TODO: Change this to have the color also be synced with the chatpanel
    jQuery( @element ).append "<p style='font-weight:bold;margin-left:3px;color:rgba(#{@randomNumber(255)}, #{@randomNumber(255)}, #{@randomNumber(255)}, 1)'>#{user}</p>"
    @paragraph = jQuery( @element ).find( "p:contains('#{user}')" )
    @paragraph.click =>
      @event.emit "aTox.new-contact", {name: "#{user}", online: 'offline'} #TODO: Get the real status of the user
    @paragraph.hover =>
      console.log "Hovered"



  randomNumber:(max, min=0) ->
    Math.floor(Math.random() * (max - min) + min)



module.exports =
class ChatBox extends View
  @content: (params) ->
    ID = "aTox-chatbox-#{params.id}"

    @div id: "#{ID}", class: 'aTox-chatbox', =>
      @div id: "#{ID}-header",      class: "aTox-chatbox-header-offline", outlet: 'header', =>
        @h1 outlet: 'name'
      @div id: "#{ID}-chathistory", class: "aTox-chatbox-chathistory",    outlet: 'chathistory'
      @div id: "#{ID}-textfield",   class: 'aTox-chatbox-textfield',      outlet: 'textfield',  =>
        @subview "inputfield", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  addToHistory: (color, user, message) ->
    @chathistory.append "<p><span style='font-weight:bold;color:rgba(#{color.red},#{color.green},#{color.blue},#{color.alpha});margin-left:5px;margin-top:5px'>#{user}: </span><span style=cursor:text;-webkit-user-select: text>#{message}</span></p>"
    jQuery( @chathistory ).scrollTop(jQuery( @chathistory )[0].scrollHeight);

  initialize: (params) ->
    atom.views.getView atom.workspace
      .appendChild @element

    @id    = params.id
    @event = params.event

    jQuery( @element   ).draggable { handle: @header }
    jQuery( @textfield ).keydown( (event) =>
      if event.which is 13 and @inputfield.getText() != ""
        params.event.emit "user-write-#{params.id}", { msg: @inputfield.getText() }
        @inputfield.setText("");
      else if event.which is 27
        params.event.emit "chat-#{params.id}-visibility", 'hide'
    )
    @chatname = params.name


    if params.online is 'group'
      @chatList = new ChatList {id: params.id, event: params.event, users: ["Taiterio", "Mensinda", "Arvius"]} #Handle this somewhere else and get a real list of users
      width = jQuery(@element).css ('width')
      width = parseInt(width)
      width += width * 0.25
      jQuery(@element).css ({ width: "#{width}px" })
      jQuery(@textfield).css ({ width: jQuery(@header).css('width')})
      @chatList.appendTo @element


    @hide()

  userMessage: (msg) ->
    @addToHistory(( atom.config.get 'atox.chatColor' ), ( atom.config.get 'atox.userName' ), msg.msg );

  update: (params) ->
    @online = params.online
    @header.attr 'class', "aTox-chatbox-header-#{params.online}"
    @name.text   params.name
