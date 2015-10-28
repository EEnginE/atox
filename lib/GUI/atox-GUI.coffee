Chatpanel     = require './atox-chatpanel'
GitHubLogin   = require './atox-GitHubLogin'
CollabSelect  = require './atox-collabSelect'
TermSelect    = require './atox-termSelect'
Message       = require './atox-message'
PasswdPrompt  = require './atox-passwd'

path          = require 'path'

{View, $, $$} = require 'atom-space-pen-views'

class TempChatHelper
  constructor: (aTox) ->
    @aTox = aTox
    @userHistory       = []
    @currentHistoryPos = 0

  genAndAddMSG: (params) ->
    return if params.msg is ''
    msg = "<p><span style='font-weight:bold;color:#{params.color};margin-left:5px;margin-top:5px'>#{params.name}: </span><span style='cursor:text;-webkit-user-select:text;'>#{params.msg}</span></p>"

    @aTox.gui.chatpanel.addMessage {msg: msg, cID: -1}

  sendMSG: (msg) ->
    @genAndAddMSG {
      msg:   msg
      name:  (atom.config.get 'aTox.userName') # TODO Use GitHub name
      color: "rgba( #{(atom.config.get 'aTox.chatColor').red}, #{(atom.config.get 'aTox.chatColor').green}, #{(atom.config.get 'aTox.chatColor').blue}, 1 )"
    }

    @userHistory.push msg
    @currentHistoryPos = @userHistory.length

    @aTox.term.process {cmd: msg, cID: @cID} if msg[0] is '/'

  getPreviousEntry: ->
    return '' if @userHistory.length is 0
    return @userHistory[@currentHistoryPos] if @currentHistoryPos is 0
    @currentHistoryPos--
    return @userHistory[@currentHistoryPos]

  getNextEntry: ->
    return '' if @currentHistoryPos is (@userHistory.length - 1) or @userHistory.length is 0
    @currentHistoryPos++
    return @userHistory[@currentHistoryPos]


module.exports =
class GUI
  constructor: (params) ->
    @aTox   = params.aTox
    params.state = {} unless params.state? # Prevents 'read from undefined' error

    @chatpanel     = new Chatpanel     {'aTox': @aTox, 'state': params.state.chatpanel}
    @chatpanel.addChat {cID: -1, img: 'none', group: false, parent: new TempChatHelper @aTox} # Terminal chat

    @GitHubLogin   = new GitHubLogin   {'aTox': @aTox}
    @collabSelect  = new CollabSelect  {'aTox': @aTox}
    @termSelect    = new TermSelect    {'aTox': @aTox}
    @pwPrompt      = new PasswdPrompt  {'aTox': @aTox}

    @chats = [] # Contains EVERY chat

    atom.config.observe 'aTox.userAvatar',  (newValue) => @correctPath         newValue

  correctPath: (pathArg) ->
    pathArg = path.normalize(pathArg)
    pathArg = pathArg.replace(/\\/g, '/')
    atom.config.set 'aTox.userAvatar', pathArg

  setUserOnlineStatus: (params) ->
    @chatpanel.statusSelector.setStatus params

  quickChat: -> @chatpanel.quickFocus()

  deactivate: ->
    for i in [@chatpanel, @GitHubLogin, @collabSelect, @termSelect, @pwPrompt]
      i.deactivate()

  serialize: ->
    state = {}
    state.chatpanel = @chatpanel.serialize()

    return state
