{View, TextEditorView, $} = require 'atom-space-pen-views'
jQuery = require 'jquery'
require 'jquery-ui/draggable'

module.exports =
class GitHubLogin extends View
  @content: ->
    @div class: 'aTox-GitHubLogin-root', =>
      @div class: 'aTox-GitHubLogin-title', =>
        @div outlet: 'working', class: 'loading loading-spinner-tiny inline-block'
        @h1  outlet: 'h1', "GitHub Connection"
      @div class: 'aTox-GitHubLogin-body', =>
        @div class: 'form', =>
          @h2 outlet: 'h2', "Please enter username and password"
          @subview "uname", new TextEditorView(mini: true, placeholderText: "Username")
          @subview "pw",    new TextEditorView(mini: true, placeholderText: "Password")
          @subview "otp",   new TextEditorView(mini: true, placeholderText: "Two-factor authentication (leave empty if disabled)")
        @div class: 'btns', =>
          @div outlet: 'btn1', class: 'btn1 btn btn-lg btn-error', 'Abort'
          @div outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Login'

  initialize: (params) ->
    @aTox   = params.aTox
    @event  = params.event
    @github = params.github

    atom.views.getView atom.workspace
      .appendChild @element

    jQuery(".aTox-GitHubLogin-root").draggable {handle: '.aTox-GitHubLogin-title'}

    for i in [@uname, @pw, @otp]
      i.on 'keydown', {t: i}, (e) =>
        @login()      if e.keyCode is 13
        e.data.t.setText '' if e.keyCode is 27

    @btn1.click => @abort()
    @btn2.click => @login() if @checkInput()

    @isOpen = false

  abort: ->
    @event.emit 'Terminal', {cid: -2, msg: "No GitHub connection"}
    @event.emit 'GitHub',   'disabled'
    @isOpen = false
    @hide()

  login: ->
    @working.show()
    i.addClass 'working' for i in [@h1, @h2, @working]

    name = @uname.getText()
    pw   = @pw.getText()
    otp  = @otp.getText()

    @github.createUserToken {user: name, password: pw, otp: otp}, (params) =>
      if params.token?
        if @postTokenGeneration() is false
          return @doTimeout 500, => @error "Internal", "Internal error. Please try again"
        @doTimeout 500, => @success()
        atom.config.set 'aTox.githubToken', params.token
      else
        @doTimeout 500, => @error "Failed", "#{params.data.message}"

  checkInput: ->
    name = @uname.getText()
    pw   = @pw.getText()
    otp  = @otp.getText()

    if name is "" or pw is ""
      @doTimeout 500, => @error "Empty", "Please enter your username and password"
      return false
    return true


  error: (name, desc) ->
    i.removeClass 'working' for i in [@h1, @h2, @working]
    i.addClass    'error'   for i in [@h1, @h2]
    @event.emit 'notify', {type: 'err', name: name, content: desc}
    @doTimeout 2500, =>
      i.removeClass 'error' for i in [@h1, @h2]

  success: ->
    i.removeClass 'working' for i in [@h1, @h2, @working]
    i.addClass    'success' for i in [@h1, @h2]
    @doTimeout 2500, =>
      @isOpen = false
      @hide()

  show: ->
    return if @isOpen is true
    if @github.getToken() is undefined or @github.getToken() is 'none'
      @isOpen = true
      super()

  postTokenGeneration: ->
    @event.emit 'GitHub',   'done'
    return true

    #@github.authentificate {user: 'arvius', password:''}, =>
      #@event.emit 'Terminal', "Github Token: #{@github.getToken()}"
      #@github.getUserImage {user: 'mensinda'}, (url) =>
        #@event.emit 'Terminal', "Github Avatar: #{url}"

  doTimeout: (s, cb) ->
    setTimeout cb, s
