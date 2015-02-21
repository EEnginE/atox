module.exports =
class Terminal
  constructor: (params) ->
    @cid     = params.cid
    @event   = params.event

  init: ->

    @event.on 'aTox.add-message', (data) =>
      return unless data.cid is @cid
      return unless data.tid is -1
      @process data.msg

    @cmds = [
      {c: 'help',      a: 0, d: 'Prints help message',    f:     => @help()}
      {c: 'exit',      a: 0, d: 'Closes terminal window', f:     => @closeChat @cid}
      {c: 'getChatID', a: 1, d: 'Print chat [1] ID',      f: (p) => @event.emit 'getChatID', p[0]}
      {c: 'openChat',  a: 1, d: 'Opens chat [1]',         f: (p) => @openChat  parseInt p[0]}
      {c: 'closeChat', a: 1, d: 'Closes chat [1]',        f: (p) => @closeChat parseInt p[0]}
      {c: 'setName',   a: 1, d: 'Set name to [1]',        f: (p) => @setName            p[0]}
      {c: 'setAvatar', a: 1, d: 'Set avatar to [1]',      f: (p) => @setAvatar          p[0]}
      {c: 'setStatus', a: 1, d: 'Set status to [1]',      f: (p) => @setStatus          p[0]}
      {c: 'setOnline', a: 1, d: 'Set online to [1]',      f: (p) => @setOnline          p[0]}
      {c: 'sendMSG',   a: 2, d: 'Send [2] to [1]',        f: (p) => @sendMSG            p[0], p[1]}
    ]

  help: ->
    @event.emit 'aTox.terminal', 'Comands: (seperator: ", ")'
    @event.emit 'aTox.terminal', ' '

    for i in @cmds
      @event.emit 'aTox.terminal', " - #{i.c} (#{i.a}): #{i.d}"

  closeChat: (id)  -> @event.emit "chat-visibility", { cid: id, what: 'hide' }
  openChat:  (id)  -> @event.emit "chat-visibility", { cid: id, what: 'show' }
  setName:   (p)   -> @event.emit "setName",         p
  setAvatar: (p)   -> @event.emit "setAvatar",       p
  setStatus: (p)   -> @event.emit "setStatus",       p
  setOnline: (p)   -> @event.emit "onlineStatus",    { tid: -1, d: p }
  sendMSG:   (f,m) -> @event.emit "sendToFriend",    { tid: f,  d: m }

  process: (cmd) ->
    args = cmd.split /,\s+/

    @err "Empty cammand" if args.length == 0
    return               if args.length == 0
    @cmd = args[0]
    args.shift()

    for a in @cmds
      if a.c == @cmd
        if args.length != a.a
          @err "Comand #{@cmd} needs #{a.a} args (#{args.length})"
          return
        if a.a == 0
          a.f()
        else
          a.f args

        return

    @err "Comand #{@cmd} not found"

  err: (what) ->
    @event.emit 'notify', {
      type: 'err'
      name: 'Terminal'
      content: what
    }
