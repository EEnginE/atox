module.exports =
class Terminal
  constructor: (params) ->
    @aTox    = params.aTox

    @cmds = [ #TODO: Test commands
      {cmd: 'help',      args: 0, desc: 'Prints help message',                                   run: (cID)    => @help        cID       }
      {cmd: 'openChat',  args: 1, desc: 'Opens chat with ID [a1]',                               run: (cID, p) => @openChat    p[0]      }
      {cmd: 'closeChat', args: 1, desc: 'Closes the chat with ID [a1]',                          run: (cID, p) => @closeChat   p[0]      }
      {cmd: 'setName',   args: 1, desc: 'Set name to [a1]',                                      run: (cID, p) => @setName     p[0]      }
      {cmd: 'setAvatar', args: 1, desc: 'Set avatar to [a1]',                                    run: (cID, p) => @setAvatar   p[0]      }
      {cmd: 'setStatus', args: 1, desc: 'Set status message to [a1]',                            run: (cID, p) => @setStatus   p[0]      }
      {cmd: 'setOnline', args: 1, desc: 'Set online status to [a1]',                             run: (cID, p) => @setOnline   p[0]      }
      {cmd: 'sendMSG',   args: 2, desc: 'Send message [a2] to user [a1]',                        run: (cID, p) => @sendMSG     p[0], p[1]}
      {cmd: 'sendToGC',  args: 2, desc: 'Send message [a2] to group chat [a1]',                  run: (cID, p) => @sendToGC    p[0], p[1]}
      {cmd: 'addFriend', args: 2, desc: 'Send friend request to user ID [a1] with message [a2]', run: (cID, p) => @addFriend   p[0], p[1]}
      {cmd: 'reqAvatar', args: 0, desc: 'Send a avatar request to all friends',                  run: (cID)    => @reqAvatar()           }
      {cmd: 'addGC',     args: 0, desc: 'Adds a new group chat',                                 run: (cID)    => @addGC()               }
      {cmd: 'invite',    args: 2, desc: 'Invites [a1] to group [a2]',                            run: (cID, p) => @invite      p[0], p[1]}
    ]

  help: (cID) ->
    @inf   {cID: cID, msg: 'Commands: (Strings are encased with "s)'}

    for i in @cmds
      @inf {cID: cID, msg: "     \"/#{i.cmd}\":  #{i.desc}"}

  #FUCKING EVENTS! FIX THIS!
  closeChat: (id)       -> @aTox.gui.chats[parseInt id].closeChat()
  openChat:  (id)       -> @aTox.gui.chats[parseInt id].openChat()
  setName:   (p)        -> @aTox.TOX.setName   p
  setAvatar: (p)        -> @aTox.TOX.setAvatar p
  setStatus: (p)        -> @aTox.TOX.setStatus p
  setOnline: (p)        -> @aTox.TOX.onlineStatus p; @aTox.gui.setUserOnlineStatus p
  sendMSG:   (f, m)     -> @aTox.TOX.sendToFriend      { fID: f,  msg: m }
  sendToGC:  (f, m)     -> @aTox.TOX.sendToGC          { gID: f,  msg: m }
  addFriend: (a, m)     -> @aTox.TOX.sendFriendRequest { addr: a, msg: m }
  reqAvatar:            -> @aTox.TOX.reqAvatar()
  addGC:                -> @aTox.TOX.createGroupChat()
  invite:    (f,g)      -> @aTox.TOX.invite        { fID: f, gID: g }

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
          arg.run data.cID #TODO: Stop sending the message when a command is found
        else
          arg.run data.cID, args

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

  inf: (data) ->
    msg = "<span style='font-style:italic;color:#979797'><b>Info:</b> #{data.msg}</span>"

    data.cID = -1 unless data.cID?

    if data.cID < 0
      @aTox.gui.chatpanel.addMessage {cID: -1, msg: "<p>#{msg}</p>"}
    else
      @aTox.gui.chats[data.cID].processMsg {msg: msg, color: "#ffffff", name: "aTox"}

    @aTox.gui.notify { type: 'inf', name: 'aTox', content: data.msg } if atom.config.get 'aTox.debugNotifications'

  warn: (data) ->
    msg = "<span style='font-style:italic;color:#c19a00'><b>Warning:</b> #{data.msg}</span>"

    data.cID = -1 unless data.cID?

    if data.cID < 0
      @aTox.gui.chatpanel.addMessage {cID: -1, msg: "<p>#{msg}</p>"}
    else
      @aTox.gui.chats[data.cID].processMsg {msg: msg, color: "#ffffff", name: "aTox"}

    @aTox.gui.notify { type: 'warn', name: 'aTox', content: data.msg }

  err: (data) ->
    msg = "<span style='font-style:italic;color:#bc0000'><b>ERROR:</b> #{data.msg}</span>"

    data.cID = -1 unless data.cID?

    if data.cID < 0
      @aTox.gui.chatpanel.addMessage {cID: -1, msg: "<p>#{msg}</p>"}
    else
      @aTox.gui.chats[data.cID].processMsg {msg: msg, color: "#ffffff", name: "aTox"}

    @aTox.gui.notify { type: 'err', name: 'aTox', content: data.msg }
