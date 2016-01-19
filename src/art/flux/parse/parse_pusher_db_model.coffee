{
  nextTick, BaseObject, log, merge
  isString, isArray
  flatten, compact
  consistentJsonStringify
  inspectLean
} = require 'art-foundation'

ParseDbModel = require './parse_db_model'
ParseDbQueryModel = require './parse_db_query_model'

pusherEventName = "changed"

###
ParsePusherDbModel Notes:

- To use Pusher, be sure to include the pusher client library and initialize
  a global "window.pusher" client object. Ex:

  window.pusher = new Pusher 'PUSHER-CLIENT-KEY'

- This extends the ParseDbModel. To use Parse, include the Parse client libarary
  such that "window.Parse" is set up.

- Code in this file only receives "changed" pusher events. It doesn't send them.
  You need to add code to your Parse cloud-code to generate this events when
  Parse objects change.

- This code outputs via console.log, on init, a list of "@addDependency"
  lines which we use at Imikimi to copy-parse into our cloud-code to fully configure
  Parse + Pusher in our cloud-code. TODO: Copy-paste? Really? Can't we do something
  better?
###

###
PusherLink maintains pusher subscriptions to match FluxStore subscriptions.
The event should always be pusherEventName = "changed"
The pusher message is ignored.

TODO: This would be a bit cleaner as a Mixin, but I don't use Mixins much and
I'm not sure if BaseObject#include is "doing the right thing"...
###
class PusherLink extends BaseObject
  constructor: (model)->
    super
    @_model = model
    @_openPusherChannels = {}
    @_pusherChannelListeners = {}

    console.log "@addDependency " + inspectLean model:model.singlesModel.name, name: model.name, keyFromData: "(" + model.keyFromData.toString().replace(/\s+/g, " ") + ")"

  fluxStoreEntryUpdated: ({key}) ->
    return unless self.pusher
    return if @_openPusherChannels[key]

    channel = @getPusherChannel key

    ParsePusherDbModel.activeSubscriptions[channel] = key
    @_pusherChannelListeners[key] ||= => @_model.load key
    @_openPusherChannels[key] = pusher.subscribe channel
    # log "pusher.subscribe #{channel}"
    @_openPusherChannels[key].bind pusherEventName, @_pusherChannelListeners[key]

  fluxStoreEntryRemoved: ({key}) ->
    return unless self.pusher
    return unless @_openPusherChannels[key]

    channel = @getPusherChannel key

    delete ParsePusherDbModel.activeSubscriptions[channel]
    pusher.unsubscribe channel
    # log "pusher.unsubscribe #{channel}"
    @_openPusherChannels[key].unbind pusherEventName, @_pusherChannelListeners[key]
    delete @_openPusherChannels[key]
    delete @_pusherChannelListeners[key]

  getPusherChannel: (key) ->
    if isString key
      "#{@_model.name}__#{key}"
    else
      "#{@_model.name}__#{consistentJsonStringify(key).replace(/:/g, '-').replace(/[ {}\[\]""]/g, '')}"

class ParsePusherDbQueryModel extends ParseDbQueryModel
  constructor: ->
    super
    @_pusherLink = new PusherLink @

  fluxStoreEntryUpdated: (entry) -> @_pusherLink?.fluxStoreEntryUpdated entry
  fluxStoreEntryRemoved: (entry) -> @_pusherLink?.fluxStoreEntryRemoved entry

module.exports = class ParsePusherDbModel extends ParseDbModel
  @activeSubscriptions: {} # for debugging / introspection
  @queryModel: ParsePusherDbQueryModel

  constructor: ->
    super
    @_pusherLink = new PusherLink @

  fluxStoreEntryUpdated: (entry) -> @_pusherLink?.fluxStoreEntryUpdated entry
  fluxStoreEntryRemoved: (entry) -> @_pusherLink?.fluxStoreEntryRemoved entry
