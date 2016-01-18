{
  BaseObject, log, peek, isArray, objectWithout
} = require 'art.foundation'

# NOTE: To use this model, be sure to include the Parse client library such that "Parse" available globally.
module.exports = class ParseUtil extends BaseObject

  # https://parse.com/docs/js/symbols/Parse.Error.html
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Response_codes
  @parseErrorToStatusCode: parseErrorToStatusCode = (error) ->
    switch error.code

      when Parse.Error.CONNECTION_FAILED                then "unreachable"

      when Parse.Error.INVALID_ACL                      then 400
      when Parse.Error.INVALID_CHANNEL_NAME             then 400
      when Parse.Error.INVALID_CLASS_NAME               then 400
      when Parse.Error.INVALID_CONTENT_LENGTH           then 400
      when Parse.Error.INVALID_EMAIL_ADDRESS            then 400
      when Parse.Error.INVALID_EVENT_NAME               then 400
      when Parse.Error.INVALID_FILE_NAME                then 400
      when Parse.Error.INVALID_IMAGE_DATA               then 400
      when Parse.Error.INVALID_JSON                     then 400
      when Parse.Error.INVALID_KEY_NAME                 then 400
      when Parse.Error.INVALID_LINKED_SESSION           then 400
      when Parse.Error.INVALID_NESTED_KEY               then 400
      when Parse.Error.INVALID_POINTER                  then 400
      when Parse.Error.INVALID_PUSH_TIME_ERROR          then 400
      when Parse.Error.INVALID_QUERY                    then 400
      when Parse.Error.INVALID_ROLE_NAME                then 400
      when Parse.Error.MISSING_CONTENT_LENGTH           then 400
      when Parse.Error.MISSING_CONTENT_TYPE             then 400
      when Parse.Error.MISSING_OBJECT_ID                then 400
      when Parse.Error.INCORRECT_TYPE                   then 400
      when Parse.Error.USERNAME_MISSING                 then 400
      when Parse.Error.EMAIL_MISSING                    then 400
      when Parse.Error.PASSWORD_MISSING                 then 400
      when Parse.Error.COMMAND_UNAVAILABLE              then 400
      when Parse.Error.PUSH_MISCONFIGURED               then 400
      when Parse.Error.VALIDATION_ERROR                 then 400
      when Parse.Error.LINKED_ID_MISSING                then 400
      when Parse.Error.NOT_INITIALIZED                  then 400
      when Parse.Error.MUST_CREATE_USER_THROUGH_SIGNUP  then 400
      when Parse.Error.UNSUPPORTED_SERVICE              then 400 # Bad request

      when Parse.Error.SESSION_MISSING                  then 401 # Unauthorized

      when Parse.Error.OPERATION_FORBIDDEN              then 403 # Forbidden

      when Parse.Error.EMAIL_NOT_FOUND                  then 404
      when Parse.Error.OBJECT_NOT_FOUND                 then 404 # not found

      when Parse.Error.DUPLICATE_VALUE                  then 409
      when Parse.Error.EMAIL_TAKEN                      then 409
      when Parse.Error.USERNAME_TAKEN                   then 409
      when Parse.Error.ACCOUNT_ALREADY_LINKED           then 409 # Conflict

      when Parse.Error.FILE_TOO_LARGE                   then 413
      when Parse.Error.OBJECT_TOO_LARGE                 then 413 # Request Entity Too Large

      when Parse.Error.AGGREGATE_ERROR                  then 500
      when Parse.Error.FILE_DELETE_ERROR                then 500
      when Parse.Error.FILE_READ_ERROR                  then 500
      when Parse.Error.FILE_SAVE_ERROR                  then 500
      when Parse.Error.SCRIPT_FAILED                    then 500
      when Parse.Error.INTERNAL_SERVER_ERROR            then 500
      when Parse.Error.CACHE_MISS                       then 500
      when Parse.Error.TIMEOUT                          then 500
      when Parse.Error.UNSAVED_FILE_ERROR               then 500
      when Parse.Error.OTHER_CAUSE                      then 500
      when Parse.Error.X_DOMAIN_REQUEST                 then 500 # internal server error

      when Parse.Error.EXCEEDED_QUOTA                   then 504
      when Parse.Error.REQUEST_LIMIT_EXCEEDED           then 504 # Service Unavailable

      else 500

  @saveParseObject: (parseObject, fields, callback) ->
    fields = objectWithout fields, "id", "createdAt", "updatedAt" # strip "id" if present
    parseObject.save fields, parseCallbackHandlers fields, callback

  # Note: The Parse.Query error handler appear to differ from single-object handlers:
  #   queries: (error) ->
  #   singles: (object, error) ->
  # SBD: current solution: assume the last argument is the error object.
  # SBD: alt solution: for a in arguments; error = a if isNumber(a.code) && isString(a.message)
  @parseCallbackHandlers: parseCallbackHandlers = (pendingData, callback) ->

    success: (parseData) =>
      # log parseCallbackHandlers:success:pendingData:pendingData
      callback? parseToFluxRecord parseData
    error: =>
      # log parseCallbackHandlers:error:pendingData:pendingData,status: parseErrorToStatusCode error
      error = peek arguments # last argument
      fluxRecord =
        status: parseErrorToStatusCode error
        parseError: error
        errorMessage: error.message
      fluxRecord.pendingData = pendingData if pendingData
      callback? fluxRecord

  @parseObjectToPlainObject: parseObjectToPlainObject = (parseObject, recursionBlock = {}) ->
    key = parseObject.className + parseObject.id

    # we could return the already-converted object and exactly represent the parseObject data structure,
    # BUT, that would result in a data structure with circular references that toJSON won't work on.
    # Parse used to return non-circular data structures, but they don't anymore (as of 1.6.2)
    # So, we just return null.
    # In many cases, the FluxStore will already have this data stored anyway, so won't have to go out to Parse to fetch it.
    return null if recursionBlock[key]
    recursionBlock[key] = true

    plainObject =
      id: parseObject.id
      createdAt: parseObject.createdAt
      updatedAt: parseObject.updatedAt

    for k, v of parseObject.attributes
      plainObject[k] = if v instanceof Parse.Object
        plainObject[k + "Id"] = v.id
        if !v.createdAt
          # log notFetched:
          #   id: v.id
          #   createdAt: v.createdAt
          #   updatedAt: v.updatedAt
          # this happens when Parse hasn't actually fetched the object yet
          null
        else
          parseObjectToPlainObject v, recursionBlock
      else
        v

    recursionBlock[key] = false

    plainObject

  # Note: This probably works fine, but attributes is part of the Officially Parse API...
  @parseToPlainObject: parseToPlainObject = (parseData) ->
    if parseData
      if isArray parseData
        parseObjectToPlainObject el for el in parseData
      else
        parseObjectToPlainObject parseData

  @parseToFluxRecord: parseToFluxRecord = (parseData) ->
    parseData &&
      data: parseToPlainObject parseData
      parseData: parseData
      status: 200

