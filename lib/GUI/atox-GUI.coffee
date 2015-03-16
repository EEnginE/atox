MainWindow    = require './atox-mainWin'
Notifications = require './atox-notifications'
Question      = require './atox-questions'
Chatpanel     = require './atox-chatpanel'
GitHubLogin   = require './atox-GitHubLogin'
QuickChat     = require './atox-quickChat'
CollabSelect  = require './atox-collabSelect'
TermSelect    = require './atox-termSelect'

{View, $, $$} = require 'atom-space-pen-views'

class TempChatHelper
  constructor: (aTox) ->
    @aTox = aTox
    @userHistory       = []
    @currentHistoryPos = 0

  processMsg: (params) ->
    return if params.msg is ''
    msg = "<p><span style='font-weight:bold;color:#{params.color};margin-left:5px;margin-top:5px'>#{params.name}: </span><span style='cursor:text;-webkit-user-select:text;'>#{params.msg}</span></p>"

    @aTox.gui.chatpanel.addMessage {msg: msg, cID: -1}

  sendMSG: (msg) ->
    @processMsg {
      msg:   msg
      name:  (atom.config.get 'aTox.userName') # TODO Use GitHub name
      color: "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"
    }

    @userHistory.push msg
    @currentHistoryPos = @userHistory.length

    @aTox.term.process {cmd: msg, cID: @cID} if msg[0] is '/'

  getPreviousEntry: ->
    return @userHistory[@currentHistoryPos] if @currentHistoryPos is 0
    @currentHistoryPos--
    return @userHistory[@currentHistoryPos]

  getNextEntry: ->
    return '' if @currentHistoryPos is (@userHistory.length - 1)
    @currentHistoryPos++
    return @userHistory[@currentHistoryPos]


module.exports =
class GUI
  constructor: (params) ->
    @aTox   = params.aTox

    @chatpanel     = new Chatpanel     {aTox: @aTox}
    @chatpanel.addChat {cID: -1, img: 'none', group: false, parent: new TempChatHelper @aTox} # Terminal chat

    @mainWin       = new MainWindow    {aTox: @aTox}
    @notifications = new Notifications {aTox: @aTox}
    @GitHubLogin   = new GitHubLogin   {aTox: @aTox}
    @quickChat     = new QuickChat     {aTox: @aTox}
    @collabSelect  = new CollabSelect  {aTox: @aTox}
    @termSelect    = new TermSelect    {aTox: @aTox}

    @chats = [] # Contains EVERY chat

    @mainWin.css 'top',  atom.config.get 'aTox.mainWinTop'
    @mainWin.css 'left', atom.config.get 'aTox.mainWinLeft'

    @mainWin.mouseup =>
      atom.config.set 'aTox.mainWinTop',  @mainWin.css 'top'
      atom.config.set 'aTox.mainWinLeft', @mainWin.css 'left'

    atom.config.observe 'aTox.mainWinTop',  (newValue) => @mainWin.css 'top',  newValue
    atom.config.observe 'aTox.mainWinLeft', (newValue) => @mainWin.css 'left', newValue
    atom.config.observe 'aTox.userAvatar',  (newValue) => @correctPath         newValue

    @mainWin.show() if atom.config.get 'aTox.showDefault'

    #@question      = new Question {name: "Test", question: "You there?", accept: "Ja", decline: "Nein", cb: this.callback}
    #@question.ask()

  correctPath: (pathArg) ->
    pathArg = path.normalize(pathArg)
    pathArg = pathArg.replace(/\\/g, '/')
    atom.config.set 'aTox.userAvatar', pathArg

  notify: (params) ->
    params.type = 'inf' unless params.type?

    @notifications.add params

  setUserOnlineStatus: (params) ->
    @mainWin.statusSelector.setStatus   params
    @chatpanel.statusSelector.setStatus params

  openQuickChat: -> @quickChat.show @chatpanel.getSelectedChatCID()
