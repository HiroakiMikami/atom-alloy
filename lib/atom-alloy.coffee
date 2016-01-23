Alloy = require './alloy'
AtomAlloyView = require './atom-alloy-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomAlloy =
  atomAlloyView: null
  alloy: null
  subscriptions: null

  config:
    alloyJar:
      title: 'Jar File of Alloy'
      type: 'string'
      default: '/usr/share/alloy/alloy4.2.jar'

  activate: (state) ->
    @alloy = new Alloy(atom.config.get("atom-alloy.alloyJar"))
    @atomAlloyView = new AtomAlloyView(status.atomAlloyViewState)

    # Wires between Alloy and AtomAlloyView
    @alloy.onCompileStarted(@atomAlloyView.onCompileStarted)
    @alloy.onCompileDone(@atomAlloyView.onCompileDone)
    @alloy.onCompileError(@atomAlloyView.onCompileError)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:compile': => @compile()

  consumeStatusBar: (statusBar) ->
    @atomAlloyView.consumeStatusBar(statusBar)

  deactivate: ->
    @subscriptions.dispose()
    @atomAlloyView?.destroy()
    @atomAlloyView = null
    @alloy.destroy()
    @alloy = null

  serialize: ->
    atomAlloyState: @atomAlloyView.serialize()

  compile: ->
    # Get a filepath of the active editor
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    path = editor.getPath()

    @alloy.compile(path)
