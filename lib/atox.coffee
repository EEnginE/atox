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
      title: "Sow on startup"
      description: "Automaticaly displays the main window on startup"
      type: "boolean"
      default: true


  activate: ->
    atom.commands.add 'atom-workspace', 'atox:toggle', => @toggle()
    atom.commands.add 'atom-workspace', 'atox:addP1',  => @addP1()

    @mainWin = new MainWindow
    @popUps  = new PopUpHelper

    @startup()      if   atom.config.get 'atox.autostart'
    @mainWin.hide() if ! atom.config.get 'atox.showDefault'

  deactivate: ->
    console.log "aTox deactivate"

  toggle: ->
    @mainWin.toggle()

  addP1: ->
    @popUps.add "info", "MAIN", "Hello PopUp", "none"

  startup: ->

  shutdown: ->
