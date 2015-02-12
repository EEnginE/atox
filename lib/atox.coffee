MainWindow = require './atox-mainWin'
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

    @mainWin = new MainWindow

    @startup()      if   atom.config.get 'atox.autostart'
    @mainWin.hide() if ! atom.config.get 'atox.showDefault'

  deactivate: ->
    console.log "aTox deactivate"

  toggle: ->
    @mainWin.toggle()

  startup: ->

  shutdown: ->
