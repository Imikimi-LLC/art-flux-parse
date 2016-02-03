Foundation = require 'art-foundation'
Parse = require 'parse'

{
  BaseObject, log, peek, isArray, objectWithout
} = Foundation

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

