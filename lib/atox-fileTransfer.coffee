fs = require 'fs'

FileTransferPanel = require './GUI/atox-fileTransfer'

# coffeelint: disable=max_line_length

module.exports=
class FileTransfer
  constructor: (params) ->
    @aTox     = params.aTox
    @role     = params.role # 'sender' or 'receiver'
    @name     = params.name
    @fullPath = params.fullPath
    @kind     = params.kind
    @size     = params.size
    @id       = params.id
    @doneCB   = params.doneCB

    @fullPath = "./#{@name}" unless @fullPath?

    switch @role
      when 'sender'   then fs.open @fullPath, 'r', (err, fd) => @fd = fd unless @checkErr err
      when 'receiver' then fs.open @fullPath, 'w', (err, fd) => @fd = fd unless @checkErr err
      else throw new Error "Unsupported role: '#{role}'"

    @aTox.term.inf {"title": "#{@role}: New file Transfer", "msg": "Path: #{@fullPath}; ID: #{@id.id}"}
    console.log @id.id

    @panel = new FileTransferPanel {
      "aTox":     @aTox
      "parent":   this
      "fileType": "code" # TODO: check file extensions, etc.
      "name":     @name
      "size":     @size
    }

    @panel.setMode @role

  destructor: ->
    fs.closeSync @fd
    @fd = null
    @panel.destructor()
    @doneCB()

  sendCTRL: (ctrl, name) ->
    @panel.setMode ctrl
    @aTox.term.inf {"title": "#{name} File Transfer", "msg": @name}
    @aTox.TOX.controlFile {"fID": @id.friend, "fileID": @id.file, "control": ctrl}
    @destructor() if ctrl is 'cancle'

  accept:  -> @sendCTRL 'resume', 'Accepted',
  decline: -> @sendCTRL 'cancle', 'Declined',
  pause:   -> @sendCTRL 'pause',  'Paused',
  resume:  -> @sendCTRL 'resume', 'Resumed',
  cancle:  -> @sendCTRL 'cancle', 'Canceled',


  control: (ctrl, ctrlName) ->
    @panel.setMode ctrlName
    @destructor() if ctrlName is 'cancle'

  chunkRequest: (pos, length) ->
    if length is 0
      @aTox.term.inf {"title": "File transfer completed", "msg": "Sent file '#{@name}'"}
      @destructor()
      return

    throw new Error "Can not recieve chunk requests in receiver mode!" if @role is 'receiver'
    throw new Error "File descriptor is null"                          unless @fd?

    data = new Buffer length

    fs.read @fd, data, 0, length, pos, (err, bRead, buffer) =>
      throw new Error "File read error" if err
      @panel.setValue pos + length
      @aTox.TOX.sendFileChunk {"id": @id, "data": buffer, "pos": pos}

  chunk: (pos, data, final) ->
    if final is true
      @aTox.term.inf {"title": "File transfer completed", "msg": "Received file '#{@name}'"}
      @destructor()
      return

    throw new Error "Can not recieve file cunks in sender mode!" if @role is 'sender'
    throw new Error "File descriptor is null"                    unless @fd?

    fs.write @fd, data, 0, data.length, pos, (err) =>
      throw new Error "File read error" if err
      @panel.setValue pos + data.length

  checkErr: (err) ->
    if err
      console.log err
