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
      {command: 'help',      minArgs: 0, description: 'Prints help message',                                           run:     => @help()}
      {command: 'exit',      minArgs: 0, description: 'Closes terminal window',                                        run:     => @closeChat @cid}
      {command: 'getChatID', minArgs: 1, description: 'Print chat ID of chat [arg1]',                                  run: (p) => @event.emit 'getChatID', p[0]}
      {command: 'openChat',  minArgs: 1, description: 'Opens chat with ID [arg1]',                                     run: (p) => @openChat  parseInt p[0]}
      {command: 'closeChat', minArgs: 1, description: 'Closes the chat with ID [arg1]',                                run: (p) => @closeChat parseInt p[0]}
      {command: 'setName',   minArgs: 1, description: 'Set name to [arg1]',                                            run: (p) => @setName            p[0]}
      {command: 'setAvatar', minArgs: 1, description: 'Set avatar to [arg1]',                                          run: (p) => @setAvatar          p[0]}
      {command: 'setStatus', minArgs: 1, description: 'Set status message to [arg1]',                                  run: (p) => @setStatus          p[0]}
      {command: 'setOnline', minArgs: 1, description: 'Set online status to [arg1]',                                   run: (p) => @setOnline          p[0]}
      {command: 'sendMSG',   minArgs: 2, description: 'Send message [arg2] to user [arg1]',                            run: (p) => @sendMSG            p[0], p[1]}
      {command: 'addFriend', minArgs: 2, description: 'Send friend request to user ID [arg1] with message [args2]',    run: (p) => @addFriend          p[0], p[1]}
      {command: 'toxDO',     minArgs: 0, description: 'Run TOX.do',             run:     => @toxDO()}
    ]

  help: ->
    @event.emit 'aTox.terminal', 'Commands: (seperator: ", ")'

    for i in @cmds
      @event.emit 'aTox.terminal', "     \"/#{i.command}\":  #{i.description}"

  closeChat: (id)  -> @event.emit "chat-visibility", { cid: id, what: 'hide' }
  openChat:  (id)  -> @event.emit "chat-visibility", { cid: id, what: 'show' }
  setName:   (p)   -> @event.emit "setName",         p
  setAvatar: (p)   -> @event.emit "setAvatar",       p
  setStatus: (p)   -> @event.emit "setStatus",       p
  setOnline: (p)   -> @event.emit "onlineStatus",    { tid: -1, d: p }
  sendMSG:   (f,m) -> @event.emit "sendToFriend",    { tid: f,  d: m }
  addFriend: (a,m) -> @event.emit "addFriend",       { addr: a, msg: m }
  toxDO:           -> @event.emit "toxDO"

  process: (cmd) ->
    return unless cmd.indexOf('/') == 0
    cmd = cmd.replace('/', '')

    args = cmd.split /,\s+/

    @err "Empty command" if args.length == 0
    return               if args.length == 0
    @cmd = args[0]
    args.shift()

    for arg in @cmds
      if arg.command.toUpperCase() == @cmd.toUpperCase()
        if args.length < arg.minArgs
          @err "/#{@cmd} requires #{arg.minArgs} arguments (You gave #{args.length})"
          return
        if arg.minArgs == 0
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
