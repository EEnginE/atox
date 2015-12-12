{View} = require 'atom-space-pen-views'

module.exports =
class ToxNotFound extends View
  @content: ->
    @div class: 'aTox-Form1-root', =>
      @h1 "TOX not found"
      @div class: 'block form', =>
        @h2  "Please install libtoxcore"
        @div class: 'block', "aTox requires the c library libtoxcore to function."
        @div class: 'block', "Most Linux Distributions should provide (experimental) toxcore binaries. You can also install toxcore from source:"
        @a "https://github.com/irungentoo/toxcore/blob/master/INSTALL.md"
      @div   outlet: 'btn2', class: 'btn2 btn btn-lg btn-info',  'Close'

  initialize: (params) ->
    @callback = ->

    @panel = atom.workspace.addModalPanel {item: this, visible: false}

    @btn2.click =>
      @panel.hide()
      @callback()

  deactivate: -> @panel.destroy()

  show: (cb) ->
    @callback = cb
    @panel.show()
