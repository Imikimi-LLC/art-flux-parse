Foundation = require 'art-foundation'
Parse = require 'parse'
{failure, missing, success} = require 'art-flux'

{
  BaseObject, log, peek, isArray, objectWithout
} = Foundation

# NOTE: To use this model, be sure to include the Parse client library such that "Parse" available globally.
module.exports = class ParseUtil extends BaseObject

  # https://parse.com/docs/js/symbols/Parse.Error.html
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Response_codes
  @parseErrorToFluxStatus: parseErrorToFluxStatus = (error) ->
    switch error.code

      when Parse.Error.CONNECTION_FAILED                then failure

      when Parse.Error.INVALID_ACL                      then failure
      when Parse.Error.INVALID_CHANNEL_NAME             then failure
      when Parse.Error.INVALID_CLASS_NAME               then failure
      when Parse.Error.INVALID_CONTENT_LENGTH           then failure
      when Parse.Error.INVALID_EMAIL_ADDRESS            then failure
      when Parse.Error.INVALID_EVENT_NAME               then failure
      when Parse.Error.INVALID_FILE_NAME                then failure
      when Parse.Error.INVALID_IMAGE_DATA               then failure
      when Parse.Error.INVALID_JSON                     then failure
      when Parse.Error.INVALID_KEY_NAME                 then failure
      when Parse.Error.INVALID_LINKED_SESSION           then failure
      when Parse.Error.INVALID_NESTED_KEY               then failure
      when Parse.Error.INVALID_POINTER                  then failure
      when Parse.Error.INVALID_PUSH_TIME_ERROR          then failure
      when Parse.Error.INVALID_QUERY                    then failure
      when Parse.Error.INVALID_ROLE_NAME                then failure
      when Parse.Error.MISSING_CONTENT_LENGTH           then failure
      when Parse.Error.MISSING_CONTENT_TYPE             then failure
      when Parse.Error.MISSING_OBJECT_ID                then failure
      when Parse.Error.INCORRECT_TYPE                   then failure
      when Parse.Error.USERNAME_MISSING                 then failure
      when Parse.Error.EMAIL_MISSING                    then failure
      when Parse.Error.PASSWORD_MISSING                 then failure
      when Parse.Error.COMMAND_UNAVAILABLE              then failure
      when Parse.Error.PUSH_MISCONFIGURED               then failure
      when Parse.Error.VALIDATION_ERROR                 then failure
      when Parse.Error.LINKED_ID_MISSING                then failure
      when Parse.Error.NOT_INITIALIZED                  then failure
      when Parse.Error.MUST_CREATE_USER_THROUGH_SIGNUP  then failure
      when Parse.Error.UNSUPPORTED_SERVICE              then failure # Bad request

      when Parse.Error.SESSION_MISSING                  then failure # Unauthorized

      when Parse.Error.OPERATION_FORBIDDEN              then failure # Forbidden

      when Parse.Error.EMAIL_NOT_FOUND                  then missing
      when Parse.Error.OBJECT_NOT_FOUND                 then missing # not found

      when Parse.Error.DUPLICATE_VALUE                  then failure
      when Parse.Error.EMAIL_TAKEN                      then failure
      when Parse.Error.USERNAME_TAKEN                   then failure
      when Parse.Error.ACCOUNT_ALREADY_LINKED           then failure # Conflict

      when Parse.Error.FILE_TOO_LARGE                   then failure
      when Parse.Error.OBJECT_TOO_LARGE                 then failure # Request Entity Too Large

      when Parse.Error.AGGREGATE_ERROR                  then failure
      when Parse.Error.FILE_DELETE_ERROR                then failure
      when Parse.Error.FILE_READ_ERROR                  then failure
      when Parse.Error.FILE_SAVE_ERROR                  then failure
      when Parse.Error.SCRIPT_FAILED                    then failure
      when Parse.Error.INTERNAL_SERVER_ERROR            then failure
      when Parse.Error.CACHE_MISS                       then failure
      when Parse.Error.TIMEOUT                          then failure
      when Parse.Error.UNSAVED_FILE_ERROR               then failure
      when Parse.Error.OTHER_CAUSE                      then failure
      when Parse.Error.X_DOMAIN_REQUEST                 then failure # internal server error

      when Parse.Error.EXCEEDED_QUOTA                   then failure
      when Parse.Error.REQUEST_LIMIT_EXCEEDED           then failure # Service Unavailable

      else failure

