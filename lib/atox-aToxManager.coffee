BotManager = require './botProtocol/prot-botManager'

module.exports =
class aToxManager extends BotManager
  constructor: (params) ->
    super params
    @aTox  = params.aTox
    @token = atom.config.get 'aTox.githubToken'
    @bots  = []

  getCollabList: -> @aTox.collab.getCollabList()

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
      @requestNewToken()
      return

    # TODO do more stuff (sign user name, etc.)
    @aTox.github.setToken @token
    @aTox.term.inf {"cID": -2, "title": "Loaded Github token from settings", "msg": "#{atom.config.get('aTox.githubToken')}"}

  requestNewToken: -> @aTox.gui.GitHubLogin.show()

  testToken: (token) ->
    return false if @token is 'none'
    return true # TODO add some 'real' tests


  login: (data, cbs) ->
    if data.user is "" or data.pw is ""
      return cbs.error "Empty", "Please enter your username and password"

    @aTox.github.createUserToken data, (params) =>
      if params.token?
        @token = params.token
        atom.config.set 'aTox.githubToken', params.token
        if @testToken @token
          cbs.success @token
        else
          cbs.error "Invalid Token", "Generated token #{@token} invalid"
      else
        cbs.error "Failed", "#{params.data.message}"
