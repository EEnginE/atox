shell   = require 'shell'
Message = require './GUI/atox-message'

# coffeelint: disable=max_line_length

module.exports =
class Terminal
  constructor: (params) ->
    @aTox    = params.aTox

    # Icons: https://octicons.github.com/
    # Currently supported parameter types:
    #  - none:   string
    #  - friend: for a friend ID
    #  - group:  for a group ID
    #  - list:   manualy make a list (REQUIRES the list option)
    @cmds = [
      {
        "cmd":  'help'
        "args": []
        "desc": 'Prints help message'
        "icon": 'book'
      }
      {
        "cmd": 'invite'
        "args": [
          {"desc": 'The friend to invite', "type": 'friend'}
          {"desc": 'The group',            "type": 'group'}
        ]
        "desc": 'Invites a friend to a group'
        "icon": 'gift'
      }
      {
        "cmd": 'addFriend'
        "args": [
          {"desc": 'The TOX ID of your friend'}
          {"desc": "The friend request message"}
        ]
        "desc": 'Sends a friend request'
        "icon": 'diff-added'
      }
      {"cmd": 'makeGC',     "args": [{"desc": 'Name/ID of the GC'}],          "desc": 'Creates/joins a group chat',  "icon": 'ruby'       }
      {"cmd": 'addGC',      "args": [],                                       "desc": 'Adds a new group chat',       "icon": 'diff-added' }
      {"cmd": 'login',      "args": [],                                       "desc": 'Opens GitHub login popup',    "icon": 'key'        }
      {"cmd": 'setName',    "args": [{"desc": 'The new name'}],               "desc": 'Set the user name',           "icon": 'pencil'     }
      {"cmd": 'setAvatar',  "args": [{"desc": 'The new avatar (full path)'}], "desc": 'Set the user avatar',         "icon": 'file-media' }
      {"cmd": 'sendAvatar', "args": [],                                       "desc": 'Sends your current avatar',   "icon": 'radio-tower'}
      {"cmd": 'setStatus',  "args": [{"desc": 'The new status message'}],     "desc": 'Set the user status message', "icon": 'pencil'     }
      {"cmd": 'changePW',   "args": [],                                       "desc": 'Set your TOX save password',  "icon": 'key'        }
      {
        "cmd": 'setOnline'
        "args": [
          {
            "desc": 'The new online status'
            "type": 'list'
            "list": ['away', 'online', 'busy']
          }
        ]
        "desc": 'Set the user online status'
        "icon": 'globe'
      }
      {
        "cmd": 'sendFile'
        "args": [{"desc": 'The friend ID', "type": "friend"}]
        "desc": 'Sends the current file to a friend'
        "icon": 'cloud-upload'
      }
      {
        "cmd":  'delFriend'
        "args": [{"desc": 'The friend ID to delete', "type": 'friend'}]
        "desc": 'Deletes the selected friend'
        "icon": 'diff-removed'
      }
      {
        "cmd":  'delGroup'
        "args": [{"desc": 'The group ID to delete', "type": 'group'}]
        "desc": 'Deletes the selected groupchat'
        "icon": 'diff-removed'
      }
    ]

  help: (p) ->
    if p.argv[0]?
      cmd = p.argv[0]
      arg = null
      for i in @cmds
        if i.cmd.toUpperCase() is cmd.toUpperCase()
          arg = i
          break

      if arg is null
        @warn {"cID": p.cID, "title": "HELP: Command #{cmd} not found"}
        return

      @inf   {"cID": p.cID, "title": "Command #{cmd} takes at least #{arg.args.length} arguments", "notify": false}
      for i, index in arg.args
        if i.type?
          switch i.type
            when "friend" then @inf {"cID": p.cID, "title": "  - arg #{index+1}: #{i.desc} - the friend ID is an integer", "notify": false}
            when "group"  then @inf {"cID": p.cID, "title": "  - arg #{index+1}: #{i.desc} - the group ID is an integer",  "notify": false}
            when "list"   then @inf {"cID": p.cID, "title": "  - arg #{index+1}: #{i.desc} - possible values: #{i.list}",  "notify": false}
            else @inf {"cID": p.cID, "title": "  - arg #{index+1}: #{i.desc}", "notify": false}
        else
          @inf {"cID": p.cID, "title": "  - arg #{index+1}: #{i.desc}", "notify": false}
    else
      @inf   {"cID": p.cID, "title": ' Commands start with a /. Use // to send a /', "notify": false}
      @inf   {"cID": p.cID, "title": ' (Strings are encased with "s)',               "notify": false}

      for i in @cmds
        @inf {"cID": p.cID, "title": "     \"/#{i.cmd}\":  #{i.desc}", "notify": false}

  setName:    (p) -> @aTox.TOX.setName   p.argv[0]
  setAvatar:  (p) -> atom.config.set 'aTox.userAvatar', p.argv[0]; @snedAvatar()
  sendAvatar: (p) -> @aTox.TOX.broadcastAvatar()
  setStatus:  (p) -> @aTox.TOX.setStatus p.argv[0]
  setOnline:  (p) -> @aTox.TOX.onlineStatus p.argv[0]; @aTox.gui.setUserOnlineStatus p.argv[0]
  sendFile:   (p) -> @aTox.TOX.sendFile {"fID": p.argv[0], "path": atom.workspace.getActiveTextEditor().getPath()}
  addFriend:  (p) -> @aTox.TOX.sendFriendRequest {"addr": p.argv[0], "msg": p.argv[1]}
  addGC:      (p) -> @aTox.TOX.createGroupChat()
  invite:     (p) -> @aTox.TOX.invite            {"fID": p.argv[0], "gID": p.argv[1]}
  login:      (p) -> @aTox.manager.requestNewToken()
  makeGC:     (p) -> return @stub 'makeGCfromName'
  delFriend:  (p) -> @aTox.TOX.deleteFriend    {"fID": p.argv[0]}
  delGroup:   (p) -> @aTox.TOX.deleteGroupChat {"gID": p.argv[0]}
  changePW:   (p) -> @aTox.TOX.changeTOXsaveKey()

  run: (cmd, args) ->
    unless this[cmd]?
      @err {"title": "Fatal internal error", "msg": "Failed to execute comand #{cmd}"}

    this[cmd] args

  process: (data) ->
    cmd = data.cmd
    return unless cmd.indexOf('/') == 0
    cmd = cmd.replace('/', '')

    args = @handleArgs cmd

    if args.length == 0
      @err {msg: "Empty cmd", cID: data.cID}
      return
    cmd = args[0]
    args.shift()

    for arg in @cmds
      if arg.cmd.toUpperCase() == cmd.toUpperCase()
        if args.length < arg.args.length
          @err "/#{cmd} requires #{arg.argc} arguments (You gave #{args.length})"
          return
        @run cmd, {"cID": data.cID, "argv": args}

        return

    @err {msg: "Command /#{cmd} not found", cID: data.cID}

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

    return if data.notify is false
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
      'color':      'success'
      'dismissable': false
      'func': (t, o) -> atom.notifications.addSuccess t, o
    }

  inf: (data) ->
    @generateNotificationEntry data, {
      'type':       'Info'
      'color':      'info'
      'dismissable': false
      'func': (t, o) -> atom.notifications.addInfo t, o
    }

  warn: (data) ->
    @generateNotificationEntry data, {
      'type':       'Warning'
      'color':      'warning'
      'dismissable': true
      'func': (t, o) -> atom.notifications.addWarning t, o
    }

  err: (data) ->
    @generateNotificationEntry data, {
      'type':       'ERROR'
      'color':      'error'
      'dismissable': true
      'func': (t, o) -> atom.notifications.addError t, o
    }

  stub: (data) ->
    data.msg   = "#{data.msg} is a stub!"
    data.title = "aTox STUB"
    @warn data
