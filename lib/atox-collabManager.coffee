{GitRepository} = require 'atom'

module.exports =
class CollabManager
  constructor: (params) ->
    @aTox = params.aTox

    @collabList   = []
    @joinableList = []

  newCollab: (path) ->
    @aTox.term.warn {msg: "TODO: Implement new collab"}

  joinCollab: (path) ->
    @aTox.term.warn {msg: "TODO: Implement join collab"}

  closeCollab: (path) ->
    index = @collabList.indexOf path

    return @aTox.term.err {msg: "#{path} is not a collabedit"} if index < 0

    @collabList.splice index, 1
    @aTox.term.inf  {msg: "Closed collab #{path}"}
    @aTox.term.warn {msg: "TODO: implement real collab closing"}

  generateJoinableList: ->
    list = []
    for f in @aTox.TOX.friends
      list.concat f.pCollabList

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
      cb()

  getCollabList:   -> return @collabList
  getJoinableList: -> return @joinableList

  getIsGitRepository: -> atom.project.getRepositories()?
  getCurrentFile:     ->
    editor   = atom.workspace.getActiveTextEditor()
    rootPath = atom.project.getRepositories()[0].getPath().replace ".git", ''
    return {error: true} unless editor?

    path = editor.getPath().replace rootPath, ''

    return {error: false, path: path, collabExists: false}
