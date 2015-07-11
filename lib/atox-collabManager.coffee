{GitRepository} = require 'atom'
Collab          = require './GUI/atox-collab'
CollabGroup     = require './atox-collabGroup'

# coffeelint: disable=max_line_length

module.exports =
class CollabManager
  __setTimeout: (t, cb) -> setTimeout cb, t

  constructor: (params) ->
    @aTox = params.aTox

    @collabList   = [] # Array of Collab
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
    @aTox.term.success {"title": "Created collab: #{name}"}

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

    @aTox.TOX.collabWaitCBs[p.id] = {
      "done": false
      "cb": (gID, name) =>
        clearTimeout timeout
        @aTox.term.success {"title": "Joined collab #{p.path}", "msg": "ID: #{p.id}"}
        @aTox.TOX.collabWaitCBs[p.id].done = true
        group = new CollabGroup {
          "aTox": @aTox
          "gID":  gID
          "name": name
        }

        paths      = atom.project.getPaths()
        path       = "/#{p.path}"
        currEditor = atom.workspace.getActiveTextEditor()

        if currEditor?
          currPath        = currEditor.getPath()
          currProjectPath = atom.project.relativizePath(currPath)[0]
          if currProjectPath?
            path = currProjectPath + path
          else
            throw {"message": "No project open"} unless paths?
            path = paths[0] + path
        else
          throw {"message": "No project open"} unless paths?
          path = paths[0] + path

        editorPromise = atom.workspace.open path

        editorPromise.then (editor) =>
          @collabList.push new Collab {
            "aTox":   @aTox
            "editor": editor
            "name":   p.path
            "group":  group
          }

        return group
    }

    id = @aTox.TOX.friends[p.array[index]].pSendCommand "joinCollab", {"name": p.path, "cID": p.id}
    index++

    timeout = @__setTimeout 10000, =>
      @aTox.term.err {
        "title": "collab: timeout"
        "msg":   "invite from peer #{index} of #{p.array.length} timed out!"
      }
      return @tryToJoinCollab p, index

    @aTox.manager.pWaitForResponses [id], 5000, (t) =>
      return if @aTox.TOX.collabWaitCBs[p.id].done
      if t.timeout is true
        clearTimeout timeout
        @aTox.term.warn {
          "title": "collab: timeout"
          "msg":   "peer #{index} of #{p.array.length} timed out"
        }
        return @tryToJoinCollab p, index

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

    @collabList[index].destructor()
    @collabList.splice index, 1
    @aTox.term.success {"title": "Closed collab #{path}"}

  generateJoinableList: ->
    list = []
    for f in @aTox.TOX.friends
      continue unless f.pCollabList? # botProtocol not valid / init
      for l in f.pCollabList
        listIndex = -1

        # Check if we are already in this collab
        for i in @collabList
          if i.getID() is l.id
            listIndex = -2
            break

        continue if listIndex is -2

        # Check for duplicate entries from different peers / friends
        for i, index in list
          if i.id is l.id
            listIndex = index
            break

        if listIndex is -1
          list.push {"name": l.name, "fIDs": [f.fID], "id": l.id}
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
    list.push {"name": i.getName(), "id": i.getID()} for i in @collabList
    return list

  getJoinableList: -> return @joinableList

  getCurrentFile:  ->
    return {"error": true} unless atom.workspace.getActiveTextEditor()?

    path = atom.workspace.getActiveTextEditor().getPath()
    path = atom.project.relativizePath( path )[1] # 0 = project path, 1 = relative path

    for i in @collabList
      if path is i.getName()
        return {"error": false, "path": path, "collabExists": 1}

    for i in @joinableList
      if path is i.name
        return {"error": false, "path": path, "collabExists": 2}

    return {"error": false, "path": path, "collabExists": 0}
