Alloy = require './alloy'
AlloyCommandPaletteView = require './alloy-command-palette-view'
AtomAlloyView = require './atom-alloy-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomAlloy =
  atomAlloyView: null
  alloyCommandPaletteView: null
  alloy: null
  subscriptions: null

  config:
    alloyJar:
      title: 'Jar File of Alloy'
      type: 'string'
      default: '/usr/share/alloy/alloy4.2.jar'
    solver:
      # TODO should show all the candidates
      title: 'SAT solver used in Alloy'
      type: 'string'
      default: 'SAT4J'
    tmpDirectory:
      title: 'A temporary directory used by this package'
      type: 'string'
      default: '/tmp/atom-alloy'

  activate: (state) ->
    @alloy = new Alloy(
      atom.config.get("atom-alloy.alloyJar"),
      atom.config.get("atom-alloy.solver"),
      atom.config.get("atom-alloy.tmpDirectory")
    )

    @atomAlloyView = new AtomAlloyView(status.atomAlloyViewState)

    @alloyCommandPaletteView = new AlloyCommandPaletteView()

    # Wires between the components
    @alloy.onCompileStarted(@atomAlloyView.compileStarted)
    @alloy.onCompileDone(@atomAlloyView.compileDone)
    @alloy.onCompileError(@atomAlloyView.compileError)
    @alloy.onExecuteStarted(@atomAlloyView.executeStarted)
    @alloy.onExecuteDone(@atomAlloyView.executeDone)
    @alloy.onExecuteError(@atomAlloyView.executeError)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:compile': => @compile()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:execute': => @execute()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:execute-all': => @executeAll()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:visualize': => @visualize()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:visualize-all': => @visualizeAll()

  consumeStatusBar: (statusBar) ->
    @atomAlloyView.consumeStatusBar(statusBar)

  deactivate: ->
    @subscriptions.dispose()

    @atomAlloyView?.destroy()
    @atomAlloyView = null

    @alloyCommandPaletteView?.destroy()
    @alloyCommandPaletteView = null

    @alloy.destroy()
    @alloy = null

  serialize: ->
    atomAlloyState: @atomAlloyView.serialize()

  getActivePath: () ->
    # Get a path of the active editor
    editor = atom.workspace.getActiveTextEditor()
    return editor?.getPath()

  selectCommand: (world, confirmed) ->
    # Obtain list of commands
    commands = @alloy.getCommands(world)

    paletteCallback1 = @alloyCommandPaletteView.onConfirmed(confirmed)
    paletteCallback2 = @alloyCommandPaletteView.onConfirmed(->
      # Remove the callbacks
      paletteCallback1.dispose()
      paletteCallback2.dispose()
    )

    # Open palette to select a command
    @alloyCommandPaletteView.open(commands)

  compile: ->
    path = @getActivePath()
    return unless path?

    @alloy.compile(path)

  execute: ->
    # TODO may be unreadable because event based callbacks are nested.
    callback = @alloy.onCompileDone((result) =>
      # Obtain the world instance
      world = result.result

      # Select a command
      @selectCommand(world, (command) => @alloy.executeCommands(result.path, world, [command]))

      # Remove this callback
      callback.dispose()
    )

    # Compile alloy files
    @compile()

  executeAll: ->
    # TODO may be unreadable because event based callbacks are nested.
    callback = @alloy.onCompileDone((result) =>
      # Obtain the world instance
      world = result.result

      # Obtain list of commands
      commands = @alloy.getCommands(world)

      @alloy.executeCommands(result.path, world, commands)

      # Remove this callback
      callback.dispose()
    )

    # Compile alloy files
    @compile()

  visualize: ->

  visualizeAll: ->
