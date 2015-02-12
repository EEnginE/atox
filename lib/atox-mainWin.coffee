{View} = require 'space-pen'

module.exports =
class MainWindow extends View
  @content: ->
    @div =>
      @h1 "Main Window"

  constructor: ->
    console.log "Constr."
