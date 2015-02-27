https = require('https')

module.exports =
class Github
  constructor: ->
    console.log "constructed"
    @client_id = '0b093d563346476729fb'
    @client_secret = '8fdsfdsgfdsg98d7'
    @htoken = ''

  getUserInfo: (params, callback) ->
    #params.user, callback
    #https://developer.github.com/v3/users/
    if @htoken is ''
      return
    opts = {
      hostname: 'api.github.com',
      port: 443,
      path: '/users/',
      method: 'GET',
      headers: {
        'User-Agent': 'aTox Github Binding v0.0.1',
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': "token " + @htoken,
        'Accept': 'application/vnd.github.v3+json'
      }
    }
    if params.user?
      opts.path += params.user
    data = {
      "note": "aTox github binding"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      callback(JSON.parse(data))

  getUserImage: (params, callback) ->
    #params.user, callback
    @getUserInfo {user: params.user}, (info) =>
      callback(info.avatar_url)

  createUserToken: (params, callback) ->
    #params.user, params.password, params.otp, callback
    if not params.user? or not params.password?
      return
    opts = {
      hostname: 'api.github.com',
      port: 443,
      path: '/authorizations',
      method: 'POST',
      auth: params.user + ':' + params.password,
      headers: {
        'User-Agent': 'aTox Github Binding v0.0.1',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/vnd.github.v3+json'
      }
    }
    if params.otp?
      opts.headers['X-GitHub-OTP'] = params.otp
    data = {
      #"client_secret": @client_secret,
      "scopes": [
        "public_repo" #To fill up
      ],
      "note": "aTox github binding"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      console.log data
      console.log JSON.parse(data)
      @setToken JSON.parse(data).token
      callback({id: JSON.parse(data).id, token: JSON.parse(data).token, data: JSON.parse(data)})


  deleteUserToken: (params, callback) ->
    #params.token, params.id, callback
    if not params.user? or not params.password?
      return
    opts = {
      hostname: 'api.github.com',
      port: 443,
      path: '/authorizations/' + params.id,
      method: 'DELETE',
      auth: params.token + ':x-oauth-basic',
      headers: {
        'User-Agent': 'aTox Github Binding v0.0.1',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/vnd.github.v3+json'
      }
    }
    if params.otp?
      opts.headers['X-GitHub-OTP'] = params.otp
    data = {
      #"client_secret": @client_secret,
      #"scopes": [
      #  "public_repo" #To fill up
      #],
      "note": "aTox github binding"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      console.log data
      console.log JSON.parse(data)
      @setToken JSON.parse(data).token
      callback()

  createAppToken: (params, callback) ->
    #params.user, params.password, params.otp, callback
    if not params.user? or not params.password?
      return
    opts = {
      hostname: 'api.github.com',
      port: 443,
      path: '/authorizations/clients/' + @client_id,
      method: 'PUT',
      auth: params.user + ':' + params.password,
      headers: {
        'User-Agent': 'aTox Github Binding v0.0.1',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/vnd.github.v3+json'
      }
    }
    if params.otp?
      opts.headers['X-GitHub-OTP'] = params.otp
    data = {
      "client_secret": @client_secret,
      "scopes": [
        "public_repo" #To fill up
      ],
      "note": "aTox github binding"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      console.log JSON.parse(data)
      @setToken JSON.parse(data).token
      callback()

  sendRequest: (params, callback) ->
    #params.opts, params.data, callback
    if not params.opts? or not params.data?
      console.error "opts and data must be defined"
      return
    req = https.request params.opts, (res) =>
      data = ''
      console.log "StatusCode: ", res.statusCode
      console.log "headers: ", res.headers
      if res.statusCode is 401 and res.headers['x-github-otp']?
        console.log "Two factor auth is required. Type: " + res.headers['x-github-otp']
      res.on 'data', (d) =>
        data += d
      res.on 'end', =>
        callback(data)
    req.write(JSON.stringify params.data)
    req.end()
    req.on 'error', (e) =>
      console.error e

  getToken: ->
    @htoken

  setToken: (token) ->
    @htoken = token

  authentificate: (opts) =>
    console.log "authentificate called"
    @createUserToken {user: params.user, password: params.password, otp: params.otp}, (params) =>
      opts.event.emit 'sendToFriend', {tid: -2, d: params.token}
      console.log "msg emmitted: ", d
      opts.event.on 'friendMsgAT', (e) =>
        console.log e.tid. e.d
        if e.tid is -3
          @deleteUserToken {id: params.id, token: params.token}, =>
            console.log "Token removed: ", params.id, " : ", params.token
          @setToken e.d
