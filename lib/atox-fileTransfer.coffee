fs = require 'fs'

FileTransferPanel = require './GUI/atox-fileTransfer'
ExtensionResolver = require './atox-extensionResolver'

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

    @inf "#{@role}: New file Transfer", "Path: #{@fullPath}; ID: #{@id.id}"
    console.log @id.id

    @panel = new FileTransferPanel {
      "aTox":     @aTox
      "parent":   this
      "fileType": ExtensionResolver.resolve @name
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
    @inf "#{name} File Transfer", @name
    @aTox.TOX.controlFile {"fID": @id.friend, "fileID": @id.file, "control": ctrl}
    @destructor() if ctrl is 'cancel'

  accept:  -> @sendCTRL 'resume', 'Accepted',
  decline: -> @sendCTRL 'cancel', 'Declined',
  pause:   -> @sendCTRL 'pause',  'Paused',
  resume:  -> @sendCTRL 'resume', 'Resumed',
  cancel:  -> @sendCTRL 'cancel', 'Canceled',


  control: (ctrl, ctrlName) ->
    ctrlName = 'peerPause' if ctrlName is 'pause'
    @panel.setMode ctrlName
    @destructor() if ctrlName is 'cancel'

  chunkRequest: (pos, length) ->
    if length is 0
      @inf "File transfer completed", "Sent file '#{@name}'"
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
      @success "File transfer completed", "Received file '#{@name}'"
      @panel.setMode 'completed'
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

  inf: (title, msg) ->
    @aTox.term.inf {
      "title": title
      "msg":   msg
      "cID":   @id.cID
    }

  success: (title, msg) ->
    @aTox.term.success {
      "title": title
      "msg":   msg
      "cID":   @id.cID
    }
