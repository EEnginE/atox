MainWindow    = require './atox-mainWin'
Notifications = require './atox-notifications'
YesNoQuestion = require './atox-questions'
Chatpanel     = require './atox-chatpanel'
Contact       = require './atox-contact'
{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'

module.exports =
  config:
    autostart:
      title: "Autologin"
      description: "Automatically starts aTox when the package is loaded"
      type: "boolean"
      default: true
    showDefault:
      title: "Show on startup"
      description: "Automatically displays the main window on startup"
      type: "boolean"
      default: true
    popupTimeout:
      title: "Pop Up timeout"
      description: "Timeout in seconds"
      type: "number"
      default: 4
      minimum: 1
    fadeDuration:
      title: "Pop Up fade duration"
      description: "Pop Up fade duration in milliseconds"
      type: "number"
      default: 250
      minimum: 1
    notificationSpeed:
      title: "Notification animation speed"
      description: "Notification animation speed in milliseconds"
      type: "number"
      default: 300
      minimum: 1
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
    scrollFactor:
      title: "Scroll Factor"
      type: "number"
      default: 0.5
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


  activate: ->
    atom.commands.add 'atom-workspace', 'aTox:toggle',  => @toggle()
    atom.commands.add 'atom-workspace', 'aTox:history', => @toggleHistory()

    @mainEvent     = new Emitter

    @mainWin       = new MainWindow @mainEvent
    @notifications = new Notifications

    @mainWin.css 'top',  atom.config.get 'atox.mainWinTop'
    @mainWin.css 'left', atom.config.get 'atox.mainWinLeft'

    @mainWin.mouseup =>
      atom.config.set 'aTox.mainWinTop',  @mainWin.css 'top'
      atom.config.set 'aTox.mainWinLeft', @mainWin.css 'left'

    atom.config.observe 'aTox.mainWinTop',  (newValue) =>
      @mainWin.css 'top',  newValue

    atom.config.observe 'aTox.mainWinLeft', (newValue) =>
      @mainWin.css 'left', newValue

    @internalContactId = 0
    @contactsArray     = []

    @addUserHelper {name: "Test1", online: 'online'}
    @addUserHelper {name: "Test2", online: 'offline'}
    @addUserHelper {name: "Test3", online: 'away'}
    @addUserHelper {name: "Test4", online: 'busy'}
    @addUserHelper {name: "Test5", online: 'group'}

    @startup()      if   atom.config.get 'atox.autostart'
    @mainWin.hide() if ! atom.config.get 'atox.showDefault'
    @hasOpenChat   = false

    @mainEvent.on 'aTox.new-contact',       (data)    => @addUserHelper      data
    @mainEvent.on 'aTox.new-online-status', (newS)    => @changeOnlineStatus newS
    @mainEvent.on 'aTox.select',            (data)    => @contactSelected    data

    $ =>
      @chatpanel    = new Chatpanel {event: @mainEvent}
      @chatpanel.addChat {cid: 1, img: (atom.config.get 'atox.userAvatar')}
      @chatpanel.addChat {cid: 2, img: (atom.config.get 'atox.userAvatar')}

  changeOnlineStatus: (newStatus) ->
    @notifications.add(
     'inf',
      newStatus.charAt(0).toUpperCase() + newStatus.slice(1),
      "You are now #{newStatus}",
      atom.config.get 'atox.userAvatar')

  contactSelected: (data) ->
    if data.selected
      @notifications.add 'inf',  "Now chatting with #{data.name}",   "Opening chat window", data.img
    else
      @notifications.add 'warn', "Stopped chatting with #{data.name}", "Closing chat window", data.img

  addUserHelper: (params) ->
    @contactsArray.push new Contact {
      name:   params.name,
      status: "Test Status", #TODO: Add status to params
      online: params.online,
      img:   (atom.config.get 'atox.userAvatar'), #TODO: Add img to params
      event:  @mainEvent,
      id:     @internalContactId
      win:    @mainWin
    }

    @internalContactId++

  toggle: ->
    @mainWin.toggle()

  toggleHistory: ->
    @chatpanel.toggleHistory()

  startup: ->

  shutdown: ->
