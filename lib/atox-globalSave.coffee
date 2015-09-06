fs   = require 'fs'
CSON = require 'season'

module.exports =
  class GlobalSave
    constructor: (params) ->
      @aTox = params.aTox
      @data = null
      @filePath = "#{atom.getConfigDirPath()}/#{params.name}"

      @afterInit = []
      @isInit    = false

      if fs.existsSync @filePath
        @readFile  => i() for i in @afterInit
      else
        @writeFile => i() for i in @afterInit

      watcherCB = (evt) =>
        console.log evt
        return unless @watcher
        if evt is 'rename'
          @watcher.close
          @watcher = null
          return @aTox.term.warn {
            'title':  'Global config file renamed'
            'msg':    "The global aTox config file #{@filePath} was renamed / removed. Some text editors may trigger such events."
            'buttons': [
              {
                'text': 'Restart watching'
                'onDidClick': =>
                  unless fs.existsSync @filePath
                    return @aTox.term.err {'title': 'File does not exist', 'msg': @filePath}
                  @watcher = fs.watch @filePath, watcherCB
                  @readFile()
                  @aTox.term.success {'title': 'Restarted file watching'}
              }
            ]
          }

        @readFile()

      @watcher = fs.watch @filePath, watcherCB

    deactivate: ->
      @watcher.close() if @watcher
      @writeFileSync()

    readFile: (cb) ->
      unless fs.existsSync @filePath
        return @aTox.term.err {
          'title': "Internal global save error"
          'msg':   "#{@filePath} does not exist!"
        }

      CSON.readFile @filePath, (err, dataSTR) =>
        throw err if err
        @data = dataSTR
        cb() if cb

    writeFile: (cb) -> CSON.writeFile     @filePath, @data
    writeFileSync:  -> fs.writeFileSync @filePath, CSON.stringify @data

    exists: (id)      -> @data[id] isnt null
    get:    (id)      -> @data[id]
    set:    (id, val) -> @data[id] = val
    setBuf: (id, val) -> @data[id] = val.toString 'base64'; @writeFile
    getBuf: (id)      ->
      return null unless @data[id]
      new Buffer @data[id], 'base64'

    onInitDone: (cb) ->
      throw new Error "Callback is undefined" unless cb
      return cb() if @data
      @afterInit.push cb
