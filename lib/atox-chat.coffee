ChatBox     = require './GUI/atox-chatbox'
ContactView = require './GUI/atox-contactView'

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

    @userHistory       = []
    @currentHistoryPos = 0

  processMsg: (params) ->
    return if params.msg is ''

    # Handle URL's
    nstr = ['http://', 'https://', 'ftp://']
    tmsg = params.msg.split(' ')
    for i in [0..(tmsg.length - 1)]
      for n in nstr
        if tmsg[i].indexOf(n) > -1
          tmsg[i] = '<a href="' + tmsg[i] + '">' + tmsg[i] + '</a>'
    params.msg = tmsg.join(' ')

    msg = "<p><span style='font-weight:bold;color:#{params.color};margin-left:5px;margin-top:5px'>#{params.name}: </span><span style='cursor:text;-webkit-user-select:text;'>#{params.msg}</span></p>"

    @chatBox.addMessage msg
    @aTox.gui.chatpanel.addMessage {msg: msg, cID: @cID}

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
    return @userHistory[@currentHistoryPos] if @currentHistoryPos is 0
    @currentHistoryPos--
    return @userHistory[@currentHistoryPos]

  getNextEntry: ->
    return '' if @currentHistoryPos is (@userHistory.length - 1)
    @currentHistoryPos++
    return @userHistory[@currentHistoryPos]

  update: (what) ->
    @chatBox.update     what
    @contactView.update what

    @aTox.gui.chatpanel.update @cID

  sendMSG: (msg) ->
    return if msg is ''
    @processMsg {
      msg:   msg
      name:  (atom.config.get 'aTox.userName') # TODO Use GitHub name
      color: "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"
    }

    @userHistory.push msg
    @currentHistoryPos = @userHistory.length

    if msg[0] is '/' and msg[1] is '/'
      @parent.sendMSG msg.slice(1, msg.length);
    else if msg[0] is '/'
      @aTox.term.process {cmd: msg, cID: @cID}
    else
      @parent.sendMSG msg
