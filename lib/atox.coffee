path          = require 'path'
{$}           = require 'atom-space-pen-views'
GUI           = require './GUI/atox-GUI'
Terminal      = require './atox-terminal'
ToxWorker     = require './atox-toxWorker'
Github        = require './atox-github'
CollabManager = require './atox-collabManager'
aToxManager   = require './atox-aToxManager'

{CompositeDisposable} = require 'atom'

module.exports =
  config:
    userAvatar:
      title: "Avatar"
      description: "A full path to your Avatar"
      type: "string"
      default: "none"
    userName:
      title: "Username"
      description: "Your username"
      type: "string"
      default: "User"
    chatColor:
      title: "Your chat's color"
      type:  "color"
      default: "#09c709"
    debugNotifications:
      title: "Debug Notifications"
      description: "When activated displays debug notifications"
      type:  "boolean"
      default: false
    githubToken:
      title: "Github Access Token"
      description: "Github access token"
      type: "string"
      default: "none"


  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:toggle',    => @gui.mainWin.toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:history',   => @gui.chatpanel.toggleHistory()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:collab',    => @gui.collabSelect.show()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:quickChat', => @gui.openQuickChat()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:terminal',  => @gui.termSelect.show()

    @term    = new Terminal      {'aTox': this}
    @TOX     = new ToxWorker     {'aTox': this, 'dll': "#{__dirname}\\..\\bin\\libtox.dll"}
    @github  = new Github
    @collab  = new CollabManager {'aTox': this}
    @manager = new aToxManager   {'aTox': this}
    @gui     = new GUI           {'aTox': this, 'state': state.gui}

    @currCID     = 0
    @hasOpenChat = false

    atom.config.observe 'aTox.githubToken', (newValue)  => @github.setToken newValue
    @TOX.startup()

  deactivate: ->
    @subscriptions.dispose()

    @TOX.deactivate()
    @gui.deactivate()

  getCID: -> return @currCID++

  serialize: ->
    state     = {}
    state.gui = @gui.serialize()

    return state
