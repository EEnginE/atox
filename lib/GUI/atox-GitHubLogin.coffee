{View, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class GitHubLogin extends View
  @content: ->
    @div class: 'aTox-GitHubLogin-root', =>
      @div outlet: 'working', class: 'loading loading-spinner-tiny inline-block'
      @h1  outlet: 'h1', "GitHub Connection"
      @div class: 'form', =>
        @h2 outlet: 'h2', "Please enter username and password"
        @subview "uname", new TextEditorView(mini: true, placeholderText: "Username")
        @subview "pw",    new TextEditorView(mini: true, placeholderText: "Password")
        @subview "otp",   new TextEditorView(mini: true, placeholderText: "Two-factor authentication (leave empty if disabled)")
      @div outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
      @div outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Login'

  initialize: (params) ->
    @aTox        = params.aTox
    @authManager = @aTox.authManager

    @panel = atom.workspace.addModalPanel {item: this, visible: false}

    for i in [@uname, @pw, @otp]
      i.on 'keydown', {t: i}, (e) =>
        @login() if e.keyCode is 13
        @hide()  if e.keyCode is 27

    @btn1.click => @hide()
    @btn2.click => @login()

  deactivate: -> @panel.destroy()

  show:  ->
    @panel.show()
    @uname.focus()

  hide: ->
    @panel.hide()
    i.setText '' for i in [@uname, @pw, @otp]

  login: ->
    @working.show()
    i.addClass 'working' for i in [@h1, @h2, @working]

    @doTimeout 500, => @authManager.login {
      'user':     @uname.getText()
      'password': @pw.getText()
      'otp':      @otp.getText()
    }, {
      'success': (token)     => @success token
      'error':   (err, desc) => @error   err, desc
    }


  error: (name, desc) ->
    @panel.show() unless @panel.isVisible() is true
    i.removeClass 'working' for i in [@h1, @h2, @working]
    i.addClass    'error'   for i in [@h1, @h2]
    @aTox.gui.notify {
      type:     'err'
      name:     name
      content:  desc
    }
    @aTox.term.err {msg: desc, notify: false}
    @doTimeout 2500, =>
      i.removeClass 'error' for i in [@h1, @h2]

  success: (token) ->
    @panel.show() unless @panel.isVisible() is true
    i.removeClass 'working' for i in [@h1, @h2, @working]
    i.addClass    'success' for i in [@h1, @h2]
    @aTox.term.inf {msg: "New token is: #{token}"}
    @doTimeout 2500, =>
      @isOpen = false
      @hide()

  doTimeout: (s, cb) ->
    setTimeout cb, s
