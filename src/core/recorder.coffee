
assign = require("object-assign")
Emitter = require("component-emitter")
Immutable = require("immutable")

core =
  records: Immutable.List()
  pointer: 0
  isTravelling: false
  initial: Immutable.Map()
  updater: updater = (state) ->
    state
  inProduction: false

recorderEmitter = new Emitter()

callUpdater = (actionType, actionData) ->
  chunks = actionType.split("/")
  groupName = chunks[0]
  if groupName is "actions-recorder"
    switch chunks[1]
      when "commit"
        initial: core.records.reduce (acc, action) ->
          core.updater acc, action.get(0), action.get(1)
        , core.initial
        records: Immutable.List()
        pointer: 0
        isTravelling: false
      when "reset"
        records: Immutable.List()
        pointer: 0
        isTravelling: false
      when "peek"
        pointer: actionData
        isTravelling: true
      when "discard"
        records: core.records.slice(0, core.pointer + 1)
      when "switch"
        isTravelling: not core.isTravelling
        pointer: 0
      else
        console.warn "Unknown actions-recorder action: " + actionType
        {}
  else
    records: core.records.push(Immutable.List([actionType, actionData]))

getNewStore = getNewStore = ->
  if core.isTravelling and core.pointer >= 0
    core.records.slice(0, core.pointer + 1).reduce((acc, action) ->
      core.updater acc, action.get(0), action.get(1)
    , core.initial)
  else core.records.reduce (acc, action) ->
    core.updater acc, action.get(0), action.get(1)
  , core.initial

exports.setup = (options) ->
  assign core, options

exports.request = (fn) ->
  fn getNewStore(), core

exports.subscribe = (fn) ->
  recorderEmitter.on "update", fn

exports.unsubscribe = (fn) ->
  recorderEmitter.off "update", fn

exports.dispatch = (actionType, actionData) ->
  actionData = Immutable.fromJS(actionData)
  if core.inProduction
    core.initial = core.updater(core.initial, actionType, actionData)
    core.records = core.records.push Immutable.List([actionType, actionData])
    recorderEmitter.emit "update", core.initial, core
  else
    assign core, callUpdater(actionType, actionData)
    recorderEmitter.emit "update", getNewStore(), core
  return