Emitter = null
PromiseWithJava = null
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
  promise: null
  currentCommand: null

  # Launch JVM and add the classpath of alloy if it is not launched
  initializeIfNecessary: ->
    return if Alloy.java? # already initialized

    # Initialize node-java
    Alloy.java ?= require "java"

    # Load alloy jar file
    Alloy.java.classpath.push(@alloyJarPath)

    # Import the required class
    Alloy.compUtil ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.parser.CompUtil")
    Alloy.translateAlloyToKodkod ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.translator.TranslateAlloyToKodkod")
    Alloy.a4Options ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.translator.A4Options")
    Alloy.executerService ?= Alloy.java.callStaticMethodSync("java.util.concurrent.Executors", "newFixedThreadPool", 1)

    # Set the solver
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

    # Make options for executing
    @options = Alloy.java.newInstanceSync("edu.mit.csail.sdg.alloy4compiler.translator.A4Options")
    @options.solver = solver

  constructor: (@alloyJarPath, @solver, @tmpDirectory) ->
    # Require the modules
    Emitter ?= require('atom').Emitter
    fs ?= require 'fs'
    PromiseWithJava ?= require('./promise-with-java')

    # Initialize the fields
    @emitter = new Emitter()
    @promise = new PromiseWithJava()
    @executedCommands = {}

    # Make a temporary directory
    try
      fs.statSync(@tmpDirectory)
    catch error
      fs.mkdir(@tmpDirectory)

  destroy: () ->
    @emitter.dispose()
    @executedCommands = {}
    fs.unlink(@tmpDirectory)
    @promise.destroy()
    @promise = null

  compile: (path) ->
    @initializeIfNecessary()

    # Add a command to the queue
    @promise.then((succeeded, rejected) =>
      @emitter.emit("CompileStarted", path)
      callable = Alloy.java.newProxy("java.util.concurrent.Callable", {
        call: =>
          Alloy.compUtil.parseEverything_fromFile(null, null, path, (err, result) =>
            try
              if err?
                @emitter.emit("CompileError", {
                  path: path
                  err: err
                })
                rejected(err)
              else
                @emitter.emit("CompileDone", {
                  path: path
                  result: result
                })
                succeeded(result)
            finally
              @currentCommand = null
          )
      })
      Alloy.executerService.submit(callable, (err, result) => if result? then @currentCommand ?= result)
    )

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

    @promise.then((succeeded, rejected) =>
      @emitter.emit("ExecuteStarted", command)
      callable = Alloy.java.newProxy("java.util.concurrent.Callable", {
        call: =>
          Alloy.translateAlloyToKodkod.execute_command(null, world.getAllReachableSigsSync(), command, @options, (err, result) =>
            try
              if err?
                @emitter.emit("ExecuteError", {
                  command: command
                  err: err
                })
                rejected(err)
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
              succeeded(result)
            finally
              @currentCommand = null
          )
      })
      Alloy.executerService.submit(callable, (err, result) =>
          if result? then @currentCommand ?= result
      )
    )

  executeCommands: (path, world, commands) ->
    for command in commands
      @executeCommandIfNecessary(path, world, command)

  visualizeCommand: (path, world, command) =>
    serializedCommand = "#{path}/#{command.label}"

    visualize = (succeeded, rejected) =>
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
        succeeded()

    if @isExecuteCommandRequired(path, command)
      @executeCommandIfNecessary(path, world, command)
      @promise.ifSucceeded(visualize)
    else
      @promise.then(visualize)

  getCommands: (world) ->
    world.getAllCommandsSync().toArraySync()

  canceled: () =>
    return unless @currentCommand?
    @currentCommand.cancelSync(true)
    @promise.cancelCurrentTask()

  onCompileStarted: (callback) -> @emitter.on("CompileStarted", callback)
  onCompileError: (callback) -> @emitter.on("CompileError", callback)
  onCompileDone: (callback) -> @emitter.on("CompileDone", callback)

  onExecuteStarted: (callback) -> @emitter.on("ExecuteStarted", callback)
  onExecuteError: (callback) -> @emitter.on("ExecuteError", callback)
  onExecuteDone: (callback) -> @emitter.on("ExecuteDone", callback)
