{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
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
        @div class: 'aTox-chatpanel-groupchat-ulist', outlet: 'ulist', =>
          @div class: 'aTox-chatpanel-groupchat-ulist-border ui-resizable-handle ui-resizable-w', outlet: 'lborder'
        @div class: 'aTox-chatpanel-chats native-key-bindings', tabindex: '-1', outlet: 'chats'
      @div class: 'aTox-chatpanel-input', outlet: 'input', =>
        @div class: 'aTox-chatpanel-input-status-con', outlet: 'status'
        @button class: 'btn aTox-chatpanel-btn', outlet: 'btn', "Send"
        @subview 'inputField', new TextEditorView(mini: true, placeholderText: 'Type to write something.')

  initialize: (params) ->
    @scrollPos   = []
    @chatClasses = []

    @aTox  = params.aTox

    atom.workspace.addBottomPanel {item: @element}
    @input.on 'keydown', (e) =>
      if @hbox.css('display') is 'none'
        @toggleHistory()
      if e.keyCode is 13
        e.preventDefault()
        id = @coverview.find('.selected').attr('cID') #get cID of selected chat
        @chatClasses[parseInt id].sendMSG @inputField.getText()
        @inputField.setText ''
      else if e.keyCode is 27
        @toggleHistory()
    @btn.click =>
      id = @coverview.find('.selected').attr('cID') #get cID of selected chat
      @chatClasses[parseInt id].sendMSG @inputField.getText()
      @inputField.setText ''

    jQuery(@hbox).resizable
      handles: {n: @rborder}
      resize: (event, ui) =>
        id = @coverview.find('.selected').attr('cID') #get cID of selected chat
        @scrollBot(id)
    jQuery(@ulist).resizable {handles: {w: @lborder}}
    @isOn = true

    @statusSelector = new StatusSelector {aTox: @aTox, win: 'panel'}
    @statusSelector.appendTo @status

  addMessage: (params) ->
    return if params.msg is ''

    isBot = false
    if @chats.prop("scrollHeight") - @chats.prop("offsetHeight") is @chats.scrollTop()
      isBot = true

    @chats.find("[cID='#{params.cID}']").append params.msg

    if parseInt(@coverview.find('.selected').attr('cID')) is params.cID
      if isBot or params.tid is -1
        @scrollBot(params.cID)
    else
      @coverview.find("[cID='#{params.cID}']").addClass 'status-modified'

  addChat: (params) ->
    return unless params.cID?

    @chatClasses[params.cID] = params.parent

    if params.group? and params.group is true
      aclass = 'groupchat'
    else
      aclass = ''

    @coverview.append $$ -> @li  class: "aTox-chatpanel-chat-status #{aclass}", cID: "#{params.cID}"
    @chats.append     $$ -> @div class: "aTox-chatpanel-chat #{aclass}",        cID: "#{params.cID}"

    if params.group? and params.group is true
      @ulist.append $$ -> @div class: "aTox-chatpanel-groupchat-ulist-con groupchat", cID: "#{params.cID}"

    @coverview.find("[cID='" + params.cID + "']").click => @selectChat(params.cID)
    @coverview.find("[cID='" + params.cID + "']").addClass('icon icon-octoface')                  if params.cID < 0
    @coverview.find("[cID='" + params.cID + "']").css({'background-image': "url(#{params.img})"}) unless params.img is 'none'
    @selectChat(params.cID)

  removeChat: (params) ->
    @coverview.find("[cID='" + params.cID + "']").remove()
    if @chats.find("[cID='" + params.cID + "']").hasClass('groupchat')
      @ulist.find("[cID='" + params.cID + "']").remove()
    @chats.find("[cID='#{params.cID}']").remove()

  update: (cID) ->
    if @chatClasses[cID].img() != 'none'
      @coverview.find("[cID='" + cID + "']").css({'background-image': "url(#{@chatClasses[cID].img()})"})
    else if atom.config.get('aTox.userAvatar') != 'none'
      # TODO add placeholder avatar
      @coverview.find("[cID='" + cID + "']").css({'background-image': "url(#{atom.config.get 'aTox.userAvatar'})"})

    # TODO update GC peer list (params.peerlist)

  selectChat: (cID) ->
    id = @coverview.find('.selected').attr('cID') #get cID of selected chat
    @scrollPos[id] = @chats.scrollTop()
    if @chats.prop("scrollHeight") - @chats.prop("offsetHeight") is @chats.scrollTop() #isBot?
      @scrollPos[id] = -1
    @coverview.find('.selected').removeClass('selected')
    @coverview.find("[cID='" + cID + "']").addClass('selected')
    @ulist.find(".aTox-chatpanel-groupchat-ulist-con").css({display: 'none'})
    @chats.find(".aTox-chatpanel-chat").css({display: 'none'})
    @ulist.find("[cID='" + cID + "']").css({display: 'block'})
    @chats.find("[cID='" + cID + "']").css({display: 'block'})
    if @chats.find("[cID='" + cID + "']").hasClass('groupchat')
      @ulist.css({display: 'block'})
    else
      @ulist.css({display: 'none'})
    if @scrollPos[cID] is -1
      @scrollBot(cID)
    else
      @chats.scrollTop(@scrollPos[cID])
    @coverview.find("[cID='#{cID}']").removeClass 'status-modified'

  addUser: (params) ->
    #Call only if groupchat
    if @chats.find("[cID='" + params.cID + "']").hasClass('groupchat') is false
      return
    @ulist.find("[cID='#{params.cID}']").append "<p style='font-weight:bold;color:#{params.color}'>#{params.name}</p>"


  scrollBot: (cID) -> #Must be fixed
    history = @chats.find("[cID='" + cID + "']")
    @chats.scrollTop(history.prop("scrollHeight"))

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
      id = @coverview.find('.selected').attr('cID') #get cID of selected chat
      @scrollBot(id)

  getColor: ->
    "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"
