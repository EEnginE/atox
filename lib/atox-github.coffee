https = require('https')

module.exports =
class Github
  constructor: ->
    @client_id = '0b093d563346476729fb'
    @client_secret = '8fdsfdsgfdsg98d7'
    @htoken = {'id': 0, 'token': ""}

  getUserInfo: (params, callback) ->
    #params.user, callback
    #https://developer.github.com/v3/users/
    path = '/users/'
    if params.user?
      path += params.user
    @request({'path': path}, callback)

  getUserImage: (params, callback) ->
    #params.user, callback
    if not params.user?
      params.user = ''
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
    if params.otp? and params.otp != ""
      opts.headers['X-GitHub-OTP'] = params.otp
    data = {
      "scopes": [], # No scopes: read-only access to public information
      "note": "aTox github binding",
      "note_url": "https://github.com/EEnginE/atox"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      parsedData = JSON.parse(data)
      console.log parsedData
      @setToken parsedData.id parsedData.token
      callback({id: parsedData.id, token: parsedData.token, data: parsedData})

  checkToken: (params, callback) ->
    #params.id, callback
    if not params.id?
      params.id = @getID()

    path = '/authorizations/' + params.id
    @request {'path': path}, (parsedData) =>
      if parsedData.id? and parsedData.id is params.id
        callback({id: parsedData.id, valid: true, data: parsedData})
      else
        callback({id: params.id, valid: false, data: parsedData})

  getRepoInfo: (params, callback) ->
    #params.owner, params.repo, callback
    if not params.owner? or not params.repo?
      return

    path = '/repos/' + params.owner + '/' + params.repo
    @request({'path': path}, callback)

  getTagInfo: (params, callback) ->
    #params.owner, params.repo, params.id callback
    if not params.owner? or not params.repo?
      return

    path = '/repos/' + params.owner + '/' + params.repo + '/tags'
    @request({'path': path}, callback)
    
  getIssueInfo: (params, callback) ->
    #params.owner, params.repo, params.id callback
    if not params.owner? or not params.repo?
      return

    path = '/repos/' + params.owner + '/' + params.repo + '/issues'
    if params.id?
      path += '/' + params.id
    @request({'path': path}, callback)

  getCommitInfo: (params, callback) ->
    #params.owner, params.repo, params.sha callback
    if not params.owner? or not params.repo?
      return

    path = '/repos/' + params.owner + '/' + params.repo + '/commits'
    if params.sha?
      path += '/' + params.sha
    @request({'path': path}, callback)

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
      "note": "aTox github binding",
      "note_url": "https://github.com/EEnginE/atox"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      console.log data
      console.log JSON.parse(data)
      @setToken JSON.parse(data).id JSON.parse(data).token
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
      "scopes": [],
      "note": "aTox github binding",
      "note_url": "https://github.com/EEnginE/atox"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      parsedData = JSON.parse(data)
      console.log parsedData
      @setToken parsedData.id parsedData.token
      callback({id: parsedData.id, token: parsedData.token, data: parsedData})

  request: (params, callback) ->
    #params.path, params.method, callback
    if @htoken.token is ''
      return
    if not params.path?
      return
    if not params.method?
      params.method = 'GET'
    opts = {
      hostname: 'api.github.com',
      port: 443,
      path: params.path,
      method: params.method,
      headers: {
        'User-Agent': 'aTox Github Binding v0.0.1',
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': "token " + @htoken.token,
        'Accept': 'application/vnd.github.v3+json'
      }
    }
    data = {
      "note": "aTox github binding",
      "note_url": "https://github.com/EEnginE/atox"
    }
    @sendRequest {opts: opts, data: data}, (data) =>
      parsedData = JSON.parse(data)
      console.log parsedData
      callback(parsedData)

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
    @htoken.token

  getID: ->
    @htoken.id

  setToken: (id, token) ->
    @htoken.id = id
    @htoken.token = token

  authentificate: (params) =>
    console.log "authentificate called"
    #@createUserToken {user: params.user, password: params.password, otp: params.otp}, (opts) =>
      #Send to friend params.token
      #on Answer, needs to be fixed
        #console.log e.tid. e.d
        #if e.tid is -3
          #@deleteUserToken {id: params.id, token: params.token}, =>
            #console.log "Token removed: ", params.id, " : ", params.token
          #@setToken e.d
