{View, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class PasswdPrompt extends View
  @content: ->
    @div class: 'aTox-Form1-root', =>
      @h1  outlet: 'h1', "aTox Login"
      @div class: 'block form', =>
        @h2 outlet: 'h2'
        @subview "pw1", new TextEditorView mini: true, placeholderText: "Password"
        @subview "pw2", new TextEditorView mini: true, placeholderText: "Repeate your new password"
      @div   outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
      @div   outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Confirm'

  initialize: (params) ->
    @aTox  = params.aTox
    @panel = atom.workspace.addModalPanel 'item': this, 'visible': false

    @pw1.attr 'pw': true
    @pw2.attr 'pw': true

    for i in [@pw1, @pw2]
      i.on 'keydown', {t: i}, (e) =>
        @btn2.trigger 'click' if e.keyCode is 13
        @hide()               if e.keyCode is 27

    @btn1.click => @hide()

  deactivate: -> @panel.destroy()

  show: ->
    @panel.show()
    @pw1.focus()

  hide: ->
    i.setText     ''     for i in [@pw1, @pw2]
    i.removeClass 'error'for i in [@h1, @h2]
    @panel.hide()

  prompt: (cb) ->
    @h2.text "Please enter your password to unlock your TOX profile"
    @pw1.attr 'marg2': false
    @pw2.hide()

    @btn2.off 'click'
    @btn2.click =>
      pw = @pw1.getText()
      @hide()
      cb pw

    @show()

  promptNewPW: (cb) ->
    @h2.text "Please enter a new password for your current profile"
    @pw1.attr 'marg2': true
    @pw2.show()

    @btn2.off 'click'
    @btn2.click =>
      p1 = @pw1.getText()
      p2 = @pw2.getText()
      if p1 is p2
        @hide()
        cb p1
      else
        i.setText  ''     for i in [@pw1, @pw2]
        i.addClass 'error'for i in [@h1, @h2]
        @aTox.term.err 'title': 'Passwords do not match'

    @show()
