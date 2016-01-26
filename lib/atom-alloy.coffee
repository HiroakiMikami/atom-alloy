Alloy = null
AlloyCommandPaletteView = null
AtomAlloyView = null
CompositeDisposable = null

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
      title: 'SAT solver used in Alloy'
      description: 'BerkMin, MiniSat, MiniSatProver, SAT4J, Spear, and ZChaff are supported now.'
      type: 'string'
      default: 'SAT4J'
    tmpDirectory:
      title: 'A temporary directory used by this package'
      type: 'string'
      default: '/tmp/atom-alloy'

  activate: (state) ->
    # Require the modules
    Alloy ?= require './alloy'
    AlloyCommandPaletteView ?= require './alloy-command-palette-view'
    AtomAlloyView ?= require './atom-alloy-view'
    CompositeDisposable ?= require('atom').CompositeDisposable

    # Initialize the fields
    @alloy = new Alloy(
      atom.config.get("atom-alloy.alloyJar"),
      atom.config.get("atom-alloy.solver"),
      atom.config.get("atom-alloy.tmpDirectory")
    )
    @atomAlloyView = new AtomAlloyView(status.atomAlloyViewState)
    @alloyCommandPaletteView = new AlloyCommandPaletteView()
    @subscriptions = new CompositeDisposable

    # Wire between the components
    @alloy.onCompileStarted(@atomAlloyView.compileStarted)
    @alloy.onCompileDone(@atomAlloyView.compileDone)
    @alloy.onCompileError(@atomAlloyView.compileError)
    @alloy.onExecuteStarted(@atomAlloyView.executeStarted)
    @alloy.onExecuteDone(@atomAlloyView.executeDone)
    @alloy.onExecuteError(@atomAlloyView.executeError)

    @atomAlloyView.onCanceled(() => @alloy.canceled())

    # Register the commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:compile': => @compile()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:execute': => @execute()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:execute-all': => @executeAll()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:visualize': => @visualize()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:visualize-all': => @visualizeAll()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-alloy:cancel': => @cancel()

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

  # This function is required by status-bar module
  consumeStatusBar: (statusBar) -> @atomAlloyView.consumeStatusBar(statusBar)

  # Get a path of the active editor
  getActivePath: () ->
    editor = atom.workspace.getActiveTextEditor()
    return editor?.getPath()

  selectCommand: (world, confirmed) ->
    # Obtain list of commands
    commands = @alloy.getCommands(world)

    paletteCallback = @alloyCommandPaletteView.onConfirmed((result) ->
      confirmed(result)
      # Remove this callback
      paletteCallback.dispose()
    )

    # Open palette to select a command
    @alloyCommandPaletteView.open(commands)

  compile: ->
    path = @getActivePath()
    return unless path?

    @alloy.compile(path)

  executeCommandTemplate: (getCommands) ->
    callback = @alloy.onCompileDone((result) =>
      # Obtain the world instance
      world = result.result

      # calculate commands that are going to be executed
      getCommands(world, (commands) =>
        @alloy.executeCommands(result.path, world, commands)
      )

      # Remove this callback
      callback.dispose()
    )

    # Compile alloy files
    @compile()

  execute: ->
    @executeCommandTemplate((world, callback) =>
      # Select a command
      @selectCommand(world, (command) => callback([command]))
    )

  executeAll: ->
    @executeCommandTemplate((world, callback) =>
      callback(@alloy.getCommands(world))
    )

  visualizeCommandTemplate: (getCommands) ->
    callback = @alloy.onCompileDone((result) =>
      world = result.result

      getCommands(world, (commands) =>
        for command in commands
          @alloy.visualizeCommand(result.path, world, command)
      )
      # Remove this callback
      callback.dispose()
    )
    @compile()


  visualize: ->
    @visualizeCommandTemplate((world, callback) =>
      # Select a command
      @selectCommand(world, (command) => callback([command]))
    )

  visualizeAll: ->
    @visualizeCommandTemplate((world, callback) =>
      callback(@alloy.getCommands(world))
    )

  cancel: -> @alloy.canceled()
