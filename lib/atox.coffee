MainWindow = require './atox-mainWin'
PopUpHelper = require './atox-PopUp'
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
      default: 400
      minimum: 1


  activate: ->
    atom.commands.add 'atom-workspace', 'atox:toggle', => @toggle()
    atom.commands.add 'atom-workspace', 'atox:addP1',  => @addP1()
    atom.commands.add 'atom-workspace', 'atox:addP2',  => @addP2()
    atom.commands.add 'atom-workspace', 'atox:addP3',  => @addP3()

    @mainWin = new MainWindow
    @popUps  = new PopUpHelper

    @startup()      if   atom.config.get 'atox.autostart'
    @mainWin.hide() if ! atom.config.get 'atox.showDefault'

  deactivate: ->
    console.log "aTox deactivate"

  toggle: ->
    @mainWin.toggle()

  addP1: ->
    @popUps.add "inf", "Info", "Hello PopUp", "none"

  addP2: ->
    @popUps.add "warn", "Warning", "Hello PopUp", "none"

  addP3: ->
    @popUps.add "err", "Error", "Hello PopUp", "none"

  startup: ->

  shutdown: ->
