Emitter = null
fs = null

module.exports =
class Alloy
  @java: null
  @compUtil: null
  @translateAlloyToKodkod: null
  @a4Options: null
  @executerService: null
  emitter: null
  solver: null
  executedCommands: null
  commandQueue: null
  currentCommand: null

  initializeIfNecessary: ->
    # Launch JVM and add the classpath of alloy if it is not launched
    if not Alloy.java?
      # Initialize node-java
      Alloy.java ?= require "java"

      # Load alloy jar file
      Alloy.java.classpath.push(@alloyJarPath)

      # import the required class
      Alloy.compUtil ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.parser.CompUtil")
      Alloy.translateAlloyToKodkod ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.translator.TranslateAlloyToKodkod")
      Alloy.a4Options ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.translator.A4Options")

      Alloy.executerService ?= Alloy.java.callStaticMethodSync("java.util.concurrent.Executors", "newFixedThreadPool", 1)

    switch @solver
      when "BerkMin"
        solver = Alloy.a4Options.SatSolver.BerkMinPIPE
      when "MiniSat"
        solver = Alloy.a4Options.SatSolver.MiniSatJNI
      when "MiniSatProver"
        solver = Alloy.a4Options.SatSolver.MiniSatProverJNI
      when "SAT4J"
        solver = Alloy.a4Options.SatSolver.SAT4J
      when "Spear"
        solver = Alloy.a4Options.SatSolver.Spear
      when "ZChaff"
        solver = Alloy.a4Options.SatSolver.ZChaffJNI

    # make options
    @options = Alloy.java.newInstanceSync("edu.mit.csail.sdg.alloy4compiler.translator.A4Options")
    @options.solver = solver

  constructor: (@alloyJarPath, @solver, @tmpDirectory) ->
    Emitter ?= require('atom').Emitter
    fs ?= require 'fs'

    @emitter = new Emitter()
    @executedCommands = {}
    @commandQueue = []

    try
      fs.statSync(@tmpDirectory)
    catch error
      fs.mkdir(@tmpDirectory)

  destroy: () ->
    @emitter.dispose()
    @executedCommands = {}
    fs.unlink(@tmpDirectory)
    @commandQueue = null

  executeFromQueue: => @commandQueue[0]?()
  executeNextCommandFromQueue: =>
    @commandQueue.shift()
    if @commandQueue.length > 0 then @executeFromQueue()

  compile: (path) ->
    @initializeIfNecessary()

    # Add a command to the queue
    @commandQueue.push(
      =>
        @emitter.emit("CompileStarted", path)
        Alloy.executerService.submit(Alloy.java.newProxy("java.util.concurrent.Callable", {
          call: =>
            # TODO should use A4Reporter, but node-java cannot generate a subclass of class (not interface)
            Alloy.compUtil.parseEverything_fromFile(null, null, path, (err, result) =>
              try
                if err?
                  @emitter.emit("CompileError", {
                    path: path
                    err: err
                  })
                else
                  @emitter.emit("CompileDone", {
                    path: path
                    result: result
                  })
              finally
                @currentCommand = null
                @executeNextCommandFromQueue()
            )
        }), (err, result) =>
          if result? then @currentCommand ?= result
      ))
    if @commandQueue.length == 1
      # Execute a command if there are no commands that are executing now
      @executeFromQueue()

  isExecuteCommandRequired: (path, command) ->
    lastModifiedTime = fs.statSync(path).mtime.getTime()
    serializedCommand = "#{path}/#{command.label}"

    result = @executedCommands[serializedCommand]

    not (result? && (lastModifiedTime >= result.time))

  executeCommandIfNecessary: (path, world, command) ->
    # This command is already executed.
    return if not @isExecuteCommandRequired(path, command)

    serializedCommand = "#{path}/#{command.label}"
    result = @executedCommands[serializedCommand]
    if result? then fs.unlink(result.filename)

    delete @executeCommands[serializedCommand]

    @commandQueue.push( =>
      @emitter.emit("ExecuteStarted", command)
      Alloy.executerService.submit(Alloy.java.newProxy("java.util.concurrent.Callable", {
        call: =>
          Alloy.translateAlloyToKodkod.execute_command(null, world.getAllReachableSigsSync(), command, @options, (err, result) =>
            try
              if err?
                @emitter.emit("ExecuteError", {
                  command: command
                  err: err
                })
                return

              if result.satisfiableSync()
                # Store command, xml, and last updated time
                lastModifiedTime = fs.statSync(path).mtime.getTime()

                filename = "#{@tmpDirectory}/#{command.label}-#{new Date().getTime()}.xml"
                # Save a solution to a xml file
                result.writeXML(filename)
                @executedCommands[serializedCommand] = {
                  time: lastModifiedTime,
                  filename: filename,
                  solution: result
                }

              @emitter.emit("ExecuteDone", {
                command: command
                result: result
              })
            finally
              @currentCommand = null
              @executeNextCommandFromQueue()
          )
      }), (err, result) =>
          if result? then @currentCommand ?= result
      )
    )

    if @commandQueue.length == 1
      # Execute a command if there are no commands that are executing now
      @executeFromQueue()

  executeCommands: (path, world, commands) ->
    for command in commands
      @executeCommandIfNecessary(path, world, command)

  visualizeCommand: (path, world, command) =>
    serializedCommand = "#{path}/#{command.label}"

    visualize = () =>
      try
        result = @executedCommands[serializedCommand]
        return unless result?

        evaluator = Alloy.java.newProxy("edu.mit.csail.sdg.alloy4.Computer", {
          compute: (input) =>
            if typeof(input) is "string"
              e = Alloy.compUtil.parseOneExpression_fromStringSync(world, input);
              return result.solution.evalSync(e) + ""
            else
              return input + ""
        })

        Alloy.java.newInstance(
          "edu.mit.csail.sdg.alloy4viz.VizGUI",
          false, result.filename, null, null, evaluator)
      finally
        @executeNextCommandFromQueue()

    if @isExecuteCommandRequired(path, command)
      @executeCommandIfNecessary(path, world, command)

    @commandQueue.push(visualize)

    if @commandQueue.length == 1
      # Execute a command if there are no commands that are executing now
      @executeFromQueue()

  getCommands: (world) ->
    world.getAllCommandsSync().toArraySync()

  canceled: () =>
    return unless @currentCommand?
    @currentCommand.cancelSync(true)
    @executeNextCommandFromQueue()

  onCompileStarted: (callback) -> @emitter.on("CompileStarted", callback)
  onCompileError: (callback) -> @emitter.on("CompileError", callback)
  onCompileDone: (callback) -> @emitter.on("CompileDone", callback)

  onExecuteStarted: (callback) -> @emitter.on("ExecuteStarted", callback)
  onExecuteError: (callback) -> @emitter.on("ExecuteError", callback)
  onExecuteDone: (callback) -> @emitter.on("ExecuteDone", callback)
