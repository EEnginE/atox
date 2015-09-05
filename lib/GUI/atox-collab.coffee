CollabGroupProtocol = require '../atox-collabGroupProtocol'
{Range, Point} = require 'atom'

module.exports =
class Collab extends CollabGroupProtocol
  constructor: (params) ->
    @aTox   = params.aTox
    @editor = params.editor
    @name   = params.name
    @disposables = []
    @internalchanges = []
    @externalchanges = []
    @pmutex = true
    @icb = []

    @disposables.push @editor.getBuffer().onDidChange (e) => @internalChange e
    @disposables.push @editor.onDidChangeSelectionRange (e) =>
      @changedSelection e

    @sLines = @editor.getBuffer().getLines()
    @sLineEndings = @editor.getBuffer().lineEndings

    try
      super params
    catch error
      console.log error

  getName: -> @name

  destructor: ->
    for d in @disposables
      d.dispose()

    super()

  internalChange: (e) ->
    if @pmutex and @icb.length > 0
      @internalchanges = @icb.concat(@internalchanges)
      @icb = []

    if (e.originFlag? and e.originFlag) or (e.newRange.originFlag? and e.newRange.originFlag)
      console.log "ignore change"
      return

    {oldRange, newRange, oldText, newText} = e
    oldRange = Range(oldRange.start, oldRange.end)
    newRange = Range(newRange.start, newRange.end)
    newRange.originFlag = true #dirty stuff - don't think about
    normalizeLineEndings = true
    e = {oldRange, newRange, oldText, newText, normalizeLineEndings}
    if @pmutex
      @internalchanges.push e
    else
      @icb.push e
      console.log @icb

  externalChange: (e) ->
    return unless e?
    console.log e

    {oldRange, newRange, oldText, newText} = e
    oldRange = Range(oldRange.start, oldRange.end)
    newRange = Range(newRange.start, newRange.end)
    newRange.originFlag = true #dirty stuff - don't think about
    normalizeLineEndings = true
    e = {oldRange, newRange, oldText, newText, normalizeLineEndings}
    @externalchanges.push e
    return

  changedSelection: (e) ->

  patchLines: ->
    ###Fix pos of external changes
    for ec, i in @externalchanges #Shift
      for e in @externalchanges
        if ec != e and ec.oldRange.compare(e.oldRange) == 1
          @externalchanges[i].oldRange.translate(Point(e.newRange.getRowCount() - e.oldRange.getRowCount(), 0))
          @externalchanges[i].newRange.translate(Point(e.newRange.getRowCount() - e.oldRange.getRowCount(), 0))###

    #Fix pos of internal changes
    for ec, i in @externalchanges
      for ic, j in @internalchanges
        if ic.oldRange.start.row() > ec.oldRange.start.row()
          @internalchanges[j].newRange.translate([ec.newRange.getRowCount() - ec.oldRange.getRowCount(), 0])
          @internalchanges[j].oldRange.translate([ec.newRange.getRowCount() - ec.oldRange.getRowCount(), 0]) #Shift row by 1
        else if ic.oldRange.start.row() is ec.oldRange.start.row() and ic.oldRange.start.column() > ec.oldRange.start.column()
          @internalchanges[j].newRange.translate([ec.newRange.getRowCount() - ec.oldRange.getRowCount(), ec.newRange.end.column() - ec.oldRange.end.column()])
          @internalchanges[j].oldRange.translate([ec.newRange.getRowCount() - ec.oldRange.getRowCount(), ec.newRange.end.column() - ec.oldRange.end.column()])

  applyExternal: ->
    #Concat both and patch local buffer
    for ec in @externalchanges
      console.log ec
      @editor.getBuffer().applyChange(ec, false)
      return

  swap: ->
    oldText = @editor.getText()

    #@editor.displayBuffer.updateAllLines() #doesn't work

    #Combine the two arrays and use @editor.getBuffer().setText()
    newText = ''
    for row in [0 .. @sLines.length - 1]
      newText += (@sLines[row] + @sLineEndings[row])
    #@editor.setText(text) #use function of editor instead

    oldRange = @editor.getBuffer().getRange()
    oldRange.freeze()
    newRange = Range.fromText(oldRange.start, newText)
    newRange.freeze()
    originFlag = true
    changeEvent = Object.freeze({oldRange, newRange, oldText, newText, originFlag})

    @editor.getBuffer().emitter.emit 'will-change', changeEvent

    @editor.getBuffer().lines = @sLines
    @editor.getBuffer().lineEndings = @sLineEndings

    @editor.getBuffer().emitter.emit 'did-change', changeEvent
    @editor.displayBuffer.updateAllScreenLines()

  applyInternal: ->
    #Apply internal changes
    for ic in @internalchanges #maybe have to fix array -> normalizeLineEndings
      @editor.getBuffer().applyChange(ic, true)

  process: ->
    @pmutex = false

    @patchLines()
    @swap()
    @applyExternal()
    @applyInternal()

    changes = @internalchanges.slice(0)
    @internalchanges = []
    @externalchanges = []

    #Save state for next round
    @sLines = @editor.getBuffer().getLines()
    @sLineEndings = @editor.getBuffer().lineEndings
    @pmutex = true

    return changes

  CMD_startSyncing: (changes) ->
    if changes?
      for c in changes
        @externalChange c if c?
    @patchLines()
    @applyExternal()

  CMD_stopSyncing: (data) ->
    if not data?
      return
    @sLines = data.lines if data.lines?
    @sLineEndings = data.lineEndings if data.lineEndings?
    @externalchanges = []

  CMD_getSyncData: ->
    return {"lines": @sLines, "lineEndings": @sLineEndings}

  CMD_process: (changes) ->
    @externalchanges = []
    console.log "External Changes:"
    console.log changes
    if changes?
      for pchanges in changes
        @externalChange(c) for c in pchanges
    @process()
