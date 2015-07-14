{View} = require 'atom-space-pen-views'

module.exports =
class Message extends View
  @getTime: ->
    d = new Date
    t = []
    for i, index in [d.getHours(), d.getMinutes(), d.getSeconds()]
      t[index] = if i < 10 then "0#{i}" else "#{i}"

    "#{t[0]}:#{t[1]}:#{t[2]}"

  @content: (params) ->

    @div      class: "historyName", =>
      @p      outlet: 'main', =>
        @span outlet: 'status'
        @span outlet: 'time', @getTime()
        @b    outlet: 'title'
        @b    outlet: 'cmdType'
        @span outlet: 'cmdTitle'
        @span outlet: 'msg'

  initialize: (params) ->
    params.type = 'normal' unless params.type?
    @type = params.type

    @time.addClass 'text-subtle'
    @time.css   {"margin-right": "7px"}

    @status.css {"float": "right"}
    @setStatus 'comment', 1, 'highlight', 'info'

    switch @type
      when 'normal' then @normalMSG params
      when 'term'   then @termMSG   params

  setStatus: (icon, opacity, textClass, iconClass) ->
    @status.removeClass()
    @main.removeClass()
    @status.addClass "icon icon-#{icon}"
    @status.addClass "text-#{iconClass}" if iconClass?
    @main.addClass   "text-#{textClass}" if textClass?
    @main.css {"opacity": opacity}

  handleURLs: (msg) ->
    nstr = ['http://', 'https://', 'ftp://']
    tmsg = msg.split(' ')
    for i in [0..(tmsg.length - 1)]
      for n in nstr
        if tmsg[i].indexOf(n) > -1
          tmsg[i] = '<a href="' + tmsg[i] + '">' + tmsg[i] + '</a>'
    msg = tmsg.join(' ')

    return msg

  normalMSG: (params) ->
    throw {"what": "Empty Message"} if not params.msg or params.msg is ''
    params.msg = @handleURLs params.msg

    @cmdType.remove()
    @cmdTitle.remove()

    @title.text params.name + ': '
    @msg.text   params.msg
    @title.css  {"color": params.color}

  markAsError:   -> @setStatus 'alert',        1,    'error'
  markAsWaiting: -> @setStatus 'cloud-upload', 0.25, 'highlight'
  markAsRead:    -> @setStatus 'check',        1,    'highlight', 'success'
  markAsOffline: -> @setStatus 'cloud-upload', 0.75, 'warning'

  termMSG: (params) ->
    params.title = @handleURLs params.title
    @setStatus 'chevron-left', 1, params.colorClass
    if params.msg?
      params.title += ': '
      @msg.text @handleURLs params.msg
      @msg.css {"font-style": params.style}
    else
      @msg.remove()

    @title.text   'aTox: '
    @cmdType.text  params.typeName + ': '
    @cmdTitle.text params.title

    @title.css   {"color":      "#FFFFFF"}
    @cmdType.css {"font-style": params.style}
