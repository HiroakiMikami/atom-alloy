module.exports =
class PromiseWithJava
  taskQueue: null
  recentResult: null

  constructor: ->
    @taskQueue = []

  destroy: ->
    @cancelCurrentTask()
    @taskQueue = []

  execute: ->
    return if @taskQueue.length == 0

    if @taskQueue[0].condition? &&
       (not @recentResult? || (@taskQueue[0].condition != @recentResult.result?))
      @taskFinished()
    else
      @taskQueue[0].task(@succeeded, @rejected, @recentResult)

  executeIfNecessary: ->
    return unless @taskQueue.length == 1

    @execute()
  taskFinished: ->
    # Remove the current task
    @taskQueue.shift()

    # Execute the next task
    @execute()

  enqueue: (taskInfo) -> @taskQueue.push(taskInfo)
  then: (task, canceled) ->
    @enqueue({
      condition: null
      task: task
      canceled: canceled
    })
    @executeIfNecessary()
  ifSucceeded: (task, canceled) ->
    @enqueue({
      condition: true
      task: task
      canceled: canceled
    })
    @executeIfNecessary()
  ifFailed: (task, canceled) ->
    @enqueue({
      condition: false
      task: task
      canceled: canceled
    })
    @executeIfNecessary()
  cancelCurrentTask: ->
    return unless @taskQueue.length != 0
    if @taskQueue[0].canceled? then @taskQueue[0].canceled()
    @taskFinished()

  succeeded: (result) =>
    @recentResult = {
      result: result
    }
    @taskFinished()
  rejected: (err) =>
    @recentResult = {
      err: err
    }
    @taskFinished()
