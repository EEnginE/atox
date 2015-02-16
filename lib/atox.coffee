MainWindow    = require './atox-mainWin'
Notifications = require './atox-notifications'
YesNoQuestion = require './atox-questions'
Chatpanel     = require './atox-chatpanel.coffee'
{View, $, $$} = require 'atom-space-pen-views'

module.exports =
  config:
    autostart:
      title: "Autologin"
      description: "Automaticaly starts tox when package is loaded"
      type: "boolean"
      default: true
    showDefault:
      title: "Show on startup"
      description: "Automaticaly displays the main window on startup"
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
      title: "User Name"
      description: "Your user name"
      type: "string"
      default: "User"
    scrollFactor:
      title: "Scroll Factor"
      type: "number"
      default: 0.5


  activate: ->
    atom.commands.add 'atom-workspace', 'atox:toggle', => @toggle()
    atom.commands.add 'atom-workspace', 'atox:addP1',  => @addP1()
    atom.commands.add 'atom-workspace', 'atox:addP2',  => @addP2()
    atom.commands.add 'atom-workspace', 'atox:addP3',  => @addP3()
    atom.commands.add 'atom-workspace', 'atox:ask',    => @ask()

    @mainWin       = new MainWindow
    @notifications = new Notifications

    console.warn atom.config.get 'atox.userAvatar'

    @mainWin.addContact { name: "Mister Mense", status: "palying Dwarf Fortress", online: 'offline', img: (atom.config.get 'atox.userAvatar') }
    @mainWin.addContact { name: "Test2", status: "Test Status", online: 'online',  img: (atom.config.get 'atox.userAvatar') }
    @mainWin.addContact { name: "Test3", status: "Test Status", online: 'away',    img: (atom.config.get 'atox.userAvatar') }
    @mainWin.addContact { name: "Test4", status: "Test Status", online: 'bussy',   img: (atom.config.get 'atox.userAvatar') }
    @mainWin.addContact { name: "Test5", status: "Test Status", online: 'groub',   img: (atom.config.get 'atox.userAvatar') }

    @startup()      if   atom.config.get 'atox.autostart'
    @mainWin.hide() if ! atom.config.get 'atox.showDefault'

    @chatpanel    = new Chatpanel {uname: 'Arvius', color: '#0f0'}

  deactivate: ->
    console.log "aTox deactivate"

  toggle: ->
    @mainWin.toggle()

  addP1: ->
    @notifications.add "inf", "Info", "Hello PopUp", "none"

  addP2: ->
    @notifications.add "warn", "Warning", "Hello PopUp", "none"

  addP3: ->
    @notifications.add "err", "Error", "Hello PopUp", "none"

  ask: ->
    q1 = new YesNoQuestion "Test Question", "Do you want a cookie?", "YES!!", "no"
    q1.callbacks =>
      @notifications.add "inf", "&#60;Cookie/&#62;", "It is delicious!", "none"
    , =>
      @notifications.add "err", ":(", "Why not !?", "none"

    q1.ask()

  startup: ->

  shutdown: ->
