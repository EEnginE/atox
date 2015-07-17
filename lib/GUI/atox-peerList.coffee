{View, TextEditorView, $, $$} = require 'atom-space-pen-views'

class PeerListItem extends View
  @content: (params) ->
    @p id: "aTox-LI-#{params.peer}-#{params.fID}", class: 'aTox-PeerList-item'

  initialize: (params) ->
    @text  params.name
    @css  {color: params.color}
    @FID  = params.fID
    @PEER = params.peer

    # TODO: Add functionality: Show additional information: Recent Projects, Contributions to current project, has push rights. Unnecessary: toxID, status, image
    # TODO: Get the real status of the user, check if User is already added and open the chat window directly

  update: (params) ->
    @text  params.name
    @css  {color: params.color}
    @FID  = params.fID
    @PEER = params.peer

  fID:  -> return @FID
  peer: -> return @PEER

module.exports =
class PeerList extends View
  @content: (params) ->
    @div class: "aTox-PeerList", cID: params.cID

  initialize: (params) ->
    @list  = []

  setList: (list) ->
    for i, index in @list
      found = false
      for j in list
        if j.fID < 0
          found = true unless i.peer() is j.peer
        else
          found = true unless i.fID()  is j.fID

        break  if found is true
      continue if found is true
      @list[index].remove()
      @list.splice index, 1

    for i in list
      found = false
      for j, index in @list
        if j.fID < 0
          continue unless i.peer is j.peer()
        else
          continue unless i.fID  is j.fID()

        @list[index].update i
        found = true
        break

      continue if found is true
      temp = new PeerListItem i
      @append temp
      @list.push temp
