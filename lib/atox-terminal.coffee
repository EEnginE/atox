module.exports =
class Terminal
  constructor: (params) ->
    @event   = params.event
    @initialize()

  initialize: ->
    @event.on 'aTox.add-message', (data) =>
      return unless data.tid is -1
      @process data.msg

    @cmds = [
      {cmd: 'help',      args: 0, desc: 'Prints help message',                                   run:     => @help()                       }
      {cmd: 'exit',      args: 0, desc: 'Closes terminal window',                                run:     => @closeChat @cid               }
      {cmd: 'getChatID', args: 1, desc: 'Print chat ID of chat [a1]',                            run: (p) => @event.emit 'getChatID', p[0] }
      {cmd: 'openChat',  args: 1, desc: 'Opens chat with ID [a1]',                               run: (p) => @openChat  parseInt p[0]      }
      {cmd: 'closeChat', args: 1, desc: 'Closes the chat with ID [a1]',                          run: (p) => @closeChat parseInt p[0]      }
      {cmd: 'setName',   args: 1, desc: 'Set name to [a1]',                                      run: (p) => @setName            p[0]      }
      {cmd: 'setAvatar', args: 1, desc: 'Set avatar to [a1]',                                    run: (p) => @setAvatar          p[0]      }
      {cmd: 'setStatus', args: 1, desc: 'Set status message to [a1]',                            run: (p) => @setStatus          p[0]      }
      {cmd: 'setOnline', args: 1, desc: 'Set online status to [a1]',                             run: (p) => @setOnline          p[0]      }
      {cmd: 'sendMSG',   args: 2, desc: 'Send message [a2] to user [a1]',                        run: (p) => @sendMSG            p[0], p[1]}
      {cmd: 'addFriend', args: 2, desc: 'Send friend request to user ID [a1] with message [a2]', run: (p) => @addFriend          p[0], p[1]}
      {cmd: 'toxDO',     args: 0, desc: 'Run TOX.do',                                            run:     => @toxDO()                      }
      {cmd: 'reqAvatar', args: 0, desc: 'Send a avatar request to all friends',                  run:     => @reqAvatar()                  }
    ]

  help: ->
    @event.emit 'Terminal', 'Commands: (seperator: ", ")'

    for i in @cmds
      @event.emit 'Terminal', "     \"/#{i.cmd}\":  #{i.desc}"

  closeChat: (id)  -> @event.emit "chat-visibility", { cid: id, what: 'hide' }
  openChat:  (id)  -> @event.emit "chat-visibility", { cid: id, what: 'show' }
  setName:   (p)   -> @event.emit "setName",         p
  setAvatar: (p)   -> @event.emit "setAvatar",       p
  setStatus: (p)   -> @event.emit "setStatus",       p
  setOnline: (p)   -> @event.emit "onlineStatus",    { tid: -1, d: p }
  sendMSG:   (f,m) -> @event.emit "sendToFriend",    { tid: f,  d: m }
  addFriend: (a,m) -> @event.emit "addFriend",       { addr: a, msg: m }
  toxDO:           -> @event.emit "toxDO"
  reqAvatar:       -> @event.emit "reqAvatar"

  process: (cmd) ->
    return unless cmd.indexOf('/') == 0
    cmd = cmd.replace('/', '')

    args = cmd.split /,\s+/

    @err "Empty cmd" if args.length == 0
    return               if args.length == 0
    @cmd = args[0]
    args.shift()

    for arg in @cmds
      if arg.cmd.toUpperCase() == @cmd.toUpperCase()
        if args.length < arg.args
          @err "/#{@cmd} requires #{arg.args} arguments (You gave #{args.length})"
          return
        if arg.args == 0
          arg.run()
        else
          arg.run args

        return

    @err "Command /#{@cmd} not found"

  err: (what) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'aTox'
      content: what
    }
