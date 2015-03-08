module.exports =
class Terminal
  constructor: (params) ->
    @event   = params.event

  initialize: ->
    @event.on 'aTox.add-message', (data) =>
      return unless data.tid is -1
      @process {cid: data.cid, cmd: data.msg}

    @cmds = [ #TODO: Test commands
      {cmd: 'help',      args: 0, desc: 'Prints help message',                                   run: (cid)    => @help      cid                                  }
      {cmd: 'exit',      args: 0, desc: 'Closes terminal window',                                run: (cid)    => @closeChat cid, @cid                            }
      {cmd: 'getChatID', args: 1, desc: 'Print chat ID of chat [a1]',                            run: (cid, p) => @event.emit 'getChatID', {cid: cid, name: p[0]} }
      {cmd: 'openChat',  args: 1, desc: 'Opens chat with ID [a1]',                               run: (cid, p) => @openChat  cid, parseInt p[0]                   }
      {cmd: 'closeChat', args: 1, desc: 'Closes the chat with ID [a1]',                          run: (cid, p) => @closeChat cid, parseInt p[0]                   }
      {cmd: 'setName',   args: 1, desc: 'Set name to [a1]',                                      run: (cid, p) => @setName   cid,          p[0]                   }
      {cmd: 'setAvatar', args: 1, desc: 'Set avatar to [a1]',                                    run: (cid, p) => @setAvatar cid,          p[0]                   }
      {cmd: 'setStatus', args: 1, desc: 'Set status message to [a1]',                            run: (cid, p) => @setStatus cid,          p[0]                   }
      {cmd: 'setOnline', args: 1, desc: 'Set online status to [a1]',                             run: (cid, p) => @setOnline cid,          p[0]                   }
      {cmd: 'sendMSG',   args: 2, desc: 'Send message [a2] to user [a1]',                        run: (cid, p) => @sendMSG   cid,          p[0], p[1]             }
      {cmd: 'addFriend', args: 2, desc: 'Send friend request to user ID [a1] with message [a2]', run: (cid, p) => @addFriend cid,          p[0], p[1]             }
      {cmd: 'toxDO',     args: 0, desc: 'Run TOX.do',                                            run: (cid)    => @toxDO                                          }
      {cmd: 'reqAvatar', args: 0, desc: 'Send a avatar request to all friends',                  run: (cid)    => @reqAvatar                                      }
      {cmd: 'addGC',     args: 0, desc: 'Adds a new group chat',                                 run: (cid)    => @addGC     cid                                  }
      {cmd: 'invite',    args: 2, desc: 'Invites [a1] to group [a2]',                            run: (cid, p) => @invite    cid, p[0], p[1]                      }
      {cmd: 'peerInfo',  args: 2, desc: 'Get info about peer [a1] in group [a2]',                run: (cid, p) => @peerInfo  cid, p[0], p[1]                      }
      {cmd: 'showAll',   args: 0, desc: 'Makes ALL chats visible',                               run: (cid)    => @showAll   cid}
    ]

  help: (cid) ->
    @event.emit 'Terminal', {cid: cid, msg: 'Commands: (Strings are encased with "s)'}

    for i in @cmds
      @event.emit 'Terminal', {cid: cid, msg: "     \"/#{i.cmd}\":  #{i.desc}"}

  closeChat: (cid, id)  -> @event.emit "chat-visibility", { scid: cid, cid: id, what: 'hide' }
  openChat:  (cid, id)  -> @event.emit "chat-visibility", { scid: cid, cid: id, what: 'show' }
  setName:   (cid, p)   -> @event.emit "setName",         { cid: cid, p: p}
  setAvatar: (cid, p)   -> @event.emit "setAvatar",       { cid: cid, p: p}
  setStatus: (cid, p)   -> @event.emit "setStatus",       { cid: cid, p: p}
  setOnline: (cid, p)   -> @event.emit "onlineStatus",    { cid: cid, tid: -1, d: p }
  sendMSG:   (cid, f,m) -> @event.emit "sendToFriend",    { cid: cid, tid: f,  d: m }
  addFriend: (cid, a,m) -> @event.emit "addFriend",       { cid: cid, addr: a, msg: m }
  toxDO:                -> @event.emit "toxDO"
  reqAvatar:            -> @event.emit "reqAvatar"
  addGC:     (cid)      -> @event.emit "addGroupChat",    { cid: cid }
  invite:    (cid, f,g) -> @event.emit "invite",          { cid: cid, friend: f, gNum: g }
  peerInfo:  (cid, p,g) -> @event.emit "getPeerInfo",     { cid: cid, gNum: g, peer: p }
  showAll:   (cid)      -> @event.emit "showAll",         { cid: cid }

  process: (data) ->
    cmd = data.cmd
    return unless cmd.indexOf('/') == 0
    cmd = cmd.replace('/', '')

    args = @handleArgs cmd

    @err "Empty cmd" if args.length == 0
    return           if args.length == 0
    @cmd = args[0]
    args.shift()

    for arg in @cmds
      if arg.cmd.toUpperCase() == @cmd.toUpperCase()
        if args.length < arg.args
          @err "/#{@cmd} requires #{arg.args} arguments (You gave #{args.length})"
          return
        if arg.args == 0
          arg.run data.cid #TODO: Stop sending the message when a command is found
        else
          arg.run data.cid, args

        return

    @err "Command /#{@cmd} not found"

  handleArgs: (args) ->
    args = args.split /\"/
    if args.length > 1
      for i in [0...args.length] by 1
        a = -1
        if i != 0 and i % 2 != 0
          a = args[i-1].split /\s+/
          a = a.concat(args[i].replace(/\"/, /''/).split(/\s+/).join(" "))
        else if i == args.length-1
          a = args[i].split /\s+/
        if a != -1
          if argsTemp?
            argsTemp = argsTemp.concat(a)
          else
            argsTemp = a
      i = 0
      x = argsTemp.length
      while i < x
        if(argsTemp[i].length == 0)
          argsTemp.splice(i, 1)
          x-=1
        else
          i += 1
      args = argsTemp
    else
      args = args.join()
      args = args.split /\s+/

    return args;

  err: (msg) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'aTox'
      content: msg
    }
