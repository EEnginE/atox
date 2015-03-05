{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery   = require 'jquery'
PeerList = require './atox-peerList'
require 'jquery-ui'

module.exports =
class ChatBox extends View
  @content: (params) ->
    ID = "aTox-chatbox-#{params.cid}"

    @div id: "#{ID}", class: 'aTox-chatbox', =>
      @div id: "#{ID}-header",      class: "aTox-chatbox-header-offline", outlet: 'header', =>
        @h1 outlet: 'name'
      @div id: "#{ID}-chathistory", class: "aTox-chatbox-chathistory native-key-bindings", tabindex: '-1', outlet: 'chathistory'
      @div id: "#{ID}-textfield",   class: 'aTox-chatbox-textfield', outlet: 'textfield',  =>
        @subview "inputField", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  initialize: (params) ->
    atom.views.getView atom.workspace
      .appendChild @element

    @cid   = params.cid
    @event = params.event

    @event.on "aTox.add-message", (msg) => @addMessage msg

    jQuery( @element   ).draggable { handle: @header }
    jQuery( @textfield ).keydown( (event) =>
      if event.which is 13 and @inputField.getText() != ""
        @event.emit "aTox.add-message", {
          cid:   @cid
          tid:   -1
          color: @getColor()
          name:  (atom.config.get 'aTox.userName')
          msg:   @inputField.getText()
        }
        @inputField.setText("");
      else if event.which is 27
        @event.emit "chat-visibility", { cid: @cid, what: 'hide' }
    )
    @chatname = params.name

    if params.online is 'group'
      @chatList = new PeerList {cid: params.cid, event: params.event}

      width = jQuery(@element).css ('width')
      width = parseInt(width)
      width += width * 0.25
      jQuery(@element).css ({ width: "#{width}px" })
      jQuery(@textfield).css ({ width: jQuery(@header).css('width')})
      @chatList.appendTo @element


    @hide()

  addMessage: (params) ->
    return unless params.cid is @cid
    return if params.msg is ''
    @chathistory.append "<p><span style='font-weight:bold;color:#{params.color};margin-left:5px;margin-top:5px'>#{params.name}: </span><span style='cursor:text;-webkit-user-select:text;'>#{params.msg}</p>"
    jQuery( @chathistory ).scrollTop(jQuery( @chathistory )[0].scrollHeight);

  update: (params) ->
    @online = params.online
    @header.attr 'class', "aTox-chatbox-header-#{params.online}"
    @name.text   params.name
    @chatList.setList params.peerlist if params.online is 'group'

  getColor: ->
    "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"
