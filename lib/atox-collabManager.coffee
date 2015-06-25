{GitRepository} = require 'atom'
Collab          = require './GUI/atox-collab'
CollabGroup     = require './atox-collabGroup'

# coffeelint: disable=max_line_length

module.exports =
class CollabManager
  __setTimeout: (t, cb) -> setTimeout cb, t

  constructor: (params) ->
    @aTox = params.aTox

    @collabList   = [] # Array of strings
    @joinableList = [] # Array of objects: {"name": "<n>", "fIDs": [], "id": <random string>}
    @editors = []

    atom.workspace.observeTextEditors (editor) =>
      @editors.push editor


  newCollab: (path) ->
    @collabList.push new Collab {
      "aTox":   @aTox
      "editor": atom.workspace.getActiveTextEditor()
      "name":   path
    }

  joinCollab: (path) ->
    fIDs = []
    id   = ""
    for i in @joinableList
      if i.name is path
        fIDs = i.fIDs
        id   = i.id
        break

    return @aTox.term.err {"title": "Collab #{path} not found"} if fIDs.length is 0
    @tryToJoinCollab {"path": path, "array": fIDs, "id": id}, 0

  tryToJoinCollab: (p, index) ->
    if index is p.array.length
      return @aTox.term.err {"title": "Failed to join collab", "msg": p.path}

    id = @aTox.TOX.friends[p.array[index]].pSendCommand "joinCollab", {"name": p.path, "id": p.id}
    index++

    timeout = @__setTimeout 5000, =>
      @aTox.term.err {
        "title": "collab: timeout"
        "msg":   "invite from peer #{index} of #{p.array.length} timed out!"
      }
      return @tryToJoinCollab p.path, p.array, index

    @aTox.TOX.collabWaitCBs[p.id] = {
      "done": false
      "cb": (gID, name) =>
        clearTimeout timeout
        @aTox.term.success {"title": "Joined collab #{p.path}", "msg": "ID: #{p.id}"}
        @aTox.term.collabCBs[p.id].done = true
        group = new CollabGroup {
          "aTox": @aTox
          "gID":  gID
          "name": name
        }

        @collabList.push new Collab {
          "aTox":   @aTox
          "editor": atom.workspace.getActiveTextEditor() # TODO use real editor / file
          "name":   path
          "group":  group
        }

        return group
    }

    @aTox.manager.pWaitForResponses [id], 2000, (t) =>
      return if @aTox.term.collabCBs[p.id].done
      if t.timeout is true
        clearTimeout timeout
        @aTox.term.warn {
          "title": "collab: timeout"
          "msg":   "peer #{index} of #{p.array.length} timed out"
        }
        return @tryToJoinCollab p.path, p.array, index

      unless @aTox.TOX.friends[p.array[index - 1]].rInviteRequestToCollabSuccess
        clearTimeout timeout
        return @tryToJoinCollab p, index

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
          if i.id is l.id
            listIndex = index
            break

        if listIndex is -1
          list.push {"name": l, "fIDs": [f.fID], "id": l.id}
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
    list.push {"name": i.name, "id": i.id} for i in @collabList
    return list

  getJoinableList: -> return @joinableList

  getIsGitRepository: -> atom.project.getRepositories()?
  getCurrentFile:     ->
    editor   = atom.workspace.getActiveTextEditor()
    rootPath = atom.project.getRepositories()[0].getPath().replace ".git", ''
    return {error: true} unless editor?

    path = editor.getPath().replace rootPath, ''

    return {error: false, path: path, collabExists: false}
