module.exports =
class AuthManager
  constructor: (params) ->
    @aTox  = params.aTox
    @token = atom.config.get 'aTox.githubToken'

#      ___        _   _      ______ _            _ _
#     / _ \      | | | |     | ___ (_)          | (_)
#    / /_\ \_   _| |_| |__   | |_/ /_ _ __   ___| |_ _ __   ___
#    |  _  | | | | __| '_ \  |  __/| | '_ \ / _ \ | | '_ \ / _ \
#    | | | | |_| | |_| | | | | |   | | |_) |  __/ | | | | |  __/
#    \_| |_/\__,_|\__|_| |_| \_|   |_| .__/ \___|_|_|_| |_|\___|
#                                    | |
#                                    |_|

  aToxAuth: ->
    unless @testToken @token
      @requestNewToken()
      return

    # TODO do more stuff (sign user name, etc.)
    @aTox.github.setToken @token
    @aTox.term.inf {cID: -2, msg: "Loaded token from settings #{atom.config.get('aTox.githubToken')}"}

  requestNewToken: -> @aTox.gui.GitHubLogin.show()

  checkInput: (user, pw) ->
    if user is "" or pw is ""
      @aTox.gui.GitHubLogin.error "Empty", "Please enter your username and password"
      return false
    return true

#     _                 _        ______ _            _ _
#    | |               (_)       | ___ (_)          | (_)
#    | |     ___   __ _ _ _ __   | |_/ /_ _ __   ___| |_ _ __   ___
#    | |    / _ \ / _` | | '_ \  |  __/| | '_ \ / _ \ | | '_ \ / _ \
#    | |___| (_) | (_| | | | | | | |   | | |_) |  __/ | | | | |  __/
#    \_____/\___/ \__, |_|_| |_| \_|   |_| .__/ \___|_|_|_| |_|\___|
#                  __/ |                 | |
#                 |___/                  |_|

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

#     _                 _         _   _      _
#    | |               (_)       | | | |    | |
#    | |     ___   __ _ _ _ __   | |_| | ___| |_ __   ___ _ __ ___
#    | |    / _ \ / _` | | '_ \  |  _  |/ _ \ | '_ \ / _ \ '__/ __|
#    | |___| (_) | (_| | | | | | | | | |  __/ | |_) |  __/ |  \__ \
#    \_____/\___/ \__, |_|_| |_| \_| |_/\___|_| .__/ \___|_|  |___/
#                  __/ |                      | |
#                 |___/                       |_|

  testToken: (token) ->
    return false if @token is 'none'
    return true # TODO add some 'real' tests
