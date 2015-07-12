{View, TextEditorView} = require 'atom-space-pen-views'

###
 Supported file types: (only visual changes)
  - binary
  - code
  - directory
  - media
  - pdf
  - submodule
  - symlink-directory
  - symlink-file
  - text
  - zip
###

MODES = {
  # Start sending -- waiting for other peer to accept
  "sender": {
    "input":  false
    "bar":    false
    "status": {"cls":  'warning', "text": 'Waiting for accept'}
    "btn1":   {"cls":  'OFF'}
    "btn2":   {"cls":  'error',   "text": 'Cancel', "icon": 'x'}
  }

  # received event -- waiting for user input
  "receiver": {
    "input":  true
    "bar":    false
    "status": {"cls":  'warning', "text": 'Waiting for input'}
    "btn1":   {"cls":  'success', "text": 'Accept',  "icon": 'download'}
    "btn2":   {"cls":  'error',   "text": 'Decline', "icon": 'x'}
  }

  # receiving data
  "resume": {
    "input":  false
    "bar":    true
    "status": {"cls":  'success', "text": 'receiving'}
    "btn1":   {"cls":  'warning', "text": 'Pause',   "icon": 'pause'}
    "btn2":   {"cls":  'error',   "text": 'Cancel',  "icon": 'x'}
  }

  # paused
  "pause": {
    "input":  false
    "bar":    false
    "status": {"cls":  'warning', "text": 'paused'}
    "btn1":   {"cls":  'success', "text": 'Resume',  "icon": 'play'}
    "btn2":   {"cls":  'error',   "text": 'Cancel',  "icon": 'x'}
  }

  # canceled
  "cancel": {
    "input":  false
    "bar":    false
    "status": {"cls":  'error', "text": 'CANCELED'}
    "btn1":   {"cls":  'OFF'}
    "btn2":   {"cls":  'OFF'}
  }
}

# coffeelint: disable=max_line_length

module.exports =
class FileTransferPanel extends View
  @content: (params) ->
    defaultPath = FileTransferPanel.genPath params

    @div        class: 'aTox-FileTransferRoot block', =>
      @label    class: "inline-block icon icon-file-#{params.fileType}", outlet: 'status'
      @label    class: 'inline-block',                                   outlet: 'textLabel'
      @subview  'pathInput', new TextEditorView mini: true, placeholderText: defaultPath
      @progress class: 'inline-block', outlet: 'bar'
      @div      class: 'inline-block btn-group', =>
        @button class: 'btn icon',     outlet: 'btn1'
        @button class: 'btn icon',     outlet: 'btn2'

  initialize: (params) ->
    @aTox     = params.aTox
    @parent   = params.parent
    @fileName = params.name

    @currentValue = 0

    @bar.prop {"max": params.size}
    @barIsActive = false

    @textLabel.text @fileName

    @pathInput.on 'keydown', (e) => @runCMD 'Accept' if e.which is 13
    @btn1.click                  => @runCMD @btn1.text()
    @btn2.click                  => @runCMD @btn2.text()

    @panel = atom.workspace.addBottomPanel {"item": @element}

  destructor: -> @panel.destroy()

  runCMD: (cmd) ->
    switch cmd
      when 'Accept'
        if @pathInput.getText() is ''
          @parent.fullPath = FileTransferPanel.genPath {"name": @fileName}
        else
          @parent.fullPath = @pathInput.getText()
        @parent.accept()

      when 'Decline' then @parent.decline()
      when 'Pause'   then @parent.pause()
      when 'Resume'  then @parent.resume()
      when 'Cancel'  then @parent.cancel()

  setMode: (mode) ->
    throw new Error "Unknown mode '#{mode}'" unless MODES[mode]?

    if MODES[mode].input
      @pathInput.show()
    else
      @pathInput.hide()

    @barIsActive = MODES[mode].bar
    if @barIsActive
      @bar.prop {"value": @currentValue}
    else
      @bar.removeAttr "value"

    @status.removeClass "text-#{i}" for i in ['success', 'info', 'warning', 'error']

    @status.addClass "text-#{MODES[mode].status.cls}"
    @status.text MODES[mode].status.text

    @setBTN "btn1", MODES[mode].btn1
    @setBTN "btn2", MODES[mode].btn2

  setBTN: (btn, mode) ->
    this[btn].removeClass()

    if mode.cls is 'OFF'
      this[btn].hide()
    else
      this[btn].show()

    this[btn].addClass "btn btn-#{mode.cls} icon icon-#{mode.icon}"
    this[btn].text     mode.text

  setValue: (value) ->
    @currentValue = value
    @bar.prop {"value": @currentValue} if @barIsActive

  @genPath: (params) ->
    paths      = atom.project.getPaths()
    path       = "/#{params.name}"
    currEditor = atom.workspace.getActiveTextEditor()

    if currEditor?
      currPath        = currEditor.getPath()
      currProjectPath = atom.project.relativizePath(currPath)[0]
      if currProjectPath?
        path = currProjectPath + path
      else
        throw new Error "No project open" unless paths?
        path = paths[0] + path
    else
      throw new Error "No project open" unless paths?
      path = paths[0] + path
