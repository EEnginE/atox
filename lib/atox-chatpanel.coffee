{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
{Emitter} = require 'event-kit'
jQuery    = require 'jquery'
require 'jquery-ui'

StatusSelector = require './atox-statusSelector'

module.exports =
class Chatpanel extends View
  @content: (params) ->
    @div class: 'aTox-chatpanel', =>
      @div class: 'aTox-chatpanel-history-box', outlet: 'hbox', =>
        @div class: 'icon icon-gear aTox-chatpanel-settings'
        @div class: 'aTox-chatpanel-border ui-resizable-handle ui-resizable-n', outlet: 'rborder'
        @ul class: 'aTox-chatpanel-chat-overview', outlet: 'coverview'
        @div class: 'aTox-chatpanel-chats native-key-bindings', tabindex: '-1', outlet: 'chats'
      @div class: 'aTox-chatpanel-input', outlet: 'input', =>
        @div class: 'aTox-chatpanel-input-status-con', outlet: 'status'
        @button class: 'btn aTox-chatpanel-btn', outlet: 'btn', "Send"
        @subview 'inputField', new TextEditorView(mini: true, placeholderText: 'Type to write something.')

  addMessage: (params) ->
    return if params.msg is ''
    @chats.find("[cid='#{params.cid}']").append "<p><span style='font-weight:bold;color:#{params.color}'>#{params.name}: </span>#{params.msg}</p>"
    @scrollBot(params.cid)

  addChat: (params) ->
    @coverview.append $$ ->
      @li class: 'aTox-chatpanel-chat-status', cid: "#{params.cid}"
    @chats.append $$ ->
      @div class: 'aTox-chatpanel-chat', cid: "#{params.cid}"
    @coverview.find("[cid='" + params.cid + "']").click =>
      @selectChat(params.cid)
    @coverview.find("[cid='" + params.cid + "']").css({'background-image': "url(#{params.img})"})
    @selectChat(params.cid)

  update: (params) ->
    if params.img != 'none'
      @coverview.find("[cid='" + params.cid + "']").css({'background-image': "url(#{params.img})"})
    else
      # TODO add placeholder avatar
      @coverview.find("[cid='" + params.cid + "']").css({'background-image': "url(#{atom.config.get 'atox.userAvatar'})"})

  selectChat: (cid) ->
    @coverview.find('.selected').removeClass('selected')
    @coverview.find("[cid='" + cid + "']").addClass('selected')
    @chats.find(".aTox-chatpanel-chat").css({display: 'none'})
    @chats.find("[cid='" + cid + "']").css({display: 'block'})
    @scrollBot(cid)

  initialize: (params) ->
    @event = params.event
    @event.on "aTox.add-message", (msg) => @addMessage msg

    atom.workspace.addBottomPanel {item: @element}
    @input.on 'keydown', (e) =>
      if e.keyCode is 13
        e.preventDefault()
        id = @coverview.find('.selected').attr('cid') #get cid of selected chat
        @event.emit "aTox.add-message", {
          cid:   parseInt id
          tid:   -1
          color: @getColor()
          name:  (atom.config.get 'atox.userName')
          msg:   @inputField.getText()
        }
        console.log "emit"
        @inputField.setText ''
        if @hbox.css('display') is 'none'
          @toggleHistory()
      else if e.keyCode is 27
        @hide()
    @btn.click =>
      id = @coverview.find('.selected').attr('cid') #get cid of selected chat
      @event.emit "aTox.add-message", {
        cid:   parseInt id
        tid:   -1
        color: @getColor()
        name:  (atom.config.get 'atox.userName')
        msg:   @inputField.getText()
      }
      @inputField.setText ''

    jQuery(@hbox).resizable
      handles: {n: @rborder}
      resize: (event, ui) =>
        id = @coverview.find('.selected').attr('cid') #get cid of selected chat
        @scrollBot(id)
    @isOn = true

    @statusSelector = new StatusSelector 'panel', @event
    @statusSelector.appendTo @status

  scrollBot: (cid) -> #Must be fixed
    history = @chats.find("[cid='" + cid + "']")
    @chats.scrollTop(history.prop("scrollHeight"));

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

  toggleHistory: ->
    jQuery(@hbox).toggle "blind", 1000, =>
      id = @coverview.find('.selected').attr('cid') #get cid of selected chat
      @scrollBot(id)

  getColor: ->
    "rgba( #{(atom.config.get 'atox.chatColor').red}, #{(atom.config.get 'atox.chatColor').green}, #{(atom.config.get 'atox.chatColor').blue}, 1 )"
