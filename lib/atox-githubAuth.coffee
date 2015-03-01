{View, TextEditorView, $} = require 'atom-space-pen-views'

jQuery = require 'jquery'
require 'jquery-ui/draggable'

module.exports =
class GithubAuth extends View
  @content: ->
    @div id: 'aTox-GithubAuth-root', =>
      @div id: 'aTox-GithubAuth-title', =>
        @div outlet: 'working', class: 'loading loading-spinner-tiny inline-block aTox-hidden'
        @h1  outlet: 't1', "GitHub Connection"
      @div id: 'aTox-GithubAuth-body', =>
        @div id: 'normal', =>
          @h2 outlet: 't2', "Please enter username and password"
          @subview "uName", new TextEditorView(mini: true, placeholderText: "Your username")
          @div class: 'empty-space'
          @subview "pw",    new TextEditorView(mini: true, placeholderText: "Your password")
          @div class: 'empty-space'
          @div class: 'empty-space'
          @div class: 'empty-space'
          @subview "PW2",   new TextEditorView(mini: true, placeholderText: "Your Two-factor authentication (leave empty if disabled)")
        @div id: 'btns', =>
          @div id: 'btn1', outlet: 'btn1', class: 'btn btn-lg btn-error', 'Do not connect'
          @div id: 'btn2', outlet: 'btn2', class: 'btn btn-lg btn-info',  'Connect'

  initialize: (params) ->
    @event  = params.event
    @github = params.github

    atom.views.getView atom.workspace
      .appendChild @element

    jQuery( "#aTox-GithubAuth-root" ).draggable {handle: '#aTox-GithubAuth-title'}

    @btn1.click => @noGithubConnection()
    @btn2.click => @handleClick()

    @isOpen = false

  noGithubConnection: ->
    @event.emit 'Terminal', {cid: -2, msg: "No GitHub connection"}
    @event.emit 'GitHub',   'disabled'
    @removeClass "aTox-shown";
    @isOpen = false

  handleClick: ->
    @working.removeClass "aTox-hidden"
    i.addClass 'work' for i in [@t1, @t2, @working]

    @doTimeout 500, => @checkInput()

  checkInput: ->
    name = @uName.getText()
    pw   = @pw.getText()
    pw2  = @PW2.getText()

    if name is "" or pw is ""
      return @doTimeout 500, => @error "Empty", "Please enter your username and password"

    @github.createUserToken {user: name, password: pw, otp: pw2}, (params) =>
      if params.token?
        if @postTokenGeneration() is false
          return @doTimeout 500, => @error "Internal", "Internal error. Please try again"

        @doTimeout 500, => @success()
        atom.config.set 'aTox.githubToken', params.token
      else
        @doTimeout 500, => @error "Failed", "#{params.data.message}"

  error: (what, desc) ->
    i.removeClass 'work' for i in [@t1, @t2, @working]
    i.addClass    'err'  for i in [@t1, @t2]
    @event.emit 'notify', {type: 'err', name: what, content: desc}
    @doTimeout 5000, =>
      i.removeClass 'err'  for i in [@t1, @t2]

  success: ->
    i.removeClass 'work' for i in [@t1, @t2, @working]
    i.addClass    'ok'   for i in [@t1, @t2]
    @doTimeout 4000, =>
      @removeClass "aTox-shown"
      @isOpen = false

  doIt: ->
    return if @isOpen is true
    if atom.config.get('aTox.githubToken') != 'none'
      @github.setToken atom.config.get('aTox.githubToken')
      @event.emit 'Terminal', {cid: -2, msg: "Loaded token from settings #{atom.config.get('aTox.githubToken')}"}
      return @postTokenGeneration()

    if @github.getToken() is undefined or @github.getToken() is 'none'
      @css {display: 'block'}
      @addClass "aTox-shown";
      @isOpen = true
      return false

    return @postTokenGeneration()

  postTokenGeneration: -> # TODO rename this
    #@event.emit 'Terminal', "TODO add what to do here"

    @event.emit 'GitHub',   'done'
    return true

    #@github.authentificate {user: 'arvius', password:''}, =>
      #@event.emit 'Terminal', "Github Token: #{@github.getToken()}"
      #@github.getUserImage {user: 'mensinda'}, (url) =>
        #@event.emit 'Terminal', "Github Avatar: #{url}"

  doTimeout: (s, cb) ->
    setTimeout cb, s
