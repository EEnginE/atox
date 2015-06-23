{GitRepository} = require 'atom'

module.exports =
class CollabManager
  constructor: (params) ->
    @aTox = params.aTox

    @collabList   = []
    @joinableList = []
    @editors = []

    atom.workspace.observeTextEditors (editor) =>
      @editors.push editor


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

  getCollabList:   -> return @collabList
  getJoinableList: -> return @joinableList

  getIsGitRepository: -> atom.project.getRepo()?
  getCurrentFile:     ->
    editor   = atom.workspace.getActiveTextEditor()
    rootPath = atom.project.getRepo().getPath().replace ".git", ''
    return {error: true} unless editor?

    path = editor.getPath().replace rootPath, ''

    return {error: false, path: path, collabExists: false}
