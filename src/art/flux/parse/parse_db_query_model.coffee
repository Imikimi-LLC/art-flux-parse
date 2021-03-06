{
  log, BaseObject, decapitalize, pluralize, pureMerge, shallowClone, isString,
  merge
  emailRegexp, urlRegexp, isNumber, nextTick, capitalize, inspect, isFunction, objectWithout, present, globalCount, time
} = require 'art-foundation'

Flux = require './flux'
{FluxDbQueryModel} = Flux.Db
{models} = Flux.Core.ModelRegistry

{parseCallbackHandlers} = require './parse_util'

###
usage:
class MyParseTable extends ParseDbModel

  # defines query model: myParseTableByField
  # returns all records where field == MyKey specified in your FluxComponent subscription:
  #   @subscriptions myParseTableByField: MyKey
  @query "field"

  # defines model: myParseTableByQueryName
  @query "queryName",
    customParseQuery: (queryKey, parseQueryObject) -> # => null
      # set all parse query parameters manually
      # Ex: matching one field
      parseQueryObject.equalTo "postId", queryKey
    postprocess: (resultsArrayPlainObjects, queryKey)

###
module.exports = class ParseDbQueryModel extends FluxDbQueryModel

  @getter
    objectClass:      -> @_singlesModel.objectClass
    newQuery:         -> @_singlesModel.getNewQuery()
    newPlainQuery:    -> @_singlesModel.getNewPlainQuery()

  _storeGet: (queryKey, callback) =>
    {customParseQuery, customIncludes, postprocess} = @_options

    # TODO - complain to Parse - The below code only sets up the query and yet it takes about 1ms per call!
    @onNextReady =>
      query = if customIncludes then @getNewPlainQuery() else @getNewQuery()

      if customParseQuery
        customParseQuery queryKey, query, models
      else if present queryKey
        query.equalTo @_parameterizedField, queryKey

      _callback = if postprocess
        (fluxRecord) ->
          if fluxRecord.data
            fluxRecord = merge fluxRecord, data: postprocess fluxRecord.data, queryKey
          callback fluxRecord
      else callback

      query.find @_singlesModel._parseCallbackHandlers null, _callback
    null
