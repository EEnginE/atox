https = require('https')

module.exports =
class Github
  constructor: ->
    console.log "constructed"
    @client_id = '0b093d563346476729fb'
    @client_secret = 'a79923fcb9ef2f4a9b4243e14a87d92c16379d64'
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
    req = https.request opts, (res) =>
      data = ''
      console.log "StatusCode: ", res.statusCode
      console.log "headers: ", res.headers
      res.on 'data', (d) =>
        data += d
      res.on 'end', =>
        callback(JSON.parse(data))
    req.write(JSON.stringify data)
    req.end()
    req.on 'error', (e) =>
      console.error e

  getUserImage: (params, callback) ->
    #params.user, callback
    @getUserInfo {user: params.user}, (info) =>
      callback(info.avatar_url)


  authentificate: (params, callback) ->
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
    req = https.request opts, (res) =>
      data = ''
      console.log "StatusCode: ", res.statusCode
      console.log "headers: ", res.headers
      if res.statusCode is 401 and res.headers['x-github-otp']?
        console.log "Two factor auth is required. Type: " + res.headers['x-github-otp']
      res.on 'data', (d) =>
        data += d
      res.on 'end', =>
        @setToken JSON.parse(data).token
        callback()
    req.write(JSON.stringify data)
    req.end()
    req.on 'error', (e) =>
      console.error e

  getToken: ->
    @htoken

  setToken: (token) ->
    @htoken = token
