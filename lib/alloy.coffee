{Emitter} = require 'atom'

module.exports =
class Alloy
  @java: null
  @compUtil: null
  @translateAlloyToKodkod: null
  @a4Options: null
  emitter: null
  solver: null

  constructor: (@alloyJarPath, solver) ->
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

    @emitter = new Emitter()

    switch solver
      when "BerkMin"
        @solver = Alloy.a4Options.SatSolver.BerkMinPIPE
      when "MiniSat"
        @solver = Alloy.a4Options.SatSolver.MiniSatJNI
      when "MiniSatProver"
        @solver = Alloy.a4Options.SatSolver.MiniSatProverJNI
      when "SAT4J"
        @solver = Alloy.a4Options.SatSolver.SAT4J
      when "Spear"
        @solver = Alloy.a4Options.SatSolver.Spear
      when "ZChaff"
        @solver = Alloy.a4Options.SatSolver.ZChaffJNI

  destroy: () ->
    @emitter.dispose()

  compile: (path) ->
    @emitter.emit("CompileStarted", path)
    # TODO should use A4Reporter, but node-java cannot generate a subclass of class (not interface)
    Alloy.compUtil.parseEverything_fromFile(null, null, path, (err, result) =>
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
    )

  executeCommands: (world, commands) ->
    allCommands = @getCommands(world)

    # make option
    options = Alloy.java.newInstanceSync("edu.mit.csail.sdg.alloy4compiler.translator.A4Options")
    options.solver = @solver

    for command in commands
      @emitter.emit("ExecuteStarted", command)
      Alloy.translateAlloyToKodkod.execute_command(
        null, world.getAllReachableSigsSync(), command, options,
        (err, result) =>
          if err?
            @emitter.emit("ExecuteError", {
              command: command
              err: err
            })
          else
            @emitter.emit("ExecuteDone", {
              command: command
              result: result
            })

      )

  getCommands: (world) ->
    world.getAllCommandsSync().toArraySync()

  onCompileStarted: (callback) -> @emitter.on("CompileStarted", callback)
  onCompileError: (callback) -> @emitter.on("CompileError", callback)
  onCompileDone: (callback) -> @emitter.on("CompileDone", callback)

  onExecuteStarted: (callback) -> @emitter.on("ExecuteStarted", callback)
  onExecuteError: (callback) -> @emitter.on("ExecuteError", callback)
  onExecuteDone: (callback) -> @emitter.on("ExecuteDone", callback)
