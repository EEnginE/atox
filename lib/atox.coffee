path          = require 'path'
GUI           = require './GUI/atox-GUI'
Contact       = require './atox-contact'
Terminal      = require './atox-terminal'
ToxWorker     = require './atox-toxWorker'
Github        = require './atox-github'

{View, $, $$} = require 'atom-space-pen-views'
{Emitter}     = require 'event-kit'

module.exports =
  config:
    showDefault:
      title: "Show on startup"
      description: "Automatically displays the main window on startup"
      type: "boolean"
      default: false
    userAvatar:
      title: "Avatar"
      description: "A full path to your Avatar"
      type: "string"
      default: "none"
    userName:
      title: "Username"
      description: "Your username"
      type: "string"
      default: "User"
    chatColor:
      title: "Your chat's color"
      type:  "color"
      default: "#09c709"
    mainWinTop:
      title: "Main Window Top"
      type: "string"
      default: "60%"
    mainWinLeft:
      title: "Main Window Left"
      type: "string"
      default: "80%"
    debugNotifications:
      title: "Debug Notifications"
      description: "When activated displays debug notifications"
      type:  "boolean"
      default: false
    githubToken:
      title: "Github Access Token"
      description: "Github access token"
      type: "string"
      default: "none"


  activate: ->
    atom.commands.add 'atom-workspace', 'aTox:toggle',  => @toggle()
    atom.commands.add 'atom-workspace', 'aTox:history', => @toggleHistory()

    @event         = new Emitter

    @terminal      = new Terminal      {event: @event, aTox: this}
    @TOX           = new ToxWorker     {dll: "#{__dirname}\\..\\bin\\libtox.dll", event: @event, aTox: this}
    @github        = new Github

    @currCID = 0

    @internalContactId = 0
    @contactsArray     = []
    @contactsPubKey    = []

    @hasOpenChat    = false

    $ =>
      @gui = new GUI {event: @event, github: @github, aTox: this}

      @event.on 'aTox.new-contact',       (data) => @addUserHelper           data
      @event.on 'getChatID',              (data) => @getChatIDFromName       data
      @event.on 'getFriendIDFromPubKey',  (data) => @getFriendIDFromPubKey   data

      @event.on 'Terminal', (data) =>
        @event.emit "aTox.add-message", {
          cid:   data.cid
          tid:   -2
          color: "rgba(255, 255, 255 ,1)"
          name:  "aTox"
          msg:   "<span style='font-style:italic;color:rgba(200, 200, 200 ,1)'>" + data.msg + "</span>"
        }
      @terminal.initialize()
      @TOX.startup()

  getChatIDFromName: (data) ->
    for i in @contactsArray
      if i.name == data.name
        @event.emit 'Terminal', {cid: data.cid, msg: "getChatIDFromName: #{i.cid} (#{data})"}
        return i.cid

    @event.emit 'Terminal', {cid: data.cid, msg: "getChatIDFromName: Not Found (#{data})"}
    return -1

  addUserHelper: (params) ->
    @contactsArray.push new Contact {
      name:   params.name
      status: params.status
      online: params.online
      img:    atom.config.get 'aTox.userAvatar' #TODO: Add img to params
      event:  @event
      cid:    @currCID
      tid:    params.tid
      win:    @gui.mainWin
      panel:  @gui.chatpanel
      hidden: params.hidden
      aTox:   this
    }
    @currCID++
    @contactsPubKey.push { tid: params.tid, pubKey: params.pubKey }

  getFriendIDFromPubKey: (params) ->
    fid = -1
    for i in @contactsPubKey
      fid = i.tid if i.pubKey is params.pubKey

    params.cb fid

  toggle: ->
    @gui.mainWin.toggle()

  toggleHistory: ->
    @gui.chatpanel.toggleHistory()
