MainWindow = require './atox-mainWin'
{View, $, $$} = require 'space-pen'

module.exports =
   config:
      autostart:
         title: "Autologin"
         description: "Automaticaly starts tox when package is loaded"
         type: "boolean"
         default: true

   activate: ->
      console.log "aTox activate"
      atom.commands.add 'atom-workspace', 'atox:toggle', => @toggle()

      @startup() if atom.config.get 'atox.autostart'
      @mainWin = new MainWindow
      #@mainWin.attatch()

   deactivate: ->
      console.log "aTox deactivate"

   toggle: ->
      console.log "toggle"

   startup: ->
      console.log "startup"

   shutdown: ->
      console.log "shutdown"
