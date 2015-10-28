path          = require 'path'
{$}           = require 'atom-space-pen-views'
GlobalSave    = require './atox-globalSave'
GUI           = require './GUI/atox-GUI'
Terminal      = require './atox-terminal'
ToxWorker     = require './atox-toxWorker'
Github        = require './atox-github'
CollabManager = require './atox-collabManager'
aToxManager   = require './atox-aToxManager'

{CompositeDisposable} = require 'atom'

# coffeelint: disable=max_line_length

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
    useToxSave:
      title: "Save and load the tox state"
      description: "When activated a permament TOX ID will be used. Disable only for debugging"
      type:  "boolean"
      default: true
    showGithubLogin:
      title: "Show Github login window"
      description: "Automatically ask for Github login data every startup when the token is invalid"
      type:  "boolean"
      default: true


  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:toggle',    => @gui.mainWin.toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:history',   => @gui.chatpanel.toggleHistory()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:collab',    => @gui.collabSelect.requestOpen()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:quickChat', => @gui.quickChat()
    @subscriptions.add atom.commands.add 'atom-workspace', 'aTox:terminal',  => @gui.termSelect.show()

    @currCID     = 0
    @hasOpenChat = false

    @gSave   = new GlobalSave    {'aTox': this, 'name': 'aTox.cson'}
    @term    = new Terminal      {'aTox': this}
    @TOX     = new ToxWorker     {'aTox': this, 'dll': "#{__dirname}\\..\\bin\\libtox.dll"}
    @github  = new Github
    @collab  = new CollabManager {'aTox': this}
    @manager = new aToxManager   {'aTox': this}

    $ =>
      @gui   = new GUI           {'aTox': this, 'state': state.gui}

      @gSave.onInitDone => @TOX.startup()

  deactivate: ->
    @TOX.deactivate()
    @gSave.deactivate()
    @gui.deactivate()

    @subscriptions.dispose()

  getCID: -> return @currCID++

  serialize: ->
    state     = {}
    state.gui = @gui.serialize()

    return state
