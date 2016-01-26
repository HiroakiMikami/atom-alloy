SelectListView = require('atom-space-pen-views').SelectListView
Emitter = null

module.exports =
class AlloyCommandPaletteView extends SelectListView
  panel: null
  emitter: null
  constructor: () ->
    super()

    # Require the module
    Emitter ?= require('atom').Emitter

    # Initialize the field
    @emitter = new Emitter()

  destroy: () ->
    @panel?.destroy()
    @emitter.dispose()

  open: (items) ->
    # Initialize the field
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

    # Show the view
    @setItems(items)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) -> "<li>#{item.label}</li>"

  getEmptyMessage: -> "There are no commands to execute."

  confirmed: (item) ->
    @emitter.emit("OnConfirmed", item)
    @panel.hide()

  onConfirmed: (callback) -> @emitter.on("OnConfirmed", callback)

  cancelled: -> @panel.hide()
