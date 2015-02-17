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
      @event.emit "aTox.new-contact", {name: "#{user}", online: 'offline'} #TODO: Get the real status of the user, check if User is already added and open the chat window directly

    @paragraph.hover =>
      console.log "Hovered" #TODO: Add functionality: Show additional information: Recent Projects, Contributions to current project, has push rights. Unnecessary: toxID, status, image



  randomNumber:(max, min=0) ->
    Math.floor(Math.random() * (max - min) + min)



module.exports =
class ChatBox extends View
  @content: (params) ->
    ID = "aTox-chatbox-#{params.cid}"

    @div id: "#{ID}", class: 'aTox-chatbox', =>
      @div id: "#{ID}-header",      class: "aTox-chatbox-header-offline", outlet: 'header', =>
        @h1 outlet: 'name'
      @div id: "#{ID}-chathistory", class: "aTox-chatbox-chathistory",    outlet: 'chathistory'
      @div id: "#{ID}-textfield",   class: 'aTox-chatbox-textfield',      outlet: 'textfield',  =>
        @subview "inputField", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  initialize: (params) ->
    atom.views.getView atom.workspace
      .appendChild @element

    @id    = params.cid
    @event = params.event

    jQuery( @element   ).draggable { handle: @header }
    jQuery( @textfield ).keydown( (event) =>
      if event.which is 13 and @inputfield.getText() != ""
        attr.event.emit "aTox-add-message#{attr.cid}", {
          cid:   @cid
          color: (atom.config.get 'atox.chatColor')
          name:  (atom.config.get 'atox.userName')
          msg:   @inputField.getText()
        }
        @inputfield.setText("");
      else if event.which is 27
        params.event.emit "chat-#{params.cid}-visibility", 'hide'
    )
    @chatname = params.name

    if params.online is 'group'
      @chatList = new ChatList {cid: params.cid, event: params.event, users: ["Taiterio", "Mensinda", "Arvius"]} #Handle this somewhere else and get a real list of users

      width = jQuery(@element).css ('width')
      width = parseInt(width)
      width += width * 0.25
      jQuery(@element).css ({ width: "#{width}px" })
      jQuery(@textfield).css ({ width: jQuery(@header).css('width')})
      @chatList.appendTo @element


    @hide()

  addMessage: (attr) ->
    return if attr.msg is ''
    @chathistory.append "<p><span style='font-weight:bold;color:rgba(#{attr.color.red},#{attr.color.green},#{attr.color.blue},#{attr.color.alpha});margin-left:5px;margin-top:5px'>#{attr.name}: </span><span style=cursor:text;-webkit-user-select: text>#{attr.msg}</p>"
    jQuery( @chathistory ).scrollTop(jQuery( @chathistory )[0].scrollHeight);

  update: (params) ->
    @online = params.online
    @header.attr 'class', "aTox-chatbox-header-#{params.online}"
    @name.text   params.name
