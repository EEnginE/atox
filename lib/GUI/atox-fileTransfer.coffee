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

MODES =
  ###
   Supported button names
    - Accept
    - Decline
    - Cancel
    - Pasue
    - Resume
    - Close
  ###

  # Start sending -- waiting for other peer to accept
  "sender":
    "input":  false
    "bar":    false
    "status": "cls": 'warning', "text": 'Waiting for accept'
    "btn1":   "cls": 'OFF'
    "btn2":   "cls": 'error',   "text": 'Cancel', "icon": 'x'

  # received event -- waiting for user input
  "receiver":
    "input":  true
    "bar":    false
    "status": "cls": 'warning', "text": 'Filesize: %s'
    "btn1":   "cls": 'success', "text": 'Accept',  "icon": 'cloud-download'
    "btn2":   "cls": 'error',   "text": 'Decline', "icon": 'x'

  # receiving data
  "resume":
    "input":  false
    "bar":    true
    "status": "cls": 'success', "text": 'receiving (%p of %s)'
    "btn1":   "cls": 'warning', "text": 'Pause',   "icon": 'playback-pause'
    "btn2":   "cls": 'error',   "text": 'Cancel',  "icon": 'x'

  # paused
  "pause":
    "input":  false
    "bar":    false
    "status": "cls": 'warning', "text": 'paused (%p of %s)'
    "btn1":   "cls": 'success', "text": 'Resume',  "icon": 'playback-play'
    "btn2":   "cls": 'error',   "text": 'Cancel',  "icon": 'x'

  # The OTHER peer has paused => we can't resume
  "peerPause":
    "input":  false
    "bar":    false
    "status": "cls": 'warning', "text": 'other peer paused (%p of %s)'
    "btn1":   "cls": 'OFF'
    "btn2":   "cls": 'error',   "text": 'Cancel',  "icon": 'x'

  # canceled
  "cancel":
    "input":  false
    "bar":    false
    "status": "cls": 'error',   "text": 'CANCELED'
    "btn1":   "cls": 'OFF'
    "btn2":   "cls": 'error',   "text": 'Close'

  "completed":
    "input":  false
    "bar":    true
    "status": "cls": 'success', "text": 'Completed'
    "btn1":   "cls": 'OFF'
    "btn2":   "cls": 'success', "text": 'Close'

module.exports =
class FileTransferPanel extends View
  @content: (params) ->
    defaultPath = FileTransferPanel.genPath params

    @div        class: 'aTox-FileTransferRoot block', =>
      @div      class: 'inline-block', outlet: 'heightFix' # Height will be set to btn height
      @label    class: "inline-block icon icon-file-#{params.fileType}", outlet: 'textLabel'
      @subview  'pathInput', new TextEditorView mini: true, placeholderText: defaultPath
      @progress class: 'inline-block', outlet: 'bar'
      @label    class: 'inline-block', outlet: 'status'
      @div      class: 'inline-block btn-group', =>
        @button class: 'btn icon',     outlet: 'btn1'
        @button class: 'btn icon',     outlet: 'btn2'
      @div      class: 'inline-block' # Margin fix

  initialize: (params) ->
    @aTox     = params.aTox
    @parent   = params.parent
    @fileName = params.name
    @size     = params.size

    tSize = @size
    for i in ['B', 'kiB', 'MiB', 'GiB', 'TiB']
      @sizeSTR = "#{tSize.toFixed 2} #{i}"
      break if tSize < 1024
      tSize /= 1024

    @currentValue = 0

    @bar.prop {"max": params.size}
    @barIsActive = false

    @pathInput.addClass 'inline-block'

    @textLabel.text @fileName

    @pathInput.on 'keydown', (e) => @runCMD 'Accept' if e.which is 13
    @btn1.click                  => @runCMD @btn1.text()
    @btn2.click                  => @runCMD @btn2.text()

    @panel = atom.workspace.addBottomPanel {"item": @element}

    @heightFix.height @pathInput.height()

  destructor: -> @parent = null

  runCMD: (cmd) ->
    switch cmd
      when 'Accept'
        return if @parent is null
        if @pathInput.getText() is ''
          @parent.fullPath = FileTransferPanel.genPath {"name": @fileName}
        else
          @parent.fullPath = @pathInput.getText()
        @parent.accept()

      when 'Decline' then @parent.decline() unless @parent is null
      when 'Pause'   then @parent.pause()   unless @parent is null
      when 'Resume'  then @parent.resume()  unless @parent is null
      when 'Cancel'  then @parent.cancel()  unless @parent is null
      when 'Close'   then @panel.destroy()

  setMode: (mode) ->
    throw new Error "Unknown mode '#{mode}'" unless MODES[mode]?

    if MODES[mode].input
      @pathInput.show()
      @bar.hide()
    else
      @pathInput.hide()
      @bar.show()

    @barIsActive = MODES[mode].bar
    if @barIsActive
      @bar.prop {"value": @currentValue}
    else
      @bar.removeAttr "value"

    @status.removeClass "text-#{i}" for i in ['success', 'info', 'warning', 'error']

    @status.addClass "text-#{MODES[mode].status.cls}"
    @status.prop {"rawText": MODES[mode].status.text}
    @updateStatusText()

    @setBTN "btn1", MODES[mode].btn1
    @setBTN "btn2", MODES[mode].btn2

  updateStatusText: ->
    text = @status.prop 'rawText'
    text = text.replace /%s/g, @sizeSTR
    text = text.replace /%p/g, "#{Math.floor (@currentValue / @size) * 100}%"
    @status.text text

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
    @updateStatusText()

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
