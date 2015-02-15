MainWindow    = require './atox-mainWin'
Notifications = require './atox-notifications'
YesNoQuestion = require './atox-questions'
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

    @addUserHelper "Test1", 'offline'
    @addUserHelper "Test2", 'online'
    @addUserHelper "Test3", 'away'
    @addUserHelper "Test4", 'bussy'
    @addUserHelper "Test5", 'groub'

    @startup()      if   atom.config.get 'atox.autostart'
    @mainWin.hide() if ! atom.config.get 'atox.showDefault'

  deactivate: ->
    console.log "aTox deactivate"

  addUserHelper: (name, online) ->
    @mainWin.addContact {
      name: name,
      status: "Test Status",
      online: online,
      img: (atom.config.get 'atox.userAvatar'),
      selectCall: (attr) =>
        if attr.selected
          @notifications.add 'inf', "Selected '#{attr.name}'", attr.status, attr.img
        else
          @notifications.add 'warn', "Deselected '#{attr.name}'", attr.status, attr.img
     }

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
