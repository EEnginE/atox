BotManager        = require './botProtocol/prot-botManager'
FriendRequestView = require './GUI/atox-friendRequest'

module.exports =
class aToxManager extends BotManager
  constructor: (params) ->
    super params
    @aTox  = params.aTox
    @bots  = []
    @aTox.gSave.onInitDone => @token = @aTox.gSave.get 'githubToken'

  getCollabList: -> @aTox.collab.getCollabList()

  handleFriendRequest: (event) ->
    # TODO autoaccept friends for joining chats
    new FriendRequestView
      "aTox":    @aTox
      "id":      event.publicKeyHex().toUpperCase()
      "msg":     event.message()
      "accept":  => @aTox.TOX.addFriendNoRequest event
      "decline": ->

#     _                 _
#    | |               (_)
#    | |     ___   __ _ _ _ __
#    | |    / _ \ / _` | | '_ \
#    | |___| (_) | (_| | | | | |
#    \_____/\___/ \__, |_|_| |_|
#                  __/ |
#                 |___/

  aToxAuth: ->
    unless @testToken @token
      return unless atom.config.get 'aTox.showGithubLogin'
      @requestNewToken()
      return

    # TODO do more stuff (sign user name, etc.)
    @aTox.github.setToken @token
    @aTox.term.inf
      "title":  "Loaded Github token from settings"
      "msg":    "#{@aTox.gSave.get('githubToken')}"
      "notify": false

  requestNewToken: -> @aTox.gui.GitHubLogin.show()

  testToken: (token) ->
    if @token then true else false
    # TODO add some 'real' tests


  login: (data, cbs) ->
    if data.user is "" or data.pw is ""
      return cbs.error "Empty", "Please enter your username and password"

    @aTox.github.createUserToken data, (params) =>
      if params.token?
        @token = params.token
        @aTox.gSave.set 'githubToken', params.token
        if @testToken @token
          cbs.success @token
        else
          cbs.error "Invalid Token", "Generated token #{@token} invalid"
      else
        cbs.error "Failed", "#{params.data.message}"
