define [
  'lib/art/foundation'
  'lib/art/flux/core'
  './parse_util'
], (Foundation, FluxCore, ParseUtil) ->
  {BaseObject, present} = Foundation

  {FluxStore, FluxModel} = FluxCore
  {fluxStore} = FluxStore

  {saveParseObject, parseCallbackHandlers, parseToFluxRecord, parseToPlainObject} = ParseUtil

  class ParseCurrentUser extends FluxModel
    # @register()

    toFluxKey: (key) -> "current"

    loadWithPromise: ->

    load: ->
      @reload()
      parseToFluxRecord @_currentUser
      null

    reload: ->
      Parse.User.currentAsync()
      .then (currentUser) -> currentUser?.fetch()
      .then (@_currentUser) =>
        @updateFluxStore @toFluxKey(), parseToFluxRecord @_currentUser
        @_currentUser
      , ({code, message}) =>
        log errorFetchingCurrentUser: code:code, message:message, INVALID_SESSION_TOKEN:Parse.Error.INVALID_SESSION_TOKEN
        if code == Parse.Error.INVALID_SESSION_TOKEN
          log "CurrentUser: INVALID_SESSION_TOKEN detected - logging out"
          Parse.User.logOut()

    @getter
      currentUser:       -> parseToPlainObject @_currentUser
      currentUserId:     -> @_currentUser?.id

    signUp: (userRecord, callback)->

      user = new Parse.User()
      user.set k, v for k, v of userRecord

      user.signUp null, parseCallbackHandlers null, (fluxRecord) =>
        @reload()
        callback? fluxRecord

    logIn: (userRecord, callback) ->
      {username, password} = userRecord

      @log logIn:username:username, passwordPresent: present password # DONT ACTUALLY LOG THE PASSWORD!

      Parse.User.logIn username, password, parseCallbackHandlers null, (fluxRecord) =>
        @reload()
        callback? fluxRecord

    logOut: ->
      Parse.User.logOut()
      @reload()
