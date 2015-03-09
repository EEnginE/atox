MainWindow    = require './atox-mainWin'
Notifications = require './atox-notifications'
Question      = require './atox-questions'
Chatpanel     = require './atox-chatpanel'
GitHubLogin   = require './atox-GitHubLogin'

{View, $, $$} = require 'atom-space-pen-views'

module.exports =
class GUI
  constructor: (params) ->
    @event  = params.event
    @github = params.github
    @aTox   = params.aTox

    @mainWin       = new MainWindow    {aTox: @aTox}
    @notifications = new Notifications {aTox: @aTox}
    @GitHubLogin   = new GitHubLogin   {aTox: @aTox, event: @event, github: @github}
    @chatpanel     = new Chatpanel     {aTox: @aTox, event: @event}

    @chatpanel.addChat { cid: -2, img: 'none', event: @event, group: false }

    @event.on 'first-connect',      =>
      if atom.config.get('aTox.githubToken') != 'none'
        @github.setToken atom.config.get('aTox.githubToken')
        @event.emit 'Terminal', {cid: -2, msg: "Loaded token from settings #{atom.config.get('aTox.githubToken')}"}
      else
        @githubauth.show()
    @event.on 'aTox.select', (data) => @contactSelected         data

    @mainWin.css 'top',  atom.config.get 'aTox.mainWinTop'
    @mainWin.css 'left', atom.config.get 'aTox.mainWinLeft'

    @mainWin.mouseup =>
      atom.config.set 'aTox.mainWinTop',  @mainWin.css 'top'
      atom.config.set 'aTox.mainWinLeft', @mainWin.css 'left'

    atom.config.observe 'aTox.mainWinTop',  (newValue) => @mainWin.css 'top',  newValue
    atom.config.observe 'aTox.mainWinLeft', (newValue) => @mainWin.css 'left', newValue
    atom.config.observe 'aTox.githubToken', (newValue) => @github.setToken     newValue
    atom.config.observe 'aTox.userAvatar',  (newValue) => @correctPath         newValue

    @mainWin.show() if atom.config.get 'aTox.showDefault'

    #@question      = new Question      {name: "Test", question: "You there?", accept: "Ja", decline: "Nein"}
    #@question.ask()

  correctPath: (pathArg) ->
    pathArg = path.normalize(pathArg)
    pathArg = pathArg.replace(/\\/g, '/')
    atom.config.set 'aTox.userAvatar', pathArg

  contactSelected: (data) ->
    if data.selected
      @notify {
        name: "#{data.name}"
        content: "Opening chat window"
        img: data.img
      }
    else
      @notify {
        type: 'warn'
        name: "#{data.name}"
        content: "Closing chat window"
        img: data.img
      }

  notify: (params) ->
    params.type = 'inf' unless params.type?

    @notifications.add params

  setUserOnlineStatus: (params) ->
    @mainWin.statusSelector.setStatus   params
    @chatpanel.statusSelector.setStatus params
