{Emitter} = require 'atom'

module.exports =
class AtomAlloyView
  element: null
  descriptionText: null
  cancelText: null
  emitter: null
  constructor: (serializedState) ->
    @element = document.createElement("div")
    @element.is = "status-bar-atom-alloy"
    @element.className = "inline-block"

    @descriptionText = document.createElement("span")

    @cancelText = document.createElement("a")
    @cancelText.innerText = "(cancel)" # TODO I want to change this to an icon.

    @element.appendChild(@descriptionText)
    @element.appendChild(@cancelText)

    @emitter = new Emitter

    handler = () =>
      @cancelText.style["display"] = "none"
      @descriptionText.innerText = ""
      @emitter.emit("Canceled")

    @cancelText.addEventListener("click", handler, true)

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addLeftTile(item: @element, priority: 100)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  getFilename: (path) -> path.match(".+/(.+?)([\?#;].*)?$")[1]

  # Tear down any state and detach
  destroy: ->
    @element.remove()
    @cancelText.remove()
    @statusBarTile?.destroy()
    @emitter.dispose()

  onCanceled: (callback) => @emitter.on("Canceled", callback)

  # Event callback functions
  compileStarted: (path) =>
    @cancelText.style["display"] = ""
    @descriptionText.innerText = "Alloy4: compiling #{@getFilename(path)}..." if @element?
  compileError: (result) =>
    atom.notifications.addError("Atom Alloy", {
      detail: @getErrorMessage(result.err)
    })
    @cancelText.style["display"] = "none"
    @descriptionText.innerText = ""
  compileDone: (result) =>
    atom.notifications.addSuccess("Atom Alloy", {
      detail: "succeed in compiling #{@getFilename(result.path)}"
    })
    @cancelText.style["display"] = "none"
    @descriptionText.innerText = ""
  executeStarted: (command) =>
    @cancelText.style["display"] = ""
    @descriptionText.innerText = "Alloy4: executing #{command.label}..." if @element?
  executeError: (result) =>
    atom.notifications.addError("Atom Alloy", {
      detail: @getErrorMessage(result.err)
    })
    @cancelText.style["display"] = "none"
    @descriptionText.innerText = ""
  executeDone: (result) =>
    solution = result.result
    satisfiable = solution.satisfiableSync() # TODO Java method is called outside of Alloy class

    if result.command.check
      if satisfiable
        isError = true
        message = "counterexamples found. Assertion is invalid."
      else
        isError = false
        message = "No counterexample found. Assertion may be valid."
    else
      if satisfiable
        isError = false
        message = "Instances found. Predicate is consistent."
      else
        isError = true
        message = "No instance found. Predicate may be inconsistent."

    if isError
      atom.notifications.addError("Atom Alloy #{result.command.label}", {
        detail: "#{message}"
      })
    else
      atom.notifications.addInfo("Atom Alloy #{result.command.label}", {
        detail: "#{message}"
      })
    @cancelText.style["display"] = "none"
    @descriptionText.innerText = ""

  getErrorMessage: (err) ->
    # extract error message from result.err
    errorMessage = ""
    lines = err.message.split("\n")
    lines.shift() # remove the first line because the first line is a message from node-java
    for line in lines
      if /^\s+at.*/.test(line)
        # ignore this line because this is stack trace of Java
        break
      else
        errorMessage += "#{line}\n"
    return errorMessage
