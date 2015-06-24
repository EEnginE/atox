
newlineRegex: /\r\n|\n|\r/g

module.exports =
class Collab
  constructor: (params) ->
    @aTox   = params.aTox
    @editor = params.editor
    @disposables = []
    @internalchanges = []
    @externalchanges = []
    @pmutex = true
    @icb = []

    @disposables.push @editor.onDidInsertText (e) => @internalChange e
    @disposables.push @editor.onDidChangeSelectionRange (e) =>
      @changedSelection e

    @sLines = @editor.getBuffer().getLines()
    @sLineEndings = @editor.getBuffer().lineEndings

  destructor: ->
    for d in @disposables
      d.dispose()

  internalChange: (e) ->
    if @pmutex and @icb.length > 0
      @internalchanges = @icb.concat(@internalchanges)
      @icb = []
    for pos in @editor.getCursorBufferPositions()
      if @pmutex
        @internalchanges.push {'pos': pos, 'text': e.text}
      else
        @icb.push {'pos': pos, 'text': e.text}

  externalChange: (e) ->
    lineStartIndex = 0
    while result = newlineRegex.exec(e.text)
      line = e.text[lineStartIndex...result.index]
      ending = result[0]
      @externalchanges.push {'pos': e.pos, 'text': line, 'nline': ending}
      lineStartIndex = newlineRegex.lastIndex
    @externalchanges.push {'pos': e.pos, 'text': line, 'nline': false}
    return

    #Alternate (old) code
    #for i in [0 .. e.text.length]
    for c, i in e.text
      #c = e.text[i]
      if c is '\n' or (c is '\r' and e.text[i+1] != '\n')
        @externalchanges.push {'pos': e.pos, 'text': e.text.slice(0, c)
          'nline': c}
        @externalChange {'pos': e.pos, 'text': e.text.slice(c + 1)}
        return
      else if c is '\r'
        @externalchanges.push {'pos': e.pos, 'text': e.text.slice(0, c)
          'nline': e.text.slice(c, c + 2)}
        @externalChange {'pos': e.pos, 'text': e.text.slice(c + 2)}
        return

    @externalchanges.push {'pos': e.pos, 'text': e.text}

  changedSelection: (e) ->
    console.log e.newBufferRange
    console.log e.selection.getText()

  process: ->
    @pmutex = false
    #Fix pos of external changes
    rshift = 0
    for ec, i in @externalchanges #Shift
      @externalchanges[i].pos[0] += rshift
      if ec.nline? and ec.nline is not false
        rshift++

    #Fix pos of internal changes
    for ec, i in @externalchanges
      for ic, j in @internalchanges
        if ec.nline? and ec.nline is not false and ic.pos.row() >= ec.pos[0]
          @internalchanges[j].pos.translate([1, 0]) #Shift row by 1
        else if ic.pos.row() is ec.pos[0] and ic.pos.column() > ec.pos[1]
          @internalchanges[j].pos.translate([0, ic.pos.column() - ec.pos[1]])

    #Concat both and patch local buffer
    for ec in @externalchanges
      if ec.nline? and ec.nline is not false
        @sLines[ec.pos[0]] = @sLines[ec.pos[0]].slice(0, ec.pos[1]) + ec.text
        @sLines.splice(ec.pos[0] + 1, 0, @sLines[ec.pos[0]].slice(ec.pos[1]))
        @sLineEndings.splice(ec.pos[0], 0, ec.nline)
      else
        @sLines[ec.pos[0]] = @sLines[ec.pos[0]].slice(0, ec.pos[1]) + ec.text +
          @sLines[ec.pos[0]].slice(ec.pos[1])

    @editor.getBuffer().lines = @sLines
    @editor.getBuffer().lineEndings = @sLineEndings
    #Apply internal changes
    for ic in @internalchanges
      @editor.getBuffer().insert(ic.pos, ic.text)

    changes = @internalchanges.slice(0)
    @internalchanges = []
    @externalchanges = []

    #Save state for next round
    @sLines = @editor.getBuffer().getLines()
    @sLineEndings = @editor.getBuffer().lineEndings
    @pmutex = true

    for c, i in changes
      changes[i].pos = changes[i].pos.toArray()

    return changes
