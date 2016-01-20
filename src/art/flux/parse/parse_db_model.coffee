{
  BaseObject, mergeInfo, log, clone, slice, merge, arrayWithOne, peek
  inspect, isArray, isString, objectWithout, globalCount, time
} = require 'art-foundation'
Parse = require 'parse'

Flux = require './flux'
{FluxDbModel} = Flux.Db

{saveParseObject, parseCallbackHandlers} = require './parse_util'
ParseDbQueryModel = require './parse_db_query_model'

###
SEARCH

Doing Search with Parse: http://blog.parse.com/2013/03/19/implementing-scalable-search-on-a-nosql-backend/

>>> OR we can just use: http://aws.amazon.com/cloudsearch/

List of tokenizer/trimmer/stemmer/stopwords for each language:
  http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/analysis-lang-analyzer.html#analysis-lang-analyzer

Full Stack Javascript English Search pipeline: http://lunrjs.com/
  Default lunrjs pipeline:
    lunr.tokenizer runs first, then each word goes through:

    idx.pipeline.add(
      lunr.trimmer,
      lunr.stopWordFilter,
      lunr.stemmer
    )

Many-language Stemmers: https://www.npmjs.com/package/snowball-stemmer.jsx
Stopwords in many languages: http://www.ranks.nl/stopwords
###

# NOTE: To use this model, be sure to include the Parse client library such that "Parse" available globally.
module.exports = class ParseDbModel extends FluxDbModel
  @singletonClass()
  @queryModel: ParseDbQueryModel

  constructor: ->
    super
    @ObjectClass = Parse.Object.extend @parseObjectName = @class.name

  @getter
    newPlainQuery: -> new Parse.Query @ObjectClass
    newQuery: -> @_addIncludedRelations new Parse.Query @ObjectClass

  getParseObjectForObjectId: (objectId)->
    ret = new @ObjectClass
    ret.id = objectId
    ret


  # returns a promise AND supports the flux callback
  # NOTE: Parse.Promises don't support "progress". How do we want to support that?
  # The Q promise library supports progress: https://github.com/kriskowal/q
  put: (id, fields, callback) ->
    promise = new Parse.Promise
    super id, fields, (fluxRecord) ->
      callback? fluxRecord
      switch fluxRecord.status
        when "pending" then
        when 200 then promise.resolve fluxRecord.data
        else promise.reject fluxRecord

    promise

  # returns a promise that resolves to the posted data
  # also supports the legacy fluxRecord callback
  post: (fields, callback) ->
    promise = new Parse.Promise
    super fields, (fluxRecord) ->
      callback? fluxRecord
      switch fluxRecord.status
        when "pending" then
        when 200 then promise.resolve fluxRecord.data
        else promise.reject fluxRecord

    promise

  ##########################
  # private
  ##########################

  @getter
    includedRelations: ->
      unless @_includedRelations
        if @_includedRelationsRecursionBlock
          throw new Error "recursive included relations starting in #{@name}. _includedRelations so far: #{inspect @_includedRelations}"

        @_includedRelationsRecursionBlock = true

        @_includedRelations = []
        for field, {linkTo, include} of @fieldProperties when linkTo && include
          model = @models[linkTo]
          @_includedRelations.push field
          if modelsIncludedRelations = model.includedRelations
            for mir in modelsIncludedRelations
              @_includedRelations.push field + "." + mir

        # log includedRelations: model: @name, included: @_includedRelations
        @_includedRelationsRecursionBlock = false

        # log _relations:@relations, self:@
        # log relations:relationKeys if (relationKeys = Object.keys(@_relations)).length > 0
      @_includedRelations

  _addIncludedRelations: (query, prefix) ->
    prefix = if prefix then prefix + "." else ""
    for ir in @getIncludedRelations()
      ir = prefix + ir
      query.include ir
    query

  # include the named field, with THIS type (@/self), and its sub-included relations
  _includeField: (query, field) ->
    query.include field
    @_addIncludedRelations query, field
    query

  # eachFunction is passed a parse object representation of every object in the table, one at a time
  # callback passes fluxRecords with status and progress info
  _eachRemoteRecord: (eachFunction, callback)->
    batchSize = 100
    processBatch = (offset) =>
      log "#{@name} #{offset},#{batchSize}"
      query = @newQuery
      query.skip offset
      query.limit batchSize
      query.find()
      .then (results) =>
        log "#{@name} #{offset},#{batchSize} => #{results.length} results"
        for result in results
          eachFunction result
        if results.length == batchSize
          callback? status:"pending", processed:offset + results.length

          processBatch offset + batchSize
        else
          callback? status:200, processed:offset + results.length

      , (error) ->
        callback? status:"error", error:error
        console.error "#{@name}#_eachRemoteRecord error: #{error.message}"

    processBatch 0

  _updateAllRecords: ->
    @_eachRemoteRecord (record) =>
      @_updateParseRecord record
    , (fluxRecord) =>
      log fluxRecord

  # used for debugging
  logRecord: (id) ->
    @_storeGet id, (fluxRecord) =>
      if fluxRecord.status == 200
        a = {}
        a[@_name] = id:id, record:fluxRecord.data
        log a
      else if fluxRecord.status != "pending"
        console.log "#{@name}: Error: id:#{id}", fluxRecord

  _updateParseRecord: (parseData) ->
    for field, {model, idField} of @getRelations()
      fieldValue = parseData.get field
      idFieldValue = parseData.get idField
      if idFieldValue && !fieldValue
        log "#{@name}: updating '#{field}': #{idFieldValue}"
        parseData.set field, model._fieldsToParseObject id:idFieldValue

    if parseData.dirty()
      parseData.save()
      .then =>
        log "#{@name}: updating: #{parseData.id} (success)"
      , =>
        log "#{@name}: updating: #{parseData.id} (failure)"

  _postProcessGet: (fluxRecord) ->
    # @_updateParseRecord fluxRecord.parseData
    fluxRecord

  _storeGet:  (id, callback) ->
    @newQuery.get id, parseCallbackHandlers null, (fluxRecord) =>
      # if fluxRecord.status == 200
      #   log "#{@name}.get #{id} (success)"
      callback if fluxRecord.status == 200 then @_postProcessGet fluxRecord else fluxRecord
      null
    status: "pending"

  _storePost: (fields, callback) -> @_saveParseObject fields, callback

  _storeDelete: (id, callback) ->
    @getOrLoad id, (fluxRecord) =>
      switch fluxRecord.status
        when "pending" then null # wait, FluxRecord.get will send a "pending" to the client callback
        when 200       then fluxRecord.parseData.destroy parseCallbackHandlers null, callback
        else                callback fluxRecord
      null
    null

  _storePut: (id, fields, callback) ->
    fields = merge fields, id:id
    @_saveParseObject fields, callback
    null

  #####################
  # OVERRIDES
  #####################

  @getter
    specialCaseFields: ->
      unless @_specialCaseFields
        @_specialCaseFields = _specialCaseFields =
          id: true
          createdAt: true
          updatedAt: true

        for field, {idField} of @getRelations()
          _specialCaseFields[field] = true
          _specialCaseFields[idField] = true

      @_specialCaseFields

  _newParseObject: (forId) ->
    parseObject = new @ObjectClass
    if isString forId = forId?.id || forId
      parseObject.id = forId

    parseObject

  _fieldsToParseObject: (fields, intoParseObject) ->
    parseObject = intoParseObject || new @ObjectClass
    parseObject.id = fields.id if fields.id

    {relations, specialCaseFields} = @

    # process relation fields
    for field, {model, idField} of relations when fields[field] || fields[idField]
      relationObject = model._fieldsToParseObject fields[field] || id:fields[idField]
      parseObject.set field, relationObject

    # process all plain fields
    for field, value of fields when !specialCaseFields[field]
      parseObject.set field, value

    parseObject

  _saveParseObject: (fields, callback) ->
    parseObject = @_fieldsToParseObject fields
    parseObject.save null, parseCallbackHandlers fields, callback
