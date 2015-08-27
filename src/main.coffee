
React = require("react")
Immutable = require("immutable")

recorder = require("./core/recorder")
updater = require("./updater")

require "origami-ui"
require "../style/main.css"

defaultInfo =
  initial: Immutable.List()
  records: Immutable.List()
  pointer: 0
  updater: updater

rawPersistent = localStorage.getItem("actions-recorder")
if rawPersistent
  try
    jsonPersistent = JSON.parse(rawPersistent)
    defaultInfo.initial = Immutable.fromJS(jsonPersistent.initial)
    defaultInfo.records = Immutable.fromJS(jsonPersistent.records)
    defaultInfo.pointer = jsonPersistent.pointer
    defaultInfo.isTravelling = jsonPersistent.isTravelling
recorder.setup defaultInfo
window.onbeforeunload = ->
  recorder.request (store, core) ->
    jsonPersistent =
      records: core.records.toJS()
      initial: core.initial.toJS()
      pointer: core.pointer
      isTravelling: core.isTravelling

    rawPersistent = JSON.stringify(jsonPersistent)
    localStorage.setItem "actions-recorder", rawPersistent


Page = React.createFactory(require("./app/page"))
render = render = (store, recorder) ->
  React.render Page(
    store: store
    recorder: recorder
  ), document.body

recorder.request render
recorder.subscribe render