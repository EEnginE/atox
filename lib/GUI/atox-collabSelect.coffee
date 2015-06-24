{SelectListView, View} = require 'atom-space-pen-views'

# coffeelint: disable=max_line_length

class Item extends View
  @content: (params) ->
    @li       outlet: 'root',    class: 'two-lines', =>
      @div    outlet: 'status',  class: 'status'
      @div    outlet: 'primary', class: 'primary-line', =>
        @span outlet: 'action',  class: '',                       params.action
        @span outlet: 'msg',     class: 'text-highlight',        " #{params.primary}"
      @div    outlet: 'desc',    class: 'secondary-line no-icon', params.desc

  initialize: (params) ->
    switch params.action
      when 'Join'
        @status.addClass  'status-renamed icon icon-diff-renamed'
        @primary.addClass 'status-added   icon icon-chevron-right'
        @action.addClass  'highlight-info'
      when 'Create'
        @status.addClass  'status-added icon icon-diff-added'
        @primary.addClass 'icon icon-file-text'
        @action.addClass  'highlight-success'
      when 'Close'
        @status.addClass  'status-removed  icon icon-diff-removed'
        @primary.addClass 'status-modified icon icon-zap'
        @action.addClass  'highlight-error'

    @action = params.action
    @path   = params.path

module.exports =
class CollabSelect extends SelectListView
  initialize: (params) ->
    @aTox = params.aTox

    super
    @panel = atom.workspace.addModalPanel {item: this, visible: false}

  deactivate: -> @panel.destroy()

  viewForItem: (item) -> new Item item
  confirmed: (item)   ->
    @cancel()

    switch item.action
      when 'Create' then @aTox.collab.newCollab   item.path
      when 'Join'   then @aTox.collab.joinCollab  item.path
      when 'Close'  then @aTox.collab.closeCollab item.path

  cancel: ->
    @panel.hide()
    super()

  requestOpen: ->
    @aTox.collab.updateJoinList (isTimeout) => @show isTimeout.timeout

  show: (isTimeout) ->
    unless @aTox.collab.getIsGitRepository()
      @setItems []
      @panel.show()
      @setError 'aTox CollabEdit needs a git repository!'
      return

    items = []

    currentFile = @aTox.collab.getCurrentFile()
    unless currentFile.error
      if currentFile.collabExists
        items.push {
          action:  "Join"
          primary: "Collab for this file"
          desc:    "Join the already existing Collab for this file (#{currentFile.path})"
          path:    currentFile.path
        }
      else
        items.push {
          action:  "Create"
          primary: "Collab for this file"
          desc:    "Create a new collab for the current file (#{currentFile.path})"
          path:    currentFile.path
        }

    for i in @aTox.collab.getJoinableList()
      items.push {
        action:  'Join'
        primary: "#{i.name}"
        desc:    "Join active collab '#{i.name}'"
        path:    i.name
      }

    for i in @aTox.collab.getCollabList()
      items.push {
        action:  'Close'
        primary: "#{i}"
        desc:    "Closes collab '#{i}'"
        path: i
      }

    @setItems items
    @panel.show()

    if isTimeout
      @setError 'One or more peers timed out'
      console.log "Timeout"
    else
      @setError ''

    @storeFocusedElement()
    @focusFilterEditor()

  getFilterKey: -> return "primary"
