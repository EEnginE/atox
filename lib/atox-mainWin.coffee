{View, $, $$} = require 'space-pen'

module.exports =
class MainWindow extends View
  @content: ->
    @div id: 'aTox-main-window', =>
      @h1 "aTox - Main Window"
      @ol outlet: "list", =>
        @li "Arvius"
        @li "Mensinda"
        @li "Taiterio"

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
