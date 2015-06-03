{View} = require 'atom-space-pen-views'

module.exports =
class Message extends View
  @content: (params) ->
    @div class: "historyName", => # TODO use p instead of div
      @p outlet: 'main'           # TODO remove this line

  initialize: (params) ->
    params.type = 'normal' unless params.type?
    @type = params.type

    switch @type
      when 'normal' then @normalMSG params
      when 'term'   then @termMSG   params

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

    @main.append "<b style='color:#{params.color};'>#{params.name}: </b></span><span>#{params.msg}</span>"

  markAsError:   ->
    @main.css {"color": "", "opacity": 1}
    @main.addClass "text-error"

  markAsWaiting: -> @main.css {"opacity": 0.25}
  markAsRead:    -> @main.css {"opacity": 1}

  termMSG: (params) ->
    @main.append "<b style='color:#FFFFFF'>aTox: </b>" if not params.defaultChat
    params.title = @handleURLs params.title

    if params.msg?
      params.msg = @handleURLs params.msg

      str  = "<span class='#{params.colorClass}'>"
      str +=   "<b style='font-style:#{params.style}'>#{params.typeName}: </b>"
      str +=   "#{params.title}: "
      str +=   "<span style='font-style:#{params.style}'>#{params.msg}</span>"
      str += "</span>"
    else
      str  = "<span class='#{params.colorClass}', style='font-style:#{params.style}'>"
      str +=   "<b>#{params.typeName}: </b>#{params.title}"
      str += "</span>"

    @main.append str
