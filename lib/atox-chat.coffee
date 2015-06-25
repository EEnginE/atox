ChatBox     = require './GUI/atox-chatbox'
ContactView = require './GUI/atox-contactView'
Message     = require './GUI/atox-message'

module.exports =
class Chat
  constructor: (params) ->
    @aTox   = params.aTox
    @parent = params.parent
    @group  = params.group

    @cID    = @aTox.getCID()

    @isSelected = false

    @chatBox = new ChatBox {
      cID:    @cID
      parent: this
      group:  @group
    }

    @contactView = new ContactView {
      cb: =>
        if @isSelected is true
          @closeChat()
        else
          @openChat()
      parent: this
    }

    @aTox.gui.chatpanel.addChat {
      group:  @group
      cID:    @cID
      parent: this
    }

    @aTox.gui.chats[@cID] = this
    @aTox.gui.mainWin.addContact @contactView

    @update 'img'
    @update 'name'

    @msgViews          = []
    @userHistory       = []
    @currentHistoryPos = 0

  genAndAddMSG: (params) -> @addMSG new Message params unless params.msg is ''

  addMSG: (msg) ->
    @chatBox.addMessage msg
    @aTox.gui.chatpanel.addMessage {'msg': msg, 'cID': @cID}

  name:     -> return @parent.name
  online:   -> return @parent.online
  status:   -> return @parent.status
  peerlist: -> return @parent.peerlist
  img:      -> return @parent.img
  selected: -> return @isSelected is true

  closeChat: ->
    @isSelected = false
    @chatBox.hide()
    @update 'select'
  openChat:  ->
    @isSelected = true
    @chatBox.show()
    @update 'select'

  getPreviousEntry: ->
    return '' if @userHistory.length is 0
    return @userHistory[@currentHistoryPos] if @currentHistoryPos is 0
    @currentHistoryPos--
    return @userHistory[@currentHistoryPos]

  getNextEntry: ->
    return '' if @currentHistoryPos is (@userHistory.length - 1) or @userHistory.length is 0
    @currentHistoryPos++
    return @userHistory[@currentHistoryPos]

  update: (what) ->
    @chatBox.update     what
    @contactView.update what
    if what is 'peers'
      @aTox.gui.chatpanel.update {cID: @cID, peers: true}
    else
      @aTox.gui.chatpanel.update {cID: @cID}

  markAsRead: (id) -> @msgViews[id].markAsRead() if @msgViews[id]?

  sendMSGcallback: (msgId, view) ->
    if msgId < 0 or not msgId?
      view.markAsError()
      @aTox.term.warn {"title": "Failed to send message"}

    @msgViews[msgId] = view

  sendMSG: (msg) ->
    return if msg is ''

    @userHistory.push msg
    @currentHistoryPos = @userHistory.length

    msgView = new Message {
      "msg":   msg
      "name":  atom.config.get 'aTox.userName'
      "color": "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"
    }

    @addMSG msgView

    if msg[0] is '/' and msg[1] is '/'
      msgView.markAsWaiting()
      @parent.sendMSG msg.slice(1, msg.length), (id) => @sendMSGcallback id, msgView
    else if msg[0] is '/'
      @aTox.term.process {cmd: msg, cID: @cID}
    else
      msgView.markAsWaiting()
      @parent.sendMSG msg, (id) => @sendMSGcallback id, msgView
