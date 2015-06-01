module.exports =
class aToxManager
  constructor: (params) ->
    @aTox  = params.aTox
    @token = atom.config.get 'aTox.githubToken'
    @bots  = []

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

#    ______       _
#    | ___ \     | |
#    | |_/ / ___ | |_ ___
#    | ___ \/ _ \| __/ __|
#    | |_/ / (_) | |_\__ \
#    \____/ \___/ \__|___/
#

  addBot: (friend) ->
    @bots.push friend
    friend.setPreeMSGhandler (msg) => @processMSG msg
    @aTox.term.inf {"title": "Added new aTox bot", "msg": "#{friend.pubKey}"}

  selectBot: (params) ->
    if @bots.length is 0
      @aTox.term.warn { "title": "No connection", "msg": "Connecting to the aTox network. Please wait" }
      return null

    unless params.key?
      return @bots[0] # No specific bot.

    params.key = params.key.slice 0, 64

    for i, index in @bots
      return @bots[index] if @bots[index].pubKey is params.key

    @aTox.term.err { "title": "NIY", "msg": "Implement missing bot" }
    return ""
