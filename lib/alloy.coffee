{Emitter} = require 'atom'

module.exports =
class Alloy
  @java: null
  @compUtil: null
  @emitter: null
  @worlds: null

  constructor: (@alloyJarPath) ->
    # Launch JVM and add the classpath of alloy if it is not launched
    if not Alloy.java?
      # Initialize node-java
      Alloy.java ?= require "java"

      # Load alloy jar file
      Alloy.java.classpath.push(@alloyJarPath)

      # import the required class
      Alloy.compUtil ?= Alloy.java.import("edu.mit.csail.sdg.alloy4compiler.parser.CompUtil")

    @emitter = new Emitter()
    @worlds = {}

  destroy: () ->
    @emitter.dispose()
    @worlds = {}

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
        @worlds[path] = result # store world to use in future tasks
        @emitter.emit("CompileDone", {
          path: path
          result: result
        })
    )

  getCommands: (world) ->
    world.getAllCommandsSync().toArraySync()

  onCompileStarted: (callback) -> @emitter.on("CompileStarted", callback)
  onCompileError: (callback) -> @emitter.on("CompileError", callback)
  onCompileDone: (callback) -> @emitter.on("CompileDone", callback)
