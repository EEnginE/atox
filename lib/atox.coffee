path          = require 'path'
{$}           = require 'atom-space-pen-views'
GUI           = require './GUI/atox-GUI'
Terminal      = require './atox-terminal'
ToxWorker     = require './atox-toxWorker'
Github        = require './atox-github'
CollabManager = require './atox-collabManager'
AuthManager   = require './atox-authManager'

module.exports =
  config:
    showDefault:
      title: "Show on startup"
      description: "Automatically displays the main window on startup"
      type: "boolean"
      default: false
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
    mainWinTop:
      title: "Main Window Top"
      type: "string"
      default: "60%"
    mainWinLeft:
      title: "Main Window Left"
      type: "string"
      default: "80%"
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


  activate: ->
    atom.commands.add 'atom-workspace', 'aTox:toggle',    => @gui.mainWin.toggle()
    atom.commands.add 'atom-workspace', 'aTox:history',   => @gui.chatpanel.toggleHistory()
    atom.commands.add 'atom-workspace', 'aTox:collab',    => @gui.collabSelct.show()
    atom.commands.add 'atom-workspace', 'aTox:quickChat', => @gui.openQuickChat()

    @term          = new Terminal      {aTox: this}
    @TOX           = new ToxWorker     {aTox: this, dll: "#{__dirname}\\..\\bin\\libtox.dll", fConnectCB: => @onFirstConnect()}
    @github        = new Github
    @collab        = new CollabManager {aTox: this}
    @authManager   = new AuthManager   {aTox: this}

    @currCID = 0
    @hasOpenChat    = false

    atom.config.observe 'aTox.githubToken', (newValue)  => @github.setToken newValue

    $ =>
      @gui = new GUI {aTox: this}
      @TOX.startup()

  onFirstConnect: -> @authManager.aToxAuth()

  getCID: -> return @currCID++
