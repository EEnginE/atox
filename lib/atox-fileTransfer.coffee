fs = require 'fs'
buffertools = require 'buffertools'

FileTransferPanel = require './GUI/atox-fileTransfer'
ExtensionResolver = require './atox-extensionResolver'

buffertools.extend()

class DummyPanel
  destructor: ->
  setMode:    ->
  setValue:   ->

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
    @fd       = params.fd # Sending ONLY

    @DATA_KIND   = @aTox.TOX.consts.TOX_FILE_KIND_DATA
    @AVATAR_KIND = @aTox.TOX.consts.TOX_FILE_KIND_AVATAR
    @friend      = @aTox.TOX.friends[@id.friend]

    @fullPath = "./#{@name}" unless @fullPath?

    @id.idHex = @id.id.toHex().toString().toUpperCase()

    switch @role
      when 'sender'   then throw new Error "No file descriptor provided" unless @fd?
      when 'receiver'
        fs.close @fd if @fd?
        @fullPath = @friend.genAvatarPath @id.idHex if @kind is @AVATAR_KIND
      else throw new Error "Unsupported role: '#{role}'"

    if @kind is @AVATAR_KIND
      @panel = new DummyPanel
      if @role is 'receiver'
        if @friend.isAvatarUpTpDate @id.idHex
          @friend.setAvatar         @id.idHex
          return @cancel()

        @accept()
    else
      @panel = new FileTransferPanel {
        "aTox":     @aTox
        "parent":   this
        "fileType": ExtensionResolver.resolve @name
        "name":     @name
        "size":     @size
        "role":     @role
      }

      @panel.setMode @role
      @inf "#{@role}: New file Transfer", @name

  destructor: ->
    fs.closeSync @fd if @fd?
    @fd = null
    @panel.destructor()
    @doneCB()

  sendCTRL: (ctrl, name) ->
    if ctrl is 'resume' and not @fd?
      return fs.open @fullPath, 'w+', (err, fd) =>
        unless @checkErr err
          @fd = fd
          @sendCTRL ctrl, name
    @panel.setMode ctrl
    @inf "#{name} File Transfer", @name
    @aTox.TOX.controlFile {"fID": @id.friend, "fileID": @id.file, "control": ctrl}
    @destructor() if ctrl is 'cancel'

  accept:  -> @sendCTRL 'resume', 'Accepted'
  decline: -> @sendCTRL 'cancel', 'Declined'
  pause:   -> @sendCTRL 'pause',  'Paused'
  resume:  -> @sendCTRL 'resume', 'Resumed'
  cancel:  -> @sendCTRL 'cancel', 'Canceled'


  control: (ctrl, ctrlName) ->
    ctrlName = 'peerPause' if ctrlName is 'pause'
    @panel.setMode ctrlName
    @destructor() if ctrlName is 'cancel'

  chunkRequest: (pos, length) ->
    if length is 0
      @inf "File transfer completed", "Sent file '#{@name}'"
      @panel.setMode 'completed'
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
      @friend.setAvatar @id.idHex if @kind is @AVATAR_KIND
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
    return if @kind is @AVATAR_KIND
    @aTox.term.inf {
      "title": title
      "msg":   msg
      "cID":   @id.cID
    }

  success: (title, msg) ->
    return if @kind is @AVATAR_KIND
    @aTox.term.success {
      "title": title
      "msg":   msg
      "cID":   @id.cID
    }
