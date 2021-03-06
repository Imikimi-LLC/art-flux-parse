Foundation = require 'art-foundation'
Parse = require 'parse'
ParseDbModel = require './parse_db_model'

{BaseObject, present, log} = Foundation

# {saveParseObject, parseCallbackHandlers, parseToFluxRecord, parseToPlainObject} = require './parse_util'

module.exports = class ParseCurrentUser extends ParseDbModel
  # @register()

  toFluxKey: (key) -> "current"

  loadWithPromise: ->

  load: ->
    @reload()
    @_parseToFluxRecord @_currentUser
    null

  reload: ->
    Parse.User.currentAsync()
    .then (currentUser) -> currentUser?.fetch()
    .then (@_currentUser) =>
      @updateFluxStore @toFluxKey(), @_parseToFluxRecord @_currentUser
      @_currentUser
    , ({code, message}) =>
      log errorFetchingCurrentUser: code:code, message:message, INVALID_SESSION_TOKEN:Parse.Error.INVALID_SESSION_TOKEN
      if code == Parse.Error.INVALID_SESSION_TOKEN
        log "CurrentUser: INVALID_SESSION_TOKEN detected - logging out"
        Parse.User.logOut()

  @getter
    currentUser:       -> @_parseToPlainObject @_currentUser
    currentUserId:     -> @_currentUser?.id

  get: -> @_parseToPlainObject @_currentUser

  signUp: (userRecord, callback)->

    user = new Parse.User()
    user.set k, v for k, v of userRecord

    user.signUp null, @_parseCallbackHandlers null, (fluxRecord) =>
      @reload()
      callback? fluxRecord

  logIn: (userRecord, callback) ->
    {username, password} = userRecord

    @log logIn:username:username, passwordPresent: present password # DONT ACTUALLY LOG THE PASSWORD!

    Parse.User.logIn username, password, @_parseCallbackHandlers null, (fluxRecord) =>
      @reload()
      callback? fluxRecord

  logOut: ->
    Parse.User.logOut()
    @reload()
