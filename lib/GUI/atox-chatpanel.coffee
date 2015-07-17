{View, TextEditorView, $, $$} = require 'atom-space-pen-views'
PeerList = require './atox-peerList'
jQuery    = require 'jquery'
require 'jquery-ui'

StatusSelector = require './atox-statusSelector'

# coffeelint: disable=max_line_length

module.exports =
class Chatpanel extends View
  @content: (params) ->
    @div        class: 'aTox-chatpanel', =>
      @div      class: 'aTox-chatpanel-history-box',                                               outlet: 'hbox', =>
        @div    class: 'icon icon-gear aTox-chatpanel-settings'
        @div    class: 'aTox-chatpanel-border ui-resizable-handle ui-resizable-n',                 outlet: 'rborder'
        @ul     class: 'aTox-chatpanel-chat-overview',                                             outlet: 'coverview'
        @div    class: 'aTox-chatpanel-groupchat-ulist',                                           outlet: 'ulist', =>
          @div  class: 'aTox-chatpanel-groupchat-ulist-border ui-resizable-handle ui-resizable-w', outlet: 'lborder'
        @div    class: 'aTox-chatpanel-chats native-key-bindings', tabindex: '-1',                 outlet: 'chats'
      @div      class: 'aTox-chatpanel-input',                                                     outlet: 'input', =>
        @div    class: 'aTox-chatpanel-input-status-con',                                          outlet: 'status'
        @subview 'inputField', new TextEditorView(mini: true, placeholderText: 'Type to write something.')
        @button class: 'btn aTox-chatpanel-btn',                                                   outlet: 'btn', "Send"


  initialize: (params) ->
    @scrollPos   = []
    @chatClasses = []
    @peerViews   = []

    @aTox  = params.aTox

    @panel = atom.workspace.addBottomPanel {item: @element}
    @input.on 'keydown', (e) =>
      @showHistory() unless @historyRendered or e.which is 27

      id = parseInt @coverview.find('.selected').attr('cID') #get cID of selected chat
      switch e.which
        when 13
          @chatClasses[id].sendMSG @inputField.getText()
          @inputField.setText ''
          @scrollBot @coverview.find('.selected').attr('cID')
        when 38 then @inputField.setText @chatClasses[id].getPreviousEntry()
        when 40 then @inputField.setText @chatClasses[id].getNextEntry()
        when 27 then @toggleHistory()

    @btn.click =>
      id = @coverview.find('.selected').attr('cID') #get cID of selected chat
      @chatClasses[parseInt id].sendMSG @inputField.getText()
      @inputField.setText ''

    jQuery(@hbox).resizable
      handles: {n: @rborder}
      start: (event, ui) =>
        @resizePos = @chats.scrollTop()
      resize: (event, ui) =>
        @chats.scrollTop(@resizePos)
    jQuery(@ulist).resizable {handles: {w: @lborder}}

    @statusSelector = new StatusSelector {aTox: @aTox, win: 'panel'}
    @statusSelector.appendTo @status

    params.state = {'height': '70px', 'showHistory': true} unless params.state?

    @hbox.css 'height', params.state.height
    @historyRendered = !params.state.showHistory
    @toggleHistory()

  deactivate: -> @panel.destroy()

  getSelectedChatCID: ->
    return parseInt @coverview.find('.selected').attr('cID')

  addMessage: (params) ->
    return if params.msg is ''
    cID = "#{params.cID}"

    isBot = false
    if @chats.prop("scrollHeight") - @chats.prop("offsetHeight") is @chats.scrollTop()
      isBot = true

    @chats.find("[cID='#{params.cID}']").append params.msg

    if "#{@getSelectedChatCID()}" is cID
      if isBot or params.tid is -1
        @scrollBot(cID)
    else
      if isBot
        @scrollPos[cID] = -1
      @coverview.find("[cID='#{cID}']").addClass 'status-modified'

  addChat: (params) ->
    return unless params.cID?

    @chatClasses[params.cID] = params.parent

    if params.group? and params.group is true
      aclass = 'groupchat'
      perrList = new PeerList {"cID": params.cID}
      @ulist.append perrList # perrList has attr cID
      @peerViews[params.cID] = perrList
    else
      aclass = ''

    @coverview.append $$ -> @li  class: "aTox-chatpanel-chat-status #{aclass}", cID: "#{params.cID}"
    @chats.append     $$ -> @div class: "aTox-chatpanel-chat #{aclass}",        cID: "#{params.cID}"

    @coverview.find("[cID='#{params.cID}']").click => @selectChat(params.cID)
    @coverview.find("[cID='#{params.cID}']").addClass('icon icon-octoface')                  if params.cID < 0
    @coverview.find("[cID='#{params.cID}']").css({'background-image': "url(#{params.img})"}) unless params.img is 'none'
    @selectChat(params.cID)

  removeChat: (params) ->
    @coverview.find("[cID='#{params.cID}']").remove()
    if @chats.find("[cID='#{params.cID}']").hasClass('groupchat')
      @ulist.find("[cID='#{params.cID}']").remove()
    @chats.find("[cID='#{params.cID}']").remove()

  update: (params) ->
    cID = "#{params.cID}"
    if @chatClasses[cID].img() != 'none'
      @coverview.find("[cID='#{cID}']").css({'background-image': "url(#{@chatClasses[cID].img()})"})
    else if atom.config.get('aTox.userAvatar') != 'none'
      # TODO add placeholder avatar
      @coverview.find("[cID='#{cID}']").css({'background-image': "url(#{atom.config.get 'aTox.userAvatar'})"})

    @peerViews[cID].setList @chatClasses[cID].peerlist() if params.peers? and params.peers

  selectChat: (cID) ->
    cID = "#{cID}"
    id = @coverview.find('.selected').attr('cID') #get cID of selected chat
    if id?
      if @chats.children().length > 0
        @scrollPos[id] = @chats.scrollTop() #@chats.prop("scrollHeight")
      if @chats.prop("scrollHeight") - @chats.prop("offsetHeight") is @chats.scrollTop() #isBot?
        @scrollPos[id] = -1
    @coverview.find('.selected').removeClass('selected')
    @coverview.find("[cID='#{cID}']").addClass('selected')
    @ulist.find(".aTox-PeerList").css({display: 'none'})
    @chats.find(".aTox-chatpanel-chat").css({display: 'none'})
    @ulist.find("[cID='#{cID}']").css({display: 'block'})
    @chats.find("[cID='#{cID}']").css({display: 'block'})
    if @chats.find("[cID='#{cID}']").hasClass('groupchat')
      @ulist.css({display: 'block'})
    else
      @ulist.css({display: 'none'})
    if @scrollPos[cID] is -1
      @scrollBot(cID)
    else if @scrollPos[cID]?
      @chats.scrollTop(parseInt @scrollPos[cID])
    @coverview.find("[cID='#{cID}']").removeClass 'status-modified'

  scrollBot: (cID) -> #Must be fixed
    history = @chats.find("[cID='#{cID}']")
    @chats.scrollTop(history.prop("scrollHeight"))

  showHistory: ->
    @historyRendered = true
    @hbox.show()

  hideHistory: ->
    @historyRendered = false
    @hbox.hide()

  toggleHistory: ->
    if @historyRendered
      @hideHistory()
    else
      @showHistory()

    id = @coverview.find('.selected').attr('cID') #get cID of selected chat
    @scrollBot(id)

  getColor: ->
    "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"

  serialize: ->
    state = {
      'height':      @hbox.css 'height'
      'showHistory': @historyRendered
    }
