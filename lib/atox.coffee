MainWindow    = require './atox-mainWin'
Notifications = require './atox-notifications'
YesNoQuestion = require './atox-questions'
Chatpanel     = require './atox-chatpanel'
Contact       = require './atox-contact'
Terminal      = require './atox-terminal'
ToxWorker     = require './atox-toxWorker'
{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'
Github        = require './atox-github'

module.exports =
  config:
    showDefault:
      title: "Show on startup"
      description: "Automatically displays the main window on startup"
      type: "boolean"
      default: true
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


  activate: ->
    atom.commands.add 'atom-workspace', 'aTox:toggle',  => @toggle()
    atom.commands.add 'atom-workspace', 'aTox:history', => @toggleHistory()

    @event         = new Emitter
    @mainWin       = new MainWindow    @event
    @notifications = new Notifications @event
    @TOX           = new ToxWorker     @event
    @term          = new Terminal      {cid: -2, event: @event}
    @github        = new Github


    @mainWin.css 'top',  atom.config.get 'atox.mainWinTop'
    @mainWin.css 'left', atom.config.get 'atox.mainWinLeft'

    @mainWin.mouseup =>
      atom.config.set 'aTox.mainWinTop',  @mainWin.css 'top'
      atom.config.set 'aTox.mainWinLeft', @mainWin.css 'left'

    atom.config.observe 'aTox.mainWinTop',  (newValue) => @mainWin.css 'top',  newValue
    atom.config.observe 'aTox.mainWinLeft', (newValue) => @mainWin.css 'left', newValue

    @internalContactId = 0
    @contactsArray     = []

    @mainWin.hide() unless atom.config.get 'atox.showDefault'
    @hasOpenChat    = false

    @event.on 'aTox.new-contact',       (data) => @addUserHelper      data
    @event.on 'aTox.new-online-status', (newS) => @changeOnlineStatus newS
    @event.on 'aTox.select',            (data) => @contactSelected    data
    @event.on 'getChatID',              (data) => @getChatIDFromName  data
    @event.on 'addContact',             (data) => @addUserHelper      data

    $ =>
      @chatpanel    = new Chatpanel {event: @event}
      @addUserHelper {
        name:   "Terminal"
        status: "I am a Terminal"
        online: "online"
        cid:    -2
      }
      @event.on 'aTox.terminal', (data) => @contactsArray[0].contactSendt {msg: data, tid: -2}
      @term.init()

      @github.authentificate {user: 'mensinda', password:'#!Mense1;Git_Hub**$5Acc', otp: '127155'}, =>
        @event.emit 'aTox.terminal', "Github Token: #{@github.getToken()}"
        @github.getUserImage {user: 'mensinda'}, (url) =>
          @event.emit 'aTox.terminal', "Github Avatar: #{url}"

      @TOX.startup()

  changeOnlineStatus: (newStatus) ->
    @event.emit 'notify', {
      type:    'inf'
      name:     newStatus.charAt(0).toUpperCase() + newStatus.slice(1)
      content: "You are now #{newStatus}"
      img:      atom.config.get 'atox.userAvatar'
    }

  getChatIDFromName: (data) ->
    for i in @contactsArray
      if i.name == data
        @event.emit 'aTox.terminal', "getChatIDFromName: #{i.cid} (#{data})"
        return i.cid

    @event.emit 'aTox.terminal', "getChatIDFromName: Not Found (#{data})"
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
      img:    atom.config.get 'atox.userAvatar' #TODO: Add img to params
      event:  @event
      cid:    params.cid
      win:    @mainWin
      panel:  @chatpanel
    }

  toggle: ->
    @mainWin.toggle()

  toggleHistory: ->
    @chatpanel.toggleHistory()
