{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
jQuery   = require 'jquery'
PeerList = require './atox-peerList'
require 'jquery-ui'

module.exports =
class ChatBox extends View
  @content: (params) ->
    @div class: 'aTox-chatbox', =>
      @div class: "aTox-chatbox-header-offline", outlet: 'header', =>
        @h1 outlet: 'name'
      @div class: "aTox-chatbox-chathistory native-key-bindings", tabindex: '-1', outlet: 'chathistory'
      @div class: 'aTox-chatbox-textfield', outlet: 'textfield',  =>
        @subview "inputField", new TextEditorView(mini: true, placeholderText: "Type here to write something.")

  initialize: (params) ->
    @cID    = params.cID
    @parent = params.parent

    atom.views.getView atom.workspace
      .appendChild @element

    jQuery( @element   ).draggable { handle: @header }
    jQuery( @textfield ).keydown (event) =>
      switch event.which
        when 13 then @parent.sendMSG @inputField.getText(); @inputField.setText ""
        when 38 then @inputField.setText @parent.getPreviousEntry()
        when 40 then @inputField.setText @parent.getNextEntry()
        when 27 then @parent.closeChat()

    if params.group? and params.group
      @chatList = new PeerList {cID: params.cID}

      width = jQuery(@element).css ('width')
      width = parseInt(width)
      width += width * 0.25
      jQuery(@element).css ({ width: "#{width}px" })
      jQuery(@textfield).css ({ width: jQuery(@header).css('width')})
      @chatList.appendTo @element

    @hide()

  addMessage: (msg) ->
    @chathistory.append msg
    @chathistory.scrollTop(@chathistory.prop('scrollHeight'));

  update: (what) ->
    switch what
      when 'name'   then @name.text @parent.name()
      when 'online' then @header.attr {class: "aTox-chatbox-header-#{@parent.online()}"}
      when 'peers'  then @chatList.setList @parent.peerlist()
