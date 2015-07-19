{View, TextEditorView} = require 'atom-space-pen-views'
shell = require 'shell'

GITHUB_LOGIN_LINK = "https://github.com/EEnginE/atox/blob/master/LoginInfo.md"

module.exports =
class GitHubLogin extends View
  @content: ->
    @div class: 'aTox-GitHubLogin-root', =>
      @div outlet: 'working', class: 'loading loading-spinner-tiny inline-block'
      @div outlet: 'info',    class: 'icon icon-info inline-block info-icon-position'
      @h1  outlet: 'h1', "GitHub Connection"
      @div class: 'block form', =>
        @h2 outlet: 'h2', "Please enter username and password"
        @subview "uname", new TextEditorView(mini: true, placeholderText: "Username")
        @subview "pw",    new TextEditorView(mini: true, placeholderText: "Password")
        @subview "otp",   new TextEditorView(mini: true, placeholderText: "Two-factor authentication (leave empty if disabled)")
        @div class: 'checkbox', =>
          @input outlet: 'cBox', type: 'checkbox'
          @div   class: 'setting-title', "Don't ask again"
      @div   outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
      @div   outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Login'

  initialize: (params) ->
    @aTox    = params.aTox
    @manager = @aTox.manager

    @panel = atom.workspace.addModalPanel {item: this, visible: false}

    for i in [@uname, @pw, @otp]
      i.on 'keydown', {t: i}, (e) =>
        @login() if e.keyCode is 13
        @hide()  if e.keyCode is 27

    @btn1.click => @hide()
    @btn2.click => @login()
    @info.click -> shell.openExternal GITHUB_LOGIN_LINK

    @cBox.prop 'checked', if atom.config.get 'aTox.showGithubLogin' then false else true

  deactivate: -> @panel.destroy()

  show:  ->
    @working.hide()
    @info.show()
    @panel.show()
    @uname.focus()

  hide: ->
    if @cBox.prop 'checked'
      atom.config.set 'aTox.showGithubLogin', false
    else
      atom.config.set 'aTox.showGithubLogin', true

    @panel.hide()
    i.setText '' for i in [@uname, @pw, @otp]

  login: ->
    atom.config.set 'aTox.showGithubLogin', true
    @working.show()
    @info.hide()
    i.addClass 'working' for i in [@h1, @h2, @working]

    @doTimeout 500, => @manager.login {
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
    @aTox.term.err {"title": "Failed to create token", "msg": desc}
    @doTimeout 2500, =>
      i.removeClass 'error' for i in [@h1, @h2]

  success: (token) ->
    @panel.show() unless @panel.isVisible() is true
    i.removeClass 'working' for i in [@h1, @h2, @working]
    i.addClass    'success' for i in [@h1, @h2]
    @aTox.term.inf {"title": "Generated new token", "msg": "#{token}"}
    @doTimeout 2500, =>
      @isOpen = false
      @hide()

  doTimeout: (s, cb) ->
    setTimeout cb, s
