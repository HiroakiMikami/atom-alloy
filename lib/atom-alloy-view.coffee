module.exports =
class AtomAlloyView
  element: null
  constructor: (serializedState) ->
    @element = document.createElement("div")
    @element.is = "status-bar-atom-alloy"
    @element.className = "inline-block"

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addLeftTile(item: @element, priority: 100)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  getFilename: (path) -> path.match(".+/(.+?)([\?#;].*)?$")[1]

  # Tear down any state and detach
  destroy: ->
    @element.remove()
    @statusBarTile?.destroy()

  # Event callback functions
  compileStarted: (path) =>
    @element.innerText = "Alloy4: compiling #{@getFilename(path)}..." if @element?
  compileError: (result) =>
    atom.notifications.addError("Atom Alloy", {
      detail: @getErrorMessage(result.err)
    })
    @element.innerText = ""
  compileDone: (result) =>
    atom.notifications.addSuccess("Atom Alloy", {
      detail: "succeed in compiling #{@getFilename(result.path)}"
    })
    @element.innerText = ""
  executeStarted: (command) =>
    @element.innerText = "Alloy4: executing #{command.label}..." if @element?
  executeError: (result) =>
    atom.notifications.addError("Atom Alloy", {
      detail: @getErrorMessage(result.err)
    })
    @element.innerText = ""
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
    @element.innerText = ""

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
