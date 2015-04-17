module.exports =
class BotManager
  constructor: (params) ->
    @aTox = params.aTox
    @bots = []

  addBot: (friend) ->
    @bots.push friend
    friend.setPreeMSGhandler (msg) => @processMSG msg
    @aTox.term.inf {"msg": "Added new aTox bot: #{friend.pubKey}"}

  selectBot: (params) ->
    if @bots.length is 0
      @aTox.term.warn { "title": "No connection", "msg": "Connecting to the aTox network. Please wait" }
      return null

    unless params.key?
      return @bots[0]

    params.key = params.key.slice 0, 64

    for i, index in @bots
      return @bots[index] if @bots[index].pubKey is params.key

    @aTox.term.err { "title": "NIY", "msg": "Implement missing bot" }

  processMSG: (msg) -> return false

  makeGCformName: (name) ->
    bot = @selectBot {}
    return if bot is null
