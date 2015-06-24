{GitRepository} = require 'atom'
Collab          = require './GUI/atox-collab'

# coffeelint: disable=max_line_length

module.exports =
class CollabManager
  constructor: (params) ->
    @aTox = params.aTox

    @collabList   = [] # Array of strings
    @joinableList = [] # Array of objects: {"name": "<n>", "fIDs": []}
    @editors = []

    atom.workspace.observeTextEditors (editor) =>
      @editors.push editor


  newCollab: (path) ->
    @collabList.push {
      "name":   path
      "collab": new Collab {
        "aTox":   @aTox
        "editor": atom.workspace.getActiveTextEditor()
      }
    }

  joinCollab: (path) ->
    fIDs = []
    for i in @joinableList
      if i.name is path
        fIDs = i.fIDs
        break

    return @aTox.term.err {"title": "Collab #{path} not found"} if fIDs.length is 0
    @tryToJoinCollab path, fIDs, 0

  tryToJoinCollab: (path, array, index) ->
    if index is array.length
      return @aTox.term.err {"title": "Failed to join collab", "msg": path}

    id = @aTox.TOX.friends[array[index]].pSendCommand "joinCollab", {"name": path}
    index++
    @aTox.manager.pWaitForResponses [id], 2000, (t) =>
      if t.timeout is true
        @aTox.term.warn {
          "title": "collab: timeout"
          "msg":   "peer #{index} of #{array.length} timed out"
        }
        return @tryToJoinCollab path, array, index

      if @aTox.TOX.friends[array[index - 1]].rInviteRequestToCollabSuccess
        return @aTox.term.success {"title": "Joined collab #{path}"}
      else
        return @tryToJoinCollab path, array, index

  closeCollab: (path) ->
    index = -1
    for i, ind in @collabList
      if i.name is path
        index = ind
        break

    return @aTox.term.err {"title": "#{path} is not a collabedit"} if index < 0

    @collabList.splice index, 1
    @aTox.term.inf  {"title": "Closed collab #{path}"}
    @aTox.term.stub {"msg": "CollabManager::closeCollab"}

  generateJoinableList: ->
    list = []
    for f in @aTox.TOX.friends
      continue unless f.pCollabList? # botProtocol not valid / init
      for l in f.pCollabList
        listIndex = -1
        for i, index in list
          if i.name is l
            listIndex = index
            break

        if listIndex is -1
          list.push {"name": l, "fIDs": [f.fID]}
        else
          list[listIndex].fIDs.push f.fID

    return list

  getJoinableCollab: (cb) ->
    ids = []
    for f, index in @aTox.TOX.friends
      continue unless f.isHuman
      continue unless f.pIsValidBot
      ids.push @aTox.TOX.friends[index].pSendCommand "collabList"

    @aTox.manager.pWaitForResponses ids, 2000, (o) =>
      o.list = @generateJoinableList()
      cb o

  updateJoinList: (cb) ->
    @getJoinableCollab (o) =>
      @joinableList = o.list
      cb o

  getCollabList: ->
    list = []
    list.push i.name for i in @collabList
    return list

  getJoinableList: -> return @joinableList

  getIsGitRepository: -> atom.project.getRepositories()?
  getCurrentFile:     ->
    editor   = atom.workspace.getActiveTextEditor()
    rootPath = atom.project.getRepositories()[0].getPath().replace ".git", ''
    return {error: true} unless editor?

    path = editor.getPath().replace rootPath, ''

    return {error: false, path: path, collabExists: false}
