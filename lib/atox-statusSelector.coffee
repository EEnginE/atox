{View, $} = require 'atom-space-pen-views'

module.exports =
class StatusSelector extends View
  @content: (win, event) ->
    ID    = "aTox-#{win}-status-selector"
    CLASS = "aTox-status-selector"

    @div id: "#{ID}", class: "#{CLASS}", =>
      @div id: "#{ID}-offline", class: "#{CLASS}-offline",        outlet: 'offline'
      @div id: "#{ID}-online",  class: "#{CLASS}-online",         outlet: 'online'
      @div id: "#{ID}-away",    class: "#{CLASS}-away",           outlet: 'away'
      @div id: "#{ID}-busy",    class: "#{CLASS}-busy",           outlet: 'busy'
      @div id: "#{ID}-current", class: "#{CLASS}-current-online", outlet: 'status'

  initialize: (win, event) ->
    @status.click  => @openSelector()
    @offline.click => @clickHandler 'offline'
    @online.click  => @clickHandler 'online'
    @away.click    => @clickHandler 'away'
    @busy.click    => @clickHandler 'busy'

    @selectorOpen = false
    @event        = event

    @event.on 'onlineStatus', (newS) => @setStatus newS.d
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
    @event.emit 'onlineStatus', {tid: -1, d: newS} if newS != @currentStatus

  setStatus: (newS) ->
    return @status.attr 'class', "aTox-status-selector-current-#{@currentStatus}" if newS is "connected"
    return @status.attr 'class', "aTox-status-selector-current-offline"           if newS is "disconnected"

    @currentStatus = newS
    @status.attr 'class', "aTox-status-selector-current-#{newS}"
