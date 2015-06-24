{GitRepository} = require 'atom'

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
    @collabList.push path
    @aTox.term.stub {"msg": "CollabManager::newCollab"}

  joinCollab: (path) ->
    @aTox.term.stub {"msg": "CollabManager::joinCollab"}

  closeCollab: (path) ->
    index = @collabList.indexOf path

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

        if listIndex is not -1
          list.push {"name": l, "fIDs": [f.fID]}
        else
          list[listIndex].fIDs.push f.fID

    return list

  getJoinableCollab: (cb) ->
    ids = []
    for f, index in @aTox.TOX.friends
      continue unless f.isHuman
      ids.push @aTox.TOX.friends[index].pSendCommand "collabList"

    @aTox.manager.pWaitForResponses ids, 2000, (o) =>
      o.list = @generateJoinableList()
      cb o

  updateJoinList: (cb) ->
    @getJoinableCollab (o) =>
      @joinableList = o.list
      cb o

  getCollabList:   -> return @collabList
  getJoinableList: -> return @joinableList

  getIsGitRepository: -> atom.project.getRepositories()?
  getCurrentFile:     ->
    editor   = atom.workspace.getActiveTextEditor()
    rootPath = atom.project.getRepositories()[0].getPath().replace ".git", ''
    return {error: true} unless editor?

    path = editor.getPath().replace rootPath, ''

    return {error: false, path: path, collabExists: false}
