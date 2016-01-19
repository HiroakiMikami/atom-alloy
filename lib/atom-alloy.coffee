{CompositeDisposable} = require 'atom'

module.exports = AtomAlloy =
  atomAlloyView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:compile': => @compile()

  deactivate: ->
    @subscriptions.dispose()

  serialize: -> []

  compile: ->
    # Get a filepath of the active editor
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    path = editor.getPath()
