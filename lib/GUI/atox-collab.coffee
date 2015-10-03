CollabGroupProtocol = require '../atox-collabGroupProtocol'
{Range, Point} = require 'atom'
newlineRegex: /\r\n|\n|\r/g

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
    @diffs = []

    @disposables.push @editor.getBuffer().onDidChange (e) => @internalChange e
    @disposables.push @editor.onDidChangeSelectionRange (e) =>
      @changedSelection e

    @sLines = @editor.getBuffer().getLines()
    @sLineEndings = @editor.getBuffer().lineEndings
    @offsetIndex = @editor.getBuffer().offsetIndex

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

    if e.originFlag? and e.originFlag
      console.log "ignore change"
      return

    if @pmutex
      @internalchanges.push e
    else
      @icb.push e

  externalChange: (e) ->
    return unless e?
    @externalchanges.push e

  generateDiff: ->
    #TODO: implement this
    console.log "Generate Diff"
    @diffs = []

  changedSelection: (e) ->

  patchLines: ->
    #Fix pos of internal changes
    for ec, i in @externalchanges
      for ic, j in @internalchanges
        if ic.oldRange.start.row > ec.oldRange.start.row
          @internalchanges[j].newRange.translate([ec.newRange.row - ec.oldRange.row, 0])
          @internalchanges[j].oldRange.translate([ec.newRange.row - ec.oldRange.row, 0]) #Shift row by 1
        else if ic.oldRange.start.row is ec.oldRange.start.row and ic.oldRange.start.column > ec.oldRange.start.column
          @internalchanges[j].newRange.translate([ec.newRange.row - ec.oldRange.row, ec.newRange.end.column - ec.oldRange.end.column])
          @internalchanges[j].oldRange.translate([ec.newRange.row - ec.oldRange.row, ec.newRange.end.column - ec.oldRange.end.column])

  applyExternal: ->
    for ec in @externalchanges
      @applyChange(ec, false)

  applyInternal: ->
    for ic in @internalchanges
      @applyChange(ic, true)

  setBuffer: ->
    for change in @diffs
      @editor.getBuffer().emitter.emit 'will-change', change

    @editor.getBuffer().lines = @sLines
    @editor.getBuffer().lineEndings = @sLineEndings
    @editor.getBuffer().offsetIndex = @offsetIndex

    for change in @diffs
      @editor.getBuffer().emitter.emit 'did-change', change

  applyChange: (change, skipUndo) ->
    {oldRange, newRange, oldText, newText, normalizeLineEndings} = change
    oldRange.freeze() if oldRange.freeze()?
    newRange.freeze() if newRange.freeze()?
    @cachedText = null

    startRow = oldRange.start.row
    endRow = oldRange.end.row
    rowCount = endRow - startRow + 1
    oldExtent = oldRange.getExtent()
    newExtent = newRange.getExtent()

    # Determine how to normalize the line endings of inserted text if enabled
    if normalizeLineEndings
      preferredLineEnding = @editor.getBuffer().getPreferredLineEnding()
      normalizedEnding = @preferredLineEnding ? @sLineEndings[startRow]
      unless normalizedEnding
        if startRow > 0
          normalizedEnding = @sLineEndings[startRow - 1]
        else
          normalizedEnding = null

    # Split inserted text into lines and line endings
    lines = []
    lineEndings = []
    lineStartIndex = 0
    normalizedNewText = ""
    while result = newlineRegex.exec(newText)
      line = newText[lineStartIndex...result.index]
      ending = normalizedEnding ? result[0]
      lines.push(line)
      lineEndings.push(ending)
      normalizedNewText += line + ending
      lineStartIndex = newlineRegex.lastIndex

    lastLine = newText[lineStartIndex..]
    lines.push(lastLine)
    lineEndings.push('')
    normalizedNewText += lastLine

    newText = normalizedNewText
    #Deactivated change event
    #changeEvent = Object.freeze({oldRange, newRange, oldText, newText})
    #@emitter.emit 'will-change', changeEvent

    # Update first and last line so replacement preserves existing prefix and suffix of oldRange
    prefix = @sLines[startRow][0...oldRange.start.column]
    lines[0] = prefix + lines[0]
    suffix = @sLines[endRow][oldRange.end.column...]
    lastIndex = lines.length - 1
    lines[lastIndex] += suffix
    lastLineEnding = @sLineEndings[endRow]
    lastLineEnding = normalizedEnding if lastLineEnding isnt '' and normalizedEnding?
    lineEndings[lastIndex] = lastLineEnding

    # Replace lines in oldRange with new lines
    spliceArray(@lines, startRow, rowCount, lines)
    spliceArray(@lineEndings, startRow, rowCount, lineEndings)

    # Update the offset index for position <-> character offset translation
    offsets = lines.map (line, index) ->
      {rows: 1, characters: line.length + lineEndings[index].length}
    @offsetIndex.spliceArray('rows', startRow, rowCount, offsets)

    #@markerStore?.splice(oldRange.start, oldRange.getExtent(), newRange.getExtent())
    #@history?.pushChange(change) unless skipUndo

    #@conflict = false if @conflict and !@isModified()
    #@scheduleModifiedEvents()

    #@changeCount++
    #Deactivated emit of change event
    #@emitter.emit 'did-change', changeEvent
    #@emit 'changed', changeEvent if Grim.includeDeprecatedAPIs

  process: ->
    @pmutex = false

    @patchLines()
    @applyExternal()
    @applyInternal()
    @generateDiff()
    @setBuffer()

    changes = @internalchanges.slice(0)
    @internalchanges = []
    @externalchanges = []

    #Save state for next round
    #@sLines = @editor.getBuffer().getLines()
    #@sLineEndings = @editor.getBuffer().lineEndings

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
    @offsetIndex = data.offsetIndex if data.offsetIndex?
    @externalchanges = []

  CMD_getSyncData: ->
    return {"lines": @sLines, "lineEndings": @sLineEndings, "offsetIndex": @offsetIndex}

  CMD_process: (changes) ->
    @externalchanges = []
    console.log "External Changes:"
    console.log changes
    if changes?
      for pchanges in changes
        @externalChange(c) for c in pchanges
    @process()
