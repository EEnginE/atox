path          = require 'path'
MainWindow    = require './GUI/atox-mainWin'
Notifications = require './GUI/atox-notifications'
Question      = require './GUI/atox-questions'
Chatpanel     = require './GUI/atox-chatpanel'
Contact       = require './atox-contact'
Terminal      = require './atox-terminal'
ToxWorker     = require './atox-toxWorker'
Github        = require './atox-github'
GithubAuth    = require './GUI/atox-githubAuth'

{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'

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
    atom.commands.add 'atom-workspace', 'aTox:toggle',  => @toggle()
    atom.commands.add 'atom-workspace', 'aTox:history', => @toggleHistory()

    @event         = new Emitter
    @mainWin       = new MainWindow    @event
    @notifications = new Notifications @event
    @terminal      = new Terminal      {event: @event}
    @TOX           = new ToxWorker     {dll: "#{__dirname}\\..\\bin\\libtox.dll", event: @event}
    @github        = new Github
    @githubauth    = new GithubAuth    {github: @github, event: @event}
    @question      = new Question      {name: "Test", question: "You there?", accept: "Ja", decline: "Nein"}
    @question.ask()
    @currCID = 0

    @mainWin.css 'top',  atom.config.get 'aTox.mainWinTop'
    @mainWin.css 'left', atom.config.get 'aTox.mainWinLeft'

    @mainWin.mouseup =>
      atom.config.set 'aTox.mainWinTop',  @mainWin.css 'top'
      atom.config.set 'aTox.mainWinLeft', @mainWin.css 'left'

    atom.config.observe 'aTox.mainWinTop',  (newValue) => @mainWin.css 'top',  newValue
    atom.config.observe 'aTox.mainWinLeft', (newValue) => @mainWin.css 'left', newValue
    atom.config.observe 'aTox.githubToken', (newValue) => @github.setToken     newValue
    atom.config.observe 'aTox.userAvatar',  (newValue) => @correctPath         newValue

    @internalContactId = 0
    @contactsArray     = []
    @contactsPubKey    = []

    @hasOpenChat    = false

    @event.on 'aTox.new-contact',       (data) => @addUserHelper           data
    @event.on 'aTox.select',            (data) => @contactSelected         data
    @event.on 'getChatID',              (data) => @getChatIDFromName       data
    @event.on 'getFriendIDFromPubKey',  (data) => @getFriendIDFromPubKey   data
    @event.on 'first-connect',                 => @githubauth.doIt()

    $ =>
      @chatpanel    = new Chatpanel {event: @event}
      @chatpanel.addChat { cid: -2, img: 'none', event: @event, group: false }

      @event.on 'Terminal', (data) =>
        @event.emit "aTox.add-message", {
          cid:   data.cid
          tid:   -2
          color: "rgba(255, 255, 255 ,1)"
          name:  "aTox"
          msg:   "<span style='font-style:italic;color:rgba(200, 200, 200 ,1)'>" + data.msg + "</span>"
        }
      @terminal.initialize()
      @TOX.startup()
      @mainWin.show() if atom.config.get 'aTox.showDefault'

  getChatIDFromName: (data) ->
    for i in @contactsArray
      if i.name == data.name
        @event.emit 'Terminal', {cid: data.cid, msg: "getChatIDFromName: #{i.cid} (#{data})"}
        return i.cid

    @event.emit 'Terminal', {cid: data.cid, msg: "getChatIDFromName: Not Found (#{data})"}
    return -1

  contactSelected: (data) ->
    if data.selected
      @event.emit 'notify', {
        type: 'inf'
        name: "Now chatting with #{data.name}"
        content: "Opening chat window"
        img: data.img
      }
    else
      @event.emit 'notify', {
        type: 'warn'
        name: "Stopped chatting with #{data.name}"
        content: "Closing chat window"
        img: data.img
      }

  addUserHelper: (params) ->
    @contactsArray.push new Contact {
      name:   params.name
      status: params.status
      online: params.online
      img:    atom.config.get 'aTox.userAvatar' #TODO: Add img to params
      event:  @event
      cid:    @currCID
      tid:    params.tid
      win:    @mainWin
      panel:  @chatpanel
      hidden: params.hidden
    }
    @currCID++
    @contactsPubKey.push { tid: params.tid, pubKey: params.pubKey }

  getFriendIDFromPubKey: (params) ->
    fid = -1
    for i in @contactsPubKey
      fid = i.tid if i.pubKey is params.pubKey

    params.cb fid

  correctPath: (pathArg) ->
    pathArg = path.normalize(pathArg)
    pathArg = pathArg.replace(/\\/g, '/')
    atom.config.set 'aTox.userAvatar', pathArg

  toggle: ->
    @mainWin.toggle()

  toggleHistory: ->
    @chatpanel.toggleHistory()
