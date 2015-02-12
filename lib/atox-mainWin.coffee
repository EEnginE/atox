{View, $, $$} = require 'space-pen'

module.exports =
class MainWindow extends View
  @content: ->
    @div =>
      @h1 "Spacecraft"
      @ol outlet: "list", =>
        @li "Apollo"
        @li "Soyuz"
        @li "Space Shuttle"

  initialize: ->
    atom.views.getView atom.workspace
      .appendChild @element

  constructor: ->
    console.log "Constr."
    super()

  attatch: ->
    console.warn "AAA"
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.appendChild @content
