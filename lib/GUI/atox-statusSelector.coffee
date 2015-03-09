{View, $} = require 'atom-space-pen-views'

module.exports =
class StatusSelector extends View
  @content: (params) ->
    @div class: "aTox-status-selector", =>
      @div class: "aTox-status-selector-offline", outlet: 'offline'
      @div class: "aTox-status-selector-online", outlet: 'online'
      @div class: "aTox-status-selector-away", outlet: 'away'
      @div class: "aTox-status-selector-busy", outlet: 'busy'
      @div class: "aTox-status-selector-current-online", outlet: 'status'

  initialize: (params) ->
    @aTox         = params.aTox

    @status.click  => @openSelector()
    @offline.click => @clickHandler 'offline'
    @online.click  => @clickHandler 'online'
    @away.click    => @clickHandler 'away'
    @busy.click    => @clickHandler 'busy'

    @selectorOpen = false

    @setStatus 'online'

  openSelector: ->
    if @selectorOpen
      @canSelect = false
      a.fadeOut 300 for a in [ @offline, @online, @away, @busy ]
    else
      @canSelect = true
      a.fadeIn  300 for a in [ @offline, @online, @away, @busy ]

    @selectorOpen = ! @selectorOpen

  clickHandler: (newS) ->
    @openSelector()
    @aTox.TOX.onlineStatus        newS unless newS is @currentStatus
    @aTox.gui.setUserOnlineStatus newS unless newS is @currentStatus

  setStatus: (newS) ->
    return @status.attr 'class', "aTox-status-selector-current-#{@currentStatus}" if newS is "connected"
    return @status.attr 'class', "aTox-status-selector-current-offline"           if newS is "disconnected"

    @currentStatus = newS
    @status.attr 'class', "aTox-status-selector-current-#{newS}"
