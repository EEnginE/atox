{View, TextEditorView, $, $$} = require 'atom-space-pen-views'

class PeerListItem extends View
  @content: (params) ->
    @p id: "aTox-LI-#{params.peer}-#{params.fid}", class: 'aTox-PeerList-item'

  initialize: (params) ->
    @text  params.name
    @css  {color: params.color}
    @FID  = params.fid
    @PEER = params.peer

  update: (params) ->
    @text  params.name
    @css  {color: params.color}
    @FID  = params.fid
    @PEER = params.peer

  fid:  -> return @FID
  peer: -> return @PEER

module.exports =
class PeerList extends View
  @content: (params) ->
    @div id: "aTox-chatbox-#{params.id}-PeerList", class: "aTox-PeerList"

  initialize: (params) ->
    @event = params.event
    @list  = []

  setList: (list) ->
    for i, index in @list
      found = false
      for j in list
        if j.fid < 0
          found = true unless i.peer() is j.peer
        else
          found = true unless i.fid()  is j.fid

        break  if found is true
      continue if found is true
      @list[index].remove()
      @list.splice index, 1

    for i in list
      found = false
      for j, index in @list
        if j.fid < 0
          continue unless i.peer is j.peer()
        else
          continue unless i.fid  is j.fid()

        @list[index].update i
        found = true
        break

      continue if found is true
      temp = new PeerListItem i
      temp.appendTo @element
      @list.push temp
