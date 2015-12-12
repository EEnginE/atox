{SelectListView, TextEditorView, View} = require 'atom-space-pen-views'

# coffeelint: disable=max_line_length

class Argument extends View
  @content: (params, parent) ->
    @div class: 'atox-termSelectArgument', =>
      @label   outlet: 'lab', params.desc
      @select  outlet: 'list', class: 'form-control'
      @subview 'editor', new TextEditorView {"mini": true}

  initialize: (params, parent) ->
    @inputType = 'list'
    if params.type?
      switch params.type
        when 'friend' then @setupFriend parent
        when 'group'  then @setupGroup  parent
        when 'list'   then @setupList params.list
        else @setupEditor parent
    else
      @setupEditor parent

  setupFriend: (parent) ->
    @editor.remove()
    for i in parent.aTox.TOX.friends
      @addOption i.getID(), i.getName() if i.getIsHuman()

  setupGroup: (parent) ->
    @editor.remove()
    for i in parent.aTox.TOX.groups
      @addOption i.getID(), i.getName() unless i.isCollab()

  setupList: (list) ->
    @editor.remove()
    @addOption i, i for i in list

  addOption: (value, text) -> @list.append "<option value='#{value}'>#{text}</option>"

  setupEditor: (parent) ->
    @inputType = 'editor'
    @list.remove()
    @editor.on 'keydown', (e) ->
      parent.run()  if e.keyCode is 13
      parent.hide() if e.keyCode is 27
    @append @editor

  get: ->
    if @inputType is 'editor'
      return @editor.getText()
    else
      return @list.val()

  focus: ->
    if @inputType is 'editor'
      return @editor.focus()
    else
      return @list.focus()

class GetArgs extends View
  @content: (params) ->
    @div class: 'atox-termSelectGetArgs', =>
      @div   outlet: 'icon', class: 'icon'
      @h1    outlet: 'cmd'
      @h2    outlet: 'desc'
      @div   outlet: 'args'
      @div   outlet: 'btns', class: 'btns', =>
        @div outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
        @div outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Run'

  initialize: (params) ->
    @aTox  = params.aTox
    @panel = atom.workspace.addModalPanel {item: this, visible: false}

    @btn1.click => @hide()
    @btn2.click => @run()

    @argsOBJ = []

  deactivate: -> @panel.destroy()

  hide: ->
    @panel.hide()

  show: (params) ->
    @args.empty()
    @argsOBJ = []

    @cmd.text  params.cmd
    @desc.text params.desc
    @icon.attr {"class": "icon icon-#{params.icon}"}

    for i in params.args
      arg = new Argument i, this
      @argsOBJ.push arg
      @args.append  arg

    @panel.show()
    @argsOBJ[0].focus()

  run: ->
    @panel.hide()
    p = []
    for i, index in @argsOBJ
      p[index] = i.get()

    @aTox.term.run @cmd.text(), {"cID": -1, "argv": p}


class Item extends View
  @content: (params, parent) ->
    @li    outlet: 'root',    class: 'two-lines', =>
      @div outlet: 'status',  class: "status badge badge-medium",             params.args.length
      @div outlet: 'primary', class: "primary-line icon icon-#{params.icon}", params.cmd
      @div outlet: 'desc',    class: 'secondary-line no-icon',                params.desc

  initialize: (params, parent) ->
    @status.css {"float": "right"}
    @status.addClass "badge-info" if params.args.length > 0


module.exports =
class TermSelect extends SelectListView
  initialize: (params) ->
    @aTox   = params.aTox

    super
    @panel   = atom.workspace.addModalPanel {item: this, visible: false}
    @getArgs = new GetArgs {"aTox": @aTox}

  deactivate: -> @panel.destroy()

  viewForItem: (item) -> new Item item, this
  confirmed:   (item) ->
    @panel.hide()
    if item.args.length is 0
      @aTox.term.run item.cmd, {"cID": -1, "argv": []}
    else
      @getArgs.show {
        args: item.args
        cmd:  item.cmd
        desc: item.desc
        icon: item.icon
      }

    @cancel()

  cancel: ->
    @panel.hide()
    super()

  show: ->
    # Dont show options requiring friends when you have none
    hasFriends = hasGroups = false

    for i in @aTox.TOX.friends
      if i.getIsHuman()
        hasFriends = true
        break

    for i in @aTox.TOX.groups
      unless i.isCollab()
        hasGroups = true
        break

    items = []
    for i in @aTox.term.cmds
      skip = false
      for j in i.args
        skip = true if j.type is 'friend' and hasFriends is false
        skip = true if j.type is 'group'  and hasGroups  is false

      items.push i unless skip

    @setItems items
    @populateList()
    @panel.show()
    @storeFocusedElement()
    @focusFilterEditor()

  getFilterKey: -> return "cmd"
