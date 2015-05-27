{SelectListView, TextEditorView, View} = require 'atom-space-pen-views'

class GetArgs extends View
  @content: (params) ->
    @div =>
      @div   outlet: 'icon'
      @h1    outlet: 'cmd'
      @label outlet: 'desc'
      @div   outlet: 'args'
      @div   outlet: 'btns', =>
        @div outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
        @div outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Run'

  initialize: ->
    @panel = atom.workspace.addModalPanel {item: this, visible: false}

    @icon.css {'float': 'right'}

    @btns.css {'padding-left': '50px', 'padding-right': '50px'}
    @btn2.css {'float':        'right'}

    @btn1.click => @hide()
    @btn2.click => @run()

    @editors = []

  deactivate: -> @panel.destroy()

  hide: ->
    @panel.hide()

  show: (params) ->
    @args.empty()
    @editors = []

    @cmd.text  params.cmd
    @desc.text params.desc
    @icon.attr {"class": "icon icon-#{params.icon}"}

    for i in [0..(params.argc-1)] by 1
      @editors[i] = new TextEditorView mini: true, placeholderText: "Arg #{i + 1}"
      @editors[i].on 'keydown', (e) =>
        @run()  if e.keyCode is 13
        @hide() if e.keyCode is 27
      @args.append @editors[i]

    @RUN  = params.run
    @panel.show()
    @editors[0].focus()

  run: ->
    @panel.hide()
    p = []
    for i, index in @editors
      p[index] = @editors[index].getText()

    @RUN -1, p


class Item extends View
  @content: (params, parent) ->
    @li    outlet: 'root',    class: 'two-lines', =>
      @div outlet: 'status',  class: "status badge badge-medium",             params.argc
      @div outlet: 'primary', class: "primary-line icon icon-#{params.icon}", params.cmd
      @div outlet: 'desc',    class: 'secondary-line no-icon',                params.desc

  initialize: (params, parent) ->
    @status.css {"float": "right"}
    @status.addClass "badge-info" if params.argc > 0


module.exports =
class TermSelect extends SelectListView
  initialize: (params) ->
    @aTox   = params.aTox
    @setItems @aTox.term.cmds

    super
    @panel   = atom.workspace.addModalPanel {item: this, visible: false}
    @getArgs = new GetArgs

  viewForItem: (item) -> new Item item, this
  confirmed:   (item) ->
    @panel.hide()
    if item.argc is 0
      item.run -1
    else
      @getArgs.show {
        argc: item.argc
        run: item.run
        cmd: item.cmd
        desc: item.desc
        icon: item.icon
      }

    @cancel()

  cancel: ->
    @panel.hide()
    super()

  show: ->
    @populateList()
    @panel.show()
    @storeFocusedElement()
    @focusFilterEditor()

  getFilterKey: -> return "cmd"
