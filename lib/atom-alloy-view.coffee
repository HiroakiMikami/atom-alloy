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
    # extract error message from result.err
    errorMessage = ""
    lines = result.err.message.split("\n")
    lines.shift() # remove the first line because the first line is a message from node-java
    for line in lines
      if /^\s+at.*/.test(line)
        # ignore this line because this is stack trace of Java
        break
      else
        errorMessage += "#{line}\n"

    atom.notifications.addError("Atom Alloy", {
      detail: errorMessage
    })
    @element.innerText = ""
  compileDone: (result) =>
    atom.notifications.addSuccess("Atom Alloy", {
      detail: "succeed in compiling #{@getFilename(result.path)}"
    })
    @element.innerText = ""
