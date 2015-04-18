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

  aToxAuth: (cb) ->
    unless @testToken @token
      @requestNewToken()
      return

    # TODO do more stuff (sign user name, etc.)
    @aTox.github.setToken @token
    @aTox.term.inf {cID: -2, msg: "Loaded token from settings #{atom.config.get('aTox.githubToken')}"}

    # use @aTox.gui.GitHubLogin.error for errors
    cb() if cb?

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

  login: (user, pw, otp) ->
    return unless @checkInput user, pw

    @generateNewTempToken {user: user, password: pw, otp: otp}, @loginContinueTT

  loginContinueTT: (tempToken) ->
    @getRealToken tempToken, (realToken) => @loginContinueRT realToken, tempToken

  loginContinueRT: (realToken, tempToken) ->
    @token = realToken
    atom.config.set 'aTox.githubToken', realToken
    @removeOldToken tempToken, @loginContinueRemovedTT

  loginContinueRemovedTT: ->
    @aToxAuth => @aTox.gui.GitHubLogin.success()

#     _                 _         _   _      _
#    | |               (_)       | | | |    | |
#    | |     ___   __ _ _ _ __   | |_| | ___| |_ __   ___ _ __ ___
#    | |    / _ \ / _` | | '_ \  |  _  |/ _ \ | '_ \ / _ \ '__/ __|
#    | |___| (_) | (_| | | | | | | | | |  __/ | |_) |  __/ |  \__ \
#    \_____/\___/ \__, |_|_| |_| \_| |_/\___|_| .__/ \___|_|  |___/
#                  __/ |                      | |
#                 |___/                       |_|

  generateNewTempToken: (data, cb) ->
    @aTox.github.createUserToken data, (params) =>
      if params.token?
        cb params.token
      else
        @aTox.gui.GitHubLogin.error "Failed", "#{params.data.message}"

  getRealToken:   (tempToken, cb) -> cb tempToken # TODO implement this
  removeOldToken: (tempToken, cb) -> cb() # TODO implement this

  testToken:      (token) ->
    return false if @token is 'none'
    return true
    # TODO add some 'real' tests
    @aTox.gui.GitHubLogin.error "Bad Token", "Your current GitHub token is invalid"
