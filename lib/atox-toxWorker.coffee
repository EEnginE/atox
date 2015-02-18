toxcore = require 'toxcore'

module.exports =
class ToxWorker
  constructor: (event) ->
    @event = event

  startup: ->

    @TOX = new toxcore.Tox

    temp = @TOX.checkHandle (err) =>
      @event.emit 'notify', {
        type: 'error'
        name: "TOX base"
        content: 'Failed to lead tox'
      }

    @event.emit 'notify', {
      type: 'inf'
      name: temp
      content: 'Bla'
    }

    #@TOX.bootstrapFromAddressSync '23.226.230.47', 33445, 'A09162D68618E742FFBCA1C2C70385E6679604B2D80EA6E84AD0996A1AC8A074'
    #@TOX.bootstrapFromAddressSync '104.219.184.206', 443, '8CD087E31C67568103E8C2A28653337E90E6B8EDA0D765D57C6B5172B4F1F04C'

    @event.emit 'notify', {
      type: 'inf'
      name: process.env.HOME
      content: 'Bla'
    }

    @TOX.start()
