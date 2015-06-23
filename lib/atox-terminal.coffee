shell   = require 'shell'
Message = require './GUI/atox-message'

# coffeelint: disable=max_line_length

module.exports =
class Terminal
  constructor: (params) ->
    @aTox    = params.aTox

    # Icons: https://octicons.github.com/
    @cmds = [ #TODO: Test commands
      {cmd: 'help',      argc: 0, desc: 'Prints help message',                                   icon: 'book',               run: (cID)    => @help        cID       }
      {cmd: 'makeGC',    argc: 1, desc: 'Creates - or joins - a group chat with the id [a1]',    icon: 'ruby',               run: (cID, p) => @makeGC      p[0]      }
      {cmd: 'invite',    argc: 2, desc: 'Invites [a1] to group [a2]',                            icon: 'gift',               run: (cID, p) => @invite      p[0], p[1]}
      {cmd: 'addGC',     argc: 0, desc: 'Adds a new group chat',                                 icon: 'diff-added',         run: (cID)    => @addGC()               }
      {cmd: 'login',     argc: 0, desc: 'Opens GitHub login popup',                              icon: 'key',                run: (cID)    => @login()               }
      {cmd: 'addFriend', argc: 2, desc: 'Send friend request to user ID [a1] with message [a2]', icon: 'diff-added',         run: (cID, p) => @addFriend   p[0], p[1]}
      {cmd: 'setName',   argc: 1, desc: 'Set name to [a1]',                                      icon: 'pencil',             run: (cID, p) => @setName     p[0]      }
      {cmd: 'setAvatar', argc: 1, desc: 'Set avatar to [a1]',                                    icon: 'file-media',         run: (cID, p) => @setAvatar   p[0]      }
      {cmd: 'setStatus', argc: 1, desc: 'Set status message to [a1]',                            icon: 'pencil',             run: (cID, p) => @setStatus   p[0]      }
      {cmd: 'setOnline', argc: 1, desc: 'Set online status to [a1]',                             icon: 'globe',              run: (cID, p) => @setOnline   p[0]      }
      {cmd: 'openChat',  argc: 1, desc: 'Opens chat with ID [a1]',                               icon: 'link-external',      run: (cID, p) => @openChat    p[0]      }
      {cmd: 'closeChat', argc: 1, desc: 'Closes the chat with ID [a1]',                          icon: 'x',                  run: (cID, p) => @closeChat   p[0]      }
      {cmd: 'sendMSG',   argc: 2, desc: 'Send message [a2] to user [a1]',                        icon: 'comment',            run: (cID, p) => @sendMSG     p[0], p[1]}
      {cmd: 'sendToGC',  argc: 2, desc: 'Send message [a2] to group chat [a1]',                  icon: 'comment-discussion', run: (cID, p) => @sendToGC    p[0], p[1]}
      {cmd: 'reqAvatar', argc: 0, desc: 'Send a avatar request to all friends',                  icon: 'cloud-download',     run: (cID)    => @reqAvatar()           }
    ]

  help: (cID) ->
    @inf   {cID: cID, msg: ' Commands start with a /. Use // to send a /'}
    @inf   {cID: cID, msg: ' (Strings are encased with "s)'}

    for i in @cmds
      @inf {cID: cID, msg: "     \"/#{i.cmd}\":  #{i.desc}"}

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
  invite:    (f,g)      -> @aTox.TOX.invite            { fID: f, gID: g }
  login:                -> @aTox.authManager.requestNewToken()
  makeGC:    (n)        -> @aTox.botManager.makeGCformName n

  process: (data) ->
    cmd = data.cmd
    return unless cmd.indexOf('/') == 0
    cmd = cmd.replace('/', '')

    args = @handleArgs cmd

    @err {msg: "Empty cmd", cID: data.cID} if args.length == 0
    return           if args.length == 0
    @cmd = args[0]
    args.shift()

    for arg in @cmds
      if arg.cmd.toUpperCase() == @cmd.toUpperCase()
        if args.length < arg.argc
          @err "/#{@cmd} requires #{arg.argc} arguments (You gave #{args.length})"
          return
        if arg.argc == 0
          arg.run data.cID #TODO: Stop sending the message when a command is found
        else
          arg.run data.cID, args

        return

    @err {msg: "Command /#{@cmd} not found", cID: data.cID}

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

  generateNotificationEntry: (data, opts) ->
    data.cID   = -1       unless data.cID?
    data.title = 'aTox'   unless data.title?
    opts.style = 'italic' unless opts.style?

    msg = new Message {
      "type":       "term"
      "title":       data.title
      "msg":         data.msg   if data.msg?
      "colorClass":  opts.color
      "style":       opts.style
      "typeName":    opts.type
      "defaultChat": if data.cID < 0 then true else false
    }

    unless data.noChat
      if data.cID < 0
        @aTox.gui.chatpanel.addMessage {'cID': -1, 'msg': msg}
      else
        @aTox.gui.chats[data.cID].addMSG msg

    return if data.notify if data.msg? is false
    opts.func data.title.replace( /<[^<]*>/g, '' ), {
      'detail':      data.msg.replace /<[^<]*>/g, '' if data.msg?
      'description': data.description.replace /<[^<]*>/g, '' if data.description?
      'dismissable': opts.dismissable
      'stack':       data.stack
      'buttons':     data.buttons
    }

  success: (data) ->
    @generateNotificationEntry data, {
      'type':       'Success'
      'color':      'text-success'
      'dismissable': false
      'func': (t, o) -> atom.notifications.addSuccess t, o
    }

  inf: (data) ->
    @generateNotificationEntry data, {
      'type':       'Info'
      'color':      'text-info'
      'dismissable': false
      'func': (t, o) -> atom.notifications.addInfo t, o
    }

  warn: (data) ->
    @generateNotificationEntry data, {
      'type':       'Warning'
      'color':      'text-warning'
      'dismissable': true
      'func': (t, o) -> atom.notifications.addWarning t, o
    }

  err: (data) ->
    @generateNotificationEntry data, {
      'type':       'ERROR'
      'color':      'text-error'
      'dismissable': true
      'func': (t, o) -> atom.notifications.addError t, o
    }

  stub: (data) ->
    data.msg   = "#{data.msg} is a stub!"
    data.title = "aTox STUB"
    @warn data
