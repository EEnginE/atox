toxcore = require 'toxcore'

module.exports =
class ToxWorker
  constructor: (event) ->
    @event = event

  startup: ->
    @TOX = new toxcore.Tox

    @err "Failed to load TOX" unless @TOX.checkHandle (e) =>

    @TOX.on 'friendRequest', (e) => @friendRequest e

    @TOX.start()
    @inf "Started TOX"
    @inf "My ID: #{@TOX.getAddressHexSync()}"


  friendRequest: (e) ->
    @inf "Friend request: #{e.publicKeyHex()} (Autoaccept)"
    fNum = 0

    try
      fNum = @TOX.addFriendNoRequestSync e.publicKey()
    catch error
      @err "Failed to add Friend"
      return

    @event.emit 'addContact', {
      name:   e.publicKeyHex()
      status: "Working Please wait..."
      online: 'offline'
      cid:    fNum
    }
    @inf "Added Friend #{fNum}"

  inf: (msg) ->
    @event.emit 'notify', {
      type: 'inf'
      name: 'TOX'
      content: msg
    } if atom.config.get 'aTox.debugNotifications'

    @event.emit 'aTox.terminal', "TOX: [Info] #{msg}"

  err: (msg) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'TOX'
      content: msg
    }

    @event.emit 'aTox.terminal', "TOX: [Error] #{msg}"
